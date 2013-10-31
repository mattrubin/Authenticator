//
//  OTPToken+Serialization.m
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

#import "OTPToken+Serialization.h"

#import "OTPAuthURL.h" // TEMPORARY
#pragma clang diagnostic ignored "-Wreceiver-is-weak" // TEMPORARY
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak" // TEMPORARY

#import "TOTPGenerator.h"
#import "HOTPGenerator.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#import <GTMNSString+URLArguments.h>
#import <GTMNSDictionary+URLArguments.h>
#pragma clang diagnostic pop


static NSString *const kOTPAuthScheme = @"otpauth";
static NSString *const kTOTPAuthScheme = @"totp";
static NSString *const kQueryAlgorithmKey = @"algorithm";
static NSString *const kQuerySecretKey = @"secret";
static NSString *const kQueryCounterKey = @"counter";
static NSString *const kQueryDigitsKey = @"digits";
static NSString *const kQueryPeriodKey = @"period";


@implementation OTPToken (Serialization)

- (NSURL *)url
{
    if ([self.dataSource isKindOfClass:[TOTPAuthURL class]]) {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];
        TOTPGenerator *generator = (TOTPGenerator *)self.generator;
        Class generatorClass = [generator class];

        NSString *algorithm = [generator algorithm];
        if (![algorithm isEqualToString:[generatorClass defaultAlgorithm]]) {
            [query setObject:algorithm forKey:kQueryAlgorithmKey];
        }

        NSUInteger digits = [generator digits];
        if (digits != [generatorClass defaultDigits]) {
            id val = [NSNumber numberWithUnsignedInteger:digits];
            [query setObject:val forKey:kQueryDigitsKey];
        }

        NSTimeInterval period = [generator period];
        if (fpclassify(period - [generatorClass defaultPeriod]) != FP_ZERO) {
            id val = [NSNumber numberWithDouble:period];
            [query setObject:val forKey:kQueryPeriodKey];
        }

        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://totp/%@?%@",
                                     kOTPAuthScheme,
                                     [self.name gtm_stringByEscapingForURLArgument],
                                     [query gtm_httpArgumentsString]]];
    } else if ([self.dataSource isKindOfClass:[HOTPAuthURL class]]) {
        NSMutableDictionary *query = [NSMutableDictionary dictionary];

        HOTPGenerator *generator = (HOTPGenerator *)self.generator;
        Class generatorClass = [generator class];

        NSString *algorithm = [generator algorithm];
        if (![algorithm isEqualToString:[generatorClass defaultAlgorithm]]) {
            [query setObject:algorithm forKey:kQueryAlgorithmKey];
        }

        NSUInteger digits = [generator digits];
        if (digits != [generatorClass defaultDigits]) {
            id val = [NSNumber numberWithUnsignedInteger:digits];
            [query setObject:val forKey:kQueryDigitsKey];
        }

        uint64_t counter = [generator counter];
        id val = [NSNumber numberWithUnsignedLongLong:counter];
        [query setObject:val forKey:kQueryCounterKey];

        return [NSURL URLWithString:[NSString stringWithFormat:@"%@://hotp/%@?%@",
                                     kOTPAuthScheme,
                                     [self.name gtm_stringByEscapingForURLArgument],
                                     [query gtm_httpArgumentsString]]];
    }
    return nil;
}

@end
