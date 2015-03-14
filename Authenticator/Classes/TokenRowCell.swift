//
//  TokenRowCell.swift
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
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

import UIKit

class TokenRowCell: OTPTokenCell {
    private var rowModel = TokenRowModel()

    func updateWithRowModel(rowModel: TokenRowModel) {
        // Check the current properties and only update the view if a change has occured
        if (rowModel.name != self.rowModel.name || rowModel.issuer != self.rowModel.issuer) {
            setName(rowModel.name, issuer: rowModel.issuer)
        }
        if (rowModel.password != self.rowModel.password) {
            setPassword(rowModel.password)
        }
        if (rowModel.showsButton != self.rowModel.showsButton) {
            setShowsButton(rowModel.showsButton)
        }

        self.rowModel = rowModel
    }

    func setName(name: String, issuer: String) {
        let titleString = NSMutableAttributedString()
        if (issuer != "") {
            titleString.appendAttributedString(NSAttributedString(string: issuer, attributes:[NSFontAttributeName: UIFont(name:  "HelveticaNeue-Medium", size: 15)!]))
        }
        if (issuer != "" && name != "") {
            titleString.appendAttributedString(NSAttributedString(string: " "))
        }
        if (name != "") {
            titleString.appendAttributedString(NSAttributedString(string: name))
        }
        self.titleLabel.attributedText = titleString
    }

    func setPassword(password: String) {
        self.passwordLabel.attributedText = NSAttributedString(string: password, attributes: [NSKernAttributeName: 2])
    }

    func setShowsButton(showsButton: Bool) {
        self.nextPasswordButton.hidden = !showsButton
    }


    func generateNextPassword() {
        self.rowModel.buttonAction()
    }

    // MARK: - Editing

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        UIView.animateWithDuration(0.3) {
            self.passwordLabel.alpha = !editing ? 1 : 0.2;
            self.nextPasswordButton.alpha = !editing ? 1 : 0;
        }
    }

}
