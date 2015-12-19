//
//  ButtonHeaderView.swift
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
    private var buttonAction: Action?
    private var dispatchAction: ((Action) -> ())?

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

    private func configureSubviews() {
        titleLabel?.textAlignment = .Center
        titleLabel?.textColor = UIColor.otpForegroundColor
        titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)

        addTarget(self, action: Selector("buttonWasPressed"), forControlEvents: .TouchUpInside)
    }

    // MARK: - View Model

    convenience init(viewModel: ButtonHeaderViewModel<Action>, dispatchAction: (Action) -> ()) {
        self.init()
        self.dispatchAction = dispatchAction
        updateWithViewModel(viewModel)
    }

    func updateWithViewModel(viewModel: ButtonHeaderViewModel<Action>) {
        setTitle(viewModel.title, forState: .Normal)
        buttonAction = viewModel.action
    }

    static func heightWithViewModel(viewModel: ButtonHeaderViewModel<Action>) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func buttonWasPressed() {
        if let action = buttonAction {
            dispatchAction?(action)
        }
    }
}
