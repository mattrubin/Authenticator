//
//  OTPAuthURL.m
//
//  Copyright 2013 Matt Rubin
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "OTPAuthURL.h"

@import Security;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
#pragma clang diagnostic ignored "-Wauto-import"
#import <GTMNSDictionary+URLArguments.h>
#import <GTMNSString+URLArguments.h>
#import <GTMNSScanner+Unsigned.h>
#pragma clang diagnostic pop

#import "HOTPGenerator.h"
#import "TOTPGenerator.h"

#import "OTPToken.h"
#import "NSData+Base32.h"

static NSString *const kOTPAuthScheme = @"otpauth";
static NSString *const kTOTPAuthScheme = @"totp";
// These are keys in the otpauth:// query string.
static NSString *const kQueryAlgorithmKey = @"algorithm";
static NSString *const kQuerySecretKey = @"secret";
static NSString *const kQueryCounterKey = @"counter";
static NSString *const kQueryDigitsKey = @"digits";
static NSString *const kQueryPeriodKey = @"period";


static const NSTimeInterval kTOTPDefaultSecondsBeforeChange = 5;
NSString *const OTPAuthURLWillGenerateNewOTPWarningNotification
  = @"OTPAuthURLWillGenerateNewOTPWarningNotification";
NSString *const OTPAuthURLDidGenerateNewOTPNotification
  = @"OTPAuthURLDidGenerateNewOTPNotification";
NSString *const OTPAuthURLSecondsBeforeNewOTPKey
  = @"OTPAuthURLSecondsBeforeNewOTP";

@interface OTPAuthURL ()

// re-declare readwrite
@property (nonatomic, strong) OTPToken *token;

// Initialize an OTPAuthURL with a dictionary of attributes from a keychain.
+ (OTPAuthURL *)authURLWithKeychainDictionary:(NSDictionary *)dict;

// Initialize an OTPAuthURL object with an otpauth:// NSURL object.
- (id)initWithOTPGenerator:(OTPGenerator *)generator
                      name:(NSString *)name;

@end

@interface TOTPAuthURL ()
@property (nonatomic, readwrite, assign) NSTimeInterval lastProgress;
@property (nonatomic, readwrite, assign) BOOL warningSent;

+ (void)totpTimer:(NSTimer *)timer;
- (id)initWithTOTPURL:(NSURL *)url;
- (id)initWithName:(NSString *)name
            secret:(NSData *)secret
         algorithm:(NSString *)algorithm
            digits:(NSUInteger)digits
             query:(NSDictionary *)query;
@end

@interface HOTPAuthURL ()
+ (BOOL)isValidCounter:(NSString *)counter;
- (id)initWithName:(NSString *)name
            secret:(NSData *)secret
         algorithm:(NSString *)algorithm
            digits:(NSUInteger)digits
             query:(NSDictionary *)query;
@property(readwrite, copy, nonatomic) NSString *otpCode;

@end

@implementation OTPAuthURL
@dynamic otpCode;

