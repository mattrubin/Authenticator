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

protocol Identifiable {
    func hasSameIdentity(other: Self) -> Bool
}

enum Change {
    case Insert(index: Int)
    case Update(index: Int)
    case Delete(index: Int)
    // TODO: Consolidate matching Inserts and Deletes into Moves
    case Move(fromIndex: Int, toIndex: Int)
}

func diff<Row>(from oldRows: [Row], to newRows: [Row],
    comparator rowsHaveSameIdentity: (Row, Row) -> Bool) -> [Change]
{
    return changes(from: ArraySlice(oldRows), to: ArraySlice(newRows),
        comparator: rowsHaveSameIdentity, equation: { (old, new) in false })
}

func changesFrom<T: Identifiable where T: Equatable>(oldRows: [T], to newRows: [T]) -> [Change] {
    return changes(from: ArraySlice(oldRows), to: ArraySlice(newRows),
        comparator: { $0.hasSameIdentity($1) }, equation: ==)
}

private func changes<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator rowsHaveSameIdentity: (Row, Row) -> Bool, equation rowsAreEqual: (Row, Row) -> Bool)
    -> [Change]
{
    // Work from the end to preserve earlier indices when recursing
    switch (oldRows.last, newRows.last) {
    case let (.Some(oldRow), .Some(newRow)):
        if rowsHaveSameIdentity(oldRow, newRow) {
            // The old and new rows have the same identity...
            if rowsAreEqual(oldRow, newRow) {
                // ...and are truly equal, so no change is needed.
                return changes(from: oldRows.dropLast(), to: newRows.dropLast(),
                    comparator: rowsHaveSameIdentity, equation: rowsAreEqual)
            } else {
                // ...but differ in some way. This can be represented by an Update.
                return changesWithUpdate(from: oldRows, to: newRows,
                    comparator: rowsHaveSameIdentity, equation: rowsAreEqual)
            }
        } else {
            // The old and new rows are different, so compute the two possible change sets:
            // one where the old row is deleted, another where the new row is inserted
            let changesA = changesWithInsertion(from: oldRows, to: newRows,
                comparator: rowsHaveSameIdentity, equation: rowsAreEqual)
            let changesB = changesWithDeletion(from: oldRows, to: newRows,
                comparator: rowsHaveSameIdentity, equation: rowsAreEqual)

            // Return the shorter of the two change sets
            return changesA.count < changesB.count ? changesA : changesB
        }

    case (.Some, .None):
        // Only old rows remain, which must be deleted
        return changesWithDeletion(from: oldRows, to: newRows,
            comparator: rowsHaveSameIdentity, equation: rowsAreEqual)

    case (.None, .Some):
        // Only new rows remain, which must be inserted
        return changesWithInsertion(from: oldRows, to: newRows,
            comparator: rowsHaveSameIdentity, equation: rowsAreEqual)

    case (.None, .None):
        // All rows are accounted for
        return []
    }
}

private func changesWithInsertion<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator: (Row, Row) -> Bool, equation: (Row, Row) -> Bool) -> [Change]
{
    let insertion = Change.Insert(index: newRows.endIndex.predecessor())
    let changesAfterInsertion = changes(from: oldRows, to: newRows.dropLast(),
        comparator: comparator, equation: equation)
    return [insertion] + changesAfterInsertion
}

private func changesWithUpdate<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator: (Row, Row) -> Bool, equation: (Row, Row) -> Bool) -> [Change]
{
    // TODO: Test update indices (old index or new?)
    let update = Change.Update(index: newRows.endIndex.predecessor())
    let changesAfterUpdate = changes(from: oldRows.dropLast(), to: newRows.dropLast(),
        comparator: comparator, equation: equation)
    return [update] + changesAfterUpdate
}

private func changesWithDeletion<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator: (Row, Row) -> Bool, equation: (Row, Row) -> Bool) -> [Change]
{
    let deletion = Change.Delete(index: oldRows.endIndex.predecessor())
    let changesAfterDeletion = changes(from: oldRows.dropLast(), to: newRows,
        comparator: comparator, equation: equation)
    return [deletion] + changesAfterDeletion
}
