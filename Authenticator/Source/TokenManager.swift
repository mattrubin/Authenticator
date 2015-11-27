//
//  TokenManager.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import OneTimePassword

class TokenManager {
    private let keychain = Keychain.sharedInstance
    private var persistentTokens: [PersistentToken]

    init() {
        do {
            let persistentTokenSet = try keychain.allPersistentTokens()
            let sortedIdentifiers = TokenManager.persistentIdentifiers()

            persistentTokens = persistentTokenSet.sort({ (A, B) in
                let indexOfA = sortedIdentifiers.indexOf(A.identifier)
                let indexOfB = sortedIdentifiers.indexOf(B.identifier)

                switch (indexOfA, indexOfB) {
                case (.Some(let iA), .Some(let iB)) where iA < iB:
                    return true
                default:
                    return false
                }
            })

            if persistentTokens.count > sortedIdentifiers.count {
                // If lost tokens were found and appended, save the full list of tokens
                saveTokenOrder()
            }
        } catch {
            persistentTokens = []
            // TODO: Handle the token loading error
        }
    }

    // MARK: -

    var numberOfTokens: Int {
        return persistentTokens.count
    }

    /// Returns a sorted, uniqued array of the periods of timer-based tokens
    var timeBasedTokenPeriods: [NSTimeInterval] {
        let periods = persistentTokens.reduce(Set<NSTimeInterval>()) { (var periods, persistentToken) in
            if case .Timer(let period) = persistentToken.token.generator.factor {
                periods.insert(period)
            }
            return periods
        }
        return Array(periods).sort()
    }

    func addToken(token: Token) throws {
        let newPersistentToken = try keychain.addToken(token)
        persistentTokens.append(newPersistentToken)
        saveTokenOrder()
    }

    func persistentTokenAtIndex(index: Int) -> PersistentToken {
        return persistentTokens[index]
    }

    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        let updatedPersistentToken = try keychain.updatePersistentToken(persistentToken, withToken: token)
        // Update the in-memory token, which is still the origin of the table view's data
        persistentTokens = persistentTokens.map {
            if $0.identifier == updatedPersistentToken.identifier {
                return updatedPersistentToken
            }
            return $0
        }
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) {
        let persistentToken = persistentTokens[origin]
        persistentTokens.removeAtIndex(origin)
        persistentTokens.insert(persistentToken, atIndex: destination)
        saveTokenOrder()
    }

    func removeTokenAtIndex(index: Int) throws {
        let persistentToken = persistentTokens[index]
        try keychain.deletePersistentToken(persistentToken)
        persistentTokens.removeAtIndex(index)
        saveTokenOrder()
    }

    // MARK: Token Order

    private static let kOTPKeychainEntriesArray = "OTPKeychainEntries"

    private static func persistentIdentifiers() -> [NSData] {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.arrayForKey(kOTPKeychainEntriesArray) as? [NSData] ?? []
    }

    private static func savePersistentIdentifiers(identifiers: [NSData]) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(identifiers, forKey: kOTPKeychainEntriesArray)
        defaults.synchronize()
    }

    private func saveTokenOrder() {
        let persistentIdentifiers = persistentTokens.map { $0.identifier }
        TokenManager.savePersistentIdentifiers(persistentIdentifiers)
    }
}
