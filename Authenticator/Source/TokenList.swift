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
    private var ephemeralMessage: EphemeralMessage?

    init(persistentTokens: [PersistentToken], displayTime: DisplayTime) {
        self.persistentTokens = persistentTokens
        self.displayTime = displayTime
        ephemeralMessage = nil
    }

    // MARK: View Model

    var viewModel: TokenListViewModel {
        let rowModels = persistentTokens.map({
            TokenRowModel(persistentToken: $0, displayTime: displayTime)
        })
        return TokenListViewModel(
            rowModels: rowModels,
            ringProgress: ringProgress,
            ephemeralMessage: ephemeralMessage
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
    enum Action: Equatable {
        case BeginAddToken
        case EditPersistentToken(PersistentToken)

        case UpdatePersistentToken(PersistentToken)
        case MoveToken(fromIndex: Int, toIndex: Int)
        case DeletePersistentToken(PersistentToken)

        case CopyPassword(String)
        // TODO: remove this action and have the component auto-update the view model on time change
        case UpdateViewModel(DisplayTime)
        case DismissEphemeralMessage

        case TokenChangeSucceeded([PersistentToken])
        case TokenChangeFailed(ErrorType)
    }

    enum Effect {
        case BeginTokenEntry
        case BeginTokenEdit(PersistentToken)

        case UpdateToken(PersistentToken, success: ([PersistentToken]) -> Action, failure: (ErrorType) -> Action)
        case MoveToken(fromIndex: Int, toIndex: Int, success: ([PersistentToken]) -> Action)
        case DeletePersistentToken(PersistentToken, success: ([PersistentToken]) -> Action, failure: (ErrorType) -> Action)

        case ShowErrorMessage(ErrorType)
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
                                failure: Action.TokenChangeFailed)

        case let .MoveToken(fromIndex, toIndex):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex,
                              success: Action.TokenChangeSucceeded)

        case .DeletePersistentToken(let persistentToken):
            return .DeletePersistentToken(persistentToken,
                                          success: Action.TokenChangeSucceeded,
                                          failure: Action.TokenChangeFailed)

        case .CopyPassword(let password):
            copyPassword(password)
            return nil

        case .UpdateViewModel(let displayTime):
            self.displayTime = displayTime
            return nil

        case .DismissEphemeralMessage:
            ephemeralMessage = nil
            return nil

        case .TokenChangeSucceeded(let persistentTokens):
            self.persistentTokens = persistentTokens
            return nil

        case .TokenChangeFailed(let error):
            return .ShowErrorMessage(error)
        }
    }

    private mutating func copyPassword(password: String) {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        // Show an ephemeral success message in the view
        ephemeralMessage = .Success("Copied")
    }
}

func == (lhs: TokenList.Action, rhs: TokenList.Action) -> Bool {
    switch (lhs, rhs) {
    case (.BeginAddToken, .BeginAddToken):
        return true

    case let (.EditPersistentToken(l), .EditPersistentToken(r)):
        return l == r

    case let (.UpdatePersistentToken(l), .UpdatePersistentToken(r)):
        return l == r

    case let (.MoveToken(l), .MoveToken(r)):
        return l.fromIndex == r.fromIndex
            && l.toIndex == r.toIndex

    case let (.DeletePersistentToken(l), .DeletePersistentToken(r)):
        return l == r

    case let (.CopyPassword(l), .CopyPassword(r)):
        return l == r

    case let (.UpdateViewModel(l), .UpdateViewModel(r)):
        return l == r

    case (.DismissEphemeralMessage, .DismissEphemeralMessage):
        return true

    case let (.TokenChangeSucceeded(l), .TokenChangeSucceeded(r)):
        return l == r

    case (.TokenChangeFailed(_), .TokenChangeFailed(_)):
        return false // FIXME

    case (.BeginAddToken, _),
         (.EditPersistentToken, _),
         (.UpdatePersistentToken, _),
         (.MoveToken, _),
         (.DeletePersistentToken, _),
         (.CopyPassword, _),
         (.UpdateViewModel, _),
         (.DismissEphemeralMessage, _),
         (.TokenChangeSucceeded, _),
         (.TokenChangeFailed, _):
        // Unlike `default`, this final verbose case will cause an error if a new case is added.
        return false
    }
}
