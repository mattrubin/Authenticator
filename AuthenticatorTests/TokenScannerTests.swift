//
//  TokenScannerTests.swift
//  Authenticator
//
//  Copyright (c) 2017 Authenticator authors
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
@testable import Authenticator
import OneTimePassword

class TokenScannerTests: XCTestCase {
    func testCancel() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let action = TokenScanner.Action.Cancel
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .Cancel = requiredEffect else {
                XCTFail("Expected effect .Cancel, got \(effect)")
                return
        }

        XCTAssertTrue(tokenScanner.viewModel.isScanning)
    }

    func testCompose() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let action = TokenScanner.Action.BeginManualTokenEntry
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .BeginManualTokenEntry = requiredEffect else {
                XCTFail("Expected effect .BeginManualTokenEntry, got \(effect)")
                return
        }

        XCTAssertTrue(tokenScanner.viewModel.isScanning)
    }

    func testScannerDecodedBadText() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let action = TokenScanner.Action.ScannerDecodedText("something...")
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .ShowErrorMessage(let message) = requiredEffect else {
                XCTFail("Expected effect .ShowErrorMessage, got \(effect)")
                return
        }
        XCTAssertEqual(message, "Invalid Token")

        XCTAssertTrue(tokenScanner.viewModel.isScanning)
    }

    func testScannerDecodedBadURL() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let urlString = "http://example.com"
        let action = TokenScanner.Action.ScannerDecodedText(urlString)
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .ShowErrorMessage(let message) = requiredEffect else {
                XCTFail("Expected effect .ShowErrorMessage, got \(effect)")
                return
        }
        XCTAssertEqual(message, "Invalid Token")

        XCTAssertTrue(tokenScanner.viewModel.isScanning)
    }

    func testScannerDecodedGoodURL() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let urlString = "otpauth://totp/Authenticator?secret=ABCDEFGHIJKLMNOP"
        let action = TokenScanner.Action.ScannerDecodedText(urlString)
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .SaveNewToken(let token) = requiredEffect else {
                XCTFail("Expected effect .SaveNewToken, got \(effect)")
                return
        }
        // swiftlint:disable:next force_unwrapping
        let expectedToken = Token(url: URL(string: urlString)!)
        XCTAssertEqual(token, expectedToken)

        // The scanner should stop after the first successful token capture.
        XCTAssertFalse(tokenScanner.viewModel.isScanning)
    }

    struct ScannerError: ErrorProtocol {}

    func testScannerError() {
        var tokenScanner = TokenScanner()
        XCTAssertTrue(tokenScanner.viewModel.isScanning)

        let action = TokenScanner.Action.ScannerError(ScannerError())
        let effect = tokenScanner.update(action)
        guard let requiredEffect = effect,
            case .ShowErrorMessage(let message) = requiredEffect else {
                XCTFail("Expected effect .ShowErrorMessage, got \(effect)")
                return
        }
        XCTAssertEqual(message, "Capture Failed")

        XCTAssertTrue(tokenScanner.viewModel.isScanning)
    }
}
