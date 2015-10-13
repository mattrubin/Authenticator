//
//  OTPHeaderView.swift
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

class OTPHeaderView: UIButton, ViewModelBasedView {
    private static let preferredHeight: CGFloat = 54

    private var buttonAction: (() -> ())?

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

    required convenience init(viewModel: HeaderViewModel) {
        self.init()
        updateWithViewModel(viewModel)
    }

    func updateWithViewModel(viewModel: HeaderViewModel) {
        setTitle(viewModel.title, forState: .Normal)
        buttonAction = viewModel.action
    }

    static func heightWithViewModel(viewModel: HeaderViewModel) -> CGFloat {
        return preferredHeight
    }

    // MARK: - Target Action

    func buttonWasPressed() {
        buttonAction?()
    }
}
