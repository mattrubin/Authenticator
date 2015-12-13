//
//  TokenEntryForm.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

private let defaultTimerFactor = Generator.Factor.Timer(period: 30)
private let defaultCounterFactor = Generator.Factor.Counter(0)

class TokenEntryForm {
    // MARK: State

    private var state: State

    private struct State {
        var issuer: String
        var name: String
        var secret: String
        var tokenType: TokenType
        var digitCount: Int
        var algorithm: Generator.Algorithm

        var showsAdvancedOptions: Bool
        var submitFailed: Bool

        var isValid: Bool {
            return !secret.isEmpty && !(issuer.isEmpty && name.isEmpty)
        }

        mutating func resetEphemera() {
            submitFailed = false
        }
    }

    // MARK: Initialization

    init() {
        state = State(
            issuer: "",
            name: "",
            secret: "",
            tokenType: .Timer,
            digitCount: 6,
            algorithm: .SHA1,
            showsAdvancedOptions: false,
            submitFailed: false
        )
    }
}

// MARK: View Model

extension TokenEntryForm {
    var viewModel: TableViewModel<Form> {
        return TableViewModel(
            title: "Add Token",
            leftBarButton: BarButtonViewModel(style: .Cancel, action: .Cancel),
            rightBarButton: BarButtonViewModel(style: .Done, action: .Submit, enabled: state.isValid),
            sections: [
                [
                    issuerRowModel,
                    nameRowModel,
                    secretRowModel,
                ],
                Section(
                    header: advancedSectionHeader,
                    rows: !state.showsAdvancedOptions ? [] :
                        [
                            tokenTypeRowModel,
                            digitCountRowModel,
                            algorithmRowModel,
                        ]
                ),
            ],
            doneKeyAction: .Submit,
            errorMessage: state.submitFailed ? "Invalid Token" : nil
        )
    }

    private var advancedSectionHeader: Form.HeaderModel {
        let model = ButtonHeaderViewModel(
            title: "Advanced Options",
            action: Form.Action.ShowAdvancedOptions
        )
        return .ButtonHeader(model)
    }

    private var issuerRowModel: Form.RowModel {
        let model = IssuerRowModel(
            value: state.issuer,
            changeAction: Form.Action.Issuer
        )
        return .TextFieldRow(model)
    }

    private var nameRowModel: Form.RowModel {
        let model = NameRowModel(
            value: state.name,
            returnKeyType: .Next,
            changeAction: Form.Action.Name
        )
        return .TextFieldRow(model)
    }

    private var secretRowModel: Form.RowModel {
        let model = SecretRowModel(
            value: state.secret,
            changeAction: Form.Action.Secret
        )
        return .TextFieldRow(model)
    }

    private var tokenTypeRowModel: Form.RowModel {
        let model = TokenTypeRowModel(
            value: state.tokenType,
            changeAction: Form.Action.TokenType
        )
        return .TokenTypeRow(model)
    }

    private var digitCountRowModel: Form.RowModel {
        let model = DigitCountRowModel(
            value: state.digitCount,
            changeAction: Form.Action.DigitCount
        )
        return .DigitCountRow(model)
    }

    private var algorithmRowModel: Form.RowModel {
        let model = AlgorithmRowModel(
            value: state.algorithm,
            changeAction: Form.Action.Algorithm
        )
        return .AlgorithmRow(model)
    }

    // MARK: Action handling
    @warn_unused_result
    func handleAction(action: Form.Action) -> AppAction? {
        switch action {
        case .Issuer(let value):
            state.issuer = value
        case .Name(let value):
            state.name = value
        case .Secret(let value):
            state.secret = value
        case .TokenType(let value):
            state.tokenType = value
        case .DigitCount(let value):
            state.digitCount = value
        case .Algorithm(let value):
            state.algorithm = value
        case .ShowAdvancedOptions:
            showAdvancedOptions()
        case .Cancel:
            return cancel()
        case .Submit:
            return submit()
        }
        return nil
    }
}

// MARK: Actions

private extension TokenEntryForm {
    func showAdvancedOptions() {
        state.showsAdvancedOptions = true
        // TODO: Scroll to the newly-expanded section
    }

    @warn_unused_result
    func cancel() -> AppAction {
        return .CancelTokenEntry
    }

    @warn_unused_result
    func submit() -> AppAction? {
        if !state.isValid {
            // TODO: Show error message?
            return nil
        }

        if let secret = NSData(base32String: state.secret) {
            if secret.length > 0 {
                let factor: Generator.Factor
                switch state.tokenType {
                case .Counter:
                    factor = defaultCounterFactor
                case .Timer:
                    factor = defaultTimerFactor
                }

                if let generator = Generator(
                    factor: factor,
                    secret: secret,
                    algorithm: state.algorithm,
                    digits: state.digitCount
                    ) {
                        let token = Token(
                            name: state.name,
                            issuer: state.issuer,
                            generator: generator
                        )

                        return .SaveNewToken(token)
                }
            }
        }

        // If the method hasn't returned by this point, token creation failed
        state.submitFailed = true
        return nil
    }
}
