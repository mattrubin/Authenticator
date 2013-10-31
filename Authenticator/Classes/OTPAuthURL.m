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
#import <GTMNSScanner+Unsigned.h>
#pragma clang diagnostic pop

#import "OTPGenerator.h"

#import "OTPToken+Serialization.h"
#import "OTPToken+Persistence.h"
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
- (id)initWithToken:(OTPToken *)token;

- (id)initWithSecret:(NSData *)secret name:(NSString *)name type:(OTPTokenType)type;

@end

@interface TOTPAuthURL ()
@property (nonatomic, readwrite, assign) NSTimeInterval lastProgress;
@property (nonatomic, readwrite, assign) BOOL warningSent;

+ (void)totpTimer:(NSTimer *)timer;
- (id)initWithTOTPURL:(NSURL *)url;
@end

@interface HOTPAuthURL ()
+ (BOOL)isValidCounter:(NSString *)counter;
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
        OTPToken *token = [[OTPToken alloc] init];
      // Optional UTF-8 encoded human readable description (skip leading "/")
      NSString *name = [[url path] substringFromIndex:1];

      NSDictionary *query =
        [NSDictionary gtm_dictionaryWithHttpArgumentsString:[url query]];

      // Optional algorithm=(SHA1|SHA256|SHA512|MD5) defaults to SHA1
      NSString *algorithm = [query objectForKey:kQueryAlgorithmKey];
      if (!algorithm) {
        algorithm = [NSString stringForAlgorithm:[OTPToken defaultAlgorithm]];
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
        digits = [OTPToken defaultDigits];
      } else {
        digits = [digitString intValue];
      }

        token.name = name;
        token.secret = secret;
        token.algorithm = [algorithm algorithmValue];
        token.digits = digits;

      NSString *type = [url host];
      if ([type isEqualToString:@"hotp"]) {
          token.type = OTPTokenTypeCounter;

          NSString *counterString = [query objectForKey:kQueryCounterKey];
          if ([HOTPAuthURL isValidCounter:counterString]) {
              NSScanner *scanner = [NSScanner scannerWithString:counterString];
              uint64_t counter;
              BOOL goodScan = [scanner gtm_scanUnsignedLongLong:&counter];
              // Good scan should always be good based on the isValidCounter check above.
              _GTMDevAssert(goodScan, @"goodscan should be true: %c", goodScan);

              token.counter = counter;
              authURL = [[HOTPAuthURL alloc] initWithToken:token];
          } else {
              _GTMDevLog(@"invalid counter: %@", counterString);
              authURL = nil;
          }
      } else if ([type isEqualToString:@"totp"]) {
          token.type = OTPTokenTypeTimer;

          NSString *periodString = [query objectForKey:kQueryPeriodKey];
          NSTimeInterval period = 0;
          if (periodString) {
              period = [periodString doubleValue];
          } else {
              period = [OTPToken defaultPeriod];
          }
          
          token.period = period;

        authURL = [[TOTPAuthURL alloc] initWithToken:token];
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

- (id)initWithSecret:(NSData *)secret name:(NSString *)name type:(OTPTokenType)type
{
    OTPToken *token = [[OTPToken alloc] init];
    token.type = type;
    token.name = name;
    token.secret = secret;
    return [self initWithToken:token];
}

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super init])) {
    if (!token || ![token validate]) {
      _GTMDevLog(@"Bad Token:%@", token);
      self = nil;
    } else {
      self.token = token;
    }
  }
  return self;
}

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}


- (NSURL *)url {
  return self.token.url;
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

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super initWithToken:token])) {
    [self setGenerationAdvanceWarning:kTOTPDefaultSecondsBeforeChange];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(totpTimer:)
                                                 name:TOTPAuthURLTimerNotification
                                               object:nil];
      self.lastProgress = token.period;
  }
  return self;
}

- (id)initWithSecret:(NSData *)secret name:(NSString *)name {
    return [self initWithSecret:secret name:name type:OTPTokenTypeTimer];
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

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)otpCode {
  return [self.token.generator generateOTP];
}

- (void)totpTimer:(NSTimer *)timer {
  NSTimeInterval delta = [[NSDate date] timeIntervalSince1970];
  NSTimeInterval period = self.token.period;
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

@end

@implementation HOTPAuthURL

@synthesize otpCode = otpCode_;

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super initWithToken:token])) {
    uint64_t counter = [token counter];
    self.otpCode = [token.generator generateOTPForCounter:counter];
  }
  return self;
}


- (id)initWithSecret:(NSData *)secret name:(NSString *)name {
    return [self initWithSecret:secret name:name type:OTPTokenTypeCounter];
}

- (void)generateNextOTPCode {
  self.otpCode = [self.token.generator generateOTP];
  [self saveToKeychain];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:OTPAuthURLDidGenerateNewOTPNotification object:self];
}

+ (BOOL)isValidCounter:(NSString *)counter {
  NSCharacterSet *nonDigits =
    [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
  NSRange pos = [counter rangeOfCharacterFromSet:nonDigits];
  return pos.location == NSNotFound;
}

@end

