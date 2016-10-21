//
//  SearchField.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

// A custom view that contains a SearchTextField displaying its placeholder centered in the
// text field.
//
// Displays a OTPProgressRing as the `leftView` control.
class SearchField: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextField()
    }

    var delegate: UITextFieldDelegate? {
        get { return textField.delegate }
        set { textField.delegate = newValue }
    }

    var text: String? {
        get { return textField.text }
    }

    let ring = OTPProgressRing(
        frame: CGRect(origin: .zero, size: CGSize(width: 22, height: 22))
    )

    let textField: UITextField = SearchTextField()

    private func setupTextField() {
        ring.tintColor = UIColor.otpLightColor
        let placeHolderAttributes = [
            NSForegroundColorAttributeName: UIColor.otpLightColor,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 16)!
        ]
        textField.attributedPlaceholder = NSAttributedString(
            string: "Authenticator",
            attributes: placeHolderAttributes
        )
        textField.textColor = UIColor.otpLightColor
        textField.backgroundColor = UIColor.otpLightColor.colorWithAlphaComponent(0.2)
        textField.leftView = ring
        textField.leftViewMode = .Always
        textField.borderStyle = .RoundedRect
        textField.clearButtonMode = .Always
        textField.autocorrectionType = .No
        textField.autocapitalizationType = .None
        textField.returnKeyType = .Done
        textField.sizeToFit()
        addSubview(textField)
    }

    override func intrinsicContentSize() -> CGSize {
        return ring.frame.union(textField.frame).size
    }

    override func sizeThatFits(size: CGSize) -> CGSize {
        let fieldSize = textField.frame.size
        let fits = CGSize(width: max(size.width, fieldSize.width), height: fieldSize.height)
        return fits
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // center the text field
        var textFieldFrame = textField.frame
        textFieldFrame.size.width = bounds.size.width
        textField.frame = textFieldFrame
        textField.center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
    }

}

// MARK: TokenListPresenter
extension SearchField {
    func updateWithViewModel(viewModel: TokenList.ViewModel) {
        if let ringProgress = viewModel.ringProgress {
            ring.progress = ringProgress
        }
        // Show the countdown ring only if a time-based token is active
        textField.leftViewMode = viewModel.ringProgress != nil ? .Always : .Never

        // Only display text field as editable if there are tokens to filter
        textField.enabled = viewModel.hasTokens
        textField.borderStyle = viewModel.hasTokens ? .RoundedRect : .None
        textField.backgroundColor = viewModel.hasTokens ?
            UIColor.otpLightColor.colorWithAlphaComponent(0.1) : UIColor.clearColor()
    }
}

// MARK: UITextField rect overrides
class SearchTextField: UITextField {
    override func leftViewRectForBounds(bounds: CGRect) -> CGRect {
        return super.leftViewRectForBounds(bounds).offsetBy(dx: 6, dy: 0)
    }

    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        if self.isFirstResponder() {
            return .zero
        }
        var rect = super.placeholderRectForBounds(bounds)
        if let size = attributedPlaceholder?.size() {
            rect.size.width = size.width
            rect.origin.x = (bounds.size.width - rect.size.width) * 0.5
        }
        return rect
    }
}
