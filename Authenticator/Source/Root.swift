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

import Foundation
import OneTimePassword

struct Root: Component {
    private var tokenList: TokenList
    private var modal: Modal
    private let deviceCanScan: Bool

    private enum Modal {
        case None
        case Scanner(TokenScanner)
        case EntryForm(TokenEntryForm)
        case EditForm(TokenEditForm)
        case Info(BackupInfo)

        var viewModel: RootViewModel.ModalViewModel {
            switch self {
            case .None:
                return .None
            case .Scanner(let scanner):
                return .Scanner(scanner.viewModel)
            case .EntryForm(let form):
                return .EntryForm(form.viewModel)
            case .EditForm(let form):
                return .EditForm(form.viewModel)
            case Info(let backupInfo):
                return .Info(backupInfo.viewModel)
            }
        }
    }

    init(persistentTokens: [PersistentToken], displayTime: DisplayTime, deviceCanScan: Bool) {
        tokenList = TokenList(persistentTokens: persistentTokens, displayTime: displayTime)
        modal = .None
        self.deviceCanScan = deviceCanScan
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
        case TokenScannerAction(TokenScanner.Action)

        case BackupInfoEffect(BackupInfo.Effect)

        case AddTokenFromURL(Token)
    }

    enum Event {
        case TokenListEvent(TokenList.Event)
        case UpdateDisplayTime(DisplayTime)

        case AddTokenFromURLSucceeded([PersistentToken])

        case TokenFormSucceeded([PersistentToken])

        case AddTokenFailed(ErrorType)
        case SaveTokenFailed(ErrorType)
    }

    enum Effect {
        case AddToken(Token,
            success: ([PersistentToken]) -> Event,
            failure: (ErrorType) -> Event)

        case SaveToken(Token, PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (ErrorType) -> Event)

        case UpdatePersistentToken(PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (ErrorType) -> Event)

        case MoveToken(fromIndex: Int, toIndex: Int,
            success: ([PersistentToken]) -> Event)

        case DeletePersistentToken(PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (ErrorType) -> Event)

        case ShowErrorMessage(String)
        case ShowSuccessMessage(String)
        case OpenURL(NSURL)
    }

    @warn_unused_result
    mutating func update(action: Action) throws -> Effect? {
        do {
            switch action {
            case .TokenListAction(let action):
                let effect = tokenList.update(action)
                return effect.flatMap { effect in
                    handleTokenListEffect(effect)
                }

            case .TokenEntryFormAction(let action):
                let effect = try modal.withEntryForm({ form in form.update(action) })
                return effect.flatMap { effect in
                    handleTokenEntryFormEffect(effect)
                }

            case .TokenEditFormAction(let action):
                let effect = try modal.withEditForm({ form in form.update(action) })
                return effect.flatMap { effect in
                    handleTokenEditFormEffect(effect)
                }

            case .TokenScannerAction(let action):
                let effect = try modal.withScanner({ scanner in scanner.update(action) })
                return effect.flatMap { effect in
                    handleTokenScannerEffect(effect)
                }
            case .BackupInfoEffect(let effect):
                return handleBackupInfoEffect(effect)

            case .AddTokenFromURL(let token):
                return .AddToken(token,
                                 success: Event.AddTokenFromURLSucceeded,
                                 failure: Event.AddTokenFailed)
            }
        } catch {
            throw ComponentError(underlyingError: error, action: action, component: self)
        }
    }

    @warn_unused_result
    mutating func update(event: Event) -> Effect? {
        switch event {
        case .TokenListEvent(let event):
            return handleTokenListEvent(event)

        case .UpdateDisplayTime(let displayTime):
            return handleTokenListEvent(.UpdateDisplayTime(displayTime))

        case .AddTokenFromURLSucceeded(let persistentTokens):
            return handleTokenListEvent(.TokenChangeSucceeded(persistentTokens))

        case .TokenFormSucceeded(let persistentTokens):
            // Dismiss the modal form.
            modal = .None
            return handleTokenListEvent(.TokenChangeSucceeded(persistentTokens))

        case .AddTokenFailed:
            return .ShowErrorMessage("Failed to add token.")
        case .SaveTokenFailed:
            return .ShowErrorMessage("Failed to save token.")
        }
    }

