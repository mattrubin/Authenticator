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
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    NSString *typeString;

    query[kQueryAlgorithmKey] = self.algorithm;
    query[kQueryDigitsKey] = @(self.digits);

    if ([self.generator isKindOfClass:[TOTPGenerator class]]) {
        query[kQueryPeriodKey] = @([(TOTPGenerator *)self.generator period]);

        typeString = @"totp";
    } else if ([self.generator isKindOfClass:[HOTPGenerator class]]) {
        query[kQueryCounterKey] = @([(HOTPGenerator *)self.generator counter]);

        typeString = @"hotp";
    }

    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%@?%@",
                                 kOTPAuthScheme,
                                 typeString,
                                 [self.name gtm_stringByEscapingForURLArgument],
                                 [query gtm_httpArgumentsString]]];
}

@end
