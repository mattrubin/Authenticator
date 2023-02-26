//
//  ErrorReport.swift
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

import Foundation
import UIKit
import MessageUI

struct ErrorReport: Codable {
    let message: String?
    let application: ApplicationInfo
    let error: ErrorInfo
    let nsError: NSErrorInfo

    init(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
        error: Error,
        message: String?
    ) {
        self.message = message
        self.application = ApplicationInfo(application: application, launchOptions: launchOptions)
        self.error = ErrorInfo(error: error)
        self.nsError = NSErrorInfo(error: error as NSError)
    }

    func toString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        let jsonData = try? encoder.encode(self)
        let jsonString = jsonData.flatMap({ String(data: $0, encoding: .utf8) })

        return jsonString ?? String(describing: self)
    }

    static func fromString(_ jsonString: String) throws -> Self {
        let decoder = JSONDecoder()
        guard let jsonData = jsonString.data(using: .utf8) else {
            struct StringEncodingError: Error {
                let string: String
            }
            throw StringEncodingError(string: jsonString)
        }
        return try decoder.decode(Self.self, from: jsonData)
    }

    func mailComposeViewController() -> MFMailComposeViewController {
        let appVersionString = application.version.map({ " v" + $0 })
        let appBuildString = application.build.map({ " (Build " + $0 + ")" })
        let subject = "Authenticator\(appVersionString ?? "")\(appBuildString ?? "") Error Report"

        let mailComposeViewController = MFMailComposeViewController()
        mailComposeViewController.setSubject(subject)
        mailComposeViewController.setMessageBody(self.toString(), isHTML: false)
        mailComposeViewController.setToRecipients(["authenticator@mattrubin.me"])
        return mailComposeViewController
    }

    struct ApplicationInfo: Codable {
        let version: String?
        let build: String?

        let applicationState: Int
        let isProtectedDataAvailable: Bool
        let launchOptionsKeys: [String]?

        init(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
            version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

            applicationState = application.applicationState.rawValue
            isProtectedDataAvailable = application.isProtectedDataAvailable

            // Only log keys for now, because some options (like `UIApplicationLaunchOptionsURLKey`) may hold user data.
            self.launchOptionsKeys = launchOptions?.keys.map(\.rawValue)
        }
    }

    struct ErrorInfo: Codable {
        let stringDescribing: String

        let errorDescription: String?
        let failureReason: String?
        let recoverySuggestion: String?
        let helpAnchor: String?

        init(error: Error) {
            stringDescribing = String(describing: error)

            let localizedError = error as? LocalizedError
            errorDescription = localizedError?.errorDescription
            failureReason = localizedError?.failureReason
            recoverySuggestion = localizedError?.recoverySuggestion
            helpAnchor = localizedError?.helpAnchor
        }
    }

    struct NSErrorInfo: Codable {
        let stringDescribing: String

        let domain: String
        let code: Int
        let userInfo: [String: String]

        let localizedDescription: String
        let localizedFailureReason: String?
        let localizedRecoverySuggestion: String?
        let localizedRecoveryOptions: [String]?

        let helpAnchor: String?

        let underlyingErrors: [NSErrorInfo]?

        init(error: NSError) {
            stringDescribing = String(describing: error)

            domain = error.domain
            code = error.code
            userInfo = error.userInfo.mapValues(String.init(describing:))

            localizedDescription = error.localizedDescription
            localizedFailureReason = error.localizedFailureReason
            localizedRecoverySuggestion = error.localizedRecoverySuggestion
            localizedRecoveryOptions = error.localizedRecoveryOptions

            helpAnchor = error.helpAnchor

            if #available(iOS 14.5, *) {
                underlyingErrors = error.underlyingErrors.map({ Self(error: $0 as NSError) })
            } else {
                underlyingErrors = nil
            }
        }
    }
}
