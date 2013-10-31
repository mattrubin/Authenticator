//
//  OTPToken.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPToken.h"
#import "OTPToken+Persistence.h"
#import "OTPGenerator.h"


NSString * const OTPTokenDidUpdateNotification = @"OTPTokenDidUpdateNotification";


@implementation OTPToken

- (id)init
{
    self = [super init];
    if (self) {
        self.algorithm = [self.class defaultAlgorithm];
        self.digits = [self.class defaultDigits];
        self.counter = [self.class defaultInitialCounter];
        self.period = [self.class defaultPeriod];
    }
    return self;
}

+ (OTPAlgorithm)defaultAlgorithm
{
    return OTPAlgorithmSHA1;
}

+ (NSUInteger)defaultDigits
{
    return 6;
}

+ (uint64_t)defaultInitialCounter
{
    return 1;
}

+ (NSTimeInterval)defaultPeriod
{
    return 30;
}


#pragma mark - Validation

- (BOOL)validate
{
    BOOL validType = (self.type == OTPTokenTypeCounter) || (self.type == OTPTokenTypeTimer);
    BOOL validSecret = !!self.secret;
    BOOL validAlgorithm = (self.algorithm == OTPAlgorithmSHA1 ||
                           self.algorithm == OTPAlgorithmSHA256 ||
                           self.algorithm == OTPAlgorithmSHA512 ||
                           self.algorithm == OTPAlgorithmMD5);
    BOOL validDigits = (self.digits <= 8) && (self.digits >= 6);

    BOOL validPeriod = (self.period > 0) && (self.period <= 300);

    return validType && validSecret && validAlgorithm && validDigits && validPeriod;
}


#pragma mark - Generation

- (OTPGenerator *)generator
{
    if (!_generator) {
        _generator = [[OTPGenerator alloc] initWithToken:self];
    }
    return _generator;
}

- (NSString *)password
{
    if (!_password) {
        if (self.type == OTPTokenTypeTimer) {
            _password = [self.generator generateOTP];
        } else if (self.type == OTPTokenTypeCounter) {
            _password = [self.generator generateOTPForCounter:self.counter];
        }
    }
    return _password;
}

- (void)updatePassword
{
    // If this is a counter-based token, the generator's generateOTP method will increment the counter.
    // A timer-based token will simply regenerate the password for the current time.
    self.password = [self.generator generateOTP];
    if (self.type == OTPTokenTypeCounter) {
        [self saveToKeychain];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPTokenDidUpdateNotification object:self];
}

@end
