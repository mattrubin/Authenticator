//
//  OTPToken+Generation.m
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

#import "OTPToken+Generation.h"
#import "OTPToken+Persistence.h"


static NSUInteger kPinModTable[] = {
    0,
    10,
    100,
    1000,
    10000,
    100000,
    1000000,
    10000000,
    100000000,
};


@implementation OTPToken (Generation)

- (NSString *)password
{
    if (self.type == OTPTokenTypeTimer) {
        self.counter = ([NSDate date].timeIntervalSince1970 / self.period);
    }
    
    return [self generatePasswordForCounter:self.counter];
}

- (void)updatePassword
{
    if (self.type == OTPTokenTypeCounter) {
        self.counter++;
        [self saveToKeychain];
    } else if (self.type == OTPTokenTypeTimer) {
        self.counter = ([NSDate date].timeIntervalSince1970 / self.period);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:OTPTokenDidUpdateNotification object:self];
}

- (NSString *)verificationCode
{
    return [self generatePasswordForCounter:0];
}


#pragma mark - Generator

- (NSString *)generatePasswordForCounter:(uint64_t)counter
{
    if (![self validate]) return nil;

    NSMutableData *hash = [NSMutableData dataWithLength:digestLengthForAlgorithm(self.algorithm)];

    counter = NSSwapHostLongLongToBig(counter);

    CCHmacContext context;
    CCHmacInit(&context, self.algorithm, self.secret.bytes, self.secret.length);
    CCHmacUpdate(&context, &counter, sizeof(counter));
    CCHmacFinal(&context, hash.mutableBytes);

    const char *ptr = hash.bytes;
    unsigned char offset = ptr[hash.length-1] & 0x0f;
    unsigned long truncatedHash = NSSwapBigLongToHost(*((unsigned long *)&ptr[offset])) & 0x7fffffff;
    unsigned long pinValue = truncatedHash % kPinModTable[self.digits];

    return [NSString stringWithFormat:@"%0*ld", self.digits, pinValue];
}

@end
