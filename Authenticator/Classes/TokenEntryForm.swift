//
//  TokenEntryForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/13/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePasswordLegacy

@objc
protocol TokenEntryFormDelegate: class {
    func form(form: TokenEntryForm, didCreateToken token: OTPToken)
}

// TODO: Segmented control cell changes don't call formValuesDidChange on the delegate

class TokenEntryForm: NSObject, TokenForm {
    weak var presenter: TokenFormPresenter?
    private weak var delegate: TokenEntryFormDelegate?

    private lazy var issuerCell: OTPTextFieldCell = {
        OTPTextFieldCell.issuerCellWithDelegate(self)
    }()
    private lazy var accountNameCell: OTPTextFieldCell = {
        OTPTextFieldCell.nameCellWithDelegate(self, returnKeyType: .Next)
    }()
    private lazy var secretKeyCell: OTPTextFieldCell = {
        OTPTextFieldCell.secretCellWithDelegate(self)
    }()
    private var tokenTypeCell = OTPSegmentedControlCell<OTPTokenType>(rowModel: TokenTypeRowModel())
    private var digitCountCell = OTPSegmentedControlCell<Int>(rowModel: DigitCountRowModel())
    private var algorithmCell = OTPSegmentedControlCell<OTPAlgorithm>(rowModel: AlgorithmRowModel())
    private lazy var advancedSectionHeaderView: OTPHeaderView = {
        let headerView = OTPHeaderView()
        headerView.updateWithTitle("Advanced Options")
        headerView.delegate = self
        return headerView
    }()

    var showsAdvancedOptions = false

    init(delegate: TokenEntryFormDelegate) {
        self.delegate = delegate
    }

    private var sections: [Section] {
        return [
            [ self.issuerCell, self.accountNameCell , self.secretKeyCell ],
            showsAdvancedOptions
                ? Section(header: advancedSectionHeaderView, rows: [ self.tokenTypeCell, self.digitCountCell, self.algorithmCell ])
                : Section(header: advancedSectionHeaderView),
        ]
    }

    var issuer: String {
        return issuerCell.textField.text ?? ""
    }
    var accountName: String {
        return accountNameCell.textField.text ?? ""
    }
    var secretKey: String {
        return secretKeyCell.textField.text ?? ""
    }
    var tokenType: OTPTokenType {
        return tokenTypeCell.value
    }
    var digitCount: UInt {
        return UInt(digitCountCell.value)
    }
    var algorithm: OTPAlgorithm {
        return algorithmCell.value
    }

    let title = "Add Token"

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

    func focusFirstField() {
        issuerCell.textField.becomeFirstResponder()
    }

    func unfocus() {
        issuerCell.textField.resignFirstResponder()
        accountNameCell.textField.resignFirstResponder()
        secretKeyCell.textField.resignFirstResponder()
    }

    var isValid: Bool {
        return !secretKey.isEmpty && !(issuer.isEmpty && accountName.isEmpty)
    }

    func submit() {
        if !isValid { return }

        if let secret = NSData(base32String: secretKey) {
            if secret.length > 0 {
                let token = OTPToken()
                token.type = tokenType;
                token.secret = secret;
                token.name = accountName;
                token.issuer = issuer;
                token.digits = digitCount;
                token.algorithm = algorithm;

                if token.password != nil {
                    delegate?.form(self, didCreateToken: token)
                    return
                }
            }
        }

        // If the method hasn't returned by this point, token creation failed
        presenter?.form(self, didFailWithErrorMessage: "Invalid Token")
    }
}

extension TokenEntryForm: OTPTextFieldCellDelegate {
    func textFieldCellDidChange(textFieldCell: OTPTextFieldCell) {
        presenter?.formValuesDidChange(self)
    }

    func textFieldCellDidReturn(textFieldCell: OTPTextFieldCell) {
        if textFieldCell == issuerCell {
            accountNameCell.textField.becomeFirstResponder()
        } else if textFieldCell == accountNameCell {
            secretKeyCell.textField.becomeFirstResponder()
        } else if textFieldCell == secretKeyCell {
            secretKeyCell.textField.resignFirstResponder()
            submit()
        }
    }
}

extension TokenEntryForm: OTPHeaderViewDelegate {
    func headerViewButtonWasPressed(headerView: OTPHeaderView) {
        if (!showsAdvancedOptions) {
            showsAdvancedOptions = true
            // TODO: Don't hard-code this index
            presenter?.form(self, didReloadSection: 1)
        }
    }
}
