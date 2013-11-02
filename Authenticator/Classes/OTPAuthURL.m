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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wauto-import"
#import <GTMDefines.h>
#pragma clang diagnostic pop

#import "OTPToken+Serialization.h"
#import "OTPToken+Persistence.h"


@interface OTPAuthURL ()

@property (nonatomic, strong) OTPToken *token;

@end


@implementation OTPAuthURL

+ (OTPAuthURL *)authURLWithURL:(NSURL *)url
                        secret:(NSData *)secret {
    OTPToken *token = [OTPToken tokenWithURL:url secret:secret];
    return [[self alloc] initWithToken:token];
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
    OTPToken *token = [OTPToken tokenWithType:type secret:secret name:name];
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
    [self.token updatePassword];
}

- (NSString*)checkCode {
    return self.token.verificationCode;
}

- (NSString *)description {
  return self.token.description;
}


#pragma mark - Internal Token

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

- (NSString *)otpCode
{
    return self.token.password;
}

@end
