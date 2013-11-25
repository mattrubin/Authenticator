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
#import "OTPToken+Persistence.h"


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@interface OTPTokenManager ()

@property (nonatomic, strong) NSMutableArray *mutableTokens;

@end


@implementation OTPTokenManager

+ (instancetype)sharedManager
{
    static OTPTokenManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}


#pragma mark - Keychain

- (void)fetchTokensFromKeychain
{
    NSArray *keychainReferences = [[NSUserDefaults standardUserDefaults] arrayForKey:kOTPKeychainEntriesArray];
    self.mutableTokens = [NSMutableArray arrayWithCapacity:keychainReferences.count];
    for (NSData *keychainItemRef in keychainReferences) {
        OTPToken *token = [OTPToken tokenWithKeychainItemRef:keychainItemRef];
        if (token) [self.mutableTokens addObject:token];
    }
}

- (BOOL)saveTokensToKeychain
{
    NSArray *keychainReferences = [self valueForKeyPath:@"tokens.keychainItemRef"];
    [[NSUserDefaults standardUserDefaults] setObject:keychainReferences forKey:kOTPKeychainEntriesArray];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - Tokens

- (NSArray *)tokens
{
    return self.mutableTokens;
}

- (BOOL)addToken:(OTPToken *)token
{
    if (token && [token saveToKeychain]) {
        [self.mutableTokens addObject:token];
        return [self saveTokensToKeychain];
    }
    return NO;
}

- (BOOL)removeTokenAtIndex:(NSUInteger)index
{
    OTPToken *token = self.tokens[index];
    if ([token removeFromKeychain]) {
        [self.mutableTokens removeObjectAtIndex:index];
        return [self saveTokensToKeychain];
    }
    return NO;
}

- (BOOL)moveTokenFromIndex:(NSUInteger)source toIndex:(NSUInteger)destination
{
    OTPToken *token = self.tokens[source];

    [self.mutableTokens removeObjectAtIndex:source];
    [self.mutableTokens insertObject:token atIndex:destination];

    return [self saveTokensToKeychain];
}

@end