+ (OTPAuthURL *)authURLWithURL:(NSURL *)url
                        secret:(NSData *)secret {
  OTPAuthURL *authURL = nil;
  NSString *urlScheme = [url scheme];
  if ([urlScheme isEqualToString:kTOTPAuthScheme]) {
    // Convert totp:// into otpauth://
    authURL = [[TOTPAuthURL alloc] initWithTOTPURL:url];
  } else if (![urlScheme isEqualToString:kOTPAuthScheme]) {
    // Required (otpauth://)
    _GTMDevLog(@"invalid scheme: %@", [url scheme]);
  } else {
    NSString *path = [url path];
    if ([path length] > 1) {
      // Optional UTF-8 encoded human readable description (skip leading "/")
      NSString *name = [[url path] substringFromIndex:1];

      NSDictionary *query =
        [NSDictionary gtm_dictionaryWithHttpArgumentsString:[url query]];

      // Optional algorithm=(SHA1|SHA256|SHA512|MD5) defaults to SHA1
      NSString *algorithm = [query objectForKey:kQueryAlgorithmKey];
      if (!algorithm) {
        algorithm = [OTPGenerator defaultAlgorithm];
      }
      if (!secret) {
        // Required secret=Base32EncodedKey
        NSString *secretString = [query objectForKey:kQuerySecretKey];
        secret = [secretString base32DecodedData];
      }
      // Optional digits=[68] defaults to 8
      NSString *digitString = [query objectForKey:kQueryDigitsKey];
      NSUInteger digits = 0;
      if (!digitString) {
        digits = [OTPGenerator defaultDigits];
      } else {
        digits = [digitString intValue];
      }

      NSString *type = [url host];
      if ([type isEqualToString:@"hotp"]) {
        authURL = [[HOTPAuthURL alloc] initWithName:name
                                              secret:secret
                                           algorithm:algorithm
                                              digits:digits
                                               query:query];
      } else if ([type isEqualToString:@"totp"]) {
        authURL = [[TOTPAuthURL alloc] initWithName:name
                                              secret:secret
                                           algorithm:algorithm
                                              digits:digits
                                               query:query];
      }
    }
  }
  return authURL;
}

+ (OTPAuthURL *)authURLWithKeychainItemRef:(NSData *)data {
  OTPAuthURL *authURL = nil;
  NSDictionary *result = [OTPToken keychainItemForPersistentRef:data];
  if (result) {
    authURL = [self authURLWithKeychainDictionary:result];
    authURL.token.keychainItemRef = data;
  }
  return authURL;
}

+ (OTPAuthURL *)authURLWithKeychainDictionary:(NSDictionary *)dict {
  NSData *urlData = [dict objectForKey:(__bridge id)kSecAttrGeneric];
  NSData *secretData = [dict objectForKey:(__bridge id)kSecValueData];
  NSString *urlString = [[NSString alloc] initWithData:urlData
                                               encoding:NSUTF8StringEncoding];
  NSURL *url = [NSURL URLWithString:urlString];
  return  [self authURLWithURL:url secret:secretData];
}

- (id)initWithOTPGenerator:(OTPGenerator *)generator
                      name:(NSString *)name {
  if ((self = [super init])) {
    if (!generator || !name) {
      _GTMDevLog(@"Bad Args Generator:%@ Name:%@", generator, name);
      self = nil;
    } else {
      self.token.generator = generator;
      self.token.name = name;
    }
  }
  return self;
}

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}


- (NSURL *)url {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (BOOL)saveToKeychain {
  return [self.token saveToKeychain];
}

- (BOOL)removeFromKeychain {
  return [self.token removeFromKeychain];
}

- (BOOL)isInKeychain {
  return self.token.isInKeychain;
}

- (void)generateNextOTPCode {
  _GTMDevLog(@"Called generateNextOTPCode on a non-HOTP generator");
}

- (NSString*)checkCode {
  return [self.token.generator generateOTPForCounter:0];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ %p> Name: %@ ref: %p checkCode: %@",
          [self class], self, self.token.name, self.token.keychainItemRef, self.checkCode];
}


#pragma mark - Internal Token

- (OTPToken *)token
{
    if (!_token) {
        _token = [[OTPToken alloc] init];
        _token.dataSource = self;
    }
    return _token;
}

- (NSData *)keychainItemRef DEPRECATED_ATTRIBUTE
{
    return [self.token keychainItemRef];
}

- (NSString *)name
{
    return [self.token name];
}

- (void)setName:(NSString *)name
{
    [self.token setName:name];
}



@end

@implementation TOTPAuthURL
static NSString *const TOTPAuthURLTimerNotification
  = @"TOTPAuthURLTimerNotification";

@synthesize generationAdvanceWarning = generationAdvanceWarning_;
@synthesize lastProgress = lastProgress_;
@synthesize warningSent = warningSent_;

+ (void)initialize {
  static NSTimer *sTOTPTimer = nil;
  if (!sTOTPTimer) {
    @autoreleasepool {
      sTOTPTimer = [NSTimer scheduledTimerWithTimeInterval:.01
                                                    target:self
                                                  selector:@selector(totpTimer:)
                                                  userInfo:nil
                                                   repeats:YES];
    }
  }
}

