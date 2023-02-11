//
//  TableDiffTests.swift
//  Authenticator
//
//  Copyright (c) 2016-2018 Authenticator authors
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

import XCTest
@testable import OneTimePassword
@testable import Authenticator

class TableDiffTests: XCTestCase {
    private let defaultDigitGroupSize = 2

    func testNoChanges() throws {
        // swiftlint:disable force_unwrapping
        let generator = try Generator(factor: .timer(period: 60),
                                      secret: "secret".data(using: String.Encoding.utf8)!,
                                      algorithm: .sha256,
                                      digits: 6)
        // swiftlint:enable force_unwrapping
        let token = Token(name: "Token Name",
                          issuer: "Token Issuer",
                          generator: generator)
        let persistentToken = PersistentToken(token: token, identifier: PersistentToken.makeUniqueIdentifier())
        let date = Date()

        let before = [
            TokenRowModel(
                persistentToken: persistentToken,
                displayTime: DisplayTime(date: date),
                digitGroupSize: defaultDigitGroupSize
            ),
        ]
        let after = [
            TokenRowModel(
                persistentToken: persistentToken,
                displayTime: DisplayTime(date: date),
                digitGroupSize: defaultDigitGroupSize
            ),
        ]

        let changes = changesFrom(before, to: after)
        XCTAssert(changes.isEmpty, "Expected no changes, got \(changes)")
    }
}
