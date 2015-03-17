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

    let autocapitalizationType =  UITextAutocapitalizationType.Words
    var autocorrectionType = UITextAutocorrectionType.Default
    var keyboardType = UIKeyboardType.Default
    let returnKeyType = UIReturnKeyType.Next;
}

struct NameRowModel: TextFieldRowModel {
    let label = "Account Name"
    let placeholder = "user@example.com"

    let autocapitalizationType =  UITextAutocapitalizationType.None
    var autocorrectionType = UITextAutocorrectionType.No
    var keyboardType = UIKeyboardType.EmailAddress
    let returnKeyType = UIReturnKeyType.Next;
}


extension OTPTextFieldCell {
    static func issuerCellWithDelegate(delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        let issuerCell = OTPTextFieldCell()
        issuerCell.updateWithRowModel(IssuerRowModel())
        issuerCell.textField.delegate = delegate;
        return issuerCell
    }

    static func nameCellWithDelegate(delegate: UITextFieldDelegate) -> OTPTextFieldCell {
        let nameCell = OTPTextFieldCell()
        nameCell.updateWithRowModel(NameRowModel())
        nameCell.textField.delegate = delegate
        return nameCell
    }
}
