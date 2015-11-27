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

import Foundation
import OneTimePassword

class TokenManager {
    private let keychain = Keychain.sharedInstance
    private var keychainItems: [PersistentToken] = []

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
        guard let persistentTokens = try? keychain.allPersistentTokens() else {
            // TODO: handle the token loading error
            return
        }

        let sortedIdentifiers = keychainItemRefs
        keychainItems = persistentTokens.sort({ (A, B) in
            let indexOfA = sortedIdentifiers.indexOf(A.identifier)
            let indexOfB = sortedIdentifiers.indexOf(B.identifier)
            switch (indexOfA, indexOfB) {
            case (.Some(let iA), .Some(let iB)) where iA < iB:
                return true
            default:
                return false
            }
        })

        if keychainItems.count > keychainItemRefs.count {
            // If lost tokens were found and appended, save the full list of tokens
            saveTokenOrder()
        }
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

    func addToken(token: Token) throws {
        let newKeychainItem = try keychain.addToken(token)
        keychainItems.append(newKeychainItem)
        saveTokenOrder()
    }

    func persistentTokenAtIndex(index: Int) -> PersistentToken {
        return keychainItems[index]
    }

    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        let newKeychainItem = try keychain.updatePersistentToken(persistentToken, withToken: token)
        // Update the in-memory token, which is still the origin of the table view's data
        keychainItems = keychainItems.map { (keychainItem) in
            if keychainItem.identifier == newKeychainItem.identifier {
                return newKeychainItem
            }
            return keychainItem
        }
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) {
        let keychainItem = keychainItems[origin]
        keychainItems.removeAtIndex(origin)
        keychainItems.insert(keychainItem, atIndex: destination)
        saveTokenOrder()
    }

    func removeTokenAtIndex(index: Int) throws {
        let keychainItem = keychainItems[index]
        try keychain.deletePersistentToken(keychainItem)
        keychainItems.removeAtIndex(index)
        saveTokenOrder()
    }

    // MARK: -

    private func saveTokenOrder() {
        keychainItemRefs = keychainItems.map { $0.identifier }
    }
}
