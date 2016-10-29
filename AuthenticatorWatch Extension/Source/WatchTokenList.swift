//
//  WatchTokenList.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

struct WatchTokenList: Component {

    var persistentTokens: [PersistentToken]

    init(persistentTokens: [PersistentToken]) {
        self.persistentTokens = persistentTokens
    }

    enum Action {
        case SelectToken(PersistentToken)
        case TokenStoreUpdated([PersistentToken])
    }
    enum Effect {
        case BeginShowEntry(PersistentToken)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case .SelectToken(let token):
            return .BeginShowEntry(token)
        case .TokenStoreUpdated(let tokens):
            self.persistentTokens = tokens
            return nil
        }
    }

}

// MARK: - View

extension WatchTokenList {

    typealias ViewModel = WatchTokenListViewModel

    var viewModel: ViewModel {
        let rowModels = persistentTokens.map({
            WatchTokenRowModel(persistentToken: $0)
        })
        func selectRowAction(index: Int) -> WatchTokenList.Action {
            let selected = persistentTokens[index]
            return .SelectToken(selected)
        }
        return WatchTokenListViewModel(rowModels: rowModels, selectRowAction: selectRowAction)
    }

}
