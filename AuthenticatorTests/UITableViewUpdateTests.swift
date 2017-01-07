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
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "A")
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
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "B")

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

    func testUpdate() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["X"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "X")

        // Update the table view.
        dataSource.titles = [["X!"]]
        let changes: [Change<NSIndexPath>] = [
            .Update(oldIndex: NSIndexPath(forRow: 0, inSection: 0), newIndex: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .Reload(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "X!")
    }

    func testManyChanges() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        // Make the table view big to ensure it allocates all the cells.
        tableView.frame = CGRect(origin: .zero, size: CGSize(width: 999, height: 999))
        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["A", "B"], ["C"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 2)
        XCTAssertEqual(tableView.numberOfRowsInSection(1), 1)
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "A")
        XCTAssert(cellAt: NSIndexPath(forRow: 1, inSection: 0), in: tableView, hasTitle: "B")
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 1), in: tableView, hasTitle: "C")

        // Update the table view.
        dataSource.titles = [["B!", "D"], ["E", "C"]]
        let changes: [Change<NSIndexPath>] = [
            .Insert(index: NSIndexPath(forRow: 0, inSection: 1)),
            .Insert(index: NSIndexPath(forRow: 1, inSection: 0)),
            .Update(oldIndex: NSIndexPath(forRow: 1, inSection: 0), newIndex: NSIndexPath(forRow: 0, inSection: 0)),
            .Delete(index: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .BeginUpdates,
            .Insert(indexPath: NSIndexPath(forRow: 0, inSection: 1)),
            .Insert(indexPath: NSIndexPath(forRow: 1, inSection: 0)),
            .Remove(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
            .EndUpdates,
            .Reload(indexPath: NSIndexPath(forRow: 0, inSection: 0)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 2)
        XCTAssertEqual(tableView.numberOfRowsInSection(1), 2)
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 0), in: tableView, hasTitle: "B!")
        XCTAssert(cellAt: NSIndexPath(forRow: 1, inSection: 0), in: tableView, hasTitle: "D")
        XCTAssert(cellAt: NSIndexPath(forRow: 0, inSection: 1), in: tableView, hasTitle: "E")
        XCTAssert(cellAt: NSIndexPath(forRow: 1, inSection: 1), in: tableView, hasTitle: "C")
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

func XCTAssert(cellAt indexPath: NSIndexPath, in tableView: UITableView, hasTitle expectedTitle: String,
                      file: StaticString = #file, line: UInt = #line) {
    guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
        XCTFail("Expected cell at index path \(indexPath)", file: file, line: line)
        return
    }
    XCTAssertEqual(cell.textLabel?.text, expectedTitle, file: file, line: line)
}
