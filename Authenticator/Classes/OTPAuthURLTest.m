//
//  OTPAuthURLTest.m
//
//  Copyright 2013 Matt Rubin
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

@import XCTest;
#import "OTPToken+Serialization.h"
#import "OTPToken+Persistence.h"

static NSString *const kValidLabel = @"Léon";
static NSString *const kValidAlgorithm = @"SHA256";
static const unsigned char kValidSecret[] =
    { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
      0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };
static const NSUInteger kValidDigits = 8;
static const NSTimeInterval kValidPeriod = 45;

static NSString *const kValidTOTPURLWithoutSecret =
    @"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45";

static NSString *const kValidTOTPURL =
    @"otpauth://totp/L%C3%A9on?algorithm=SHA256&digits=8&period=45"
    @"&secret=AAAQEAYEAUDAOCAJBIFQYDIOB4";


@interface OTPToken ()

+ (instancetype)tokenWithKeychainDictionary:(NSDictionary *)keychainDictionary;
@property (nonatomic, readonly) BOOL isInKeychain;

@end

@interface OTPAuthURLTest : XCTestCase
@end

@implementation OTPAuthURLTest

- (void)testInitWithKeychainDictionary {
  NSData *secret = [NSData dataWithBytes:kValidSecret
                                  length:sizeof(kValidSecret)];
  NSData *urlData = [kValidTOTPURLWithoutSecret
                     dataUsingEncoding:NSUTF8StringEncoding];

  OTPToken *token = [OTPToken tokenWithKeychainDictionary:
                     [NSDictionary dictionaryWithObjectsAndKeys:
                      urlData, (id)kSecAttrGeneric,
                      secret, (id)kSecValueData,
                      nil]];

  XCTAssertEqualObjects([token name], kValidLabel, @"Léon");

  XCTAssertEqualObjects([token secret], secret);
  XCTAssertEqualObjects([NSString stringForAlgorithm:token.algorithm], kValidAlgorithm);
  XCTAssertEqual([token period], kValidPeriod);
  XCTAssertEqual([token digits], kValidDigits);

  XCTAssertFalse([token isInKeychain]);
}


- (void)testInitWithOTPGeneratorLabel {
    OTPToken *token = [[OTPToken alloc] init];
    token.name = kValidLabel;
    token.type = OTPTokenTypeTimer;
    token.secret = [NSData data];

    XCTAssertEqualObjects([token name], kValidLabel);
    XCTAssertFalse([token isInKeychain]);
}


- (void)testDuplicateURLs {
  NSURL *url = [NSURL URLWithString:kValidTOTPURL];
  OTPToken *token1 = [OTPToken tokenWithURL:url];
  OTPToken *token2 = [OTPToken tokenWithURL:url];
  XCTAssertTrue([token1 saveToKeychain]);
  XCTAssertTrue([token2 saveToKeychain]);
  XCTAssertTrue([token1 removeFromKeychain],
               @"Your keychain may now have an invalid entry %@", token1);
  XCTAssertTrue([token2 removeFromKeychain],
               @"Your keychain may now have an invalid entry %@", token2);
}

@end
