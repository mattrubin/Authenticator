//
//  TableDiff.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

import Foundation

enum Change {
    case Insert(index: Int)
    case Update(index: Int)
    case Delete(index: Int)
    case Move(fromIndex: Int, toIndex: Int)
}

func diff<Row>(from oldArray: [Row], to newArray: [Row], comparator isSameRow: (Row, Row) -> Bool)
    -> [Change] {
        return changes(from: ArraySlice(oldArray), to: ArraySlice(newArray), comparator: isSameRow)
}

private func changes<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator isSameRow: (Row, Row) -> Bool) -> [Change] {
        // Work from the end to preserve earlier indices when recursing
        switch (oldRows.last, newRows.last) {
        case let (.Some(oldRow), .Some(newRow)):
            if isSameRow(oldRow, newRow) {
                // The old and new rows are the same row, and can be represented by an Update
                // TODO: Don't update if the rows are truly equal
                return changesWithUpdate(from: oldRows, to: newRows, comparator: isSameRow)
            } else {
                // The old and new rows are different, so compute the two possible change sets:
                // one where the old row is deleted, another where the new row is inserted
                let changesA = changesWithInsertion(from: oldRows, to: newRows, comparator: isSameRow)
                let changesB = changesWithDeletion(from: oldRows, to: newRows, comparator: isSameRow)

                // Return the shorter of the two change sets
                return changesA.count < changesB.count ? changesA : changesB
            }

        case (.Some, .None):
            // Only old rows remain, which must be deleted
            return changesWithDeletion(from: oldRows, to: newRows, comparator: isSameRow)

        case (.None, .Some):
            // Only new rows remain, which must be inserted
            return changesWithInsertion(from: oldRows, to: newRows, comparator: isSameRow)

        case (.None, .None):
            // All rows are accounted for
            return []
        }
}

private func changesWithInsertion<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator isSameRow: (Row, Row) -> Bool) -> [Change] {
        let insertion = Change.Insert(index: newRows.endIndex.predecessor())
        let changesAfterInsertion = changes(from: oldRows, to: newRows.dropLast(),
            comparator: isSameRow)
        return [insertion] + changesAfterInsertion
}

private func changesWithUpdate<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator isSameRow: (Row, Row) -> Bool) -> [Change] {
        // TODO: Test update indices
        let update = Change.Update(index: newRows.endIndex.predecessor())
        let changesAfterUpdate = changes(from: oldRows.dropLast(), to: newRows.dropLast(),
            comparator: isSameRow)
        return [update] + changesAfterUpdate
}

private func changesWithDeletion<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator isSameRow: (Row, Row) -> Bool) -> [Change] {
        let deletion = Change.Delete(index: oldRows.endIndex.predecessor())
        let changesAfterDeletion = changes(from: oldRows.dropLast(), to: newRows,
            comparator: isSameRow)
        return [deletion] + changesAfterDeletion
}
