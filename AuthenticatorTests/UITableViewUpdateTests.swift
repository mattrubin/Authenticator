//
//  UITableViewUpdateTests.swift
//  Authenticator
//
//  Copyright (c) 2017-2018 Authenticator authors
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
        addToTestViewHierarchy(tableView)

        let dataSource = MockTableViewDataSource()
        tableView.dataSource = dataSource

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)

        // Update the table view.
        dataSource.titles = [["A"]]
        let changes: [Change<IndexPath>] = [
            .insert(index: IndexPath(row: 0, section: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRows(at: [indexPath], with: .automatic)
            XCTFail("Unexpected update of row at \(indexPath)")
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .beginUpdates,
            .insert(indexPath: IndexPath(row: 0, section: 0)),
            .endUpdates,
            .scroll(indexPath: IndexPath(row: 0, section: 0)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "A")
    }

    func testDelete() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        addToTestViewHierarchy(tableView)

        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["B"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "B")

        // Update the table view.
        dataSource.titles = [[]]
        let changes: [Change<IndexPath>] = [
            .delete(index: IndexPath(row: 0, section: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRows(at: [indexPath], with: .automatic)
            XCTFail("Unexpected update of row at \(indexPath)")
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .beginUpdates,
            .remove(indexPath: IndexPath(row: 0, section: 0)),
            .endUpdates,
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)
    }

    func testUpdate() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        addToTestViewHierarchy(tableView)

        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["X"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "X")

        // Update the table view.
        dataSource.titles = [["X!"]]
        let changes: [Change<IndexPath>] = [
            .update(oldIndex: IndexPath(row: 0, section: 0), newIndex: IndexPath(row: 0, section: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRows(at: [indexPath], with: .automatic)
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .reload(indexPath: IndexPath(row: 0, section: 0)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 1)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "X!")
    }

    func testManyChanges() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        addToTestViewHierarchy(tableView)

        // Make the table view big to ensure it allocates all the cells.
        tableView.frame = CGRect(origin: .zero, size: CGSize(width: 999, height: 999))
        let dataSource = MockTableViewDataSource()
        dataSource.titles = [["A", "B"], ["C"]]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 1)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "A")
        XCTAssert(cellAt: IndexPath(row: 1, section: 0), in: tableView, hasTitle: "B")
        XCTAssert(cellAt: IndexPath(row: 0, section: 1), in: tableView, hasTitle: "C")

        // Update the table view.
        dataSource.titles = [["B!", "D"], ["E", "C"]]
        let changes: [Change<IndexPath>] = [
            .insert(index: IndexPath(row: 0, section: 1)),
            .insert(index: IndexPath(row: 1, section: 0)),
            .update(oldIndex: IndexPath(row: 1, section: 0), newIndex: IndexPath(row: 0, section: 0)),
            .delete(index: IndexPath(row: 0, section: 0)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRows(at: [indexPath], with: .automatic)
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .beginUpdates,
            .insert(indexPath: IndexPath(row: 0, section: 1)),
            .insert(indexPath: IndexPath(row: 1, section: 0)),
            .remove(indexPath: IndexPath(row: 0, section: 0)),
            .endUpdates,
            .reload(indexPath: IndexPath(row: 0, section: 0)),
            .scroll(indexPath: IndexPath(row: 0, section: 1)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 2)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "B!")
        XCTAssert(cellAt: IndexPath(row: 1, section: 0), in: tableView, hasTitle: "D")
        XCTAssert(cellAt: IndexPath(row: 0, section: 1), in: tableView, hasTitle: "E")
        XCTAssert(cellAt: IndexPath(row: 1, section: 1), in: tableView, hasTitle: "C")
    }

    func testScrollToLastInsert() {
        // Set up a table view and empty data source.
        let tableView = MockTableView()
        addToTestViewHierarchy(tableView)

        // Make the table view big to ensure it allocates all the cells.
        tableView.frame = CGRect(origin: .zero, size: CGSize(width: 999, height: 999))
        let dataSource = MockTableViewDataSource()
        dataSource.titles = [[], []]
        tableView.dataSource = dataSource
        tableView.reloadData()

        // Test the inital state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 0)

        // Update the table view.
        dataSource.titles = [["A", "B"], ["C", "D", "E"]]
        let changes: [Change<IndexPath>] = [
            .insert(index: IndexPath(row: 0, section: 0)),
            .insert(index: IndexPath(row: 1, section: 1)),
            .insert(index: IndexPath(row: 2, section: 1)),
            .insert(index: IndexPath(row: 1, section: 0)),
            .insert(index: IndexPath(row: 0, section: 1)),
        ]
        tableView.applyChanges(changes, updateRow: { indexPath in
            tableView.reloadRows(at: [indexPath], with: .automatic)
        })

        // Test the changes applied the table view.
        let expectedChanges: [MockTableView.ChangeType] = [
            .beginUpdates,
            .insert(indexPath: IndexPath(row: 0, section: 0)),
            .insert(indexPath: IndexPath(row: 1, section: 1)),
            .insert(indexPath: IndexPath(row: 2, section: 1)),
            .insert(indexPath: IndexPath(row: 1, section: 0)),
            .insert(indexPath: IndexPath(row: 0, section: 1)),
            .endUpdates,
            .scroll(indexPath: IndexPath(row: 2, section: 1)),
        ]
        XCTAssertEqual(tableView.changes, expectedChanges)

        // Test the updated state of the table view.
        XCTAssertEqual(tableView.numberOfSections, 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 2)
        XCTAssertEqual(tableView.numberOfRows(inSection: 1), 3)
        XCTAssert(cellAt: IndexPath(row: 0, section: 0), in: tableView, hasTitle: "A")
        XCTAssert(cellAt: IndexPath(row: 1, section: 0), in: tableView, hasTitle: "B")
        XCTAssert(cellAt: IndexPath(row: 0, section: 1), in: tableView, hasTitle: "C")
        XCTAssert(cellAt: IndexPath(row: 1, section: 1), in: tableView, hasTitle: "D")
        XCTAssert(cellAt: IndexPath(row: 2, section: 1), in: tableView, hasTitle: "E")
    }
}

class MockTableViewDataSource: NSObject, UITableViewDataSource {
    var titles: [[String]] = [[]]

    func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self)
        cell.textLabel?.text = titles[indexPath.section][indexPath.row]
        return cell
    }
}

func XCTAssert(cellAt indexPath: IndexPath, in tableView: UITableView, hasTitle expectedTitle: String,
               file: StaticString = #file, line: UInt = #line) {
    guard let cell = tableView.cellForRow(at: indexPath) else {
        XCTFail("Expected cell at index path \(indexPath)", file: file, line: line)
        return
    }
    XCTAssertEqual(cell.textLabel?.text, expectedTitle, file: file, line: line)
}