+ (void)totpTimer:(NSTimer *)timer {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:TOTPAuthURLTimerNotification object:self];
}

- (id)initWithOTPGenerator:(OTPGenerator *)generator
                      name:(NSString *)name {
  if ((self = [super initWithOTPGenerator:generator
                                     name:name])) {
    [self setGenerationAdvanceWarning:kTOTPDefaultSecondsBeforeChange];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(totpTimer:)
                                                 name:TOTPAuthURLTimerNotification
                                               object:nil];
  }
  return self;
}

- (id)initWithSecret:(NSData *)secret name:(NSString *)name {
  TOTPGenerator *generator
    = [[TOTPGenerator alloc] initWithSecret:secret
                                   algorithm:[TOTPGenerator defaultAlgorithm]
                                      digits:[TOTPGenerator defaultDigits]
                                      period:[TOTPGenerator defaultPeriod]];
  return [self initWithOTPGenerator:generator
                               name:name];
}

// totp:// urls are generated by the GAIA smsauthconfig page and implement
// a subset of the functionality available in otpauth:// urls, so we just
// translate to that internally.
- (id)initWithTOTPURL:(NSURL *)url {
  NSMutableString *name = nil;
  if ([[url user] length]) {
    name = [NSMutableString stringWithString:[url user]];
  }
  if ([url host]) {
    [name appendFormat:@"@%@", [url host]];
  }

  NSData *secret = [url.fragment base32DecodedData];
  return [self initWithSecret:secret name:name];
}

