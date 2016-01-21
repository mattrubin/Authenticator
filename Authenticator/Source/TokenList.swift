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
import UIKit
import MobileCoreServices
import OneTimePassword

struct TokenList {
    private var persistentTokens: [PersistentToken]
    private var ephemeralMessage: EphemeralMessage?

    init(persistentTokens: [PersistentToken]) {
        self.persistentTokens = persistentTokens
        ephemeralMessage = nil
    }

    mutating func updateWithPersistentTokens(persistentTokens: [PersistentToken]) {
        self.persistentTokens = persistentTokens
    }

    // MARK: View Model

    var viewModel: TokenListViewModel {
        let rowModels = persistentTokens.map(TokenRowModel.init)
        return TokenListViewModel(
            rowModels: rowModels,
            ringPeriod: timeBasedTokenPeriods.first,
            ephemeralMessage: ephemeralMessage
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
}

extension TokenList {
    enum Action {
        case BeginAddToken
        case EditPersistentToken(PersistentToken)

        case UpdatePersistentToken(PersistentToken)
        case MoveToken(fromIndex: Int, toIndex: Int)
        case DeletePersistentToken(PersistentToken)

        case CopyPassword(String)
        // TODO: remove this action and have the component auto-update the view model on time change
        case UpdateViewModel
    }

    @warn_unused_result
    mutating func handleAction(action: Action) -> AppAction? {
        // Reset any ephemeral state set by the previous action
        resetEphemera()

        switch action {
        case .BeginAddToken:
            return .BeginTokenEntry
        case .EditPersistentToken(let persistentToken):
            return .BeginTokenEdit(persistentToken)
        case .UpdatePersistentToken(let persistentToken):
            return .UpdateToken(persistentToken)
        case let .MoveToken(fromIndex, toIndex):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex)
        case .DeletePersistentToken(let persistentToken):
            return .DeletePersistentToken(persistentToken)

        case .CopyPassword(let password):
            copyPassword(password)
            return nil

        case .UpdateViewModel:
            // TODO: Currently, this action causes a view model update simply because the call to
            //       resetEphemera() above causes the variable containing this TokenList to be set.
            //       This action should trigger a more reliable method for ensuring the view model
            //       is updated.
            return nil
        }
    }

    private mutating func resetEphemera() {
        ephemeralMessage = nil
    }

    private mutating func copyPassword(password: String) {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        // Show an ephemeral success message in the view
        ephemeralMessage = .Success("Copied")
    }
}
