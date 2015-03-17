//
//  OTPTextFieldCell+TokenForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 3/16/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import Foundation

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
    let returnKeyType: UIReturnKeyType = .Next
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
    static func issuerCellWithDelegate(delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        return cellWithRowModel(IssuerRowModel(), delegate: delegate)
    }

    static func nameCellWithDelegate(delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        return cellWithRowModel(NameRowModel(), delegate: delegate)
    }

    static func secretCellWithDelegate(delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        return cellWithRowModel(SecretRowModel(), delegate: delegate)
    }

    static func cellWithRowModel(rowModel: TextFieldRowModel, delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        let cell = OTPTextFieldCell()
        cell.updateWithRowModel(rowModel)
        cell.textField.delegate = delegate
        return cell
    }
}
