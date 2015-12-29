//
//  TokenEditForm.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import OneTimePassword

struct TokenEditForm {
    // MARK: State

    private var state: State

    private struct State {
        let persistentToken: PersistentToken

        var issuer: String
        var name: String

        var isValid: Bool {
            return !(issuer.isEmpty && name.isEmpty)
        }

        init(persistentToken: PersistentToken) {
            self.persistentToken = persistentToken
            issuer = persistentToken.token.issuer
            name = persistentToken.token.name
        }
    }

    // MARK: View Model

    var viewModel: TableViewModel<Form> {
        return TableViewModel(
            title: "Edit Token",
            leftBarButton: BarButtonViewModel(style: .Cancel, action: .Cancel),
            rightBarButton: BarButtonViewModel(style: .Done, action: .Submit, enabled: state.isValid),
            sections: [
                [
                    issuerRowModel,
                    nameRowModel,
                ]
            ],
            doneKeyAction: .Submit
        )
    }

    private var issuerRowModel: Form.RowModel {
        let model = TextFieldRowModel(
            issuerValue: state.issuer,
            changeAction: Form.Action.Issuer
        )
        return .TextFieldRow(model)
    }

    private var nameRowModel: Form.RowModel {
        let model = TextFieldRowModel(
            nameValue: state.name,
            returnKeyType: .Done,
            changeAction: Form.Action.Name
        )
        return .TextFieldRow(model)
    }

    // MARK: Action handling

    @warn_unused_result
    mutating func handleAction(action: Form.Action) -> AppAction? {
        switch action {
        case .Issuer(let value):
            state.issuer = value
        case .Name(let value):
            state.name = value
        case .Secret:
            fatalError()
        case .TokenType:
            fatalError()
        case .DigitCount:
            fatalError()
        case .Algorithm:
            fatalError()
        case .ShowAdvancedOptions:
            fatalError()
        case .Cancel:
            return cancel()
        case .Submit:
            return submit()
        }
        return nil
    }

    // MARK: Initialization

    init(persistentToken: PersistentToken) {
        state = State(persistentToken: persistentToken)
    }

    // MARK: Actions

    @warn_unused_result
    private func cancel() -> AppAction {
        return .CancelTokenEdit
    }

    @warn_unused_result
    private func submit() -> AppAction? {
        guard state.isValid else {
            // TODO: Show error message?
            return nil
        }

        let token = Token(
            name: state.name,
            issuer: state.issuer,
            generator: state.persistentToken.token.generator
        )
        return .SaveChanges(token, state.persistentToken)
    }
}
