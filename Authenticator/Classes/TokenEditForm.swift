//
//  TokenEditForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 8/29/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePasswordLegacy

protocol TokenEditFormDelegate: class {
    func form(form: TokenEditForm, didEditToken token: OTPToken)
}

class TokenEditForm: NSObject, TokenForm {
    weak var presenter: TokenFormPresenter?
    private weak var delegate: TokenEditFormDelegate?

    private lazy var issuerCell: OTPTextFieldCell = {
        OTPTextFieldCell.issuerCellWithDelegate(self)
    }()
    private lazy var accountNameCell: OTPTextFieldCell = {
        OTPTextFieldCell.nameCellWithDelegate(self, returnKeyType: .Done)
    }()

    private var sections: [Section] {
        return [
            [
                issuerCell,
                accountNameCell,
            ]
        ]
    }

    let token: OTPToken

    init(token: OTPToken, delegate: TokenEditFormDelegate) {
        self.token = token
        self.delegate = delegate
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
        return sections.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        if section < sections.startIndex { return 0 }
        if section >= sections.endIndex { return 0 }
        return sections[section].rows.count
    }

    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
        if indexPath.section < sections.startIndex { return nil }
        if indexPath.section >= sections.endIndex { return nil }
        let section = sections[indexPath.section]
        if indexPath.row < section.rows.startIndex { return nil }
        if indexPath.row >= section.rows.endIndex { return nil }
        return section.rows[indexPath.row]
    }

    func viewForHeaderInSection(section: Int) -> UIView? {
        return nil
    }

    var isValid: Bool {
        return !issuerCell.textField.text.isEmpty ||
            !accountNameCell.textField.text.isEmpty
    }

    func submit() {
        if (!isValid) { return }

        let issuer = issuerCell.textField.text ?? ""
        let accountName = accountNameCell.textField.text ?? ""

        if (token.name != accountName ||
            token.issuer != issuer) {
                self.token.name = accountName
                self.token.issuer = issuer
                self.token.saveToKeychain()
        }

        delegate?.form(self, didEditToken: token)
    }
}

extension TokenEditForm: OTPTextFieldCellDelegate {
    func textFieldCellDidChange(textFieldCell: OTPTextFieldCell) {
        presenter?.formValuesDidChange(self)
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
