//
//  RemoteLogger.swift
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

class RemoteLogger {
    func log(_ entry: LogEntry) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)

        func printable(_ data: Data) -> String {
            return String(data: data, encoding: .utf8) ?? String(describing: data)
        }
        print("Logging:\n\(printable(data))")

        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "https://httpbin.org/anything")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data

        let session = URLSession.shared
        let (responseData, response) = try await session.data(for: request)
        print("Response:\n\(response)\nData:\n\(printable(responseData))")
    }

    struct LogEntry: Encodable {
        let message: String?
        let application: ApplicationInfo
        let error: ErrorInfo
        let nsError: NSErrorInfo

        init(error: Error, message: String?) {
            self.message = message
            self.application = ApplicationInfo()
            self.error = ErrorInfo(error: error)
            self.nsError = NSErrorInfo(error: error as NSError)
        }
    }

    struct ApplicationInfo: Encodable {
        let applicationState: Int
        let isProtectedDataAvailable: Bool

        init() {
            let application = UIApplication.shared

            applicationState = application.applicationState.rawValue
            isProtectedDataAvailable = application.isProtectedDataAvailable
        }
    }

    struct ErrorInfo: Encodable {
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

    struct NSErrorInfo: Encodable {
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
