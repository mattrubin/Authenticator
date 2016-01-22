//
//  Root.swift
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

import OneTimePassword

struct Root: Component {
    private var tokenList: TokenList
    private var modalState: Modal

    private enum Modal {
        case None
        case Scanner
        case EntryForm(TokenEntryForm)
        case EditForm(TokenEditForm)
    }

    init(persistentTokens: [PersistentToken]) {
        tokenList = TokenList(persistentTokens: persistentTokens)
        modalState = .None
    }

    var viewModel: RootViewModel {
        let modal: RootViewModel.ModalViewModel
        switch modalState {
        case .None:
            modal = .None
        case .Scanner:
            modal = .Scanner
        case .EntryForm(let form):
            modal = .EntryForm(form.viewModel)
        case .EditForm(let form):
            modal = .EditForm(form.viewModel)
        }

        return RootViewModel(
            tokenList: tokenList.viewModel,
            modal: modal
        )
    }
}

extension Root {
    enum Action {
        case TokenListAction(TokenList.Action)
        case TokenEntryFormAction(TokenEntryForm.Action)
        case TokenEditFormAction(TokenEditForm.Action)

        case TokenScannerEffect(TokenScannerViewController.Effect)
    }

    enum Effect {
        case AddToken(Token)
        case SaveToken(Token, PersistentToken)
        case UpdatePersistentToken(PersistentToken)
        case MoveToken(fromIndex: Int, toIndex: Int)
        case DeletePersistentToken(PersistentToken)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case .TokenListAction(let action):
            let effect = tokenList.update(action)
            // Handle the resulting action after committing the changes of the initial action
            if let effect = effect {
                return handleTokenListEffect(effect)
            }

        case .TokenEntryFormAction(let action):
            if case .EntryForm(let form) = modalState {
                var newForm = form
                let effect = newForm.update(action)
                modalState = .EntryForm(newForm)
                // Handle the resulting action after committing the changes of the initial action
                if let effect = effect {
                    return handleTokenEntryEffect(effect)
                }
            }

        case .TokenEditFormAction(let action):
            if case .EditForm(let form) = modalState {
                var newForm = form
                let effect = newForm.update(action)
                modalState = .EditForm(newForm)
                // Handle the resulting effect after committing the changes of the initial action
                if let effect = effect {
                    return handleTokenEditEffect(effect)
                }
            }

        case .TokenScannerEffect(let effect):
            return handleTokenScannerEffect(effect)
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenListEffect(effect: TokenList.Effect) -> Effect? {
        switch effect {
        case .BeginTokenEntry:
            if QRScanner.deviceCanScan {
                modalState = .Scanner
            } else {
                modalState = .EntryForm(TokenEntryForm())
            }
            return nil

        case .BeginTokenEdit(let persistentToken):
            let form = TokenEditForm(persistentToken: persistentToken)
            modalState = .EditForm(form)
            return nil

        case .UpdateToken(let persistentToken):
            return .UpdatePersistentToken(persistentToken)

        case let .MoveToken(fromIndex, toIndex):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex)

        case .DeletePersistentToken(let persistentToken):
            return .DeletePersistentToken(persistentToken)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEntryEffect(effect: TokenEntryForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modalState = .None
            return nil

        case .SaveNewToken(let token):
            modalState = .None
            return .AddToken(token)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEditEffect(effect: TokenEditForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modalState = .None
            return nil

        case let .SaveChanges(token, persistentToken):
            modalState = .None
            return .SaveToken(token, persistentToken)
        }
    }

    @warn_unused_result
    private mutating func handleTokenScannerEffect(effect: TokenScannerViewController.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modalState = .None
            return nil

        case .BeginManualTokenEntry:
            modalState = .EntryForm(TokenEntryForm())
            return nil

        case .SaveNewToken(let token):
            modalState = .None
            return .AddToken(token)
        }
    }

    mutating func updateWithPersistentTokens(persistentTokens: [PersistentToken]) {
        tokenList.updateWithPersistentTokens(persistentTokens)
    }
}
