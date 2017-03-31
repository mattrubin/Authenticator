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
    fileprivate var tokenList: TokenList
    fileprivate var modal: Modal
    fileprivate let deviceCanScan: Bool

    fileprivate enum Modal {
        case none
        case scanner(TokenScanner)
        case entryForm(TokenEntryForm)
        case editForm(TokenEditForm)
        case info(Authenticator.Info)

        var viewModel: RootViewModel.ModalViewModel {
            switch self {
            case .none:
                return .none
            case .scanner(let scanner):
                return .scanner(scanner.viewModel)
            case .entryForm(let form):
                return .entryForm(form.viewModel)
            case .editForm(let form):
                return .editForm(form.viewModel)
            case .info(let info):
                return .info(info.viewModel)
            }
        }
    }

    init(persistentTokens: [PersistentToken], displayTime: DisplayTime, deviceCanScan: Bool) {
        tokenList = TokenList(persistentTokens: persistentTokens, displayTime: displayTime)
        modal = .none
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
        case tokenListAction(TokenList.Action)
        case tokenEntryFormAction(TokenEntryForm.Action)
        case tokenEditFormAction(TokenEditForm.Action)
        case tokenScannerAction(TokenScanner.Action)

        case infoEffect(Info.Effect)

        case addTokenFromURL(Token)
    }

    enum Event {
        case tokenListEvent(TokenList.Event)
        case updateDisplayTime(DisplayTime)

        case addTokenFromURLSucceeded([PersistentToken])

        case tokenFormSucceeded([PersistentToken])

        case addTokenFailed(Error)
        case saveTokenFailed(Error)
    }

    enum Effect {
        case addToken(Token,
            success: ([PersistentToken]) -> Event,
            failure: (Error) -> Event)

        case saveToken(Token, PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (Error) -> Event)

        case updatePersistentToken(PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (Error) -> Event)

        case moveToken(fromIndex: Int, toIndex: Int,
            success: ([PersistentToken]) -> Event)

        case deletePersistentToken(PersistentToken,
            success: ([PersistentToken]) -> Event,
            failure: (Error) -> Event)

        case showErrorMessage(String)
        case showSuccessMessage(String)
        case openURL(URL)
    }

    @warn_unused_result
    mutating func update(_ action: Action) throws -> Effect? {
        do {
            switch action {
            case .tokenListAction(let action):
                let effect = tokenList.update(action)
                return effect.flatMap { effect in
                    handleTokenListEffect(effect)
                }

            case .tokenEntryFormAction(let action):
                let effect = try modal.withEntryForm({ form in form.update(action) })
                return effect.flatMap { effect in
                    handleTokenEntryFormEffect(effect)
                }

            case .tokenEditFormAction(let action):
                let effect = try modal.withEditForm({ form in form.update(action) })
                return effect.flatMap { effect in
                    handleTokenEditFormEffect(effect)
                }

            case .tokenScannerAction(let action):
                let effect = try modal.withScanner({ scanner in scanner.update(action) })
                return effect.flatMap { effect in
                    handleTokenScannerEffect(effect)
                }
            case .infoEffect(let effect):
                return handleInfoEffect(effect)

            case .addTokenFromURL(let token):
                return .addToken(token,
                                 success: Event.addTokenFromURLSucceeded,
                                 failure: Event.addTokenFailed)
            }
        } catch {
            throw ComponentError(underlyingError: error, action: action, component: self)
        }
    }

    @warn_unused_result
    mutating func update(_ event: Event) -> Effect? {
        switch event {
        case .tokenListEvent(let event):
            return handleTokenListEvent(event)

        case .updateDisplayTime(let displayTime):
            return handleTokenListEvent(.updateDisplayTime(displayTime))

        case .addTokenFromURLSucceeded(let persistentTokens):
            return handleTokenListEvent(.tokenChangeSucceeded(persistentTokens))

        case .tokenFormSucceeded(let persistentTokens):
            // Dismiss the modal form.
            modal = .none
            return handleTokenListEvent(.tokenChangeSucceeded(persistentTokens))

        case .addTokenFailed:
            return .showErrorMessage("Failed to add token.")
        case .saveTokenFailed:
            return .showErrorMessage("Failed to save token.")
        }
    }

    @warn_unused_result
    fileprivate mutating func handleTokenListEvent(_ event: TokenList.Event) -> Effect? {
        let effect = tokenList.update(event)
        return effect.flatMap { effect in
            handleTokenListEffect(effect)
        }
    }

    @warn_unused_result
    fileprivate mutating func handleTokenListEffect(_ effect: TokenList.Effect) -> Effect? {
        switch effect {
        case .beginTokenEntry:
            if deviceCanScan {
                modal = .scanner(TokenScanner())
            } else {
                modal = .entryForm(TokenEntryForm())
            }
            return nil

        case .beginTokenEdit(let persistentToken):
            let form = TokenEditForm(persistentToken: persistentToken)
            modal = .editForm(form)
            return nil

        case let .updateToken(persistentToken, success, failure):
            return .updatePersistentToken(persistentToken,
                                          success: compose(success, Event.tokenListEvent),
                                          failure: compose(failure, Event.tokenListEvent))

        case let .moveToken(fromIndex, toIndex, success):
            return .moveToken(fromIndex: fromIndex, toIndex: toIndex,
                              success: compose(success, Event.tokenListEvent))

        case let .deletePersistentToken(persistentToken, success, failure):
            return .deletePersistentToken(persistentToken,
                                          success: compose(success, Event.tokenListEvent),
                                          failure: compose(failure, Event.tokenListEvent))

        case .showErrorMessage(let message):
            return .showErrorMessage(message)

        case .showSuccessMessage(let message):
            return .showSuccessMessage(message)

        case .showBackupInfo:
            do {
                modal = .info(try Info.backupInfo())
                return nil
            } catch {
                return .showErrorMessage("Failed to load backup info.")
            }

        case .showLicenseInfo:
            do {
                modal = .info(try Info.licenseInfo())
                return nil
            } catch {
                return .showErrorMessage("Failed to load acknowledgements.")
            }
        }
    }

    @warn_unused_result
    fileprivate mutating func handleTokenEntryFormEffect(_ effect: TokenEntryForm.Effect) -> Effect? {
        switch effect {
        case .cancel:
            modal = .none
            return nil

        case .saveNewToken(let token):
            return .addToken(token,
                             success: Event.tokenFormSucceeded,
                             failure: Event.addTokenFailed)

        case .showErrorMessage(let message):
            return .showErrorMessage(message)
        }
    }

    @warn_unused_result
    fileprivate mutating func handleTokenEditFormEffect(_ effect: TokenEditForm.Effect) -> Effect? {
        switch effect {
        case .cancel:
            modal = .none
            return nil

        case let .saveChanges(token, persistentToken):
            return .saveToken(token, persistentToken,
                              success: Event.tokenFormSucceeded,
                              failure: Event.saveTokenFailed)

        case .showErrorMessage(let message):
            return .showErrorMessage(message)
        }
    }

    @warn_unused_result
    fileprivate mutating func handleTokenScannerEffect(_ effect: TokenScanner.Effect) -> Effect? {
        switch effect {
        case .cancel:
            modal = .none
            return nil

        case .beginManualTokenEntry:
            if CommandLine.isDemo {
                // If this is a demo, show the pre-filled demo form.
                modal = .entryForm(TokenEntryForm.demoForm)
                return nil
            }

            modal = .entryForm(TokenEntryForm())
            return nil

        case .saveNewToken(let token):
            return .addToken(token,
                             success: Event.tokenFormSucceeded,
                             failure: Event.addTokenFailed)

        case .showErrorMessage(let message):
            return .showErrorMessage(message)
        }
    }

    @warn_unused_result
    fileprivate mutating func handleInfoEffect(_ effect: Info.Effect) -> Effect? {
        switch effect {
        case .done:
            modal = .none
            return nil
        case let .openURL(url):
            return .openURL(url)
        }
    }
}

