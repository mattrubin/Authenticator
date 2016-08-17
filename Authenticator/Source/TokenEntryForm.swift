//
//  TokenEntryForm.swift
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

private let defaultTimerFactor = Generator.Factor.Timer(period: 30)
private let defaultCounterFactor = Generator.Factor.Counter(0)

struct TokenEntryForm: Component {
    private var issuer: String = ""
    private var name: String = ""
    private var secret: String = ""
    private var tokenType: TokenType = .Timer
    private var digitCount: Int = 6
    private var algorithm: Generator.Algorithm = .SHA1

    private var showsAdvancedOptions: Bool = false

    private var isValid: Bool {
        return !secret.isEmpty && !(issuer.isEmpty && name.isEmpty)
    }

    // MARK: Initialization

    init() {
    }
}

// MARK: Associated Types

extension TokenEntryForm: TableViewModelRepresentable {
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
}

// MARK: View Model

extension TokenEntryForm {
    typealias ViewModel = TableViewModel<TokenEntryForm>

    var viewModel: ViewModel {
        return TableViewModel(
            title: "Add Token",
            leftBarButton: BarButtonViewModel(style: .Cancel, action: .Cancel),
            rightBarButton: BarButtonViewModel(style: .Done, action: .Submit, enabled: isValid),
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
            doneKeyAction: .Submit
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
                returnKeyType: .Next,
                changeAction: Action.Name
            )
        )
    }

    private var secretRowModel: RowModel {
        return .TextFieldRow(
            identity: "token.secret",
            viewModel: TextFieldRowViewModel(
                secret: secret,
                changeAction: Action.Secret
            )
        )
    }

    private var tokenTypeRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.tokenType",
            viewModel: SegmentedControlRowViewModel(
                tokenType: tokenType,
                changeAction: Action.TokenType
            )
        )
    }

    private var digitCountRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.digitCount",
            viewModel: SegmentedControlRowViewModel(
                digitCount: digitCount,
                changeAction: Action.DigitCount
            )
        )
    }

    private var algorithmRowModel: RowModel {
        return .SegmentedControlRow(
            identity: "token.algorithm",
            viewModel: SegmentedControlRowViewModel(
                algorithm: algorithm,
                changeAction: Action.Algorithm
            )
        )
    }
}

// MARK: Actions

extension TokenEntryForm {
    enum Effect {
        case Cancel
        case SaveNewToken(Token)
        case ShowErrorMessage(String)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case let .Issuer(issuer):
            self.issuer = issuer
        case let .Name(name):
            self.name = name
        case let .Secret(secret):
            self.secret = secret
        case let .TokenType(tokenType):
            self.tokenType = tokenType
        case let .DigitCount(digitCount):
            self.digitCount = digitCount
        case let .Algorithm(algorithm):
            self.algorithm = algorithm
        case .ShowAdvancedOptions:
            showsAdvancedOptions = true
            // TODO: Scroll to the newly-expanded section
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
            // TODO: Show more specific error messages for different failure cases
            return .ShowErrorMessage("Invalid Token")
        }

        guard let secretData = NSData(base32String: secret)
            where secretData.length > 0 else {
                return .ShowErrorMessage("Invalid Token")
        }

        let factor: Generator.Factor
        switch tokenType {
        case .Counter:
            factor = defaultCounterFactor
        case .Timer:
            factor = defaultTimerFactor
        }

        guard let generator = Generator(
            factor: factor,
            secret: secretData,
            algorithm: algorithm,
            digits: digitCount
            ) else {
                return .ShowErrorMessage("Invalid Token")
        }

        let token = Token(
            name: name,
            issuer: issuer,
            generator: generator
        )

        return .SaveNewToken(token)
    }
}
