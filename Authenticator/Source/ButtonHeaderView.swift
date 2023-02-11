//
//  ButtonHeaderView.swift
//  Authenticator
//
//  Copyright (c) 2015-2017 Authenticator authors
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
    private var buttonAction: Action?
    private var dispatchAction: ((Action) -> Void)?

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
        titleLabel?.textAlignment = .center
        setTitleColor(.otpForegroundColor, for: .normal)
        titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .light)

        addTarget(self, action: #selector(ButtonHeaderView.buttonWasPressed), for: .touchUpInside)
    }

    // MARK: - View Model

    convenience init(viewModel: ButtonHeaderViewModel<Action>, dispatchAction: @escaping (Action) -> Void) {
        self.init()
        self.dispatchAction = dispatchAction
        update(with: viewModel)
    }

    func update(with viewModel: ButtonHeaderViewModel<Action>) {
        setTitle(viewModel.title, for: .normal)
        buttonAction = viewModel.action
    }

    static func heightForHeader(with viewModel: ButtonHeaderViewModel<Action>) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    @objc
    func buttonWasPressed() {
        if let action = buttonAction {
            dispatchAction?(action)
        }
    }
}
