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
#import "NSString+PercentEncoding.h"
#import "NSDictionary+QueryString.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#import <Base32/MF_Base32Additions.h>
#pragma clang diagnostic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#pragma clang diagnostic ignored "-Wauto-import"
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

+ (instancetype)tokenWithURL:(NSURL *)url
                        secret:(NSData *)secret {
    OTPToken *token = nil;
    NSString *urlScheme = [url scheme];
    if ([urlScheme isEqualToString:kTOTPAuthScheme]) {
        // Convert totp:// into otpauth://
        token = [self tokenWithTOTPURL:url];
    } else if (![urlScheme isEqualToString:kOTPAuthScheme]) {
        // Required (otpauth://)
        NSLog(@"invalid scheme: %@", [url scheme]);
    } else {
        NSString *path = [url path];
        if ([path length] > 1) {
            token = [[OTPToken alloc] init];
            // Optional UTF-8 encoded human readable description (skip leading "/")
            NSString *name = [[url path] substringFromIndex:1];

            NSDictionary *query =
            [NSDictionary gtm_dictionaryWithHttpArgumentsString:[url query]];

            // Optional algorithm=(SHA1|SHA256|SHA512|MD5) defaults to SHA1
            NSString *algorithm = [query objectForKey:kQueryAlgorithmKey];
            if (!algorithm) {
                algorithm = [NSString stringForAlgorithm:[OTPToken defaultAlgorithm]];
            }
            if (!secret) {
                // Required secret=Base32EncodedKey
                NSString *secretString = [query objectForKey:kQuerySecretKey];
                secret = [NSData dataWithBase32String:secretString];
            }
            // Optional digits=[68] defaults to 8
            NSString *digitString = [query objectForKey:kQueryDigitsKey];
            NSUInteger digits = 0;
            if (!digitString) {
                digits = [OTPToken defaultDigits];
            } else {
                digits = (NSUInteger)[digitString integerValue];
            }

            token.name = name;
            token.secret = secret;
            token.algorithm = [algorithm algorithmValue];
            token.digits = digits;

            NSString *type = [url host];
            if ([type isEqualToString:@"hotp"]) {
                token.type = OTPTokenTypeCounter;

                NSString *counterString = [query objectForKey:kQueryCounterKey];
                if ([self isValidCounter:counterString]) {
                    token.counter = strtoull([counterString UTF8String], NULL, 10);
                } else {
                    NSLog(@"invalid counter: %@", counterString);
                    token = nil;
                }
            } else if ([type isEqualToString:@"totp"]) {
                token.type = OTPTokenTypeTimer;

                NSString *periodString = [query objectForKey:kQueryPeriodKey];
                NSTimeInterval period = 0;
                if (periodString) {
                    period = [periodString doubleValue];
                } else {
                    period = [OTPToken defaultPeriod];
                }
                
                token.period = period;
            }
        }
    }
    if (![token validate])
        return nil;
    return token;
}

// totp:// urls are generated by the GAIA smsauthconfig page and implement
// a subset of the functionality available in otpauth:// urls, so we just
// translate to that internally.
+ (instancetype)tokenWithTOTPURL:(NSURL *)url
{
    NSMutableString *name = [NSMutableString string];
    if (url.user.length)
        [name appendString:url.user];
    if (url.user.length && url.host.length)
        [name appendString:@"@"];
    if (url.host.length)
        [name appendString:url.host];

    NSData *secret = [NSData dataWithBase32String:url.fragment];

    OTPToken *token = [[OTPToken alloc] init];
    token.type = OTPTokenTypeTimer;
    token.secret = secret;
    token.name = name;

    return token;
}

+ (BOOL)isValidCounter:(NSString *)counter {
    NSCharacterSet *nonDigits =
    [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange pos = [counter rangeOfCharacterFromSet:nonDigits];
    return pos.location == NSNotFound;
}


- (NSURL *)url
{
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    NSString *typeString;

    query[kQueryAlgorithmKey] = [NSString stringForAlgorithm:self.algorithm];
    query[kQueryDigitsKey] = @(self.digits);

    if (self.type == OTPTokenTypeTimer) {
        query[kQueryPeriodKey] = @(self.period);

        typeString = @"totp";
    } else if (self.type == OTPTokenTypeCounter) {
        query[kQueryCounterKey] = @(self.counter);

        typeString = @"hotp";
    }

    return [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/%@?%@",
                                 kOTPAuthScheme,
                                 typeString,
                                 [self.name percentEncodedString],
                                 [query queryString]]];
}

@end
