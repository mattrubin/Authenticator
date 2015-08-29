//
//  TokenEditForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 8/29/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

class TokenEditForm: NSObject, TableViewModel {
    var issuerCell: OTPTextFieldCell
    var accountNameCell: OTPTextFieldCell

    var cells: [[UITableViewCell]] {
        return [
            [
                issuerCell,
                accountNameCell,
            ]
        ]
    }

    init(issuerCell: OTPTextFieldCell, accountNameCell: OTPTextFieldCell) {
        self.issuerCell = issuerCell
        self.accountNameCell = accountNameCell
    }

    func focusFirstField() {
        self.issuerCell.textField.becomeFirstResponder()
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
}
