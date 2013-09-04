//
//  UIColor+OTP.m
//
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

#import "UIColor+OTP.h"


@implementation UIColor (OTP)

+ (UIColor *)otpBarColor {
  return [UIColor colorWithRed:(float)0x5C/0xFF
                         green:(float)0x7D/0xFF
                          blue:(float)0xD2/0xFF
                         alpha:1.0];
}

+ (UIColor *)otpBackgroundColor {
  return [UIColor colorWithRed:(float)0xEB/0xFF
                         green:(float)0xEF/0xFF
                          blue:(float)0xF9/0xFF
                         alpha:1.0];
}

@end
