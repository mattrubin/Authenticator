//
//  TokenEditForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 8/29/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePasswordLegacy

class TokenEditForm: NSObject, TokenForm {
    weak var delegate: TokenFormDelegate?

    private lazy var issuerCell: OTPTextFieldCell = {
        OTPTextFieldCell.issuerCellWithDelegate(self)
    }()
    private lazy var accountNameCell: OTPTextFieldCell = {
        OTPTextFieldCell.nameCellWithDelegate(self, returnKeyType: .Done)
    }()

    var issuer: String? {
        return issuerCell.textField.text
    }
    var accountName: String? {
        return accountNameCell.textField.text
    }

    private var cells: [[UITableViewCell]] {
        return [
            [
                issuerCell,
                accountNameCell,
            ]
        ]
    }

    let token: OTPToken

    init(token: OTPToken) {
        self.token = token
        super.init()
        issuerCell.textField.text = token.issuer;
        accountNameCell.textField.text = token.name;
    }

    let title = "Edit Token"

    func focusFirstField() {
        issuerCell.textField.becomeFirstResponder()
    }

    func unfocus() {
        issuerCell.textField.resignFirstResponder()
        accountNameCell.textField.resignFirstResponder()
    }

    var numberOfSections: Int {
        return cells.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        if section < cells.startIndex { return 0 }
        if section >= cells.endIndex { return 0 }
        return cells[section].count
    }

    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
        if indexPath.section < cells.startIndex { return nil }
        if indexPath.section >= cells.endIndex { return nil }
        let sectionCells = cells[indexPath.section]
        if indexPath.row < sectionCells.startIndex { return nil }
        if indexPath.row >= sectionCells.endIndex { return nil }
        return sectionCells[indexPath.row]
    }

    var isValid: Bool {
        return !issuerCell.textField.text.isEmpty ||
            !accountNameCell.textField.text.isEmpty
    }

    func submit() {
        // Do something
        delegate?.formDidSubmit(self)
    }
}

extension TokenEditForm: OTPTextFieldCellDelegate {
    func textFieldCellDidChange(textFieldCell: OTPTextFieldCell) {
        delegate?.formValuesDidChange(self)
    }

    func textFieldCellDidReturn(textFieldCell: OTPTextFieldCell) {
        if textFieldCell == issuerCell {
            accountNameCell.textField.becomeFirstResponder()
        } else if textFieldCell == accountNameCell {
            accountNameCell.textField.resignFirstResponder()
            submit()
        }
    }
}
