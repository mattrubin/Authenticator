//
//  TokenRowCell.swift
//  Authenticator
//
//  Copyright (c) 2013-2017 Authenticator authors
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
    var dispatchAction: ((TokenRowModel.Action) -> Void)?
    private var rowModel: TokenRowModel?

    private let titleLabel = UILabel()
    private let passwordLabel = UILabel()
    private let nextPasswordButton = UIButton(type: .contactAdd)

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
        selectionStyle = .none

        configureSubviews()
        updateAppearance(with: rowModel)
    }

    // MARK: - Subviews

    private func configureSubviews() {
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .light)
        titleLabel.textColor = .otpForegroundColor
        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)

        passwordLabel.font = UIFont.systemFont(ofSize: 50, weight: .thin)
        passwordLabel.textColor = .otpForegroundColor
        passwordLabel.textAlignment = .center
        contentView.addSubview(passwordLabel)

        nextPasswordButton.tintColor = .otpForegroundColor
        nextPasswordButton.addTarget(self, action: #selector(TokenRowCell.generateNextPassword), for: .touchUpInside)
        nextPasswordButton.accessibilityLabel = "Increment token"
        nextPasswordButton.accessibilityHint = "Double-tap to generate a new password."
        contentView.addSubview(nextPasswordButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Keep the contents centered in the full cell even when the contentView shifts in edit mode
        let fullFrame = convert(bounds, to: contentView)

        titleLabel.frame = fullFrame
        titleLabel.frame.size.height = 20

        passwordLabel.frame = fullFrame
        passwordLabel.frame.origin.y += 20
        passwordLabel.frame.size.height -= 30

        nextPasswordButton.center = CGPoint(x: fullFrame.maxX - 25, y: passwordLabel.frame.midY)
    }

    // MARK: - Update

    func update(with rowModel: TokenRowModel) {
        updateAppearance(with: rowModel)
        self.rowModel = rowModel
    }

    private func updateAppearance(with rowModel: TokenRowModel?) {
        let name = rowModel?.name ?? ""
        let issuer = rowModel?.issuer ?? ""
        let password = rowModel?.password ?? ""
        let showsButton = rowModel?.showsButton ?? false

        setName(name, issuer: issuer)
        setPassword(password)
        nextPasswordButton.isHidden = !showsButton
    }

    private func setName(_ name: String, issuer: String) {
        let titleString = NSMutableAttributedString()
        if !issuer.isEmpty {
            let issuerAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15, weight: .medium)]
            titleString.append(NSAttributedString(string: issuer, attributes: issuerAttributes))
        }
        if !issuer.isEmpty && !name.isEmpty {
            titleString.append(NSAttributedString(string: " "))
        }
        if !name.isEmpty {
            titleString.append(NSAttributedString(string: name))
        }
        titleLabel.attributedText = titleString
    }

    private func setPassword(_ password: String) {
        passwordLabel.attributedText = NSAttributedString(string: password, attributes: [.kern: 2])
    }

    // MARK: - Editing

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.showsReorderControl = editing && (rowModel?.canReorder ?? true)
        UIView.animate(withDuration: 0.3) {
            self.passwordLabel.alpha = !editing ? 1 : 0.2
            self.nextPasswordButton.alpha = !editing ? 1 : 0
        }
    }

    // MARK: - Actions

    @objc
    func generateNextPassword() {
        if let action = rowModel?.buttonAction {
            dispatchAction?(action)
        }
    }
}
