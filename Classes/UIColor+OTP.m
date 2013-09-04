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


#define STATIC_COLOR(NAME, OBJECT) + (instancetype)NAME {\
    static UIColor *_NAME;\
    static dispatch_once_t onceToken;\
    dispatch_once(&onceToken, ^{\
        _NAME = OBJECT;\
    });\
    return _NAME;\
}\


@implementation UIColor (OTP)

STATIC_COLOR(otpBarColor,
             [UIColor colorWithRed:(float)0x5C/0xFF
                             green:(float)0x7D/0xFF
                              blue:(float)0xD2/0xFF
                             alpha:1.0])

STATIC_COLOR(otpBackgroundColor,
             [UIColor colorWithRed:(float)0xEB/0xFF
                             green:(float)0xEF/0xFF
                              blue:(float)0xF9/0xFF
                             alpha:1.0])

@end
