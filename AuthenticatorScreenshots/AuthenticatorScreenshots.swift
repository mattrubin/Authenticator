//
//  AuthenticatorScreenshots.swift
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

import XCTest
import SimulatorStatusMagiciOS

class AuthenticatorScreenshots: XCTestCase {
    override class func setUp() {
        super.setUp()
        SDStatusBarManager.sharedInstance().batteryDetailEnabled = false
        SDStatusBarManager.sharedInstance().enableOverrides()
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        if let demoScannerImagePath = UserDefaults.standard.string(forKey: "demo-scanner-image") {
            app.launchArguments += ["-demo-scanner-image", demoScannerImagePath]
        }
        app.launch()
    }

    override class func tearDown() {
        SDStatusBarManager.sharedInstance().disableOverrides()
        super.tearDown()
    }

    func testScreenshots() {
        let app = XCUIApplication()

        // Wait for the scroll bars to fade.
        sleep(1)
        // Take a screenshot of the token list.
        snapshot("0-TokenList")

        // Tap the "+" button.
        app.toolbars.buttons["Add"].tap()
        // Wait for the HUD to fade.
        sleep(1)
        // Take a screenshot of the token scanner.
        snapshot("1-ScanToken")

        app.navigationBars.buttons["Manual token entry"].tap()
        // Wait for the scroll bars to fade.
        sleep(1)
        // Take a screenshot of the token entry form.
        snapshot("2-AddToken")
    }
}
