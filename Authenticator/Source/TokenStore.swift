//
//  TokenStore.swift
//  Authenticator
//
//  Copyright (c) 2015-2023 Authenticator authors
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

    func addToken(_ token: Token) throws
    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws
    func updatePersistentToken(_ persistentToken: PersistentToken) throws
    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) throws
    func deletePersistentToken(_ persistentToken: PersistentToken) throws
}

class KeychainTokenStore: TokenStore {
    private let keychain: Keychain
    private let userDefaults: UserDefaults
    private(set) var persistentTokens: [PersistentToken]

    // Throws an error if the initial state could not be loaded from the keychain.
    init(keychain: Keychain, userDefaults: UserDefaults) throws {
        self.keychain = keychain
        self.userDefaults = userDefaults

        // Try to load persistent tokens.
        let persistentTokenSet = try keychain.allPersistentTokens()
        let sortedIdentifiers = userDefaults.persistentIdentifiers()

        persistentTokens = persistentTokenSet.sorted(by: {
            let indexOfA = sortedIdentifiers.firstIndex(of: $0.identifier)
            let indexOfB = sortedIdentifiers.firstIndex(of: $1.identifier)

            switch (indexOfA, indexOfB) {
            case let (.some(iA), .some(iB)) where iA < iB:
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

    func addToken(_ token: Token) throws {
        let newPersistentToken = try keychain.add(token)
        persistentTokens.append(newPersistentToken)
        saveTokenOrder()
    }

    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        let updatedPersistentToken = try keychain.update(persistentToken, with: token)
        // Update the in-memory token, which is still the origin of the table view's data
        persistentTokens = persistentTokens.map {
            if $0.identifier == updatedPersistentToken.identifier {
                return updatedPersistentToken
            }
            return $0
        }
    }

    func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        let newToken = persistentToken.token.updatedToken()
        try saveToken(newToken, toPersistentToken: persistentToken)
    }

    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {
        let persistentToken = persistentTokens[origin]
        persistentTokens.remove(at: origin)
        persistentTokens.insert(persistentToken, at: destination)
        saveTokenOrder()
    }

    func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        try keychain.delete(persistentToken)
        if let index = persistentTokens.firstIndex(of: persistentToken) {
            persistentTokens.remove(at: index)
        }
        saveTokenOrder()
    }
}

// MARK: - Token Order Persistence

private let kOTPKeychainEntriesArray = "OTPKeychainEntries"

private extension UserDefaults {
    func persistentIdentifiers() -> [Data] {
        return array(forKey: kOTPKeychainEntriesArray) as? [Data] ?? []
    }

    func savePersistentIdentifiers(_ identifiers: [Data]) {
        set(identifiers, forKey: kOTPKeychainEntriesArray)
    }
}
