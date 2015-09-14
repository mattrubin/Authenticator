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
    weak var delegate: TokenEntryFormDelegate?

    private lazy var issuerCell: OTPTextFieldCell = {
        OTPTextFieldCell.issuerCellWithDelegate(self)
    }()
    private lazy var accountNameCell: OTPTextFieldCell = {
        OTPTextFieldCell.nameCellWithDelegate(self, returnKeyType: .Next)
    }()
    private lazy var secretKeyCell: OTPTextFieldCell = {
        OTPTextFieldCell.secretCellWithDelegate(self)
    }()
    private lazy var tokenTypeCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.tokenTypeCell()
    }()
    private lazy var digitCountCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.digitCountCell()
    }()
    private lazy var algorithmCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.algorithmCell()
    }()
    private lazy var advancedSectionHeaderView: OTPHeaderView = {
        let headerView = OTPHeaderView()
        headerView.updateWithTitle("Advanced Options")
        headerView.delegate = self
        return headerView
    }()

    var showsAdvancedOptions = false

    private var cells: [[UITableViewCell]] {
        return [
            [ self.issuerCell, self.accountNameCell , self.secretKeyCell ],
            showsAdvancedOptions ? [ self.tokenTypeCell, self.digitCountCell, self.algorithmCell ] : [],
        ]
    }

    var issuer: String {
        return issuerCell.textField.text ?? ""
    }
    var accountName: String {
        return accountNameCell.textField.text ?? ""
    }
    var secretKey: String? {
        return secretKeyCell.textField.text
    }
    var tokenType: OTPTokenType {
        return (tokenTypeCell.value == OTPTokenTypeOption.Timer.rawValue) ? .Timer : .Counter
    }
    var digitCount: UInt {
        switch digitCountCell.value {
        case OTPTokenDigitsOption.Six.rawValue:
            return 6
        case OTPTokenDigitsOption.Seven.rawValue:
            return 7
        case OTPTokenDigitsOption.Eight.rawValue:
            return 8
        default:
            return 6 // FIXME: this should never need a default
        }
    }
    var algorithm: OTPAlgorithm {
        switch algorithmCell.value {
        case OTPTokenAlgorithmOption.SHA1.rawValue:
            return .SHA1
        case OTPTokenAlgorithmOption.SHA256.rawValue:
            return .SHA256
        case OTPTokenAlgorithmOption.SHA512.rawValue:
            return .SHA512
        default:
            return .SHA1 // FIXME: this should never need a default
        }
    }

    let title = "Add Token"

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

    func viewForHeaderInSection(section: Int) -> UIView? {
        // TODO: Don't hard-code this index
        if (section == 1) {
            return advancedSectionHeaderView
        }
        return nil
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
        return !self.secretKeyCell.textField.text.isEmpty &&
            !(self.issuerCell.textField.text.isEmpty && self.accountNameCell.textField.text.isEmpty)
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
