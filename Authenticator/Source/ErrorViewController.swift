//
//  ErrorViewController.swift
//  Authenticator
//
//  Copyright (c) 2023 Authenticator authors
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
import MessageUI

class ErrorViewController: UIViewController {
    private let errorReport: ErrorReport

    init(errorReport: ErrorReport) {
        self.errorReport = errorReport
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .otpBackgroundColor

        let title = UILabel()
        title.text = "An Error Occurred"
        title.textColor = .otpForegroundColor
        title.font = .preferredFont(forTextStyle: .title1)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)

        let emailButton = UIButton(type: .roundedRect)
        emailButton.addTarget(self, action: #selector(sendEmail), for: .touchUpInside)
        emailButton.setTitle("Send error report", for: .normal)
        emailButton.titleLabel?.font = .preferredFont(forTextStyle: .title2)
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emailButton)

        let label = UITextView()
        label.font = .preferredFont(forTextStyle: .body)
        label.isEditable = false
        label.layer.cornerRadius = 4
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        view.addConstraints([
            title.topAnchor.constraint(equalToSystemSpacingBelow: view.layoutMarginsGuide.topAnchor, multiplier: 1),
            title.leadingAnchor.constraint(equalToSystemSpacingAfter: view.layoutMarginsGuide.leadingAnchor, multiplier: 1),
            view.layoutMarginsGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: title.trailingAnchor, multiplier: 1),

            emailButton.topAnchor.constraint(
                equalTo: title.layoutMarginsGuide.bottomAnchor,
                constant: 16),
            emailButton.centerXAnchor.constraint(equalTo: view.layoutMarginsGuide.centerXAnchor),
            emailButton.leadingAnchor.constraint(
                greaterThanOrEqualToSystemSpacingAfter: view.layoutMarginsGuide.leadingAnchor,
                multiplier: 1),
            emailButton.trailingAnchor.constraint(
                lessThanOrEqualToSystemSpacingAfter: view.layoutMarginsGuide.trailingAnchor,
                multiplier: 1),

            label.topAnchor.constraint(equalTo: emailButton.bottomAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])

        let errorReportString = errorReport.toString()
        label.text = errorReportString
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func sendEmail() {
        let mailComposeViewController = errorReport.mailComposeViewController()
        mailComposeViewController.mailComposeDelegate = self
        present(mailComposeViewController, animated: true)
    }
}

extension ErrorViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        dismiss(animated: true)
    }
}
