//
//  TextFieldRowModel.swift
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

import UIKit

protocol TextFieldRowViewModel {
    var label: String { get }
    var placeholder: String { get }

    var autocapitalizationType: UITextAutocapitalizationType { get }
    var autocorrectionType: UITextAutocorrectionType { get }
    var keyboardType: UIKeyboardType { get }
    var returnKeyType: UIReturnKeyType { get }

    var value: String { get }
    var identifier: Form.Field { get }
}

struct IssuerRowViewModel: TextFieldRowViewModel {
    let label = "Issuer"
    let placeholder = "Some Website"

    let autocapitalizationType: UITextAutocapitalizationType = .Words
    let autocorrectionType: UITextAutocorrectionType = .Default
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Next

    let value: String
    let identifier: Form.Field = .Issuer

    init(value: String) {
        self.value = value
    }
}

struct NameRowViewModel: TextFieldRowViewModel {
    let label = "Account Name"
    let placeholder = "user@example.com"

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .EmailAddress
    let returnKeyType: UIReturnKeyType

    let value: String
    let identifier: Form.Field = .Name

    init(value: String, returnKeyType: UIReturnKeyType) {
        self.value = value
        self.returnKeyType = returnKeyType
    }
}

struct SecretRowViewModel: TextFieldRowViewModel {
    let label = "Secret Key"
    let placeholder = "•••• •••• •••• ••••"

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Done

    let value: String
    let identifier: Form.Field = .Secret

    init(value: String) {
        self.value = value
    }
}
