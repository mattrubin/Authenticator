//
//  TokenStore.swift
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

class TokenStore {
    weak var presenter: TokenListPresenter?

    private let keychain = Keychain.sharedInstance
    private(set) var persistentTokens: [PersistentToken] {
        didSet {
            presenter?.update()
        }
    }

    init() {
        do {
            let persistentTokenSet = try keychain.allPersistentTokens()
            let sortedIdentifiers = TokenStore.persistentIdentifiers()

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
}

extension TokenStore {
    // MARK: Actions

    func addToken(token: Token) {
        do {
            let newPersistentToken = try keychain.addToken(token)
            persistentTokens.append(newPersistentToken)
            saveTokenOrder()
            // TODO: Scroll to the new token (added at the bottom)
        } catch {
            // TODO: Handle the addToken(_:) failure
        }
    }

    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) {
        do {
            let updatedPersistentToken = try keychain.updatePersistentToken(persistentToken,
                withToken: token)
            // Update the in-memory token, which is still the origin of the table view's data
            persistentTokens = persistentTokens.map {
                if $0.identifier == updatedPersistentToken.identifier {
                    return updatedPersistentToken
                }
                return $0
            }
        } catch {
            // TODO: Handle the updatePersistentToken(_:withToken:) failure
        }
    }

    func updatePersistentToken(persistentToken: PersistentToken) {
        let newToken = persistentToken.token.updatedToken()
        saveToken(newToken, toPersistentToken: persistentToken)
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) {
        let persistentToken = persistentTokens[origin]
        persistentTokens.removeAtIndex(origin)
        persistentTokens.insert(persistentToken, atIndex: destination)
        saveTokenOrder()
    }

    func deleteTokenAtIndex(index: Int) {
        do {
            let persistentToken = persistentTokens[index]
            try keychain.deletePersistentToken(persistentToken)
            persistentTokens.removeAtIndex(index)
            saveTokenOrder()
        } catch {
            // TODO: Handle the deletePersistentToken(_:) failure
        }
    }
}

extension TokenStore {
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
        TokenStore.savePersistentIdentifiers(persistentIdentifiers)
    }
}
