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

class TokenEditForm: TokenForm {
    weak var presenter: TokenFormPresenter?
    private weak var actionHandler: ActionHandler?

    // MARK: State

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

    private var state: State {
        didSet {
            presenter?.updateWithViewModel(viewModel)
        }
    }

    // MARK: View Model

    var viewModel: TableViewModel<Form> {
        return TableViewModel(
            title: "Edit Token",
            leftBarButton: BarButtonViewModel(style: .Cancel) { [weak self] in
                self?.cancel()
            },
            rightBarButton: BarButtonViewModel(style: .Done, enabled: state.isValid) { [weak self] in
                self?.submit()
            },
            sections: [
                [
                    issuerRowModel,
                    nameRowModel,
                ]
            ],
            doneKeyAction: { [weak self] in
                self?.submit()
            }
        )
    }

    private var issuerRowModel: Form.RowModel {
        let model = IssuerRowViewModel(
            value: state.issuer,
            changeAction: { [weak self] (newIssuer) -> () in
                self?.state.issuer = newIssuer
            }
        )
        return .TextFieldRow(model)
    }

    private var nameRowModel: Form.RowModel {
        let model = NameRowViewModel(
            value: state.name,
            returnKeyType: .Done,
            changeAction: { [weak self] (newName) -> () in
                self?.state.name = newName
            }
        )
        return .TextFieldRow(model)
    }

    // MARK: Initialization

    init(persistentToken: PersistentToken, actionHandler: ActionHandler) {
        state = State(persistentToken: persistentToken)
        self.actionHandler = actionHandler
    }

    // MARK: Actions

    func cancel() {
        actionHandler?.handleAction(.CancelTokenEdit)
    }

    func submit() {
        guard state.isValid else { return }

        let token = Token(
            name: state.name,
            issuer: state.issuer,
            generator: state.persistentToken.token.generator
        )
        actionHandler?.handleAction(.SaveChanges(token, state.persistentToken))
    }
}
