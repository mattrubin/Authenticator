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


@interface OTPGenerator ()
@end

@implementation OTPGenerator

- (id)init {
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super init])) {
    self.token = token;

    if (![token validate]) {
      NSLog(@"Attempted to initialize generator with invalid token: %@", token);
      self = nil;
    }
  }
  return self;
}


- (NSString *)generateOTP {
    OTPToken *token = self.token;
    NSAssert(token, @"The generator must have a token");
    if (token.type == OTPTokenTypeCounter) {
        uint64_t counter = [token counter];
        counter += 1;
        NSString *otp = [self generateOTPForCounter:counter];
        [token setCounter:counter];
        return otp;
    } else if (token.type == OTPTokenTypeTimer) {
        return [self generateOTPForDate:[NSDate date]];
    }
    // If type is undefined, fail
  [self doesNotRecognizeSelector:_cmd];
  return nil;
}

- (NSString *)generateOTPForDate:(NSDate *)date {
    OTPToken *token = self.token;
    NSAssert(token, @"The generator must have a token");
    if (!date) {
        // If no now date specified, use the current date.
        date = [NSDate date];
    }

    NSTimeInterval seconds = [date timeIntervalSince1970];
    uint64_t counter = (uint64_t)(seconds / token.period);
    return [self generateOTPForCounter:counter];
}

- (NSString *)generateOTPForCounter:(uint64_t)counter {
    OTPToken *token = self.token;
    NSAssert([token validate], @"The generator must have a valid token");
    if (![token validate]) {
        return nil;
    }

    NSUInteger hashLength = [self hashLengthForAlgorithm:token.algorithm];
  NSMutableData *hash = [NSMutableData dataWithLength:hashLength];

  counter = NSSwapHostLongLongToBig(counter);
  NSData *counterData = [NSData dataWithBytes:&counter
                                       length:sizeof(counter)];
  CCHmacContext ctx;
  CCHmacInit(&ctx, token.algorithm, [token.secret bytes], [token.secret length]);
  CCHmacUpdate(&ctx, [counterData bytes], [counterData length]);
  CCHmacFinal(&ctx, [hash mutableBytes]);

  const char *ptr = [hash bytes];
  unsigned char offset = ptr[hashLength-1] & 0x0f;
  unsigned long truncatedHash =
    NSSwapBigLongToHost(*((unsigned long *)&ptr[offset])) & 0x7fffffff;
  unsigned long pinValue = truncatedHash % kPinModTable[token.digits];

#ifdef DEBUG
    NSLog(@"secret: %@", token.secret);
    NSLog(@"counter: %llu", counter);
    NSLog(@"hash: %@", hash);
    NSLog(@"offset: %d", offset);
    NSLog(@"truncatedHash: %lu", truncatedHash);
    NSLog(@"pinValue: %lu", pinValue);
#endif

  return [NSString stringWithFormat:@"%0*ld", token.digits, pinValue];
}

- (NSUInteger)hashLengthForAlgorithm:(OTPAlgorithm)algorithm
{
    switch (algorithm) {
        case OTPAlgorithmSHA1:
            return CC_SHA1_DIGEST_LENGTH;
        case OTPAlgorithmSHA256:
            return CC_SHA256_DIGEST_LENGTH;
        case OTPAlgorithmSHA512:
            return CC_SHA512_DIGEST_LENGTH;
        case OTPAlgorithmMD5:
            return CC_MD5_DIGEST_LENGTH;
    }
}

@end
