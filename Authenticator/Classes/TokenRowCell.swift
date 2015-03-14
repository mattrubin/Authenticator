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
    func updateWithRowModel(rowModel: TokenRowModel) {
        if let currentRowModel = self.rowModel {
            // Check the current properties and only update the view if a change has occured
            if (rowModel.name != currentRowModel.name || rowModel.issuer != currentRowModel.issuer) {
                setName(rowModel.name, issuer: rowModel.issuer)
            }
            if (rowModel.password != currentRowModel.password) {
                setPassword(rowModel.password)
            }
            if (rowModel.showsButton != currentRowModel.showsButton) {
                setShowsButton(rowModel.showsButton)
            }
        } else {
            // If the cell has not yet been configured, set all properties
            setName(rowModel.name, issuer: rowModel.issuer)
            setPassword(rowModel.password)
            setShowsButton(rowModel.showsButton)
        }

        self.rowModel = rowModel
    }
}
