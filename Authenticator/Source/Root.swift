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

class Root {
    weak var presenter: AppPresenter?

    private let tokenStore: TokenStore

    private var tokenList: TokenList {
        didSet {
            presenter?.updateWithViewModel(viewModel)
        }
    }

    private var modalState: ModalState {
        didSet {
            presenter?.updateWithViewModel(viewModel)
        }
    }

    private enum ModalState {
        case None
        case EntryScanner
        case EntryForm(TokenEntryForm)
        case EditForm(TokenEditForm)
    }

    init(store: TokenStore) {
        tokenStore = store
        tokenList = TokenList(persistentTokens: tokenStore.persistentTokens)
        modalState = .None
    }

    var viewModel: RootViewModel {
        let modal: RootViewModel.Modal
        switch modalState {
        case .None:
            modal = .None
        case .EntryScanner:
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
        case AddTokenFromURL(Token)

        case TokenListAction(TokenList.Action)
        case TokenEntryFormAction(TokenEntryForm.Action)
        case TokenEditFormAction(TokenEditForm.Action)

        case TokenScannerEffect(TokenScannerViewController.Effect)
    }

    func handleAction(action: Action) {
        switch action {
        case .AddTokenFromURL(let token):
            addToken(token)

        case .TokenListAction(let action):
            let sideEffect = tokenList.handleAction(action)
            // Handle the resulting action after committing the changes of the initial action
            if let effect = sideEffect {
                handleTokenListEffect(effect)
            }

        case .TokenEntryFormAction(let action):
            if case .EntryForm(let form) = modalState {
                var newForm = form
                let sideEffect = newForm.handleAction(action)
                modalState = .EntryForm(newForm)
                // Handle the resulting action after committing the changes of the initial action
                if let effect = sideEffect {
                    handleTokenEntryEffect(effect)
                }
            }

        case .TokenEditFormAction(let action):
            if case .EditForm(let form) = modalState {
                var newForm = form
                let sideEffect = newForm.handleAction(action)
                modalState = .EditForm(newForm)
                // Handle the resulting effect after committing the changes of the initial action
                if let effect = sideEffect {
                    handleTokenEditEffect(effect)
                }
            }

        case .TokenScannerEffect(let effect):
            handleTokenScannerEffect(effect)
        }
    }

    func handleTokenListEffect(effect: TokenList.Effect) {
        switch effect {
        case .BeginTokenEntry:
            guard QRScanner.deviceCanScan else {
                beginManualTokenEntry()
                break
            }
            modalState = .EntryScanner

        case .BeginTokenEdit(let persistentToken):
            let form = TokenEditForm(persistentToken: persistentToken)
            modalState = .EditForm(form)

        case .UpdateToken(let persistentToken):
            tokenStore.updatePersistentToken(persistentToken)
            tokenList.updateWithPersistentTokens(tokenStore.persistentTokens)

        case let .MoveToken(fromIndex, toIndex):
            tokenStore.moveTokenFromIndex(fromIndex, toIndex: toIndex)
            tokenList.updateWithPersistentTokens(tokenStore.persistentTokens)

        case .DeletePersistentToken(let persistentToken):
            tokenStore.deletePersistentToken(persistentToken)
            tokenList.updateWithPersistentTokens(tokenStore.persistentTokens)
        }
    }

    func handleTokenEntryEffect(effect: TokenEntryForm.Effect) {
        switch effect {
        case .Cancel:
            modalState = .None

        case .SaveNewToken(let token):
            addToken(token)
            modalState = .None
        }
    }

    func handleTokenEditEffect(effect: TokenEditForm.Effect) {
        switch effect {
        case .Cancel:
            modalState = .None

        case let .SaveChanges(token, persistentToken):
            tokenStore.saveToken(token, toPersistentToken: persistentToken)
            tokenList.updateWithPersistentTokens(tokenStore.persistentTokens)
            modalState = .None
        }
    }

    func handleTokenScannerEffect(effect: TokenScannerViewController.Effect) {
        switch effect {
        case .CancelTokenEntry:
            modalState = .None

        case .BeginManualTokenEntry:
            beginManualTokenEntry()

        case .SaveNewToken(let token):
            addToken(token)
            modalState = .None
        }
    }

    func beginManualTokenEntry() {
        let form = TokenEntryForm()
        modalState = .EntryForm(form)
    }

    func addToken(token: Token) {
        tokenStore.addToken(token)
        tokenList.updateWithPersistentTokens(tokenStore.persistentTokens)
    }
}
