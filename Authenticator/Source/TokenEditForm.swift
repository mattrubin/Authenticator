//
//  TokenEditForm.swift
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

struct TokenEditForm: Component {
    fileprivate let persistentToken: PersistentToken

    fileprivate var issuer: String
    fileprivate var name: String

    fileprivate var isValid: Bool {
        return !(issuer.isEmpty && name.isEmpty)
    }

    // MARK: Initialization

    init(persistentToken: PersistentToken) {
        self.persistentToken = persistentToken
        issuer = persistentToken.token.issuer
        name = persistentToken.token.name
    }
}

// MARK: Associated Types

extension TokenEditForm: TableViewModelRepresentable {
    enum Action {
        case issuer(String)
        case name(String)
        case cancel
        case submit
    }

    typealias HeaderModel = TokenFormHeaderModel<Action>
    typealias RowModel = TokenFormRowModel<Action>
}

// MARK: View Model

extension TokenEditForm {
    typealias ViewModel = TableViewModel<TokenEditForm>

    var viewModel: ViewModel {
        return TableViewModel(
            title: "Edit Token",
            leftBarButton: BarButtonViewModel(style: .cancel, action: .cancel),
            rightBarButton: BarButtonViewModel(style: .done, action: .submit, enabled: isValid),
            sections: [
                [
                    issuerRowModel,
                    nameRowModel,
                ],
            ],
            doneKeyAction: .submit
        )
    }

    fileprivate var issuerRowModel: RowModel {
        return .textFieldRow(
            identity: "token.issuer",
            viewModel: TextFieldRowViewModel(
                issuer: issuer,
                changeAction: Action.issuer
            )
        )
    }

    fileprivate var nameRowModel: RowModel {
        return .textFieldRow(
            identity: "token.name",
            viewModel: TextFieldRowViewModel(
                name: name,
                // TODO: Change the behavior of the return key based on validation of the form.
                returnKeyType: .done,
                changeAction: Action.name
            )
        )
    }
}

// MARK: Actions

extension TokenEditForm {
    enum Effect {
        case cancel
        case saveChanges(Token, PersistentToken)
        case showErrorMessage(String)
    }

    @warn_unused_result
    mutating func update(_ action: Action) -> Effect? {
        switch action {
        case let .issuer(issuer):
            self.issuer = issuer
        case let .name(name):
            self.name = name
        case .cancel:
            return .cancel
        case .submit:
            return submit()
        }
        return nil
    }

    @warn_unused_result
    fileprivate mutating func submit() -> Effect? {
        guard isValid else {
            return .showErrorMessage("An issuer or name is required.")
        }

        let token = Token(
            name: name,
            issuer: issuer,
            generator: persistentToken.token.generator
        )
        return .saveChanges(token, persistentToken)
    }
}