- (id)initWithName:(NSString *)name
            secret:(NSData *)secret
         algorithm:(NSString *)algorithm
            digits:(NSUInteger)digits
             query:(NSDictionary *)query {
  NSString *periodString = [query objectForKey:kQueryPeriodKey];
  NSTimeInterval period = 0;
  if (periodString) {
    period = [periodString doubleValue];
  } else {
    period = [TOTPGenerator defaultPeriod];
  }

  TOTPGenerator *generator
    = [[TOTPGenerator alloc] initWithSecret:secret
                                   algorithm:algorithm
                                      digits:digits
                                      period:period];

  if ((self = [self initWithOTPGenerator:generator
                                    name:name])) {
    self.lastProgress = period;
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)otpCode {
  return [self.token.generator generateOTP];
}

- (void)totpTimer:(NSTimer *)timer {
  TOTPGenerator *generator = (TOTPGenerator *)self.token.generator;
  NSTimeInterval delta = [[NSDate date] timeIntervalSince1970];
  NSTimeInterval period = [generator period];
  uint64_t progress = (uint64_t)delta % (uint64_t)period;
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  if (progress == 0 || progress > self.lastProgress) {
    [nc postNotificationName:OTPAuthURLDidGenerateNewOTPNotification object:self];
    self.lastProgress = period;
    self.warningSent = NO;
  } else if (progress > period - self.generationAdvanceWarning
             && !self.warningSent) {
    NSNumber *warning = [NSNumber numberWithDouble:ceil(period - progress)];
    NSDictionary *userInfo
      = [NSDictionary dictionaryWithObject:warning
                                    forKey:OTPAuthURLSecondsBeforeNewOTPKey];

    [nc postNotificationName:OTPAuthURLWillGenerateNewOTPWarningNotification
                      object:self
                    userInfo:userInfo];
    self.warningSent = YES;
  }
}

- (NSURL *)url {

  NSMutableDictionary *query = [NSMutableDictionary dictionary];
  TOTPGenerator *generator = (TOTPGenerator *)self.token.generator;
  Class generatorClass = [generator class];

  NSString *algorithm = [generator algorithm];
  if (![algorithm isEqualToString:[generatorClass defaultAlgorithm]]) {
    [query setObject:algorithm forKey:kQueryAlgorithmKey];
  }

  NSUInteger digits = [generator digits];
  if (digits != [generatorClass defaultDigits]) {
    id val = [NSNumber numberWithUnsignedInteger:digits];
    [query setObject:val forKey:kQueryDigitsKey];
  }

  NSTimeInterval period = [generator period];
  if (fpclassify(period - [generatorClass defaultPeriod]) != FP_ZERO) {
    id val = [NSNumber numberWithDouble:period];
    [query setObject:val forKey:kQueryPeriodKey];
  }

  return [NSURL URLWithString:[NSString stringWithFormat:@"%@://totp/%@?%@",
                               kOTPAuthScheme,
                               [self.token.name gtm_stringByEscapingForURLArgument],
                               [query gtm_httpArgumentsString]]];
}

@end

@implementation HOTPAuthURL

@synthesize otpCode = otpCode_;

- (id)initWithOTPGenerator:(OTPGenerator *)generator
               name:(NSString *)name {
  if ((self = [super initWithOTPGenerator:generator name:name])) {
    uint64_t counter = [(HOTPGenerator *)generator counter];
    self.otpCode = [generator generateOTPForCounter:counter];
  }
  return self;
}


- (id)initWithSecret:(NSData *)secret name:(NSString *)name {
  HOTPGenerator *generator
    = [[HOTPGenerator alloc] initWithSecret:secret
                                   algorithm:[HOTPGenerator defaultAlgorithm]
                                      digits:[HOTPGenerator defaultDigits]
                                     counter:[HOTPGenerator defaultInitialCounter]];
  return [self initWithOTPGenerator:generator name:name];
}

- (id)initWithName:(NSString *)name
            secret:(NSData *)secret
         algorithm:(NSString *)algorithm
            digits:(NSUInteger)digits
             query:(NSDictionary *)query {
  NSString *counterString = [query objectForKey:kQueryCounterKey];
  if ([[self class] isValidCounter:counterString]) {
    NSScanner *scanner = [NSScanner scannerWithString:counterString];
    uint64_t counter;
    BOOL goodScan = [scanner gtm_scanUnsignedLongLong:&counter];
    // Good scan should always be good based on the isValidCounter check above.
    _GTMDevAssert(goodScan, @"goodscan should be true: %c", goodScan);
    HOTPGenerator *generator
      = [[HOTPGenerator alloc] initWithSecret:secret
                                     algorithm:algorithm
                                        digits:digits
                                       counter:counter];
    self = [self initWithOTPGenerator:generator
                                 name:name];
  } else {
    _GTMDevLog(@"invalid counter: %@", counterString);
    self = [super initWithOTPGenerator:nil name:nil];
    self = nil;
  }

  return self;
}


- (void)generateNextOTPCode {
  self.otpCode = [self.token.generator generateOTP];
  [self saveToKeychain];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:OTPAuthURLDidGenerateNewOTPNotification object:self];
}

- (NSURL *)url {
  NSMutableDictionary *query = [NSMutableDictionary dictionary];

  HOTPGenerator *generator = (HOTPGenerator *)self.token.generator;
  Class generatorClass = [generator class];

  NSString *algorithm = [generator algorithm];
  if (![algorithm isEqualToString:[generatorClass defaultAlgorithm]]) {
    [query setObject:algorithm forKey:kQueryAlgorithmKey];
  }

  NSUInteger digits = [generator digits];
  if (digits != [generatorClass defaultDigits]) {
    id val = [NSNumber numberWithUnsignedInteger:digits];
    [query setObject:val forKey:kQueryDigitsKey];
  }

  uint64_t counter = [generator counter];
  id val = [NSNumber numberWithUnsignedLongLong:counter];
  [query setObject:val forKey:kQueryCounterKey];

  return [NSURL URLWithString:[NSString stringWithFormat:@"%@://hotp/%@?%@",
                               kOTPAuthScheme,
                               [self.token.name gtm_stringByEscapingForURLArgument],
                               [query gtm_httpArgumentsString]]];
}

+ (BOOL)isValidCounter:(NSString *)counter {
  NSCharacterSet *nonDigits =
    [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
  NSRange pos = [counter rangeOfCharacterFromSet:nonDigits];
  return pos.location == NSNotFound;
}

@end

