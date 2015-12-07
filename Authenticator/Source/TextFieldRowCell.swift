//
//  TextFieldRowCell.swift
//  Authenticator
//
//  Copyright (c) 2014-2015 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

protocol TextFieldRowCellDelegate: class {
    func textFieldCellDidReturn(textFieldCell: TextFieldRowCell)
    func handleAction(action: Form.Action)
}

class TextFieldRowCell: UITableViewCell {
    private static let preferredHeight: CGFloat = 74

    let textField = UITextField()
    weak var delegate: TextFieldRowCellDelegate?
    var changeAction: ((String) -> Form.Action)?


    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    // MARK: - Subviews

    private func configureSubviews() {
        textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 17)

        textField.delegate = self
        textField.addTarget(self, action: Selector("textFieldValueChanged"), forControlEvents: UIControlEvents.EditingChanged)
        textField.borderStyle = .RoundedRect
        textField.font = UIFont(name: "HelveticaNeue-Light", size: 16)
        contentView.addSubview(textField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textLabel?.frame = CGRectMake(20, 15, CGRectGetWidth(contentView.bounds) - 40, 21)
        textField.frame = CGRectMake(20, 44, CGRectGetWidth(contentView.bounds) - 40, 30)
    }

    // MARK: - View Model

    func updateWithViewModel(viewModel: TextFieldRowModel) {
        textLabel?.text = viewModel.label
        textField.placeholder = viewModel.placeholder

        textField.autocapitalizationType = viewModel.autocapitalizationType
        textField.autocorrectionType = viewModel.autocorrectionType
        textField.keyboardType = viewModel.keyboardType
        textField.returnKeyType = viewModel.returnKeyType

        // UITextField can behave erratically if its text is updated while it is being edited,
        // especially with Chinese text entry. Only update if truly necessary.
        if textField.text != viewModel.value {
            textField.text = viewModel.value
        }
        changeAction = viewModel.changeAction
    }

    static func heightWithViewModel(viewModel: TextFieldRowModel) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func textFieldValueChanged() {
        let newText = textField.text ?? ""
        if let changeAction = changeAction {
            delegate?.handleAction(changeAction(newText))
        }
    }
}

extension TextFieldRowCell: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        delegate?.textFieldCellDidReturn(self)
        return false
    }
}

extension TextFieldRowCell: FocusCell {
    func focus() -> Bool {
        return textField.becomeFirstResponder()
    }

    func unfocus() -> Bool {
        return textField.resignFirstResponder()
    }
}
