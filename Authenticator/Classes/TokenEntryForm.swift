//
//  TokenEntryForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/13/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

// TODO: Segmented control cell changes don't call formValuesDidChange on the delegate

class TokenEntryForm: NSObject, TokenForm {
    weak var delegate: TokenFormDelegate?

    lazy var issuerCell: OTPTextFieldCell = {
        OTPTextFieldCell.issuerCellWithDelegate(self)
    }()
    lazy var accountNameCell: OTPTextFieldCell = {
        OTPTextFieldCell.nameCellWithDelegate(self, returnKeyType: .Next)
    }()
    lazy var secretKeyCell: OTPTextFieldCell = {
        OTPTextFieldCell.secretCellWithDelegate(self)
    }()
    lazy var tokenTypeCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.tokenTypeCell()
    }()
    lazy var digitCountCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.digitCountCell()
    }()
    lazy var algorithmCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.algorithmCell()
    }()

    var showsAdvancedOptions = false

    var cells: [[UITableViewCell]] {
        return [
            [ self.issuerCell, self.accountNameCell , self.secretKeyCell ],
            showsAdvancedOptions ? [ self.tokenTypeCell, self.digitCountCell, self.algorithmCell ] : [],
        ]
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
}

extension TokenEntryForm: OTPTextFieldCellDelegate {
    func textFieldCellDidChange(textFieldCell: OTPTextFieldCell) {
        delegate?.formValuesDidChange(self)
    }

    func textFieldCellDidReturn(textFieldCell: OTPTextFieldCell) {
        if textFieldCell == issuerCell {
            accountNameCell.textField.becomeFirstResponder()
        } else if textFieldCell == accountNameCell {
            secretKeyCell.textField.becomeFirstResponder()
        } else if textFieldCell == secretKeyCell {
            secretKeyCell.textField.resignFirstResponder()
            delegate?.formDidSubmit(self)
        }
    }
}
