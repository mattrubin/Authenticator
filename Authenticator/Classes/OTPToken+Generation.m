//
//  OTPToken+Generation.m
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

#import "OTPToken+Generation.h"
#import "OTPToken+Persistence.h"
#import "OTPGenerator.h"
@import ObjectiveC.runtime;


@interface OTPToken ()

@property (nonatomic, strong) OTPGenerator *generator;
@property (nonatomic, strong) NSString *password;

@end


@implementation OTPToken (Generation)

#pragma mark - Generation

- (OTPGenerator *)generator
{
    OTPGenerator *_generator = objc_getAssociatedObject(self, @selector(generator));
    if (!_generator) {
        _generator = [[OTPGenerator alloc] initWithToken:self];
    }
    return _generator;
}

- (void)setGenerator:(OTPGenerator *)generator
{
    objc_setAssociatedObject(self, @selector(generator), generator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)password
{
    NSString *_password = objc_getAssociatedObject(self, @selector(password));
    if (!_password) {
        if (self.type == OTPTokenTypeTimer) {
            _password = [self generatePassword];
        } else if (self.type == OTPTokenTypeCounter) {
            _password = [self.generator generateOTPForCounter:self.counter];
        }
    }
    return _password;
}

- (void)setPassword:(NSString *)password
{
    objc_setAssociatedObject(self, @selector(password), password, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)updatePassword
{
    // If this is a counter-based token, the generator's generateOTP method will increment the counter.
    // A timer-based token will simply regenerate the password for the current time.
    self.password = [self generatePassword];
    if (self.type == OTPTokenTypeCounter) {
        [self saveToKeychain];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPTokenDidUpdateNotification object:self];
}

- (NSString *)verificationCode
{
    return [self.generator generateOTPForCounter:0];
}


#pragma mark - Generator

- (NSString *)generatePassword
{
    if (self.type == OTPTokenTypeCounter) {
        self.counter++;
        return [self.generator generateOTPForCounter:self.counter];
    } else if (self.type == OTPTokenTypeTimer) {
        return [self generatePasswordForDate:[NSDate date]];
    }
    // If type is undefined, fail
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSString *)generatePasswordForDate:(NSDate *)date {
    if (!date) {
        // If no now date specified, use the current date.
        date = [NSDate date];
    }

    NSTimeInterval seconds = [date timeIntervalSince1970];
    uint64_t counter = (uint64_t)(seconds / self.period);
    return [self.generator generateOTPForCounter:counter];
}

@end