private extension Root.Modal {
    struct Error: Swift.Error {
        let expectedType: Any.Type
        let actualState: Root.Modal
    }

    @warn_unused_result
    mutating func withEntryForm<ResultType>(_ body: (inout TokenEntryForm) -> ResultType) throws -> ResultType {
        guard case .entryForm(var form) = self else {
            throw Error(expectedType: TokenEntryForm.self, actualState: self)
        }
        let result = body(&form)
        self = .entryForm(form)
        return result
    }

    @warn_unused_result
    mutating func withEditForm<ResultType>(_ body: (inout TokenEditForm) -> ResultType) throws -> ResultType {
        guard case .editForm(var form) = self else {
            throw Error(expectedType: TokenEditForm.self, actualState: self)
        }
        let result = body(&form)
        self = .editForm(form)
        return result
    }

    @warn_unused_result
    mutating func withScanner<ResultType>(_ body: (inout TokenScanner) -> ResultType) throws -> ResultType {
        guard case .scanner(var scanner) = self else {
            throw Error(expectedType: TokenScanner.self, actualState: self)
        }
        let result = body(&scanner)
        self = .scanner(scanner)
        return result
    }
}

private func compose<A, B, C>(_ transform: @escaping (A) -> B, _ handler: @escaping (B) -> C) -> (A) -> C {
    return { handler(transform($0)) }
}
