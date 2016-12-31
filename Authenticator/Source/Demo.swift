//
//  Demo.swift
//  Authenticator
//
//  Copyright (c) 2016 Authenticator authors
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

extension Process {
    static var isDemo: Bool {
        return arguments.contains("--demo")
            || NSUserDefaults.standardUserDefaults().boolForKey("FASTLANE_SNAPSHOT")
    }
}

struct DemoTokenStore: TokenStore {
    let persistentTokens = demoTokens.map(PersistentToken.init(demoToken:))

    private static let demoTokens = [
        Token(
            name: "john.appleseed@gmail.com",
            issuer: "Google",
            factor: .Timer(period: 10)
        ),
        Token(
            name: "johnappleseed",
            issuer: "GitHub",
            factor: .Timer(period: 20)
        ),
        Token(
            issuer: "Dropbox",
            factor: .Timer(period: 30)
        ),
        Token(
            name: "john@appleseed.com",
            factor: .Counter(0)
        ),
        Token(
            name: "johnny.apple",
            issuer: "Facebook",
            factor: .Timer(period: 40)
        ),
    ]

    private struct Error: ErrorType {}

    func addToken(token: Token) throws {
        throw Error()
    }

    func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        throw Error()
    }

    func updatePersistentToken(persistentToken: PersistentToken) throws {
        throw Error()
    }

    func moveTokenFromIndex(origin: Int, toIndex destination: Int) {
        return
    }

    func deletePersistentToken(persistentToken: PersistentToken) throws {
        throw Error()
    }
}

private extension Token {
    init(name: String = "", issuer: String = "", factor: Generator.Factor) {
        let generator = Generator(factor: factor, secret: NSData(), algorithm: .SHA1, digits: 6)!
        self.init(name: name, issuer: issuer, generator: generator)
    }
}

private extension PersistentToken {
    init(demoToken: Token) {
        token = demoToken
        identifier = NSUUID().UUIDString.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

extension TokenEntryForm {
    static let demoForm: TokenEntryForm = {
        // Construct a pre-filled demo form.
        var form = TokenEntryForm()
        _ = form.update(.Issuer("Google"))
        _ = form.update(.Name("john.appleseed@gmail.com"))
        _ = form.update(.Secret("JBSWY3DPEHPK6PX9"))
        if UIScreen.mainScreen().bounds.height > 550 {
            // Expand the advanced options for iPhone 5 and later, but not for the earlier 3.5-inch screens.
            _ = form.update(.ShowAdvancedOptions)
        }
        return form
    }()
}

extension DisplayTime {
    /// A constant demo display time, selected along with the time-based token periods to fix the progress ring at an
    /// aesthetically-pleasing angle.
    static let demoTime = DisplayTime(date: NSDate(timeIntervalSince1970: 123_456_783.75))
}

extension UIImage {
    static func demoScannerImage() -> UIImage? {
        guard let imagePath = NSUserDefaults.standardUserDefaults().stringForKey("demo-scanner-image") else {
            return nil
        }
        return UIImage(contentsOfFile: imagePath)
    }
}
