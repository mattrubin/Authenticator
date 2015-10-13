//
//  OTPTextFieldCell+TokenForm.swift
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

struct IssuerRowViewModel: TextFieldRowViewModel {
    let label = "Issuer"
    let placeholder = "Some Website"
    let initialValue: String

    let autocapitalizationType: UITextAutocapitalizationType = .Words
    let autocorrectionType: UITextAutocorrectionType = .Default
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Next

    let changeAction: (String) -> ()

    init(initialValue: String, changeAction: (String) -> ()) {
        self.initialValue = initialValue
        self.changeAction = changeAction
    }
}

struct NameRowViewModel: TextFieldRowViewModel {
    let label = "Account Name"
    let placeholder = "user@example.com"
    let initialValue: String

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .EmailAddress
    let returnKeyType: UIReturnKeyType

    let changeAction: (String) -> ()

    init(initialValue: String, returnKeyType: UIReturnKeyType, changeAction: (String) -> ()) {
        self.initialValue = initialValue
        self.returnKeyType = returnKeyType
        self.changeAction = changeAction
    }
}

struct SecretRowViewModel: TextFieldRowViewModel {
    let label = "Secret Key"
    let placeholder = "•••• •••• •••• ••••"
    let initialValue: String

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Done

    let changeAction: (String) -> ()

    init(initialValue: String, changeAction: (String) -> ()) {
        self.initialValue = initialValue
        self.changeAction = changeAction
    }
}
