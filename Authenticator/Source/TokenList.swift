//
//  TokenList.swift
//  Authenticator
//
//  Copyright (c) 2015-2018 Authenticator authors
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
    fileprivate var filter: String?

    // MARK: View Model

    typealias ViewModel = TokenListViewModel

    func viewModel(with persistentTokens: [PersistentToken], at displayTime: DisplayTime, digitGroupSize: Int) -> (viewModel: TokenListViewModel, nextRefreshTime: Date) {
        let isFiltering = !(filter ?? "").isEmpty
        let rowModels = filteredTokens(from: persistentTokens).map({
            TokenRowModel(persistentToken: $0, displayTime: displayTime, digitGroupSize: digitGroupSize, canReorder: !isFiltering)
        })

        let lastRefreshTime = persistentTokens.reduce(.distantPast) { (lastRefreshTime, persistentToken) in
            max(lastRefreshTime, persistentToken.lastRefreshTime(before: displayTime))
        }
        let nextRefreshTime = persistentTokens.reduce(.distantFuture) { (nextRefreshTime, persistentToken) in
            min(nextRefreshTime, persistentToken.nextRefreshTime(after: displayTime))
        }

        let viewModel = TokenListViewModel(
            rowModels: rowModels,
            progressRingViewModel: persistentTokens.isEmpty ? nil :
                ProgressRingViewModel(startTime: lastRefreshTime, endTime: nextRefreshTime),
            totalTokens: persistentTokens.count,
            isFiltering: isFiltering
        )

        return (viewModel: viewModel, nextRefreshTime: nextRefreshTime)
    }

    private func filteredTokens(from persistentTokens: [PersistentToken]) -> [PersistentToken] {
        guard let filter = self.filter, !filter.isEmpty else {
            return persistentTokens
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return persistentTokens.filter({
            $0.token.issuer.range(of: filter, options: options) != nil ||
                $0.token.name.range(of: filter, options: options) != nil
        })
    }
}

extension TokenList {
    enum Action: Equatable {
        case beginAddToken
        case editPersistentToken(PersistentToken)

        case updatePersistentToken(PersistentToken)
        case moveToken(fromIndex: Int, toIndex: Int)
        case deletePersistentToken(PersistentToken)

        case copyPassword(String)

        case filter(String)
        case clearFilter

        case showBackupInfo
        case showInfo
    }

    enum Effect {
        case beginTokenEntry
        case beginTokenEdit(PersistentToken)

        case updateToken(PersistentToken)
        case moveToken(fromIndex: Int, toIndex: Int)
        case deletePersistentToken(PersistentToken)

        case showErrorMessage(String)
        case showSuccessMessage(String)
        case showBackupInfo
        case showInfo
    }

    mutating func update(with action: Action) -> Effect? {
        switch action {
        case .beginAddToken:
            return .beginTokenEntry

        case .editPersistentToken(let persistentToken):
            return .beginTokenEdit(persistentToken)

        case .updatePersistentToken(let persistentToken):
            return .updateToken(persistentToken)

        case let .moveToken(fromIndex, toIndex):
            return .moveToken(fromIndex: fromIndex, toIndex: toIndex)

        case .deletePersistentToken(let persistentToken):
            return .deletePersistentToken(persistentToken)

        case .copyPassword(let password):
            return copyPassword(password)

        case .filter(let filter):
            self.filter = filter
            return nil

        case .clearFilter:
            self.filter = nil
            return nil

        case .showBackupInfo:
            return .showBackupInfo

        case .showInfo:
            return .showInfo
        }
    }

    private mutating func copyPassword(_ password: String) -> Effect {
        let pasteboard = UIPasteboard.general
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        // Show an ephemeral success message.
        return .showSuccessMessage("Copied")
    }
}

private extension PersistentToken {
    func lastRefreshTime(before displayTime: DisplayTime) -> Date {
        switch token.generator.factor {
        case .counter:
            return .distantPast
        case .timer(let period):
            let epoch = displayTime.timeIntervalSince1970
            return Date(timeIntervalSince1970: epoch - epoch.truncatingRemainder(dividingBy: period))
        }
    }

    func nextRefreshTime(after displayTime: DisplayTime) -> Date {
        switch token.generator.factor {
        case .counter:
            return .distantFuture
        case .timer(let period):
            let epoch = displayTime.timeIntervalSince1970
            return Date(timeIntervalSince1970: epoch + (period - epoch.truncatingRemainder(dividingBy: period)))
        }
    }
}
