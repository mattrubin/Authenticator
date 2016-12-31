//
//  TokenStore.swift
//  Authenticator
//
//  Copyright (c) 2015-2016 Authenticator authors
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

protocol TokenStore {
    var persistentTokens: [PersistentToken] { get }
    func addToken(token: Token) throws
    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) throws
    func updatePersistentToken(persistentToken: PersistentToken) throws
    func moveTokenFromIndex(origin: Int, toIndex destination: Int)
    func deletePersistentToken(persistentToken: PersistentToken) throws
}

class KeychainTokenStore: TokenStore {
    private let keychain: Keychain
    private let userDefaults: NSUserDefaults
    private(set) var persistentTokens: [PersistentToken]

    // Throws an error if the initial state could not be loaded from the keychain.
    init(keychain: Keychain, userDefaults: NSUserDefaults) throws {
        self.keychain = keychain
        self.userDefaults = userDefaults

        // Try to load persistent tokens.
        let persistentTokenSet = try keychain.allPersistentTokens()
        let sortedIdentifiers = userDefaults.persistentIdentifiers()

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
    }

    private func saveTokenOrder() {
        let persistentIdentifiers = persistentTokens.map { $0.identifier }
        userDefaults.savePersistentIdentifiers(persistentIdentifiers)
    }
}

extension KeychainTokenStore {
    // MARK: Actions

    func addToken(token: Token) throws {
        let newPersistentToken = try keychain.addToken(token)
        persistentTokens.append(newPersistentToken)
        saveTokenOrder()
    }

    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        let updatedPersistentToken = try keychain.updatePersistentToken(persistentToken,
                                                                        withToken: token)
        // Update the in-memory token, which is still the origin of the table view's data
        persistentTokens = persistentTokens.map {
            if $0.identifier == updatedPersistentToken.identifier {
                return updatedPersistentToken
            }
            return $0
        }
    }

    func updatePersistentToken(persistentToken: PersistentToken) throws {
        let newToken = persistentToken.token.updatedToken()
        try saveToken(newToken, toPersistentToken: persistentToken)
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) {
        let persistentToken = persistentTokens[origin]
        persistentTokens.removeAtIndex(origin)
        persistentTokens.insert(persistentToken, atIndex: destination)
        saveTokenOrder()
    }

    func deletePersistentToken(persistentToken: PersistentToken) throws {
        try keychain.deletePersistentToken(persistentToken)
        if let index = persistentTokens.indexOf(persistentToken) {
            persistentTokens.removeAtIndex(index)
        }
        saveTokenOrder()
    }
}

// MARK: - Token Order Persistence

private let kOTPKeychainEntriesArray = "OTPKeychainEntries"

private extension NSUserDefaults {
    func persistentIdentifiers() -> [NSData] {
        return arrayForKey(kOTPKeychainEntriesArray) as? [NSData] ?? []
    }

    func savePersistentIdentifiers(identifiers: [NSData]) {
        setObject(identifiers, forKey: kOTPKeychainEntriesArray)
    }
}
