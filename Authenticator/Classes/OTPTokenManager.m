//
//  OTPTokenManager.m
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

#import "OTPTokenManager.h"
@import OneTimePasswordLegacy;


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@implementation OTPTokenManager

- (NSArray *)tokens
{
    return self.mutableTokens;
}

- (void)fetchTokensFromKeychain
{
    NSArray<NSData *> *keychainItemRefs = [self.class keychainRefList];
    NSArray<OTPToken *> *sortedTokens = [self.class tokens:[OTPToken allTokensInKeychain]
                                  sortedByKeychainItemRefs:keychainItemRefs];
    self.mutableTokens = [sortedTokens mutableCopy];

    if (sortedTokens.count > keychainItemRefs.count) {
        // If lost tokens were found and appended, save the full list of tokens
        NSArray *keychainReferences = [self.tokens valueForKey:@"keychainItemRef"];
        [self.class setKeychainRefList:keychainReferences];
    }
}

+ (NSArray<OTPToken *> *)tokens:(NSArray<OTPToken *> *)tokens
       sortedByKeychainItemRefs:(NSArray<NSData *> *)keychainItemRefs
{
    NSMutableArray *sortedTokens = [NSMutableArray arrayWithCapacity:tokens.count];
    NSMutableArray *remainingTokens = [tokens mutableCopy];
    // Iterate through the keychain item refs, building an array of the corresponding tokens
    for (NSData *keychainItemRef in keychainItemRefs) {
        NSUInteger indexOfTokenWithSameKeychainItemRef =
        [remainingTokens indexOfObjectPassingTest:^BOOL(OTPToken *token, NSUInteger idx, BOOL *stop) {
            if ([token.keychainItemRef isEqualToData:keychainItemRef]) {
                return YES;
            }
            return NO;
        }];

        OTPToken *matchingToken = remainingTokens[indexOfTokenWithSameKeychainItemRef];
        [remainingTokens removeObjectAtIndex:indexOfTokenWithSameKeychainItemRef];
        [sortedTokens addObject:matchingToken];
    }
    // Append the remaining tokens which didn't match any keychain item refs
    [sortedTokens addObjectsFromArray:remainingTokens];
    return [sortedTokens copy];
}


+ (NSArray<NSData *> *)keychainRefList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kOTPKeychainEntriesArray];
}

+ (BOOL)setKeychainRefList:(NSArray<NSData *> *)keychainReferences
{
    [[NSUserDefaults standardUserDefaults] setObject:keychainReferences forKey:kOTPKeychainEntriesArray];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
