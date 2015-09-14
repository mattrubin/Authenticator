//
//  TokenEntryForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/13/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

class TokenEntryForm: NSObject, TokenForm {
    weak var delegate: TokenFormDelegate?

    var issuerCell: OTPTextFieldCell
    var accountNameCell: OTPTextFieldCell
    var secretKeyCell: OTPTextFieldCell
    var tokenTypeCell: OTPSegmentedControlCell = {
        OTPSegmentedControlCell.tokenTypeCell()
    }()
    var digitCountCell: OTPSegmentedControlCell = {
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

    init(issuerCell: OTPTextFieldCell, accountNameCell: OTPTextFieldCell, secretKeyCell: OTPTextFieldCell) {
        self.issuerCell = issuerCell
        self.accountNameCell = accountNameCell
        self.secretKeyCell = secretKeyCell
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
