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

@end

@interface TOTPAuthURL ()
@property (nonatomic, readwrite, assign) NSTimeInterval lastProgress;
@property (nonatomic, readwrite, assign) BOOL warningSent;

+ (void)totpTimer:(NSTimer *)timer;
@end

@interface HOTPAuthURL ()
@property(readwrite, copy, nonatomic) NSString *otpCode;

@end

@implementation OTPAuthURL
@dynamic otpCode;

+ (OTPAuthURL *)authURLWithURL:(NSURL *)url
                        secret:(NSData *)secret {
  OTPAuthURL *authURL = nil;
    OTPToken *token = [OTPToken tokenWithURL:url secret:secret];

    if (token.type == OTPTokenTypeCounter) {
        authURL = [[HOTPAuthURL alloc] initWithToken:token];
    } else if (token.type == OTPTokenTypeTimer) {
        authURL = [[TOTPAuthURL alloc] initWithToken:token];
    }
  return authURL;
}

+ (OTPAuthURL *)authURLWithKeychainItemRef:(NSData *)data {
    OTPToken *token = [OTPToken tokenWithKeychainItemRef:data];
    return [[self alloc] initWithToken:token];
}

+ (OTPAuthURL *)authURLWithKeychainDictionary:(NSDictionary *)dict {
    OTPToken *token = [OTPToken tokenWithKeychainDictionary:dict];
    return [[self alloc] initWithToken:token];
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

        // Check that it's the right subclass (temporary)
        Class authURLClass = (token.type == OTPTokenTypeTimer) ? [TOTPAuthURL class] : [HOTPAuthURL class];
        if (self && ![self isKindOfClass:authURLClass]) {
            self = [[authURLClass alloc] initWithToken:token];
        }
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

- (void)generateNextOTPCode {
  self.otpCode = [self.token.generator generateOTP];
  [self saveToKeychain];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc postNotificationName:OTPAuthURLDidGenerateNewOTPNotification object:self];
}

@end

