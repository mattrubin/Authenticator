//
//  RootTests.swift
//  Authenticator
//
//  Copyright (c) 2017-2023 Authenticator authors
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
    private struct FakeError: Error {}

    private let defaultDigitGroupSize = 2
    let displayTime = DisplayTime(date: Date())

    func testShowBackupInfo() {
        var root = Root(deviceCanScan: false)

        // Ensure there is no modal visible.
        let (firstViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        guard case .none = firstViewModel.modal else {
            XCTFail("Expected .none, got \(firstViewModel.modal)")
            return
        }

        // Show the backup info.
        let showAction: Root.Action = .tokenListAction(.showBackupInfo)
        let showEffect: Root.Effect?
        do {
            showEffect = try root.update(with: showAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(showEffect)

        // Ensure the backup info modal is visible.
        let (secondViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        switch secondViewModel.modal {
        case .menu(let menu):
            switch menu.child {
            case .info(let infoViewModel):
                XCTAssert(infoViewModel.title == "Backups")
            default:
                XCTFail("Expected Backups .info, got \(menu.child)")
            }
        default:
            XCTFail("Expected .menu, got \(secondViewModel.modal)")
        }

        // Hide the backup info.
        let hideAction: Root.Action = .menuAction(.infoEffect(.done))
        let hideEffect: Root.Effect?
        do {
            hideEffect = try root.update(with: hideAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(hideEffect)

        // Ensure the backup info modal no longer visible.
        let (thirdViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        guard case .none = thirdViewModel.modal else {
            XCTFail("Expected .none, got \(thirdViewModel.modal)")
            return
        }
    }

    func testShowLicenseInfo() {
        var root = Root(deviceCanScan: false)

        // Ensure there is no modal visible.
        let (firstViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        guard case .none = firstViewModel.modal else {
            XCTFail("Expected .none, got \(firstViewModel.modal)")
            return
        }

        // Show the info list.
        let showInfoAction: Root.Action = .tokenListAction(.showInfo)
        let showInfoEffect: Root.Effect?
        do {
            showInfoEffect = try root.update(with: showInfoAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(showInfoEffect)

        // Ensure the info list modal is visible.
        let (nextViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        guard case .menu(let menu) = nextViewModel.modal, case .none = menu.child else {
            XCTFail("Expected .info list, got \(nextViewModel.modal)")
            return
        }

        // Show the license info.
        let showAction: Root.Action = .menuAction(.infoListEffect(.showLicenseInfo))
        let showEffect: Root.Effect?
        do {
            showEffect = try root.update(with: showAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(showEffect)

        // Ensure the license info modal is visible.
        let (secondViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        switch secondViewModel.modal {
        case .menu(let menu):
            switch menu.child {
            case .info(let infoViewModel):
                XCTAssert(infoViewModel.title == "Acknowledgements")
            default:
                XCTFail("Expected Acknowledgements .info, got \(menu.child)")
            }
        default:
            XCTFail("Expected .menu, got \(secondViewModel.modal)")
        }

        // Hide the license info.
        let hideAction: Root.Action = .menuAction(.infoEffect(.done))
        let hideEffect: Root.Effect?
        do {
            hideEffect = try root.update(with: hideAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }
        XCTAssertNil(hideEffect)

        // Ensure the license info modal no longer visible.
        let (thirdViewModel, _) = root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize)
        guard case .none = thirdViewModel.modal else {
            XCTFail("Expected .none, got \(thirdViewModel.modal)")
            return
        }
    }

    func testOpenURL() {
        var root = Root(deviceCanScan: false)

        guard let url = URL(string: "https://example.com") else {
            XCTFail("Failed to initialize URL.")
            return
        }

        let action: Root.Action = .menuAction(.infoEffect(.openURL(url)))
        let effect: Root.Effect?
        do {
            XCTAssertNil(try root.update(with: .tokenListAction(.showBackupInfo)))
            effect = try root.update(with: action)
        } catch {
            XCTFail("Unexpected error: \(error)")
            return
        }

        guard case .some(.openURL(url)) = effect else {
            XCTFail("Expected .openURL(\(url)), got \(String(describing: effect))")
            return
        }
    }

    func testEventAddTokenFailed() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .addTokenFailed(FakeError())
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed

        guard case .some(.showErrorMessage("Failed to add token.")) = effect else {
            XCTFail("Expected .showErrorMessage(\"Failed to add token.\"), got \(String(describing: effect))")
            return
        }
    }

    // MARK: Events

    func testEventAddTokenFromURLSucceeded() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .addTokenFromURLSucceeded
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed
        XCTAssertNil(effect)
    }

    func testEventTokenFormSucceeded() {
        var root = Root(deviceCanScan: false)

        func modalViewModel(from root: Root) -> RootViewModel.ModalViewModel {
            return root.viewModel(with: [], at: displayTime, digitGroupSize: defaultDigitGroupSize).viewModel.modal
        }

        // Ensure the initial view model has no modal.
        guard case .none = modalViewModel(from: root) else {
            XCTFail("The initial view model should have no modal.")
            return
        }

        // Show the token entry form.
        do {
            let effect = try root.update(with: .tokenListAction(.beginAddToken))
            XCTAssertNil(effect)
        } catch {
            XCTFail("Caught unexpected error: \(error)")
        }

        // Ensure the view model now has a modal entry form.
        guard case .entryForm = modalViewModel(from: root) else {
            XCTFail("The view model should have a modal entry form.")
            return
        }

        // Signal token entry success.
        let effect = root.update(with: .tokenFormSucceeded)
        XCTAssertNil(effect)

        // Ensure the token entry form hides on success.
        guard case .none = modalViewModel(from: root) else {
            XCTFail("The final view model should have no modal.")
            return
        }
    }

    func testEventSaveTokenFailed() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .saveTokenFailed(FakeError())
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed

        guard case .some(.showErrorMessage("Failed to save token.")) = effect else {
            XCTFail("Expected .showErrorMessage(\"Failed to save token.\"), got \(String(describing: effect))")
            return
        }
    }

    func testEventUpdateTokenFailed() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .updateTokenFailed(FakeError())
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed

        guard case .some(.showErrorMessage("Failed to update token.")) = effect else {
            XCTFail("Expected .showErrorMessage(\"Failed to update token.\"), got \(String(describing: effect))")
            return
        }
    }

    func testEventMoveTokenFailed() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .moveTokenFailed(FakeError())
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed

        guard case .some(.showErrorMessage("Failed to move token.")) = effect else {
            XCTFail("Expected .showErrorMessage(\"Failed to move token.\"), got \(String(describing: effect))")
            return
        }
    }

    func testEventDeleteTokenFailed() {
        var root = Root(deviceCanScan: false)
        let event: Root.Event = .deleteTokenFailed(FakeError())
        let effect = root.update(with: event)
        // TODO: check that the component state hasn't changed

        guard case .some(.showErrorMessage("Failed to delete token.")) = effect else {
            XCTFail("Expected .showErrorMessage(\"Failed to delete token.\"), got \(String(describing: effect))")
            return
        }
    }
}
