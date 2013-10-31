//
//  TOTPGenerator.m
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

#import "TOTPGenerator.h"
#import "OTPToken.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wauto-import"
#import <GTMDefines.h>
#pragma clang diagnostic pop


@implementation TOTPGenerator

- (id)initWithToken:(OTPToken *)token
{
  if ((self = [super initWithToken:token])) {
    if (token.period <= 0 || token.period > 300) {
      _GTMDevLog(@"Bad Period: %f", token.period);
      self = nil;
    }
  }
  return self;
}

- (NSString *)generateOTP {
  return [self generateOTPForDate:[NSDate date]];
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
  return [super generateOTPForCounter:counter];
}

@end
