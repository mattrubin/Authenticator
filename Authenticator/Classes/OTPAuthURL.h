//
//  OTPAuthURL.h
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

@import Foundation;
#import "OTPToken.h"

// This class encapsulates the parsing of otpauth:// urls, the creation of
// either HOTPGenerator or TOTPGenerator objects, and the persistence of the
// objects state to the iPhone keychain in a secure fashion.
//
// The secret key is stored as the "password" in the keychain item, and the
// re-constructed URL is stored in an attribute.
@interface OTPAuthURL : NSObject

@property (nonatomic, readonly) OTPToken *token; //TEMPORARY

// |name| is an arbitrary UTF8 text string extracted from the url path.
@property(readwrite, copy, nonatomic) NSString *name;
@property(readonly, nonatomic) NSString *otpCode;
@property(readonly, nonatomic) NSString *checkCode;

+ (OTPAuthURL *)authURLWithURL:(NSURL *)url
                        secret:(NSData *)secret;
+ (OTPAuthURL *)authURLWithKeychainItemRef:(NSData *)keychainItemRef;

// Returns a reconstructed NSURL object representing the current state of the
// |generator|.
- (NSURL *)url;

// Saves the current object state to the keychain.
- (BOOL)saveToKeychain;

// Removes the current object state from the keychain.
- (BOOL)removeFromKeychain;

// Returns true if the object was loaded from or subsequently added to the
// iPhone keychain.
// It does not assert that the keychain is up to date with the latest
// |generator| state.
- (BOOL)isInKeychain;


- (id)initWithSecret:(NSData *)secret name:(NSString *)name type:(OTPTokenType)type;

- (void)generateNextOTPCode;

@end
