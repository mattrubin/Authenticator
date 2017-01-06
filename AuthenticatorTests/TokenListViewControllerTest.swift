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
@testable import Authenticator

func buildController(withTokens tokens: [(String, String)],
                                dispatcher: (TokenList.Action) -> Void) throws -> TokenListViewController? {
    let (viewModel, _) = try mockListViewModel(tokens)
    return buildController(withViewModel: viewModel, dispatcher: dispatcher)

}

func buildController(withViewModel model: TokenList.ViewModel,
                                   dispatcher: (TokenList.Action) -> Void) -> TokenListViewController? {
    return TokenListViewController(viewModel: model, dispatchAction: dispatcher)
}

class TokenListViewControllerTest: XCTestCase {

    var lastActionDispatched: TokenList.Action?
    var controller: TokenListViewController?
    var tableView: MockTableView?

    func defaultViewModel() throws -> TokenList.ViewModel {
        let (viewModel, _) = try mockListViewModel()
        return viewModel
    }

    override func setUp() {
        super.setUp()

        do {
            controller = try buildController(withTokens: [], dispatcher: self.onDispatch)
            tableView = MockTableView()
            controller?.tableView = tableView
        } catch {
            XCTFail("Unable to initialize controller" )
        }
    }

    override func tearDown() {
        lastActionDispatched = nil
        super.tearDown()
    }

    func onDispatch(action: TokenList.Action) {
        lastActionDispatched = action
    }

    func testTokenListInsertsNewToken() throws {
        let (updated, _) = try mockListViewModel([
            ("Service", "email@example.com"),
        ])

        controller?.updateWithViewModel(updated)
        // swiftlint:disable force_unwrapping
        XCTAssertTrue(tableView!.didBeginUpdates)
        XCTAssertTrue(tableView!.didEndUpdates)
        XCTAssertEqual(tableView!.changes.count, 1)
        // swiftlint:enable force_unwrapping
        guard let change = tableView?.changes.first else {
            XCTFail("No change")
            return
        }
        switch change {
        case .Insert(let indexPath):
            XCTAssertEqual(indexPath.section, 0)
            XCTAssertEqual(indexPath.row, 0)
            break
        default:
            XCTFail("Change was not an insert")
        }

    }

    // not entirely sure wear I was headed with test
    func testUpdatesExistingRow() throws {
        let token = try mockToken("account@example.com", issuer: "Issuer")
        var startingTokenList = TokenList(persistentTokens: [token], displayTime: DisplayTime(date: NSDate()))
        controller = buildController(withViewModel: startingTokenList.viewModel, dispatcher: self.onDispatch)

        _ = startingTokenList.update(.EditPersistentToken(token))
    }

    func testNumberOfRowsAndSection() throws {
        let (viewModel, _) = try mockListViewModel([
            ("Service", "example@google.com"),
            ("Service", "username"),
        ])
        controller = TokenListViewController(viewModel: viewModel, dispatchAction: { [weak self] action in
            self?.lastActionDispatched = action
        })

        XCTAssertEqual(
            // swiftlint:disable:next force_unwrapping
            controller!.numberOfSectionsInTableView(controller!.tableView),
            1
        )
        XCTAssertEqual(
            // swiftlint:disable:next force_unwrapping
            controller!.tableView(controller!.tableView, numberOfRowsInSection: 0),
            viewModel.rowModels.count
        )
    }
}
