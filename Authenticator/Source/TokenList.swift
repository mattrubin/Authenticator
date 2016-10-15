//
//  TokenList.swift
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
import UIKit
import MobileCoreServices
import OneTimePassword

struct TokenList: Component {
    private var persistentTokens: [PersistentToken]
    private var displayTime: DisplayTime

    init(persistentTokens: [PersistentToken], displayTime: DisplayTime) {
        self.persistentTokens = persistentTokens
        self.displayTime = displayTime
    }

    // MARK: View Model

    var viewModel: TokenListViewModel {
        let rowModels = persistentTokens.map({
            TokenRowModel(persistentToken: $0, displayTime: displayTime)
        })
        return TokenListViewModel(
            rowModels: rowModels,
            ringProgress: ringProgress
        )
    }

    /// Returns a sorted, uniqued array of the periods of timer-based tokens
    private var timeBasedTokenPeriods: [NSTimeInterval] {
        var periods = Set<NSTimeInterval>()
        persistentTokens.forEach { (persistentToken) in
            if case .Timer(let period) = persistentToken.token.generator.factor {
                periods.insert(period)
            }
        }
        return Array(periods).sort()
    }

    private var ringProgress: Double? {
        guard let ringPeriod = timeBasedTokenPeriods.first else {
            // If there are no time-based tokens, return nil to hide the progress ring.
            return nil
        }
        guard ringPeriod > 0 else {
            // If the period is >= zero, return zero to display the ring but avoid the potential
            // divide-by-zero error below.
            return 0
        }
        // Calculate the percentage progress in the current period.
        return fmod(displayTime.timeIntervalSince1970, ringPeriod) / ringPeriod
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
        case UpdateViewModel(DisplayTime)

        case TokenChangeSucceeded([PersistentToken])
        case UpdateTokenFailed(ErrorType)
        case DeleteTokenFailed(ErrorType)
    }

    enum Effect {
        case BeginTokenEntry
        case BeginTokenEdit(PersistentToken)

        case UpdateToken(PersistentToken,
            success: ([PersistentToken]) -> Action,
            failure: (ErrorType) -> Action)

        case MoveToken(fromIndex: Int, toIndex: Int,
            success: ([PersistentToken]) -> Action)

        case DeletePersistentToken(PersistentToken,
            success: ([PersistentToken]) -> Action,
            failure: (ErrorType) -> Action)

        case ShowErrorMessage(String)
        case ShowSuccessMessage(String)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case .BeginAddToken:
            return .BeginTokenEntry

        case .EditPersistentToken(let persistentToken):
            return .BeginTokenEdit(persistentToken)

        case .UpdatePersistentToken(let persistentToken):
            return .UpdateToken(persistentToken, success: Action.TokenChangeSucceeded,
                                failure: Action.UpdateTokenFailed)

        case let .MoveToken(fromIndex, toIndex):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex,
                              success: Action.TokenChangeSucceeded)

        case .DeletePersistentToken(let persistentToken):
            return .DeletePersistentToken(persistentToken,
                                          success: Action.TokenChangeSucceeded,
                                          failure: Action.DeleteTokenFailed)

        case .CopyPassword(let password):
            return copyPassword(password)

        case .UpdateViewModel(let displayTime):
            self.displayTime = displayTime
            return nil

        case .TokenChangeSucceeded(let persistentTokens):
            self.persistentTokens = persistentTokens
            return nil

        case .UpdateTokenFailed:
            return .ShowErrorMessage("Failed to update token.")
        case .DeleteTokenFailed:
            return .ShowErrorMessage("Failed to delete token.")
        }
    }

    private mutating func copyPassword(password: String) -> Effect {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        // Show an ephemeral success message.
        return .ShowSuccessMessage("Copied")
    }
}

extension TokenList.Action: Equatable {}
func == (lhs: TokenList.Action, rhs: TokenList.Action) -> Bool {
    switch (lhs, rhs) {
    case (.BeginAddToken, .BeginAddToken):
        return true
    case let (.EditPersistentToken(l), .EditPersistentToken(r)):
        return l == r
    case let (.UpdatePersistentToken(l), .UpdatePersistentToken(r)):
        return l == r
    case let (.MoveToken(l), .MoveToken(r)):
        return l == r
    case let (.DeletePersistentToken(l), .DeletePersistentToken(r)):
        return l == r
    case let (.CopyPassword(l), .CopyPassword(r)):
        return l == r
    case let (.UpdateViewModel(l), .UpdateViewModel(r)):
        return l == r
    case let (.TokenChangeSucceeded(l), .TokenChangeSucceeded(r)):
        return l == r
    case let (.UpdateTokenFailed(l), .UpdateTokenFailed(r)):
        return (l as NSError) == (r as NSError)
    case let (.DeleteTokenFailed(l), .DeleteTokenFailed(r)):
        return (l as NSError) == (r as NSError)
    case (.BeginAddToken, _), (.EditPersistentToken, _), (.UpdatePersistentToken, _),
         (.MoveToken, _), (.DeletePersistentToken, _), (.CopyPassword, _), (.UpdateViewModel, _),
         (.TokenChangeSucceeded, _), (.UpdateTokenFailed, _), (.DeleteTokenFailed, _):
        // Using this verbose case for non-matching `Action`s instead of `default` ensures a 
        // compiler error if a new `Action` is added and not expicitly checked for equality.
        return false
    }
}
