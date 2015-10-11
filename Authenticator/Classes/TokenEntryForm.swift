//
//  TokenEntryForm.swift
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

@objc
protocol TokenEntryFormDelegate: class {
    func entryFormDidCancel(form: TokenEntryForm)
    func form(form: TokenEntryForm, didCreateToken token: OTPToken)
}

class TokenEntryForm: NSObject, TokenForm {
    weak var presenter: TokenFormPresenter?
    private weak var delegate: TokenEntryFormDelegate?

    private let issuerCell = OTPTextFieldCell()
    private let accountNameCell = OTPTextFieldCell()
    private let secretKeyCell = OTPTextFieldCell()
    private let tokenTypeCell = OTPSegmentedControlCell<OTPTokenType>()
    private let digitCountCell = OTPSegmentedControlCell<Int>()
    private let algorithmCell = OTPSegmentedControlCell<OTPAlgorithm>()
    private var advancedSectionHeader: HeaderViewModel {
        return HeaderViewModel(title: "Advanced Options") { [weak self] in
            self?.toggleAdvancedOptions()
        }
    }

    var showsAdvancedOptions = false

    init(delegate: TokenEntryFormDelegate) {
        self.delegate = delegate
        super.init()

        issuerCell.updateWithRowModel(IssuerRowModel())
        accountNameCell.updateWithRowModel(NameRowModel(returnKeyType: .Next))
        secretKeyCell.updateWithRowModel(SecretRowModel())

        issuerCell.delegate = self
        accountNameCell.delegate = self
        secretKeyCell.delegate = self

        tokenTypeCell.updateWithRowModel(tokenTypeRowModel)
        digitCountCell.updateWithRowModel(digitCountRowModel)
        algorithmCell.updateWithRowModel(algorithmRowModel)
    }

    var viewModel: TableViewModel {
        return TableViewModel(
            title: "Add Token",
            leftBarButton: BarButtonViewModel(style: .Cancel) { [weak self] in
                self?.cancel()
            },
            rightBarButton: BarButtonViewModel(style: .Done, enabled: isValid) { [weak self] in
                self?.submit()
            },
            sections: [
                [ self.issuerCell, self.accountNameCell , self.secretKeyCell ],
                showsAdvancedOptions
                    ? Section(header: advancedSectionHeader, rows: [ self.tokenTypeCell, self.digitCountCell, self.algorithmCell ])
                    : Section(header: advancedSectionHeader),
            ]
        )
    }

    // Mark: Row Models

    var tokenTypeRowModel: TokenTypeRowModel {
        return TokenTypeRowModel(valueChangedAction: { [weak self] (newTokenType) -> () in
            self?.tokenTypeDidChange(tokenType)
        })
    }

    var digitCountRowModel: DigitCountRowModel {
        return DigitCountRowModel(valueChangedAction: { [weak self] (newDigitCount) -> () in
            self?.digitCountDidChange(newDigitCount)
        })
    }

    var algorithmRowModel: AlgorithmRowModel {
        return AlgorithmRowModel(valueChangedAction: { [weak self] (newAlgorithm) -> () in
            self?.algorithmDidChange(newAlgorithm)
        })
    }

    // Mark: Values

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

    func cancel() {
        delegate?.entryFormDidCancel(self)
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

extension TokenEntryForm {
    func tokenTypeDidChange(newTokenType: OTPTokenType) {
        presenter?.formValuesDidChange(self)
    }

    func digitCountDidChange(newDigitCount: Int) {
        presenter?.formValuesDidChange(self)
    }

    func algorithmDidChange(newAlgorithm: OTPAlgorithm) {
        presenter?.formValuesDidChange(self)
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

extension TokenEntryForm {
    func toggleAdvancedOptions() {
        if (!showsAdvancedOptions) {
            showsAdvancedOptions = true
            // TODO: Don't hard-code this index
            presenter?.form(self, didReloadSection: 1)
        }
    }
}
