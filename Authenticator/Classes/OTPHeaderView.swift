//
//  OTPHeaderView.swift
//  Authenticator
//
//  Created by Matt Rubin on 9/14/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import UIKit

@objc
protocol OTPHeaderViewDelegate: class {
    func headerViewButtonWasPressed(headerView: OTPHeaderView)
}

class OTPHeaderView: UIButton {
    static let preferredHeight: CGFloat = 54

    weak var delegate: OTPHeaderViewDelegate?

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

    // MARK: - Update

    func updateWithTitle(title: String) {
        setTitle("Advanced Options", forState: .Normal)
    }

    // MARK: - Target Action

    func buttonWasPressed() {
        delegate?.headerViewButtonWasPressed(self)
    }
}
