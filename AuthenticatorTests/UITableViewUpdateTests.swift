//
//  UITableViewUpdateTests.swift
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

class UITableViewUpdateTests: XCTestCase {
    func testInsert() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        let dataSource = MockTableViewDataSource()
        tableView.dataSource = dataSource

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 0)

        // Update the table view.
        dataSource.titles = [["A"]]
        let changes: [Change<NSIndexPath>] = [
            .Insert(index: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            XCTFail("Unexpected update of row at \(indexPath)")
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .BeginUpdates,
            .Insert(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
            .EndUpdates,
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            XCTFail("Expected cell at index path \(indexPath)")
            return
        }
        XCTAssertEqual(cell.textLabel?.text, "A")
    }

    func testDelete() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["B"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            XCTFail("Expected cell at index path \(indexPath)")
            return
        }
        XCTAssertEqual(cell.textLabel?.text, "B")

        // Update the table view.
        dataSource.titles = [[]]
        let changes: [Change<NSIndexPath>] = [
            .Delete(index: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            XCTFail("Unexpected update of row at \(indexPath)")
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .BeginUpdates,
            .Remove(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
            .EndUpdates,
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 0)
    }
}

class MockTableViewDataSource: NSObject, UITableViewDataSource {
    var titles: [[String]] = [[]]

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return titles.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithClass(UITableViewCell)
        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        return cell
    }
}
