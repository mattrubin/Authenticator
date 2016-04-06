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
    private var time: DisplayTime
    private var ephemeralMessage: EphemeralMessage?

    init(persistentTokens: [PersistentToken], time: DisplayTime) {
        self.persistentTokens = persistentTokens
        self.time = time
        ephemeralMessage = nil
    }

    mutating func updateWithPersistentTokens(persistentTokens: [PersistentToken]) {
        self.persistentTokens = persistentTokens
    }

    // MARK: View Model

    var viewModel: TokenListViewModel {
        let rowModels = persistentTokens.map({
            TokenRowModel(persistentToken: $0, displayTime: time)
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
        return fmod(time.timeIntervalSince1970, ringPeriod) / ringPeriod
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
    }

    enum Effect {
        case BeginTokenEntry
        case BeginTokenEdit(PersistentToken)

        case UpdateToken(PersistentToken)
        case MoveToken(fromIndex: Int, toIndex: Int)
        case DeletePersistentToken(PersistentToken)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
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

        case .UpdateViewModel(let time):
            self.time = time
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

func == (lhs: TokenList.Action, rhs: TokenList.Action) -> Bool {
    switch lhs {
    case .BeginAddToken:
        return rhs == .BeginAddToken
    case let .EditPersistentToken(l):
        if case let .EditPersistentToken(r) = rhs {
            return l == r
        }
    case let .UpdatePersistentToken(l):
        if case let .UpdatePersistentToken(r) = rhs {
            return l == r
        }
    case let .MoveToken(l):
        if case let .MoveToken(r) = rhs {
            return l.fromIndex == r.fromIndex
                && l.toIndex == r.toIndex
        }
    case let .DeletePersistentToken(l):
        if case let .DeletePersistentToken(r) = rhs {
            return l == r
        }
    case let .CopyPassword(l):
        if case let .CopyPassword(r) = rhs {
            return l == r
        }
    case let .UpdateViewModel(l):
        if case let .UpdateViewModel(r) = rhs {
            return l == r
        }
    }
    return false
}
