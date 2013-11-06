//
//  HOTPGeneratorTests.m
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
#import "OTPToken+Generation.h"

@interface OTPToken ()
- (NSString *)generatePasswordForCounter:(uint64_t)counter;
@end


@interface HOTPGeneratorTests : XCTestCase
@end


@implementation HOTPGeneratorTests

// The values in this test are found in Appendix D of the HOTP RFC
// https://tools.ietf.org/html/rfc4226#appendix-D
- (void)testRFCValues
{
    NSData *secret = [@"12345678901234567890" dataUsingEncoding:NSASCIIStringEncoding];
    OTPToken *token = [[OTPToken alloc] init];
    token.type = OTPTokenTypeCounter;
    token.secret = secret;
    token.algorithm = OTPAlgorithmSHA1;
    token.digits = 6;
    token.counter = 0;

    XCTAssertEqualObjects(@"755224", [token generatePasswordForCounter:0], @"The 0th OTP should be the expected string.");
    XCTAssertEqualObjects(@"755224", [token generatePasswordForCounter:0], @"The generatePasswordForCounter: method should be idempotent.");

    NSArray *expectedValues = @[@"287082",
                                @"359152",
                                @"969429",
                                @"338314",
                                @"254676",
                                @"287922",
                                @"162583",
                                @"399871",
                                @"520489"];

    for (NSString *expectedPassword in expectedValues) {
        [token updatePassword];
        XCTAssertEqualObjects(token.password, expectedPassword, @"The generator did not produce the expected OTP.");
    }
}

@end
