//
//  OTPAlgorithm.h
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

#import <CommonCrypto/CommonHMAC.h>


typedef NS_ENUM(CCHmacAlgorithm, OTPAlgorithm) {
    OTPAlgorithmSHA1   = kCCHmacAlgSHA1,
    OTPAlgorithmSHA256 = kCCHmacAlgSHA256,
    OTPAlgorithmSHA512 = kCCHmacAlgSHA512,
};

extern OTPAlgorithm OTPAlgorithmUnknown;

NSUInteger digestLengthForAlgorithm(OTPAlgorithm algorithm);


#pragma mark - String Representations

extern NSString *const kOTPAlgorithmSHA1;
extern NSString *const kOTPAlgorithmSHA256;
extern NSString *const kOTPAlgorithmSHA512;

@interface NSString (OTPAlgorithm)

+ (instancetype)stringForAlgorithm:(OTPAlgorithm)algorithm;

- (OTPAlgorithm)algorithmValue;

@end
