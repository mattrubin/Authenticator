//
//  TOTPGeneratorTests.m
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
#import "TOTPGenerator.h"
#import "OTPToken.h"


@interface TOTPGeneratorTests : XCTestCase
@end


@implementation TOTPGeneratorTests

// The values in this test are found in Appendix B of the TOTP RFC
// https://tools.ietf.org/html/rfc6238#appendix-B
- (void)testRFCValues
{
    NSDictionary *secretKeys = @{kOTPAlgorithmSHA1:   @"12345678901234567890",
                                 kOTPAlgorithmSHA256: @"12345678901234567890123456789012",
                                 kOTPAlgorithmSHA512: @"1234567890123456789012345678901234567890123456789012345678901234"};

    NSArray *times = @[@59,
                       @1111111109,
                       @1111111111,
                       @1234567890,
                       @2000000000,
                       @20000000000];

    NSDictionary *expectedValues = @{kOTPAlgorithmSHA1:   @[@"94287082", @"07081804", @"14050471", @"89005924", @"69279037", @"65353130"],
                                     kOTPAlgorithmSHA256: @[@"46119246", @"68084774", @"67062674", @"91819424", @"90698825", @"77737706"],
                                     kOTPAlgorithmSHA512: @[@"90693936", @"25091201", @"99943326", @"93441116", @"38618901", @"47863826"]};

    for (NSString *algorithm in secretKeys) {
        NSData *secret = [secretKeys[algorithm] dataUsingEncoding:NSASCIIStringEncoding];
        OTPToken *token = [[OTPToken alloc] init];
        token.type = OTPTokenTypeTimer;
        token.secret = secret;
        token.algorithm = algorithm;
        token.digits = 8;
        token.period = 30;
        TOTPGenerator *generator = [[TOTPGenerator alloc] initWithToken:token];
        XCTAssertNotNil(generator, @"The generator should not be nil.");

        for (NSUInteger i = 0; i < times.count; i++) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[times[i] doubleValue]];
            NSString *password = expectedValues[algorithm][i];
            XCTAssertEqualObjects([generator generateOTPForDate:date], password, @"The generator did not produce the expected OTP.");
        }
    }
}

- (void)testGoogleValues
{
    NSData *secret = [@"12345678901234567890" dataUsingEncoding:NSASCIIStringEncoding];

    NSTimeInterval intervals[] = { 1111111111, 1234567890, 2000000000 };

    NSArray *algorithms = @[kOTPAlgorithmSHA1,
                            kOTPAlgorithmSHA256,
                            kOTPAlgorithmSHA512,
                            kOTPAlgorithmMD5];
    NSArray *results = @[// SHA1      SHA256     SHA512     MD5
                         @"050471", @"584430", @"380122", @"275841", // date1
                         @"005924", @"829826", @"671578", @"280616", // date2
                         @"279037", @"428693", @"464532", @"090484", // date3
                         ];

    for (NSUInteger i = 0, j = 0; i < sizeof(intervals)/sizeof(*intervals); i++) {
        for (NSString *algorithm in algorithms) {
            OTPToken *token = [[OTPToken alloc] init];
            token.type = OTPTokenTypeTimer;
            token.secret = secret;
            token.algorithm = algorithm;
            token.digits = 6;
            token.period = 30;
            TOTPGenerator *generator = [[TOTPGenerator alloc] initWithToken:token];

            NSDate *date = [NSDate dateWithTimeIntervalSince1970:intervals[i]];

            XCTAssertEqualObjects([results objectAtIndex:j],
                                  [generator generateOTPForDate:date],
                                  @"Invalid result %d, %@, %@", i, algorithm, date);
            j++;
        }
    }
}

@end
