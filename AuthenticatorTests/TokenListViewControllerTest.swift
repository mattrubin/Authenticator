//
//  TokenListViewControllerTest.swift
//  Authenticator
//
//  Created by Beau Collins on 10/25/16.
//  Copyright © 2016 Matt Rubin. All rights reserved.
//

import XCTest
@testable import Authenticator

func buildController(withTokens tokens:[(String, String)],
                                dispatcher:(TokenList.Action)->()) throws -> TokenListViewController? {

    let (viewModel, _) = try mockListViewModel(tokens)
    return buildController(withViewModel: viewModel, dispatcher: dispatcher)

}

func buildController(withViewModel model:TokenList.ViewModel, dispatcher:(TokenList.Action)->()) -> TokenListViewController? {
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
        let (updated, _)  = try mockListViewModel([
            ("Service", "email@example.com")
            ])

        controller?.updateWithViewModel(updated)
        XCTAssertTrue(tableView!.didBeginUpdates)
        XCTAssertTrue(tableView!.didEndUpdates)
        XCTAssertEqual(tableView!.changes.count, 1)
        guard let change = tableView?.changes.first else {
            XCTFail("No change")
            return
        }
        switch change {
        case .Insert(let indexPath):
            XCTAssertEqual(indexPath.section, 0)
            XCTAssertEqual(indexPath.row, 0)
            break;
        default:
            XCTFail("Change was not an insert")
        }

    }

    // not entirely sure wear I was headed with test
    func testUpdatesExistingRow() throws {
        var token = try mockToken("account@example.com", issuer: "Issuer")
        var startingTokenList = TokenList(persistentTokens: [token], displayTime: DisplayTime(date: NSDate()))
        controller = buildController(withViewModel: startingTokenList.viewModel, dispatcher: self.onDispatch)

        startingTokenList.update(.EditPersistentToken(token))

    }

    func testNumberOfRowsAndSection() throws {
        let (viewModel, _) = try mockListViewModel([
            ("Service", "example@google.com"),
            ("Service", "username")
            ])
        controller = TokenListViewController(viewModel: viewModel, dispatchAction: { [weak self] (action) -> () in
            self?.lastActionDispatched = action
        } )

        XCTAssertEqual(
            controller!.numberOfSectionsInTableView(controller!.tableView),
            1
        )
        XCTAssertEqual(
            controller!.tableView(controller!.tableView, numberOfRowsInSection: 0),
            viewModel.rowModels.count
        )

    }
    
}
