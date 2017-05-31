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
        case info(InfoList, Info?)

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
            case .info(let infoList, let info):
                return .info(infoList.viewModel, info?.viewModel)
            }
        }
    }

    init(deviceCanScan: Bool) {
        tokenList = TokenList()
        modal = .none
        self.deviceCanScan = deviceCanScan
    }
}

// MARK: View

extension Root {
    typealias ViewModel = RootViewModel

    func viewModel(for persistentTokens: [PersistentToken], at displayTime: DisplayTime) -> ViewModel {
        return ViewModel(
            tokenList: tokenList.viewModel(for: persistentTokens, at: displayTime),
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

        case infoListEffect(InfoList.Effect)
        case infoEffect(Info.Effect)
        case dismissInfo

        case addTokenFromURL(Token)
    }

    enum Event {
        case addTokenFromURLSucceeded
        case tokenFormSucceeded

        case addTokenFailed(Error)
        case saveTokenFailed(Error)
        case updateTokenFailed(Error)
        case moveTokenFailed(Error)
        case deleteTokenFailed(Error)
    }

    enum Effect {
        case addToken(Token,
            success: Event,
            failure: (Error) -> Event)

        case saveToken(Token, PersistentToken,
            success: Event,
            failure: (Error) -> Event)

        case updatePersistentToken(PersistentToken,
            failure: (Error) -> Event)

        case moveToken(fromIndex: Int, toIndex: Int,
            failure: (Error) -> Event)

        case deletePersistentToken(PersistentToken,
            failure: (Error) -> Event)

        case showErrorMessage(String)
        case showSuccessMessage(String)
        case showApplicationSettings
        case openURL(URL)
    }

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

            case .infoListEffect(let effect):
                return handleInfoListEffect(effect)

            case .infoEffect(let effect):
                return handleInfoEffect(effect)

            case .dismissInfo:
                try modal.dismissInfo()
                return nil

            case .addTokenFromURL(let token):
                return .addToken(token,
                                 success: Event.addTokenFromURLSucceeded,
                                 failure: Event.addTokenFailed)
            }
        } catch {
            throw ComponentError(underlyingError: error, action: action, component: self)
        }
    }

    mutating func update(_ event: Event) -> Effect? {
        switch event {
        case .addTokenFromURLSucceeded:
            return nil

        case .tokenFormSucceeded:
            // Dismiss the modal form.
            modal = .none
            return nil

        case .addTokenFailed:
            return .showErrorMessage("Failed to add token.")
        case .saveTokenFailed:
            return .showErrorMessage("Failed to save token.")
        case .updateTokenFailed:
            return .showErrorMessage("Failed to update token.")
        case .moveTokenFailed:
            return .showErrorMessage("Failed to move token.")
        case .deleteTokenFailed:
            return .showErrorMessage("Failed to delete token.")
        }
    }

    private mutating func handleTokenListEffect(_ effect: TokenList.Effect) -> Effect? {
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

        case let .updateToken(persistentToken):
            return .updatePersistentToken(persistentToken,
                                          failure: Event.updateTokenFailed)

        case let .moveToken(fromIndex, toIndex):
            return .moveToken(fromIndex: fromIndex, toIndex: toIndex,
                              failure: Event.moveTokenFailed)

        case let .deletePersistentToken(persistentToken):
            return .deletePersistentToken(persistentToken,
                                          failure: Event.deleteTokenFailed)

        case .showErrorMessage(let message):
            return .showErrorMessage(message)

        case .showSuccessMessage(let message):
            return .showSuccessMessage(message)

        case .showBackupInfo:
            do {
                modal = .info(InfoList(), try Info.backupInfo())
                return nil
            } catch {
                return .showErrorMessage("Failed to load backup info.")
            }

        case .showInfoList:
            modal = .info(InfoList(), nil)
            return nil
        }
    }

    private mutating func handleTokenEntryFormEffect(_ effect: TokenEntryForm.Effect) -> Effect? {
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

    private mutating func handleTokenEditFormEffect(_ effect: TokenEditForm.Effect) -> Effect? {
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

    private mutating func handleTokenScannerEffect(_ effect: TokenScanner.Effect) -> Effect? {
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

        case .showApplicationSettings:
            return .showApplicationSettings

        case .saveNewToken(let token):
            return .addToken(token,
                             success: Event.tokenFormSucceeded,
                             failure: Event.addTokenFailed)

        case .showErrorMessage(let message):
            return .showErrorMessage(message)
        }
    }

    private mutating func handleInfoListEffect(_ effect: InfoList.Effect) -> Effect? {
        switch effect {
        case .showBackupInfo:
            do {
                try modal.setInfo(Info.backupInfo())
                return nil
            } catch {
                return .showErrorMessage("Failed to load backup info.")
            }

        case .showLicenseInfo:
            do {
                try modal.setInfo(Info.licenseInfo())
                return nil
            } catch {
                return .showErrorMessage("Failed to load acknowledgements.")
            }

        case .done:
            modal = .none
            return nil

        }
    }

    private mutating func handleInfoEffect(_ effect: Info.Effect) -> Effect? {
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

    mutating func withEntryForm<ResultType>(_ body: (inout TokenEntryForm) -> ResultType) throws -> ResultType {
        guard case .entryForm(var form) = self else {
            throw Error(expectedType: TokenEntryForm.self, actualState: self)
        }
        let result = body(&form)
        self = .entryForm(form)
        return result
    }

    mutating func withEditForm<ResultType>(_ body: (inout TokenEditForm) -> ResultType) throws -> ResultType {
        guard case .editForm(var form) = self else {
            throw Error(expectedType: TokenEditForm.self, actualState: self)
        }
        let result = body(&form)
        self = .editForm(form)
        return result
    }

    mutating func withScanner<ResultType>(_ body: (inout TokenScanner) -> ResultType) throws -> ResultType {
        guard case .scanner(var scanner) = self else {
            throw Error(expectedType: TokenScanner.self, actualState: self)
        }
        let result = body(&scanner)
        self = .scanner(scanner)
        return result
    }

    mutating func setInfo(_ info: Info) throws {
        guard case .info(let infoList, .none) = self else {
            throw Error(expectedType: InfoList.self, actualState: self)
        }
        self = .info(infoList, info)
    }

    mutating func dismissInfo() throws {
        guard case .info(let infoList, .some) = self else {
            throw Error(expectedType: Info.self, actualState: self)
        }
        self = .info(infoList, nil)
    }
}
