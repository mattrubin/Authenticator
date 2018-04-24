//
//  TokenFormModels.swift
//  Authenticator
//
//  Copyright (c) 2015-2017 Authenticator authors
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

import UIKit
import OneTimePassword

enum TokenFormHeaderModel<Action> {
    case buttonHeader(identity: String, viewModel: ButtonHeaderViewModel<Action>)
}

enum TokenFormRowModel<Action>: Identifiable {
    case textFieldRow(identity: String, viewModel: TextFieldRowViewModel<Action>)
    case segmentedControlRow(identity: String, viewModel: SegmentedControlRowViewModel<Action>)

    func hasSameIdentity(as other: TokenFormRowModel) -> Bool {
        switch (self, other) {
        case let (.textFieldRow(rowA), .textFieldRow(rowB)):
            return rowA.identity == rowB.identity
        case let (.segmentedControlRow(rowA), .segmentedControlRow(rowB)):
            return rowA.identity == rowB.identity
        default:
            return false
        }
    }
}

enum TokenType {
    case counter, timer
}

extension TextFieldRowViewModel {
    init(issuer value: String, changeAction: @escaping (String) -> Action) {
        label = "Issuer"
        placeholder = "Some Website"

        autocapitalizationType = .words
        autocorrectionType = .default
        keyboardType = .default
        returnKeyType = .next

        self.value = value
        self.changeAction = changeAction
    }

    init(name value: String, returnKeyType: UIReturnKeyType, changeAction: @escaping (String) -> Action) {
        label = "Account Name"
        placeholder = "user@example.com"

        autocapitalizationType = .none
        autocorrectionType = .no
        keyboardType = .emailAddress
        self.returnKeyType = returnKeyType

        self.value = value
        self.changeAction = changeAction
    }

    init(secret value: String, changeAction: @escaping (String) -> Action) {
        label = "Secret Key"
        placeholder = "•••• •••• •••• ••••"

        autocapitalizationType = .none
        autocorrectionType = .no
        keyboardType = .default
        returnKeyType = .done

        self.value = value
        self.changeAction = changeAction
    }
}

extension SegmentedControlRowViewModel {
    init(tokenType value: TokenType, changeAction: (TokenType) -> Action) {
        let options = [
            (title: "Time Based", value: TokenType.timer),
            (title: "Counter Based", value: TokenType.counter),
        ]
        self.init(options: options, value: value, changeAction: changeAction)
    }

    init(digitCount value: Int, changeAction: (Int) -> Action) {
        let options = [
            (title: "6 Digits", value: 6),
            (title: "7 Digits", value: 7),
            (title: "8 Digits", value: 8),
        ]
        self.init(options: options, value: value, changeAction: changeAction)
    }

    init(algorithm value: Generator.Algorithm, changeAction: (Generator.Algorithm) -> Action) {
        let options = [
            (title: "SHA-1", value: Generator.Algorithm.sha1),
            (title: "SHA-256", value: Generator.Algorithm.sha256),
            (title: "SHA-512", value: Generator.Algorithm.sha512),
        ]
        self.init(options: options, value: value, changeAction: changeAction)
    }
}
