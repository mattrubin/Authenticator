//
//  OTPTokenPersistenceTests.m
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
@import Security.SecItem;
#import "OTPToken+Persistence.h"
#import "OTPToken+Serialization.h"


static const unsigned char kValidSecret[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };

static NSURL *kValidTokenURL;


@interface OTPToken ()
+ (instancetype)tokenWithKeychainDictionary:(NSDictionary *)keychainDictionary;
@end


@interface OTPTokenPersistenceTests : XCTestCase

@end


@implementation OTPTokenPersistenceTests

+ (void)setUp
{
    kValidTokenURL = [NSURL URLWithString:@"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4"];
}

- (void)testTokenWithKeychainDictionary
{
    NSData *secret = [NSData dataWithBytes:kValidSecret length:sizeof(kValidSecret)];
    NSData *urlData = [@"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keychainItemRef = [[NSData alloc] initWithBase64EncodedString:@"Z2VucAAAAAAAAAAQ" options:NSDataBase64DecodingIgnoreUnknownCharacters];

    OTPToken *token = [OTPToken tokenWithKeychainDictionary:@{(__bridge id)kSecAttrGeneric: urlData,
                                                              (__bridge id)kSecValueData: secret,
                                                              (__bridge id)kSecValuePersistentRef: keychainItemRef,
                                                              }];

    XCTAssertEqual(token.type, OTPTokenTypeTimer);
    XCTAssertEqualObjects(token.name, @"Léon");
    XCTAssertEqual(token.algorithm, OTPAlgorithmSHA256);
    XCTAssertTrue(ABS(token.period - 45.0) < DBL_EPSILON);
    XCTAssertEqual(token.digits, 8U);

    XCTAssertEqualObjects(token.secret, secret);

    XCTAssertEqualObjects(token.keychainItemRef, keychainItemRef);
    XCTAssertTrue(token.isInKeychain);
}

- (void)testTokenWithKeychainItemRef
{
    // Create a token
    OTPToken *token = [OTPToken tokenWithURL:kValidTokenURL];

    XCTAssertEqual(token.type, OTPTokenTypeTimer);
    XCTAssertEqualObjects(token.name, @"Léon");
    XCTAssertEqual(token.algorithm, OTPAlgorithmSHA256);
    XCTAssertTrue(ABS(token.period - 45.0) < DBL_EPSILON);
    XCTAssertEqual(token.digits, 8U);

    XCTAssertEqualObjects(token.secret, [NSData dataWithBytes:kValidSecret length:sizeof(kValidSecret)]);

    // Save the token
    XCTAssertFalse(token.isInKeychain);
    XCTAssertNil(token.keychainItemRef);

    XCTAssertTrue([token saveToKeychain]);

    XCTAssertTrue(token.isInKeychain);
    XCTAssertNotNil(token.keychainItemRef);

    // Restore the token
    NSData *keychainItemRef = token.keychainItemRef;

    OTPToken *secondToken = [OTPToken tokenWithKeychainItemRef:keychainItemRef];

    XCTAssertEqual(secondToken.type, OTPTokenTypeTimer);
    XCTAssertEqualObjects(secondToken.name, @"Léon");
    XCTAssertEqual(secondToken.algorithm, OTPAlgorithmSHA256);
    XCTAssertTrue(ABS(secondToken.period - 45.0) < DBL_EPSILON);
    XCTAssertEqual(secondToken.digits, 8U);

    XCTAssertEqualObjects(secondToken.secret, [NSData dataWithBytes:kValidSecret length:sizeof(kValidSecret)]);

    XCTAssertEqualObjects(secondToken.keychainItemRef, token.keychainItemRef);
    XCTAssertTrue(secondToken.isInKeychain);

    // Remove the token
    XCTAssertTrue(token.isInKeychain);
    XCTAssertNotNil(token.keychainItemRef);

    XCTAssertTrue([token removeFromKeychain]);

    XCTAssertFalse(token.isInKeychain);
    XCTAssertNil(token.keychainItemRef);

    // Attempt to restore the deleted token
    OTPToken *thirdToken = [OTPToken tokenWithKeychainItemRef:keychainItemRef];
    XCTAssertNil(thirdToken);

}

- (void)testDuplicateURLs
{
    OTPToken *token1 = [OTPToken tokenWithURL:kValidTokenURL];
    OTPToken *token2 = [OTPToken tokenWithURL:kValidTokenURL];

    XCTAssertFalse(token1.isInKeychain, @"Token should not be in keychain: %@", token1);
    XCTAssertFalse(token2.isInKeychain, @"Token should not be in keychain: %@", token2);

    XCTAssertTrue([token1 saveToKeychain], @"Failed to save to keychain: %@", token1);
    XCTAssertTrue([token2 saveToKeychain], @"Failed to save to keychain: %@", token2);

    XCTAssertTrue(token1.isInKeychain, @"Token should be in keychain: %@", token1);
    XCTAssertTrue(token2.isInKeychain, @"Token should be in keychain: %@", token2);

    XCTAssertTrue([token1 removeFromKeychain], @"Failed to remove from keychain: %@", token1);
    XCTAssertTrue([token2 removeFromKeychain], @"Failed to remove from keychain: %@", token2);

    XCTAssertFalse(token1.isInKeychain, @"Token should not be in keychain: %@", token1);
    XCTAssertFalse(token2.isInKeychain, @"Token should not be in keychain: %@", token2);
}

@end
