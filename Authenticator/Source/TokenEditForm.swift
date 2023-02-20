//
//  TokenEditForm.swift
//  Authenticator
//
//  Copyright (c) 2015-2019 Authenticator authors
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
import Base32

struct TokenEditForm: Component {
    private let persistentToken: PersistentToken

    private var issuer: String
    private var name: String
    private var secret: String

    private var isValid: Bool {
        return !(issuer.isEmpty && name.isEmpty)
    }

    // MARK: Initialization

    init(persistentToken: PersistentToken) {
        self.persistentToken = persistentToken
        secret = MF_Base32Codec.base32String(from: persistentToken.token.generator.secret)
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
        case secret(String)
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
                    tokenRowModel,
                    issuerRowModel,
                    nameRowModel,
                ],
            ],
            doneKeyAction: .submit
        )
    }

    private var tokenRowModel: RowModel {
        return .textFieldRow(
            identity: "token.secret",
            viewModel: TextFieldRowViewModel(
                secret: secret,
                changeAction: Action.secret
            )
        )
    }
    
    private var issuerRowModel: RowModel {
        return .textFieldRow(
            identity: "token.issuer",
            viewModel: TextFieldRowViewModel(
                issuer: issuer,
                changeAction: Action.issuer
            )
        )
    }

    private var nameRowModel: RowModel {
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

    mutating func update(with action: Action) -> Effect? {
        switch action {
        case let .secret(secret):
            self.secret = secret
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

    private mutating func submit() -> Effect? {
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
