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

- (NSString *)generateOTPForCounter:(uint64_t)counter {
    OTPToken *token = self.token;
    NSAssert([token validate], @"The generator must have a valid token");
    if (![token validate]) {
        return nil;
    }

  NSMutableData *hash = [NSMutableData dataWithLength:digestLengthForAlgorithm(token.algorithm)];

  counter = NSSwapHostLongLongToBig(counter);
  NSData *counterData = [NSData dataWithBytes:&counter
                                       length:sizeof(counter)];
  CCHmacContext ctx;
  CCHmacInit(&ctx, token.algorithm, [token.secret bytes], [token.secret length]);
  CCHmacUpdate(&ctx, [counterData bytes], [counterData length]);
  CCHmacFinal(&ctx, [hash mutableBytes]);

  const char *ptr = [hash bytes];
  unsigned char offset = ptr[hash.length-1] & 0x0f;
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

@end
