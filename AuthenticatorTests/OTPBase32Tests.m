//
//  OTPBase32Tests.m
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
#import <Base32/MF_Base32Additions.h>


@interface OTPBase32Tests : XCTestCase
@end


@implementation OTPBase32Tests

// The values in this test are found in Section 10 of the Base32 RFC
// https://tools.ietf.org/html/rfc4648#section-10
- (void)testRFCValues
{
    NSDictionary *vectors = @{@"":       @"",
                              @"f":      @"MY======",
                              @"fo":     @"MZXQ====",
                              @"foo":    @"MZXW6===",
                              @"foob":   @"MZXW6YQ=",
                              @"fooba":  @"MZXW6YTB",
                              @"foobar": @"MZXW6YTBOI======"};
    [self _testEncodingWithVectors:vectors];
    [self _testDecodingWithVectors:vectors];
}

- (void)testUnpaddedRFCValues
{
    NSDictionary *vectors = @{@"":       @"",
                              @"f":      @"MY",
                              @"fo":     @"MZXQ",
                              @"foo":    @"MZXW6",
                              @"foob":   @"MZXW6YQ",
                              @"fooba":  @"MZXW6YTB",
                              @"foobar": @"MZXW6YTBOI"};
    [self _testDecodingWithVectors:vectors];
}

- (void)testUnpaddedLowercaseRFCValues
{
    NSDictionary *vectors = @{@"":       @"",
                              @"f":      @"my",
                              @"fo":     @"mzxq",
                              @"foo":    @"mzxw6",
                              @"foob":   @"mzxw6yq",
                              @"fooba":  @"mzxw6ytb",
                              @"foobar": @"mzxw6ytboi"};
    [self _testDecodingWithVectors:vectors];
}


- (void)_testEncodingWithVectors:(NSDictionary *)vectors
{
    for (NSString *plaintext in vectors) {
        NSString *ciphertext = vectors[plaintext];

        NSString *encryptedPlaintext = [[plaintext dataUsingEncoding:NSUTF8StringEncoding] base32String];
        XCTAssertEqualObjects(encryptedPlaintext, ciphertext, @"");
    }
}

- (void)_testDecodingWithVectors:(NSDictionary *)vectors
{
    for (NSString *plaintext in vectors) {
        NSString *ciphertext = vectors[plaintext];

        NSString *decryptedCiphertext = [[NSString alloc] initWithData:[NSData dataWithBase32String:ciphertext] encoding:NSUTF8StringEncoding];
        XCTAssertEqualObjects(decryptedCiphertext, plaintext, @"");
    }
}

@end
