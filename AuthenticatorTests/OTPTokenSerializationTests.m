//
//  OTPTokenSerializationTests.m
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

@import XCTest;
#import "OTPToken+Serialization.h"
#import "NSDictionary+QueryString.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#import <Base32/MF_Base32Additions.h>
#pragma clang diagnostic pop


static NSString * const kOTPScheme = @"otpauth";
static NSString * const kOTPTokenTypeCounterHost = @"hotp";
static NSString * const kOTPTokenTypeTimerHost   = @"totp";
static NSString * const kRandomKey = @"RANDOM";

static NSArray *typeNumbers;
static NSArray *names;
static NSArray *secretStrings;
static NSArray *algorithmNumbers;
static NSArray *digitNumbers;
static NSArray *periodNumbers;
static NSArray *counterNumbers;


@interface OTPTokenSerializationTests : XCTestCase

@end


@implementation OTPTokenSerializationTests

+ (void)setUp
{
    [super setUp];

    typeNumbers = @[@(OTPTokenTypeCounter), @(OTPTokenTypeTimer)]; // TODO: OTPTokenTypeUndefined
    names = @[@"", @"Login", @"user123@website.com", @"Léon", @":/?#[]@!$&'()*+,;=%\""]; // TODO: nil
    secretStrings = @[@"12345678901234567890", @"12345678901234567890123456789012",
                      @"1234567890123456789012345678901234567890123456789012345678901234"]; // TODO: @"", nil
    algorithmNumbers = @[@(OTPAlgorithmMD5), @(OTPAlgorithmSHA1), @(OTPAlgorithmSHA256), @(OTPAlgorithmSHA512)]; // TODO: OTPAlgorithmUnknown
    digitNumbers = @[@6, @7, @8];
    periodNumbers = @[@0, @1, @([OTPToken defaultPeriod]), kRandomKey];
    counterNumbers = @[@0, @1, @([OTPToken defaultInitialCounter]), kRandomKey];

}

