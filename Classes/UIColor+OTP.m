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

#define STATIC_RGB(NAME, RED, GREEN, BLUE) STATIC_COLOR(NAME,\
[UIColor colorWithRed:(RED)/255.f green:(GREEN)/255.f blue:(BLUE)/255.f alpha:1.0])



@implementation UIColor (OTP)

STATIC_RGB(otpBarColor, 0, 125, 210)
STATIC_RGB(otpBackgroundColor, 250, 253, 255)
STATIC_RGB(otpCellTextColor, 30, 60, 90)

@end
