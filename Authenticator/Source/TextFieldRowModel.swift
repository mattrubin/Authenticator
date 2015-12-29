//
//  TextFieldRowModel.swift
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

import UIKit

protocol TextFieldRowModel {
    typealias Action

    var label: String { get }
    var placeholder: String { get }

    var autocapitalizationType: UITextAutocapitalizationType { get }
    var autocorrectionType: UITextAutocorrectionType { get }
    var keyboardType: UIKeyboardType { get }
    var returnKeyType: UIReturnKeyType { get }

    var value: String { get }
    var changeAction: (String) -> Action { get }
}

struct IssuerRowModel: TextFieldRowModel {
    let label: String
    let placeholder: String

    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType

    let value: String
    let changeAction: (String) -> Form.Action

    init(value: String, changeAction: (String) -> Form.Action) {
        label = "Issuer"
        placeholder = "Some Website"

        autocapitalizationType = .Words
        autocorrectionType = .Default
        keyboardType = .Default
        returnKeyType = .Next

        self.value = value
        self.changeAction = changeAction
    }
}

struct NameRowModel: TextFieldRowModel {
    let label: String
    let placeholder: String

    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType

    let value: String
    let changeAction: (String) -> Form.Action

    init(value: String, returnKeyType: UIReturnKeyType, changeAction: (String) -> Form.Action) {
        label = "Account Name"
        placeholder = "user@example.com"

        autocapitalizationType = .None
        autocorrectionType = .No
        keyboardType = .EmailAddress
        self.returnKeyType = returnKeyType

        self.value = value
        self.changeAction = changeAction
    }
}

struct SecretRowModel: TextFieldRowModel {
    let label: String
    let placeholder: String

    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType

    let value: String
    let changeAction: (String) -> Form.Action

    init(value: String, changeAction: (String) -> Form.Action) {
        label = "Secret Key"
        placeholder = "•••• •••• •••• ••••"

        autocapitalizationType = .None
        autocorrectionType = .No
        keyboardType = .Default
        returnKeyType = .Done

        self.value = value
        self.changeAction = changeAction
    }
}
