//
//  TokenListViewControllerTest.swift
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

import XCTest
import OneTimePassword
@testable import Authenticator

class TokenListViewControllerTest: XCTestCase {

    var lastActionDispatched: TokenList.Action?

    func emptyListViewModel() -> TokenList.ViewModel {
        return mockList([]).viewModel
    }

    override func setUp() {
        super.setUp()

    }

    override func tearDown() {
        lastActionDispatched = nil
        super.tearDown()
    }

    func onDispatch(action: TokenList.Action) {
        lastActionDispatched = action
    }

    func testTokenListInsertsNewToken() {
        // Set up a view controller with a mock table view.
        let initialViewModel = emptyListViewModel()
        let controller = TokenListViewController(viewModel: initialViewModel, dispatchAction: self.onDispatch)
        let tableView = MockTableView()
        controller.tableView = tableView

        // Update the view controller.
        let updatedViewModel = mockList([
            ("Service", "email@example.com"),
        ]).viewModel
        controller.updateWithViewModel(updatedViewModel)

        // Check the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .BeginUpdates,
            .Insert(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
            .EndUpdates,
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)
    }

    func testUpdatesExistingRow() {
        // Set up a view controller with a mock table view.
        let displayTime = DisplayTime(date: NSDate())
        let initialPersistentToken = mockPersistentToken(name: "account@example.com", issuer: "Issuer")
        let initialTokenList = TokenList(persistentTokens: [initialPersistentToken], displayTime: displayTime)
        let controller = TokenListViewController(viewModel: initialTokenList.viewModel, dispatchAction: self.onDispatch)
        let tableView = MockTableView()
        controller.tableView = tableView

        // Update the view controller.
        let updatedPersistentToken = initialPersistentToken.updated(with: mockToken(name: "name", issuer: "issuer"))
        let updatedTokenList = TokenList(persistentTokens: [updatedPersistentToken], displayTime: displayTime)
        controller.updateWithViewModel(updatedTokenList.viewModel)

        // Check the table view.
        // Updates to existing rows should be applied directly to the cells, without changing the table view.
        // TODO: Test for direct updates to the cell via `updateWithRowModel`.
        let expectedChanges: [MockTableView.ChangeType] = []
        XCTAssertEqual(tableView.changes, expectedChanges)
    }

    func testNumberOfRowsAndSection() {
        let viewModel = mockList([
            ("Service", "example@google.com"),
            ("Service", "username"),
        ]).viewModel

        let controller = TokenListViewController(viewModel: viewModel, dispatchAction: { [weak self] action in
            self?.lastActionDispatched = action
        })

        XCTAssertEqual(
            controller.numberOfSectionsInTableView(controller.tableView),
            1
        )
        XCTAssertEqual(
            controller.tableView(controller.tableView, numberOfRowsInSection: 0),
            viewModel.rowModels.count
        )
    }
}
