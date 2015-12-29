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

struct TokenEntryForm: TableViewModelFamily {
    enum Action {
        case Issuer(String)
        case Name(String)
        case Secret(String)
        case TokenType(Authenticator.TokenType)
        case DigitCount(Int)
        case Algorithm(Generator.Algorithm)

        case ShowAdvancedOptions
        case Cancel
        case Submit
    }

    typealias HeaderModel = TokenFormHeaderModel<Action>
    typealias RowModel = TokenFormRowModel<Action>

    typealias ViewModel = TableViewModel<TokenEntryForm>

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
    var viewModel: ViewModel {
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

    private var advancedSectionHeader: HeaderModel {
        return .ButtonHeader(
            identity: "advanced-options",
            viewModel: ButtonHeaderViewModel(
                title: "Advanced Options",
                action: Action.ShowAdvancedOptions
            )
        )
    }

    private var issuerRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.issuer",
            viewModel: TextFieldRowViewModel(
                issuer: state.issuer,
                changeAction: Action.Issuer
            )
        )
    }

    private var nameRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.name",
            viewModel: TextFieldRowViewModel(
                name: state.name,
                returnKeyType: .Next,
                changeAction: Action.Name
            )
        )
    }

    private var secretRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.secret",
            viewModel: TextFieldRowViewModel(
                secret: state.secret,
                changeAction: Action.Secret
            )
        )
    }

    private var tokenTypeRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.tokenType",
            viewModel: SegmentedControlRowViewModel(
                tokenType: state.tokenType,
                changeAction: Action.TokenType
            )
        )
    }

    private var digitCountRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.digitCount",
            viewModel: SegmentedControlRowViewModel(
                digitCount: state.digitCount,
                changeAction: Action.DigitCount
            )
        )
    }

    private var algorithmRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.algorithm",
            viewModel: SegmentedControlRowViewModel(
                algorithm: state.algorithm,
                changeAction: Action.Algorithm
            )
        )
    }

    // MARK: Action handling
    @warn_unused_result
    mutating func handleAction(action: Action) -> AppAction? {
        state.resetEphemera()
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
    mutating func showAdvancedOptions() {
        state.showsAdvancedOptions = true
        // TODO: Scroll to the newly-expanded section
    }

    @warn_unused_result
    mutating func cancel() -> AppAction {
        return .CancelTokenEntry
    }

    @warn_unused_result
    mutating func submit() -> AppAction? {
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
