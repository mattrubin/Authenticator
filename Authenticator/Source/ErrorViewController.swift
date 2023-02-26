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

        let label = UITextView()
        label.font = .preferredFont(forTextStyle: .body)
        label.isEditable = false
        label.backgroundColor = .otpBackgroundColor
        label.textColor = .otpForegroundColor
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        view.addConstraints([
            label.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
        ])

        let errorReportString = errorReport.toString()
        label.text = errorReportString

        sendEmail(body: errorReportString)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sendEmail(body: String) {
        let emailViewController = MFMailComposeViewController()
        emailViewController.mailComposeDelegate = self

        let appVersionString = errorReport.application.version.map({ " v" + $0 })
        let appBuildString = errorReport.application.build.map({ " (Build " + $0 + ")" })
        emailViewController.setSubject("Authenticator\(appVersionString ?? "")\(appBuildString ?? "") Error Report")
        emailViewController.setMessageBody(body, isHTML: false)
        emailViewController.setToRecipients(["authenticator@mattrubin.me"])

        present(emailViewController, animated: true)
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
