//
//  TokenManager.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
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

import OneTimePassword
import OneTimePasswordLegacy

class TokenManager {
    var tokens: [OTPToken] = []

    init() {
        fetchTokensFromKeychain()
    }

    // MARK: -

    private let kOTPKeychainEntriesArray = "OTPKeychainEntries"

    private var keychainItemRefs: [NSData] {
        get {
            return NSUserDefaults.standardUserDefaults().arrayForKey(kOTPKeychainEntriesArray) as? [NSData] ?? []
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: kOTPKeychainEntriesArray)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }

    func fetchTokensFromKeychain() {
        tokens = TokenManager.keychainItems(Token.KeychainItem.allKeychainItems(),
            sortedByKeychainItemRefs: keychainItemRefs).map {
                OTPToken.tokenWithKeychainItem($0)
        }

        if tokens.count > keychainItemRefs.count {
            // If lost tokens were found and appended, save the full list of tokens
            saveTokenOrder()
        }
    }

    class func keychainItems(keychainItems: [Token.KeychainItem], sortedByKeychainItemRefs keychainItemRefs: [NSData]) -> [Token.KeychainItem] {
        var sorted: [Token.KeychainItem] = []
        var remaining = keychainItems
        // Iterate through the keychain item refs, building an array of the corresponding tokens
        for keychainItemRef in keychainItemRefs {
            let indexOfTokenWithSameKeychainItemRef = remaining.indexOf {
                return ($0.persistentRef == keychainItemRef)
            }

            if let index = indexOfTokenWithSameKeychainItemRef {
                let matchingItem = remaining[index]
                remaining.removeAtIndex(index)
                sorted.append(matchingItem)
            }
        }
        // Append the remaining tokens which didn't match any keychain item refs
        return sorted + remaining
    }

    // MARK: -

    var numberOfTokens: Int {
        return tokens.count
    }

    var hasTimeBasedTokens: Bool {
        for otpToken in tokens {
            if otpToken.type == .Timer {
                return true
            }
        }
        return false
    }

    func addToken(token: Token) -> Bool {
        let otpToken = OTPToken(token: token)
        guard otpToken.saveToKeychain() else {
            return false
        }
        tokens.append(otpToken)
        return saveTokenOrder()
    }

    func tokenAtIndex(index: Int) -> Token {
        let otpToken = tokens[index]
        return otpToken.token
    }

    func saveToken(token: Token) -> Bool {
        guard let keychainItem = token.identity as? Token.KeychainItem,
            let newKeychainItem = updateKeychainItem(keychainItem, withToken: token) else {
                return false
        }
        // Update the in-memory token, which is still the origin of the table view's data
        for otpToken in tokens {
            if otpToken.keychainItemRef == newKeychainItem.persistentRef {
                otpToken.updateWithToken(newKeychainItem.token)
            }
        }
        return true
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) -> Bool {
        let token = tokens[origin]
        tokens.removeAtIndex(origin)
        tokens.insert(token, atIndex: destination)
        return saveTokenOrder()
    }

    func removeTokenAtIndex(index: Int) -> Bool {
        let token = tokenAtIndex(index)
        guard let keychainItem = token.identity as? Token.KeychainItem else {
            return false
        }
        guard deleteKeychainItem(keychainItem) else {
            return false
        }
        tokens.removeAtIndex(index)
        return saveTokenOrder()
    }

    // MARK: -

    func saveTokenOrder() -> Bool {
        keychainItemRefs = tokens.flatMap { $0.keychainItemRef }
        return true
    }
}
