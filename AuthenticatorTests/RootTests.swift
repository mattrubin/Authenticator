//
//  RootTests.swift
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

class RootTests: XCTestCase {
    func testShowBackupInfo() {
        var root = mockRoot()

        // Ensure there is no modal visible.
        let firstViewModel = root.viewModel
        switch firstViewModel.modal {
        case .None:
            // This is the expected case
            break
        default:
            XCTFail("Expected .None, got \(firstViewModel.modal)")
        }

        // Show the backup info.
        let showAction: Root.Action = .TokenListAction(.ShowBackupInfo)
        let showEffect: Root.Effect?
        do {
            showEffect = try root.update(showAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(showEffect)

        // Ensure the backup info modal is visible.
        let secondViewModel = root.viewModel
        switch secondViewModel.modal {
        case .Info:
            // This is the expected case
            break
        default:
            XCTFail("Expected .Info, got \(secondViewModel.modal)")
        }

        // Hide the backup info.
        let hideAction: Root.Action = .BackupInfoEffect(.Done)
        let hideEffect: Root.Effect?
        do {
            hideEffect = try root.update(hideAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(hideEffect)

        // Ensure the backup info modal no longer visible.
        let thirdViewModel = root.viewModel
        switch thirdViewModel.modal {
        case .None:
            // This is the expected case
            break
        default:
            XCTFail("Expected .None, got \(thirdViewModel.modal)")
        }
    }

    func testOpenURL() {
        var root = mockRoot()

        guard let url = NSURL(string: "https://example.com") else {
            XCTFail("Failed to initialize URL.")
            return
        }

        let action: Root.Action = .BackupInfoEffect(.OpenURL(url))
        let effect: Root.Effect?
        do {
            effect = try root.update(action)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        switch effect {
        case .Some(.OpenURL(let effectURL)):
            XCTAssertEqual(effectURL, url)
        default:
            XCTFail("Expected .None, got \(effect)")
        }
    }
}

private func mockRoot() -> Root {
    return Root(
        persistentTokens: [],
        displayTime: DisplayTime(date: NSDate()),
        deviceCanScan: false
    )
}