- (void)testDeserialization
{
    for (NSNumber *typeNumber in typeNumbers) {
        for (NSString *name in names) {
            for (NSString *secretString in secretStrings) {
                for (NSNumber *algorithmNumber in algorithmNumbers) {
                    for (NSNumber *digitNumber in digitNumbers) {
                        for (NSNumber *periodNumber in periodNumbers) {
                            for (NSNumber *counterNumber in counterNumbers) {
                                // Construct the URL
                                NSMutableDictionary *query = [NSMutableDictionary dictionary];
                                query[@"algorithm"] = [NSString stringForAlgorithm:[algorithmNumber unsignedIntValue]];
                                query[@"digits"] = digitNumber;
                                query[@"secret"] = [[[secretString dataUsingEncoding:NSASCIIStringEncoding] base32String] stringByReplacingOccurrencesOfString:@"=" withString:@""];
                                query[@"period"] = [periodNumber isEqual:kRandomKey] ? @(arc4random()%299 + 1) : periodNumber;
                                query[@"counter"] = [counterNumber isEqual:kRandomKey] ? @(arc4random() + ((uint64_t)arc4random() << 32)) : counterNumber;

                                NSURLComponents *urlComponents = [NSURLComponents new];
                                urlComponents.scheme = kOTPScheme;
                                urlComponents.host = [NSString stringForTokenType:[typeNumber unsignedIntegerValue]];
                                urlComponents.path = [@"/" stringByAppendingString:name];
                                urlComponents.query = [query queryString];

                                // Create the token
                                OTPToken *token = [OTPToken tokenWithURL:[urlComponents URL]];

                                // Note: [OTPToken tokenWithURL:] will return nil if the token described by the URL is invalid.
                                if (token) {
                                    XCTAssertEqual(token.type, [typeNumber unsignedIntegerValue], @"Incorrect token type");
                                    XCTAssertEqualObjects(token.name, [name isEqualToString:@""] ? nil : name, @"Incorrect token name");
                                    XCTAssertEqualObjects(token.secret, [secretString dataUsingEncoding:NSASCIIStringEncoding], @"Incorrect token secret");
                                    XCTAssertEqual(token.algorithm, [algorithmNumber unsignedIntValue], @"Incorrect token algorithm");
                                    XCTAssertEqual(token.digits, [digitNumber unsignedIntegerValue], @"Incorrect token digits");
                                    XCTAssertEqual(token.period, [query[@"period"] doubleValue], @"Incorrect token period");
                                    XCTAssertEqual(token.counter, [query[@"counter"] unsignedLongLongValue], @"Incorrect token counter");
                                } else {
                                    // If nil was returned from [OTPToken tokenWithURL:], create the same token manually and ensure it's invalid
                                    OTPToken *invalidToken = [OTPToken new];
                                    invalidToken.type = [typeNumber unsignedIntegerValue];
                                    invalidToken.name = name;
                                    invalidToken.secret = [secretString dataUsingEncoding:NSASCIIStringEncoding];
                                    invalidToken.algorithm = [algorithmNumber unsignedIntValue];
                                    invalidToken.digits = [digitNumber unsignedIntegerValue];
                                    invalidToken.period = [query[@"period"] doubleValue];
                                    invalidToken.counter = [query[@"counter"] unsignedLongLongValue];

                                    XCTAssertFalse([invalidToken validate], @"The token should be invalid");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

- (void)test_tokenWithURL_secret
{
}

- (void)test_tokenWithOTPAuthURL
{
}

- (void)test_tokenWithTOTPURL
{
}

- (void)testSerialization
{
    for (NSNumber *typeNumber in typeNumbers) {
        for (NSString *name in names) {
            for (NSString *secretString in secretStrings) {
                for (NSNumber *algorithmNumber in algorithmNumbers) {
                    for (NSNumber *digitNumber in digitNumbers) {
                        for (NSNumber *periodNumber in periodNumbers) {
                            for (NSNumber *counterNumber in counterNumbers) {

                                NSTimeInterval period;
                                if ([periodNumber isEqual:kRandomKey]) {
                                    period = arc4random();
                                } else {
                                    period = [periodNumber doubleValue];
                                }

                                uint64_t counter;
                                if ([counterNumber isEqual:kRandomKey]) {
                                    counter = arc4random() + ((uint64_t)arc4random() << 32);
                                } else {
                                    counter = [counterNumber unsignedLongLongValue];
                                }

                                // Create the token
                                OTPToken *token = [OTPToken new];
                                token.type = [typeNumber unsignedIntegerValue];
                                token.name = name;
                                token.secret = [secretString dataUsingEncoding:NSASCIIStringEncoding];
                                token.algorithm = [algorithmNumber unsignedIntValue];
                                token.digits = [digitNumber unsignedIntegerValue];
                                token.period = period;
                                token.counter = counter;

                                // Serialize
                                NSURL *url = token.url;

                                // Test scheme
                                XCTAssertEqualObjects(url.scheme, kOTPScheme,
                                                      @"The url scheme should be \"%@\"", kOTPScheme);
                                // Test type
                                NSString *expectedHost = [typeNumber unsignedIntegerValue] == OTPTokenTypeCounter ? kOTPTokenTypeCounterHost : kOTPTokenTypeTimerHost;
                                XCTAssertEqualObjects(url.host, expectedHost,
                                                      @"The url host should be \"%@\"", expectedHost);
                                // Test name
                                XCTAssertEqualObjects([url.path substringFromIndex:1], name,
                                                      @"The url path should be \"%@\"", name);

                                NSDictionary *queryArguments = [NSDictionary dictionaryWithQueryString:url.query];

                                // Test algorithm
                                NSString *expectedAlgorithmString = [NSString stringForAlgorithm:[algorithmNumber unsignedIntValue]];
                                XCTAssertEqualObjects(queryArguments[@"algorithm"], expectedAlgorithmString,
                                                      @"The algorithm value should be \"%@\"", expectedAlgorithmString);
                                // Test digits
                                NSString *expectedDigitsString = [digitNumber stringValue];
                                XCTAssertEqualObjects(queryArguments[@"digits"], expectedDigitsString,
                                                      @"The digits value should be \"%@\"", expectedDigitsString);
                                // Test secret
                                XCTAssertNil(queryArguments[@"secret"], @"The url query string should not contain the secret");

                                // Test period
                                if ([typeNumber unsignedIntegerValue] == OTPTokenTypeTimer) {
                                    NSString *expectedPeriodString = [@(period) stringValue];
                                    XCTAssertEqualObjects(queryArguments[@"period"], expectedPeriodString,
                                                          @"The period value should be \"%@\"", expectedPeriodString);
                                } else {
                                    XCTAssertNil(queryArguments[@"period"], @"The url query string should not contain the period");
                                }
                                // Test counter
                                if ([typeNumber unsignedIntegerValue] == OTPTokenTypeCounter) {
                                    NSString *expectedCounterString = [@(counter) stringValue];
                                    XCTAssertEqualObjects(queryArguments[@"counter"], expectedCounterString,
                                                          @"The counter value should be \"%@\"", expectedCounterString);
                                } else {
                                    XCTAssertNil(queryArguments[@"counter"], @"The url query string should not contain the counter");
                                }

                                XCTAssertEqual(queryArguments.count, (NSUInteger)3, @"There shouldn't be any unexpected query arguments");

                                // Check url again
                                NSURL *checkURL = token.url;
                                XCTAssertEqualObjects(url, checkURL, @"Repeated calls to -url should return the same result!");
                            }
                        }
                    }
                }
            }
        }
    }
}

@end
