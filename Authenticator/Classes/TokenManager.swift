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

class TokenManager {
    private var keychainItems: [Token.KeychainItem] = []

    init() {
        fetchTokensFromKeychain()
    }

    // MARK: -

    private let kOTPKeychainEntriesArray = "OTPKeychainEntries"

    private var keychainItemRefs: [NSData] {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            return defaults.arrayForKey(kOTPKeychainEntriesArray) as? [NSData] ?? []
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setObject(newValue, forKey: kOTPKeychainEntriesArray)
            defaults.synchronize()
        }
    }

    private func fetchTokensFromKeychain() {
        keychainItems = TokenManager.keychainItems(Token.KeychainItem.allKeychainItems(),
            sortedByPersistentRefs: keychainItemRefs)

        if keychainItems.count > keychainItemRefs.count {
            // If lost tokens were found and appended, save the full list of tokens
            saveTokenOrder()
        }
    }

    private class func keychainItems(keychainItems: [Token.KeychainItem],
        sortedByPersistentRefs persistentRefs: [NSData]) -> [Token.KeychainItem]
    {
        var sorted: [Token.KeychainItem] = []
        var remaining = keychainItems
        // Iterate through the keychain item refs, building an array of the corresponding tokens
        for persistentRef in persistentRefs {
            let indexOfTokenWithSameKeychainItemRef = remaining.indexOf {
                return ($0.persistentRef == persistentRef)
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
        return keychainItems.count
    }

    /// Returns a sorted, uniqued array of the periods of timer-based tokens
    var timeBasedTokenPeriods: [NSTimeInterval] {
        let periods = keychainItems.reduce(Set<NSTimeInterval>()) { (var periods, keychainItem) in
            if case .Timer(let period) = keychainItem.token.generator.factor {
                periods.insert(period)
            }
            return periods
        }
        return Array(periods).sort()
    }

    func addToken(token: Token) -> Bool {
        guard let newKeychainItem = addTokenToKeychain(token) else {
            return false
        }
        keychainItems.append(newKeychainItem)
        saveTokenOrder()
        return true
    }

    func keychainItemAtIndex(index: Int) -> Token.KeychainItem {
        return keychainItems[index]
    }

    func saveToken(token: Token, toKeychainItem keychainItem: Token.KeychainItem) -> Bool {
        guard let newKeychainItem = updateKeychainItem(keychainItem, withToken: token) else {
            return false
        }
        // Update the in-memory token, which is still the origin of the table view's data
        keychainItems = keychainItems.map { (keychainItem) in
            if keychainItem.persistentRef == newKeychainItem.persistentRef {
                return newKeychainItem
            }
            return keychainItem
        }
        return true
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) -> Bool {
        let keychainItem = keychainItems[origin]
        keychainItems.removeAtIndex(origin)
        keychainItems.insert(keychainItem, atIndex: destination)
        saveTokenOrder()
        return true
    }

    func removeTokenAtIndex(index: Int) -> Bool {
        let keychainItem = keychainItems[index]
        guard deleteKeychainItem(keychainItem) else {
            return false
        }
        keychainItems.removeAtIndex(index)
        saveTokenOrder()
        return true
    }

    // MARK: -

    private func saveTokenOrder() {
        keychainItemRefs = keychainItems.map { $0.persistentRef }
    }
}
