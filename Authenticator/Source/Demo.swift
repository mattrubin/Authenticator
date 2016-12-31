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

extension Process {
    static var isDemo: Bool {
        return arguments.contains("-DEMO") || arguments.contains("-FASTLANE_SNAPSHOT")
    }
}

struct DemoTokenStore: TokenStore {
    let persistentTokens: [PersistentToken] = [
        PersistentToken(
            demoToken: Token(
                name: "john.appleseed@gmail.com",
                issuer: "Google",
                generator: Generator(
                    factor: .Timer(period: 10),
                    secret: NSData(),
                    algorithm: .SHA1,
                    digits: 6
                )!
            )
        ),
        PersistentToken(
            demoToken: Token(
                name: "johnappleseed",
                issuer: "GitHub",
                generator: Generator(
                    factor: .Timer(period: 20),
                    secret: NSData(),
                    algorithm: .SHA1,
                    digits: 6
                )!
            )
        ),
        PersistentToken(
            demoToken: Token(
                issuer: "Dropbox",
                generator: Generator(
                    factor: .Timer(period: 30),
                    secret: NSData(),
                    algorithm: .SHA1,
                    digits: 6
                )!
            )
        ),
        PersistentToken(
            demoToken: Token(
                name: "john@appleseed.com",
                generator: Generator(
                    factor: .Counter(0),
                    secret: NSData(),
                    algorithm: .SHA1,
                    digits: 6
                )!
            )
        ),
        PersistentToken(
            demoToken: Token(
                name: "johnny.apple",
                issuer: "Facebook",
                generator: Generator(
                    factor: .Timer(period: 40),
                    secret: NSData(),
                    algorithm: .SHA1,
                    digits: 6
                )!
            )
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

private extension PersistentToken {
    init(demoToken: Token) {
        self.token = demoToken
        self.identifier = NSUUID().UUIDString.dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

extension TokenEntryForm {
    static let demoForm: TokenEntryForm = {
        // Construct a pre-filled demo form.
        var form = TokenEntryForm()
        _ = form.update(.Issuer("Google"))
        _ = form.update(.Name("john.appleseed@gmail.com"))
        _ = form.update(.Secret("JBSWY3DPEHPK6PX9"))
        _ = form.update(.ShowAdvancedOptions)
        return form
    }()
}

extension DisplayTime {
    /// A constant demo display time, selected along with the time-based token periods to fix the progress ring at an
    /// aesthetically-pleasing angle.
    static let demoTime = DisplayTime(date: NSDate(timeIntervalSince1970: 123_456_783.75))
}
