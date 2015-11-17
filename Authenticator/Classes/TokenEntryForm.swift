//
//  TokenEntryForm.swift
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

import Foundation
import OneTimePassword

let defaultTimerFactor = Generator.Factor.Timer(period: 30)
let defaultCounterFactor = Generator.Factor.Counter(0)

class TokenEntryForm: TokenForm {
    weak var presenter: TokenFormPresenter?

    // MARK: Events

    enum Event {
        case Save(Token)
        case Close
    }

    private let callback: (Event) -> ()

    // MARK: State

    private struct State {
        var issuer: String
        var name: String
        var secret: String
        var tokenType: TokenType
        var digitCount: Int
        var algorithm: Generator.Algorithm

        var isValid: Bool {
            return !secret.isEmpty && !(issuer.isEmpty && name.isEmpty)
        }
    }

    private var state: State {
        didSet {
            presenter?.formValuesDidChange(self)
        }
    }

    // TODO: move this into State when form(_:didReloadSection:) is no longer necessary
    var showsAdvancedOptions = false

    // MARK: Initialization

    init(callback: (Event) -> ()) {
        self.callback = callback
        state = State(
            issuer: "",
            name: "",
            secret: "",
            tokenType: .Timer,
            digitCount: 6,
            algorithm: .SHA1
        )
    }

    // MARK: View Model

    var viewModel: TableViewModel<Form> {
        return TableViewModel(
            title: "Add Token",
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
                    secretRowModel,
                ],
                Section(
                    header: advancedSectionHeader,
                    rows: !showsAdvancedOptions ? [] :
                        [
                            tokenTypeRowModel,
                            digitCountRowModel,
                            algorithmRowModel,
                        ]
                ),
            ],
            doneKeyAction: { [weak self] in
                self?.submit()
            }
        )
    }

    private var advancedSectionHeader: Form.HeaderModel {
        let model = ButtonHeaderViewModel(title: "Advanced Options") { [weak self] in
            self?.toggleAdvancedOptions()
        }
        return .ButtonHeader(model)
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
            returnKeyType: .Next,
            changeAction: { [weak self] (newName) -> () in
                self?.state.name = newName
            }
        )
        return .TextFieldRow(model)
    }

    private var secretRowModel: Form.RowModel {
        let model = SecretRowViewModel(
            value: state.secret,
            changeAction: { [weak self] (newSecret) -> () in
                self?.state.secret = newSecret
            }
        )
        return .TextFieldRow(model)
    }

    private var tokenTypeRowModel: Form.RowModel {
        let model = TokenTypeRowViewModel(
            value: state.tokenType,
            changeAction: { [weak self] (newTokenType) -> () in
                self?.state.tokenType = newTokenType
            }
        )
        return .TokenTypeRow(model)
    }

    private var digitCountRowModel: Form.RowModel {
        let model = DigitCountRowViewModel(
            value: state.digitCount,
            changeAction: { [weak self] (newDigitCount) -> () in
                self?.state.digitCount = newDigitCount
            }
        )
        return .DigitCountRow(model)
    }

    private var algorithmRowModel: Form.RowModel {
        let model = AlgorithmRowViewModel(
            value: state.algorithm,
            changeAction: { [weak self] (newAlgorithm) -> () in
                self?.state.algorithm = newAlgorithm
            }
        )
        return .AlgorithmRow(model)
    }

    // MARK: Actions

    func cancel() {
        callback(.Close)
    }

    func submit() {
        if !state.isValid { return }

        if let secret = NSData(base32String: state.secret) {
            if secret.length > 0 {
                let factor: Generator.Factor
                switch state.tokenType {
                case .Counter:
                    factor = defaultCounterFactor
                case .Timer:
                    factor = defaultTimerFactor
                }

                let generator = Generator(
                    factor: factor,
                    secret: secret,
                    algorithm: state.algorithm,
                    digits: state.digitCount
                )
                let token = Token(
                    name: state.name,
                    issuer: state.issuer,
                    generator: generator
                )

                if token.currentPassword != nil {
                    callback(.Save(token))
                    callback(.Close)
                    return
                }
            }
        }

        // If the method hasn't returned by this point, token creation failed
        presenter?.form(self, didFailWithErrorMessage: "Invalid Token")
    }

    func toggleAdvancedOptions() {
        if !showsAdvancedOptions {
            showsAdvancedOptions = true
            // TODO: Don't hard-code this index
            presenter?.form(self, didReloadSection: 1)
        }
    }
}