    @warn_unused_result
    private mutating func handleTokenListEvent(event: TokenList.Event) -> Effect? {
        let effect = tokenList.update(event)
        return effect.flatMap { effect in
            handleTokenListEffect(effect)
        }
    }

    @warn_unused_result
    private mutating func handleTokenListEffect(effect: TokenList.Effect) -> Effect? {
        switch effect {
        case .BeginTokenEntry:
            if deviceCanScan {
                modal = .Scanner(TokenScanner())
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
                                          success: compose(success, Event.TokenListEvent),
                                          failure: compose(failure, Event.TokenListEvent))

        case let .MoveToken(fromIndex, toIndex, success):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex,
                              success: compose(success, Event.TokenListEvent))

        case let .DeletePersistentToken(persistentToken, success, failure):
            return .DeletePersistentToken(persistentToken,
                                          success: compose(success, Event.TokenListEvent),
                                          failure: compose(failure, Event.TokenListEvent))

        case .ShowErrorMessage(let message):
            return .ShowErrorMessage(message)

        case .ShowSuccessMessage(let message):
            return .ShowSuccessMessage(message)

        case .ShowBackupInfo:
            modal = .Info(BackupInfo())
            return nil
        }
    }

    @warn_unused_result
    private mutating func handleTokenEntryFormEffect(effect: TokenEntryForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .SaveNewToken(let token):
            return .AddToken(token,
                             success: Event.TokenFormSucceeded,
                             failure: Event.AddTokenFailed)

        case .ShowErrorMessage(let message):
            return .ShowErrorMessage(message)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEditFormEffect(effect: TokenEditForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case let .SaveChanges(token, persistentToken):
            return .SaveToken(token, persistentToken,
                              success: Event.TokenFormSucceeded,
                              failure: Event.SaveTokenFailed)

        case .ShowErrorMessage(let message):
            return .ShowErrorMessage(message)
        }
    }

    @warn_unused_result
    private mutating func handleTokenScannerEffect(effect: TokenScanner.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .BeginManualTokenEntry:
            if Process.isDemo {
                // If this is a demo, show the pre-filled demo form.
                modal = .EntryForm(TokenEntryForm.demoForm)
                return nil
            }

            modal = .EntryForm(TokenEntryForm())
            return nil

        case .SaveNewToken(let token):
            return .AddToken(token,
                             success: Event.TokenFormSucceeded,
                             failure: Event.AddTokenFailed)

        case .ShowErrorMessage(let message):
            return .ShowErrorMessage(message)
        }
    }

    @warn_unused_result
    private mutating func handleBackupInfoEffect(effect: BackupInfo.Effect) -> Effect? {
        switch effect {
        case .Done:
            modal = .None
            return nil
        case let .OpenURL(url):
            return .OpenURL(url)
        }
    }
}

private extension Root.Modal {
    struct Error: ErrorType {
        let expectedType: Any.Type
        let actualState: Root.Modal
    }

    @warn_unused_result
    private mutating func withEntryForm<ResultType>(body: (inout TokenEntryForm) -> ResultType) throws -> ResultType {
        guard case .EntryForm(var form) = self else {
            throw Error(expectedType: TokenEntryForm.self, actualState: self)
        }
        let result = body(&form)
        self = .EntryForm(form)
        return result
    }

    @warn_unused_result
    private mutating func withEditForm<ResultType>(body: (inout TokenEditForm) -> ResultType) throws -> ResultType {
        guard case .EditForm(var form) = self else {
            throw Error(expectedType: TokenEditForm.self, actualState: self)
        }
        let result = body(&form)
        self = .EditForm(form)
        return result
    }

    @warn_unused_result
    private mutating func withScanner<ResultType>(body: (inout TokenScanner) -> ResultType) throws -> ResultType {
        guard case .Scanner(var scanner) = self else {
            throw Error(expectedType: TokenScanner.self, actualState: self)
        }
        let result = body(&scanner)
        self = .Scanner(scanner)
        return result
    }
}

private func compose<A, B, C>(transform: A -> B, _ handler: B -> C) -> A -> C {
    return { handler(transform($0)) }
}
