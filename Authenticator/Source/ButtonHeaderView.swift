//
//  ButtonHeaderView.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

struct ButtonHeaderViewModel<Action> {
    let title: String
    let action: Action?

    init(title: String, action: Action? = nil) {
        self.title = title
        self.action = action
    }
}

private let preferredHeight: CGFloat = 54

class ButtonHeaderView<Action>: UIButton {
    fileprivate var buttonAction: Action?
    fileprivate var dispatchAction: ((Action) -> Void)?

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSubviews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    // MARK: - Subviews

    fileprivate func configureSubviews() {
        titleLabel?.textAlignment = .center
        titleLabel?.textColor = UIColor.otpForegroundColor
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: UIFontWeightLight)

        let action = #selector(ButtonHeaderView.buttonWasPressed)
        addTarget(self, action: action, for: .touchUpInside)
    }

    // MARK: - View Model

    convenience init(viewModel: ButtonHeaderViewModel<Action>, dispatchAction: @escaping (Action) -> Void) {
        self.init()
        self.dispatchAction = dispatchAction
        updateWithViewModel(viewModel)
    }

    func updateWithViewModel(_ viewModel: ButtonHeaderViewModel<Action>) {
        setTitle(viewModel.title, for: UIControlState())
        buttonAction = viewModel.action
    }

    static func heightWithViewModel(_ viewModel: ButtonHeaderViewModel<Action>) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func buttonWasPressed() {
        if let action = buttonAction {
            dispatchAction?(action)
        }
    }
}
