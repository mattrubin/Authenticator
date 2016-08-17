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
    private let persistentToken: PersistentToken

    private var issuer: String
    private var name: String

    private var isValid: Bool {
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
        case Issuer(String)
        case Name(String)
        case Cancel
        case Submit
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
            leftBarButton: BarButtonViewModel(style: .Cancel, action: .Cancel),
            rightBarButton: BarButtonViewModel(style: .Done, action: .Submit, enabled: isValid),
            sections: [
                [
                    issuerRowModel,
                    nameRowModel,
                ]
            ],
            doneKeyAction: .Submit
        )
    }

    private var issuerRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.issuer",
            viewModel: TextFieldRowViewModel(
                issuer: issuer,
                changeAction: Action.Issuer
            )
        )
    }

    private var nameRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.name",
            viewModel: TextFieldRowViewModel(
                name: name,
                returnKeyType: .Done,
                changeAction: Action.Name
            )
        )
    }
}

// MARK: Actions

extension TokenEditForm {
    enum Effect {
        case Cancel
        case SaveChanges(Token, PersistentToken)
        case ShowErrorMessage(String)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case let .Issuer(issuer):
            self.issuer = issuer
        case let .Name(name):
            self.name = name
        case .Cancel:
            return .Cancel
        case .Submit:
            return submit()
        }
        return nil
    }

    @warn_unused_result
    private mutating func submit() -> Effect? {
        guard isValid else {
            return .ShowErrorMessage("Invalid Token")
        }

        let token = Token(
            name: name,
            issuer: issuer,
            generator: persistentToken.token.generator
        )
        return .SaveChanges(token, persistentToken)
    }
}
