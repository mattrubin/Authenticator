//
//  Root.swift
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

import OneTimePassword

struct Root: Component {
    private var tokenList: TokenList
    private var modal: Modal

    private enum Modal {
        case None
        case Scanner
        case EntryForm(TokenEntryForm)
        case EditForm(TokenEditForm)

        var viewModel: RootViewModel.ModalViewModel {
            switch self {
            case .None:
                return .None
            case .Scanner:
                return .Scanner
            case .EntryForm(let form):
                return .EntryForm(form.viewModel)
            case .EditForm(let form):
                return .EditForm(form.viewModel)
            }
        }
    }

    init(persistentTokens: [PersistentToken], displayTime: DisplayTime) {
        tokenList = TokenList(persistentTokens: persistentTokens, displayTime: displayTime)
        modal = .None
    }
}

// MARK: View

extension Root {
    typealias ViewModel = RootViewModel

    var viewModel: ViewModel {
        return ViewModel(
            tokenList: tokenList.viewModel,
            modal: modal.viewModel
        )
    }
}

// MARK: Update

extension Root {
    enum Action {
        case TokenListAction(TokenList.Action)
        case TokenEntryFormAction(TokenEntryForm.Action)
        case TokenEditFormAction(TokenEditForm.Action)

        case TokenScannerEffect(TokenScannerViewController.Effect)

        case UpdateWithPersistentTokens([PersistentToken])

        case _AddTokenSucceeded([PersistentToken])
        case _AddTokenFailed(ErrorType)

        case _SaveTokenSucceeded([PersistentToken])
        case _SaveTokenFailed(ErrorType)
    }

    enum Effect {
        case AddToken(Token, success: ([PersistentToken]) -> Action, failure: (ErrorType) -> Action)
        case SaveToken(Token, PersistentToken, success: ([PersistentToken]) -> Action, failure: (ErrorType) -> Action)
        case UpdatePersistentToken(PersistentToken, success: ([PersistentToken]) -> Action, failure: (ErrorType) -> Action)
        case MoveToken(fromIndex: Int, toIndex: Int, success: ([PersistentToken]) -> Action)
        case DeletePersistentToken(PersistentToken, success: ([PersistentToken]) -> Action)

        case ShowErrorMessage(ErrorType)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case .TokenListAction(let action):
            return handleTokenListAction(action)
        case .TokenEntryFormAction(let action):
            return handleTokenEntryFormAction(action)
        case .TokenEditFormAction(let action):
            return handleTokenEditFormAction(action)
        case .TokenScannerEffect(let effect):
            return handleTokenScannerEffect(effect)

        case .UpdateWithPersistentTokens(let persistentTokens):
            return handleTokenListAction(.UpdateWithPersistentTokens(persistentTokens))

        case ._AddTokenSucceeded(let persistentTokens):
            // Dismiss the modal entry form.
            modal = .None
            // TODO: Scroll to the new token (added at the bottom)
            return handleTokenListAction(.UpdateWithPersistentTokens(persistentTokens))
        case ._AddTokenFailed(let error):
            return .ShowErrorMessage(error)

        case ._SaveTokenSucceeded(let persistentTokens):
            // Dismiss the modal edit form.
            modal = .None
            return handleTokenListAction(.UpdateWithPersistentTokens(persistentTokens))
        case ._SaveTokenFailed(let error):
            return .ShowErrorMessage(error)
        }
    }

    @warn_unused_result
    private mutating func handleTokenListAction(action: TokenList.Action) -> Effect? {
        let effect = tokenList.update(action)
        if let effect = effect {
            return handleTokenListEffect(effect)
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenListEffect(effect: TokenList.Effect) -> Effect? {
        switch effect {
        case .BeginTokenEntry:
            if QRScanner.deviceCanScan {
                modal = .Scanner
            } else {
                modal = .EntryForm(TokenEntryForm())
            }
            return nil

        case .BeginTokenEdit(let persistentToken):
            let form = TokenEditForm(persistentToken: persistentToken)
            modal = .EditForm(form)
            return nil

        case let .UpdateToken(persistentToken, success, failure):
            return .UpdatePersistentToken(persistentToken,
                                          success: compose(success, Action.TokenListAction),
                                          failure: compose(failure, Action.TokenListAction))

        case let .MoveToken(fromIndex, toIndex, success):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex,
                              success: compose(success, Action.TokenListAction))

        case let .DeletePersistentToken(persistentToken, success):
            return .DeletePersistentToken(persistentToken,
                                          success: compose(success, Action.TokenListAction))

        case .ShowErrorMessage(let error):
            return .ShowErrorMessage(error)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEntryFormAction(action: TokenEntryForm.Action) -> Effect? {
        if case .EntryForm(let form) = modal {
            var newForm = form
            let effect = newForm.update(action)
            modal = .EntryForm(newForm)
            // Handle the resulting action after committing the changes of the initial action
            if let effect = effect {
                return handleTokenEntryFormEffect(effect)
            }
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenEntryFormEffect(effect: TokenEntryForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .SaveNewToken(let token):
            return .AddToken(token,
                             success: Action._AddTokenSucceeded,
                             failure: Action._AddTokenFailed)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEditFormAction(action: TokenEditForm.Action) -> Effect? {
        if case .EditForm(let form) = modal {
            var newForm = form
            let effect = newForm.update(action)
            modal = .EditForm(newForm)
            // Handle the resulting effect after committing the changes of the initial action
            if let effect = effect {
                return handleTokenEditFormEffect(effect)
            }
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenEditFormEffect(effect: TokenEditForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case let .SaveChanges(token, persistentToken):
            return .SaveToken(token, persistentToken,
                              success: Action._SaveTokenSucceeded,
                              failure: Action._SaveTokenFailed)
        }
    }

    @warn_unused_result
    private mutating func handleTokenScannerEffect(effect: TokenScannerViewController.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .BeginManualTokenEntry:
            modal = .EntryForm(TokenEntryForm())
            return nil

        case .SaveNewToken(let token):
            // TODO: Only dismiss the modal if the action succeeds.
            modal = .None
            return .AddToken(token, success: Action.UpdateWithPersistentTokens, failure: Action._AddTokenFailed)
        }
    }
}

private func compose<A, B, C>(transform: A -> B, _ handler: B -> C) -> A -> C {
    return { handler(transform($0)) }
}
