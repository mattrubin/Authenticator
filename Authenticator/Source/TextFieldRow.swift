//
//  TextFieldRow.swift
//  Authenticator
//
//  Copyright (c) 2014-2016 Authenticator authors
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

struct TextFieldRowViewModel<Action> {
    let label: String
    let placeholder: String

    let autocapitalizationType: UITextAutocapitalizationType
    let autocorrectionType: UITextAutocorrectionType
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType

    let value: String
    let changeAction: (String) -> Action
}

protocol TextFieldRowCellDelegate: class {
    func textFieldCellDidReturn<Action>(textFieldCell: TextFieldRowCell<Action>)
}

private let preferredHeight: CGFloat = 74

class TextFieldRowCell<Action>: UITableViewCell, UITextFieldDelegate {

    let textField = UITextField()
    weak var delegate: TextFieldRowCellDelegate?
    var dispatchAction: ((Action) -> Void)?
    private var changeAction: ((String) -> Action)?

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
        textLabel?.font = UIFont.systemFontOfSize(17, weight: UIFontWeightLight)

        textField.delegate = self
        let action = #selector(TextFieldRowCell.textFieldValueChanged)
        textField.addTarget(self, action: action, forControlEvents: .EditingChanged)
        textField.borderStyle = .RoundedRect
        textField.font = UIFont.systemFontOfSize(16, weight: UIFontWeightLight)
        contentView.addSubview(textField)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let margin: CGFloat = 20
        let width = contentView.bounds.width - (2 * margin)
        textLabel?.frame = CGRect(x: margin, y: 15, width: width, height: 21)
        textField.frame = CGRect(x: margin, y: 44, width: width, height: 30)
    }

    // MARK: - View Model

    func updateWithViewModel(viewModel: TextFieldRowViewModel<Action>) {
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

    static func heightWithViewModel(viewModel: TextFieldRowViewModel<Action>) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func textFieldValueChanged() {
        let newText = textField.text ?? ""
        if let action = changeAction?(newText) {
            dispatchAction?(action)
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === self.textField {
            delegate?.textFieldCellDidReturn(self)
        }
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
