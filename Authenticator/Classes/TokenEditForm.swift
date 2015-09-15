//
//  TokenEditForm.swift
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
        if section < sections.startIndex { return nil }
        if section >= sections.endIndex { return nil }
        return sections[section].header
    }

    private var issuer: String {
        return issuerCell.textField.text ?? ""
    }

    private var accountName: String {
        return accountNameCell.textField.text ?? ""
    }

    var isValid: Bool {
        return !(issuer.isEmpty && accountName.isEmpty)
    }

    func submit() {
        if (!isValid) { return }

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
