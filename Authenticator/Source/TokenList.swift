//
//  TokenList.swift
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
import MobileCoreServices
import OneTimePassword
import UIKit

class TokenList {
    weak var delegate: MasterPresenter?
    weak var presenter: TokenListPresenter?

    private let keychain = Keychain.sharedInstance
    private var persistentTokens: [PersistentToken] {
        didSet {
            presenter?.updateWithViewModel(viewModel, ephemeralMessage: nil)
        }
    }

    init(delegate: MasterPresenter) {
        self.delegate = delegate
        do {
            let persistentTokenSet = try keychain.allPersistentTokens()
            let sortedIdentifiers = TokenList.persistentIdentifiers()

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

    var viewModel: TokenListViewModel {
        let rowModels = persistentTokens.map(TokenRowModel.init)
        return TokenListViewModel(
            rowModels: rowModels,
            ringPeriod: timeBasedTokenPeriods.first
        )
    }

    /// Returns a sorted, uniqued array of the periods of timer-based tokens
    private var timeBasedTokenPeriods: [NSTimeInterval] {
        let periods = persistentTokens.reduce(Set<NSTimeInterval>()) {
            (var periods, persistentToken) in
            if case .Timer(let period) = persistentToken.token.generator.factor {
                periods.insert(period)
            }
            return periods
        }
        return Array(periods).sort()
    }

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
}

extension TokenList: TokenListDelegate {
    func beginAddToken() {
        delegate?.beginAddToken()
    }

    func beginEditPersistentToken(persistentToken: PersistentToken) {
        delegate?.beginEditPersistentToken(persistentToken)
    }

    func updatePersistentToken(persistentToken: PersistentToken) {
        let newToken = persistentToken.token.updatedToken()
        saveToken(newToken, toPersistentToken: persistentToken)
    }

    func copyPassword(password: String) {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        // Show an emphemeral success message in the view
        presenter?.updateWithViewModel(viewModel, ephemeralMessage: .Success("Copied"))
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
            // Show an emphemeral failure message
            let errorMessage = "Deletion Failed:\n\(error)"
            presenter?.updateWithViewModel(viewModel, ephemeralMessage: .Error(errorMessage))
        }
    }

    func updateViewModel() {
        presenter?.updateWithViewModel(viewModel, ephemeralMessage: nil)
    }
}

extension TokenList {
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
        TokenList.savePersistentIdentifiers(persistentIdentifiers)
    }
}
