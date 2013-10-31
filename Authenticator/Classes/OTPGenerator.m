//
//  HOTPGenerator.m
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

#import "OTPGenerator.h"
#import "OTPToken.h"

#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonDigest.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wauto-import"
#import <GTMDefines.h>
#pragma clang diagnostic pop


static NSUInteger kPinModTable[] = {
  0,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
};

NSString *const kOTPGeneratorSHA1Algorithm = @"SHA1";
NSString *const kOTPGeneratorSHA256Algorithm = @"SHA256";
NSString *const kOTPGeneratorSHA512Algorithm = @"SHA512";
NSString *const kOTPGeneratorSHAMD5Algorithm = @"MD5";

@interface OTPGenerator ()
@end

@implementation OTPGenerator

+ (NSString *)defaultAlgorithm {
  return kOTPGeneratorSHA1Algorithm;
}

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super init])) {
    self.token = token;

    BOOL goodAlgorithm
      = ([token.algorithm isEqualToString:kOTPGeneratorSHA1Algorithm] ||
         [token.algorithm isEqualToString:kOTPGeneratorSHA256Algorithm] ||
         [token.algorithm isEqualToString:kOTPGeneratorSHA512Algorithm] ||
         [token.algorithm isEqualToString:kOTPGeneratorSHAMD5Algorithm]);
    if (!goodAlgorithm || token.digits > 8 || token.digits < 6 || !token.secret) {
      _GTMDevLog(@"Bad args digits(min 6, max 8): %d secret: %@ algorithm: %@",
                 token.digits, token.secret, token.algorithm);
      self = nil;
    }
  }
  return self;
}


// Must be overriden by subclass.
- (NSString *)generateOTP {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSString *)generateOTPForCounter:(uint64_t)counter {
    OTPToken *token = self.token;
    NSAssert(token, @"The generator must have a token");
    NSAssert(token.secret, @"The token must have a secret");
    NSAssert(token.algorithm, @"The token must have an algorithm");
  CCHmacAlgorithm alg;
  NSUInteger hashLength = 0;
  if ([token.algorithm isEqualToString:kOTPGeneratorSHA1Algorithm]) {
    alg = kCCHmacAlgSHA1;
    hashLength = CC_SHA1_DIGEST_LENGTH;
  } else if ([token.algorithm isEqualToString:kOTPGeneratorSHA256Algorithm]) {
    alg = kCCHmacAlgSHA256;
    hashLength = CC_SHA256_DIGEST_LENGTH;
  } else if ([token.algorithm isEqualToString:kOTPGeneratorSHA512Algorithm]) {
    alg = kCCHmacAlgSHA512;
    hashLength = CC_SHA512_DIGEST_LENGTH;
  } else if ([token.algorithm isEqualToString:kOTPGeneratorSHAMD5Algorithm]) {
    alg = kCCHmacAlgMD5;
    hashLength = CC_MD5_DIGEST_LENGTH;
  } else {
    _GTMDevAssert(NO, @"Unknown algorithm");
    return nil;
  }

  NSMutableData *hash = [NSMutableData dataWithLength:hashLength];

  counter = NSSwapHostLongLongToBig(counter);
  NSData *counterData = [NSData dataWithBytes:&counter
                                       length:sizeof(counter)];
  CCHmacContext ctx;
  CCHmacInit(&ctx, alg, [token.secret bytes], [token.secret length]);
  CCHmacUpdate(&ctx, [counterData bytes], [counterData length]);
  CCHmacFinal(&ctx, [hash mutableBytes]);

  const char *ptr = [hash bytes];
  unsigned char offset = ptr[hashLength-1] & 0x0f;
  unsigned long truncatedHash =
    NSSwapBigLongToHost(*((unsigned long *)&ptr[offset])) & 0x7fffffff;
  unsigned long pinValue = truncatedHash % kPinModTable[token.digits];

  _GTMDevLog(@"secret: %@", token.secret);
  _GTMDevLog(@"counter: %llu", counter);
  _GTMDevLog(@"hash: %@", hash);
  _GTMDevLog(@"offset: %d", offset);
  _GTMDevLog(@"truncatedHash: %lu", truncatedHash);
  _GTMDevLog(@"pinValue: %lu", pinValue);

  return [NSString stringWithFormat:@"%0*ld", token.digits, pinValue];
}

@end
