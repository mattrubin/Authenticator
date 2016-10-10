//
//  TokenRowCell.swift
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

class TokenRowCell: UITableViewCell {
    var dispatchAction: ((TokenRowModel.Action) -> ())?
    private var rowModel: TokenRowModel?

    private let titleLabel = UILabel()
    private let passwordLabel = UILabel()
    private let nextPasswordButton = UIButton(type: .ContactAdd)

    // MARK: - Setup

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureCell()
    }

    private func configureCell() {
        backgroundColor = .otpBackgroundColor
        selectionStyle = .None

        configureSubviews()
        updateAppearanceWithRowModel(rowModel)
    }

    // MARK: - Subviews

    private func configureSubviews() {
        titleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 15)
        titleLabel.textColor = .otpForegroundColor
        titleLabel.textAlignment = .Center
        contentView.addSubview(titleLabel)

        passwordLabel.font = UIFont(name: "HelveticaNeue-UltraLight", size: 50)
        passwordLabel.textColor = .otpForegroundColor
        passwordLabel.textAlignment = .Center
        contentView.addSubview(passwordLabel)

        nextPasswordButton.tintColor = .otpForegroundColor
        let action = #selector(TokenRowCell.generateNextPassword)
        nextPasswordButton.addTarget(self, action: action, forControlEvents: .TouchUpInside)
        contentView.addSubview(nextPasswordButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the contents centered in the full cell even when the contentView shifts in edit mode
        let fullFrame = convertRect(bounds, toView: contentView)

        titleLabel.frame = fullFrame
        titleLabel.frame.size.height = 20

        passwordLabel.frame = fullFrame
        passwordLabel.frame.origin.y += 20
        passwordLabel.frame.size.height -= 30

        nextPasswordButton.center = CGPoint(x: fullFrame.maxX - 25, y: passwordLabel.frame.midY)
    }

    // MARK: - Update

    func updateWithRowModel(rowModel: TokenRowModel) {
        updateAppearanceWithRowModel(rowModel)
        self.rowModel = rowModel
    }

    private func updateAppearanceWithRowModel(rowModel: TokenRowModel?) {
        let name = rowModel?.name ?? ""
        let issuer = rowModel?.issuer ?? ""
        let password = rowModel?.password ?? ""
        let showsButton = rowModel?.showsButton ?? false

        setName(name, issuer: issuer)
        setPassword(password)
        nextPasswordButton.hidden = !showsButton
    }

    private func setName(name: String, issuer: String) {
        let titleString = NSMutableAttributedString()
        if !issuer.isEmpty {
            // swiftlint:disable:next force_unwrapping
            titleString.appendAttributedString(NSAttributedString(string: issuer, attributes:[NSFontAttributeName: UIFont(name: "HelveticaNeue-Medium", size: 15)!]))
        }
        if !issuer.isEmpty && !name.isEmpty {
            titleString.appendAttributedString(NSAttributedString(string: " "))
        }
        if !name.isEmpty {
            titleString.appendAttributedString(NSAttributedString(string: name))
        }
        titleLabel.attributedText = titleString
    }

    private func setPassword(password: String) {
        passwordLabel.attributedText = NSAttributedString(string: password, attributes: [NSKernAttributeName: 2])
    }

    // MARK: - Editing

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.showsReorderControl = editing && rowModel?.canReorder ?? true
        UIView.animateWithDuration(0.3) {
            self.passwordLabel.alpha = !editing ? 1 : 0.2
            self.nextPasswordButton.alpha = !editing ? 1 : 0
        }
    }

    // MARK: - Actions

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected, let rowModel = rowModel {
            if self.editing {
                dispatchAction?(rowModel.editAction)
            } else {
                dispatchAction?(rowModel.selectAction)
            }
        }
    }

    func generateNextPassword() {
        if let action = rowModel?.buttonAction {
            dispatchAction?(action)
        }
    }
}
