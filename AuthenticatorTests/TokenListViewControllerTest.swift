//
//  TokenListViewControllerTest.swift
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
import OneTimePassword
@testable import Authenticator

class TokenListViewControllerTest: XCTestCase {
    let tokenList = TokenList()
    let displayTime = DisplayTime(date: Date())

    lazy var testWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        return window
    }()

    func emptyListViewModel() -> TokenList.ViewModel {
        return tokenList.viewModel(with: [], at: displayTime).viewModel
    }

    // Test that inserting a new token will produce the expected changes to the table view.
    func testTokenListInsertsNewToken() {
        // Set up a view controller with a mock table view.
        let initialViewModel = emptyListViewModel()
        let controller = TokenListViewController(viewModel: initialViewModel, dispatchAction: { _ in })
        let tableView = MockTableView()
        controller.tableView = tableView

        // Update the view controller.
        let persistentTokens = mockPersistentTokens([
            ("Service", "email@example.com"),
        ])
        let (updatedViewModel, _) = tokenList.viewModel(with: persistentTokens, at: displayTime)
        controller.update(with: updatedViewModel)

        // Check the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .beginUpdates,
            .insert(indexPath: IndexPath(row: 0, section: 0)),
            .endUpdates,
            .scroll(indexPath: IndexPath(row: 0, section: 0)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)
    }

    // Test that updating an existing token will produce the expected changes to the table view.
    func testUpdatesExistingToken() {
        // Set up a view controller with a mock table view.
        let initialPersistentToken = mockPersistentToken(name: "account@example.com", issuer: "Issuer")
        let (initialTokenListViewModel, _) = tokenList.viewModel(with: [initialPersistentToken], at: displayTime)
        let controller = TokenListViewController(viewModel: initialTokenListViewModel, dispatchAction: { _ in })
        let tableView = MockTableView()
        controller.tableView = tableView

        // Add the view controller to a test window so it will create cells as if it were visible.
        testWindow.rootViewController = controller

        // Update the view controller.
        let updatedPersistentToken = initialPersistentToken.updated(with: mockToken(name: "name", issuer: "issuer"))
        let (updatedTokenListViewModel, _) = tokenList.viewModel(with: [updatedPersistentToken], at: displayTime)
        controller.update(with: updatedTokenListViewModel)

        // Check the changes to the table view.
        // Updates to existing rows should be applied directly to the cells, without changing the table view.
        let expectedChanges: [MockTableView.ChangeType] = []
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Check that the table view contains the expected cells.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        let indexPath = IndexPath(row: 0, section: 0)
        let expectedText = updatedPersistentToken.token.issuer + " " + updatedPersistentToken.token.name
        XCTAssert(cellAt: indexPath, in: tableView, containsText: expectedText)
    }

    // Test that the view controller will display the expected number of rows and sections for a given view model.
    func testNumberOfRowsAndSection() {
        let persistentTokens = mockPersistentTokens([
            ("Service", "example@google.com"),
            ("Service", "username"),
        ])
        let (viewModel, _) = tokenList.viewModel(with: persistentTokens, at: displayTime)
        let controller = TokenListViewController(viewModel: viewModel, dispatchAction: { _ in })

        // Check that the table view contains the expected cells.
        XCTAssertEqual(controller.tableView.numberOfSections, 1)
        XCTAssertEqual(controller.tableView.numberOfRows(inSection: 0), viewModel.rowModels.count)
        let visibleCells = controller.tableView.visibleCells
        XCTAssertEqual(visibleCells.count, 2)
        for (rowModel, cell) in zip(viewModel.rowModels, visibleCells) {
            let expectedText = rowModel.issuer + " " + rowModel.name
            XCTAssert(cell, containsText: expectedText)
        }
    }
}

func XCTAssert(_ cell: UITableViewCell, containsText expectedText: String,
               file: StaticString = #file, line: UInt = #line) {
    let textInCellLabels = cell.contentView.subviews.compactMap({ ($0 as? UILabel)?.text })
    XCTAssert(textInCellLabels.contains(expectedText), "Expected \(textInCellLabels) to contain \"\(expectedText)\"",
              file: file, line: line)
}

func XCTAssert(cellAt indexPath: IndexPath, in tableView: UITableView, containsText expectedText: String,
               file: StaticString = #file, line: UInt = #line) {
    guard let cell = tableView.cellForRow(at: indexPath) else {
        XCTFail("Expected cell at index path \(indexPath)", file: file, line: line)
        return
    }
    XCTAssert(cell, containsText: expectedText, file: file, line: line)
}
