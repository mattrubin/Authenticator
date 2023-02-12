//
//  Demo.swift
//  Authenticator
//
//  Copyright (c) 2016-2023 Authenticator authors
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

import OneTimePassword
import Foundation
import UIKit

extension CommandLine {
    static var isDemo: Bool {
#if DEBUG
        return arguments.contains("--demo")
            || UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
#else
        return false
#endif
    }
}

struct DemoTokenStore: TokenStore {
#if DEBUG
    let persistentTokens = demoTokens.map(PersistentToken.init(demoToken:))
#else
    let persistentTokens: [PersistentToken] = []
#endif

    private static let demoTokens = [
        Token(
            name: "john.appleseed@gmail.com",
            issuer: "Google",
            factor: .timer(period: 10)
        ),
        Token(
            name: "johnappleseed",
            issuer: "GitHub",
            factor: .timer(period: 20)
        ),
        Token(
            issuer: "Dropbox",
            factor: .timer(period: 30)
        ),
        Token(
            name: "john@appleseed.com",
            factor: .counter(0)
        ),
        Token(
            name: "johnny.apple",
            issuer: "Facebook",
            factor: .timer(period: 40)
        ),
    ]

    private struct Error: Swift.Error {}

    func addToken(_ token: Token) throws {
        throw Error()
    }

    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        throw Error()
    }

    func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        throw Error()
    }

    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) throws {
        throw Error()
    }

    func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        throw Error()
    }
}

private extension Token {
    init(name: String = "", issuer: String = "", factor: Generator.Factor) {
        // swiftlint:disable:next force_try
        let generator = try! Generator(factor: factor, secret: Data(), algorithm: .sha1, digits: 6)
        self.init(name: name, issuer: issuer, generator: generator)
    }
}

#if DEBUG
@testable import OneTimePassword

private extension PersistentToken {
    init(demoToken: Token) {
        // swiftlint:disable:next force_unwrapping
        let identifier = UUID().uuidString.data(using: String.Encoding.utf8)!

        self.init(token: demoToken, identifier: identifier)
    }
}

#endif

extension TokenEntryForm {
    static let demoForm: TokenEntryForm = {
        // Construct a pre-filled demo form.
        var form = TokenEntryForm()
        _ = form.update(with: .issuer("Google"))
        _ = form.update(with: .name("john.appleseed@gmail.com"))
        _ = form.update(with: .secret("JBSWY3DPEHPK6PX9"))
        if UIScreen.main.bounds.height > 550 {
            // Expand the advanced options for iPhone 5 and later, but not for the earlier 3.5-inch screens.
            _ = form.update(with: .showAdvancedOptions)
        }
        return form
    }()
}

extension DisplayTime {
    /// A constant demo display time, selected along with the time-based token periods to fix the progress ring at an
    /// aesthetically-pleasing angle.
    static let demoTime = DisplayTime(date: Date(timeIntervalSince1970: 123_456_783.75))
}

extension UIImage {
    static func demoScannerImage() -> UIImage? {
        guard let imagePath = UserDefaults.standard.string(forKey: "demo-scanner-image") else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
}
