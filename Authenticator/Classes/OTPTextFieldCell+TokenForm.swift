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

struct IssuerRowModel: TextFieldRowModel {
    let label = "Issuer"
    let placeholder = "Some Website"

    let autocapitalizationType: UITextAutocapitalizationType = .Words
    let autocorrectionType: UITextAutocorrectionType = .Default
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Next
}

struct NameRowModel: TextFieldRowModel {
    let label = "Account Name"
    let placeholder = "user@example.com"

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .EmailAddress
    let returnKeyType: UIReturnKeyType

    init(returnKeyType: UIReturnKeyType) {
        self.returnKeyType = returnKeyType
    }
}

struct SecretRowModel: TextFieldRowModel {
    let label = "Secret Key"
    let placeholder = "•••• •••• •••• ••••"

    let autocapitalizationType: UITextAutocapitalizationType = .None
    let autocorrectionType: UITextAutocorrectionType = .No
    let keyboardType: UIKeyboardType = .Default
    let returnKeyType: UIReturnKeyType = .Done
}


extension OTPTextFieldCell {
    static func issuerCellWithDelegate(delegate: OTPTextFieldCellDelegate) -> OTPTextFieldCell {
        return cellWithRowModel(IssuerRowModel(), delegate: delegate)
    }

    static func nameCellWithDelegate(delegate: OTPTextFieldCellDelegate, returnKeyType: UIReturnKeyType) -> OTPTextFieldCell {
        return cellWithRowModel(NameRowModel(returnKeyType: returnKeyType), delegate: delegate)
    }

    static func secretCellWithDelegate(delegate: OTPTextFieldCellDelegate) -> OTPTextFieldCell {
        return cellWithRowModel(SecretRowModel(), delegate: delegate)
    }

    static func cellWithRowModel(rowModel: TextFieldRowModel, delegate: OTPTextFieldCellDelegate) -> OTPTextFieldCell {
        let cell = OTPTextFieldCell()
        cell.updateWithRowModel(rowModel)
        cell.delegate = delegate
        return cell
    }
}
