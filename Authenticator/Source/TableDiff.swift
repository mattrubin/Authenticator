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

func changesFrom<T>(oldArray: [T], to newArray: [T], hasSameIdentity: (T, T) -> Bool) -> [Change] {
    return changes(from: ArraySlice(oldArray), to: ArraySlice(newArray),
        comparator: hasSameIdentity, equation: { (_, _) in false })
}

func changesFrom<T: Identifiable where T: Equatable>(oldArray: [T], to newArray: [T]) -> [Change] {
    return changes(from: ArraySlice(oldArray), to: ArraySlice(newArray),
        comparator: { $0.hasSameIdentity($1) }, equation: ==)
}

private func changes<Row>(from oldRows: ArraySlice<Row>, to newRows: ArraySlice<Row>,
    comparator rowsHaveSameIdentity: (Row, Row) -> Bool, equation rowsAreEqual: (Row, Row) -> Bool)
    -> [Change]
{
    print("OLD: \(oldRows)")
    print("NEW: \(newRows)")
    let MAX = oldRows.count + newRows.count
    if MAX == 0 {
        return []
    }
    print("\(MAX) = \(oldRows.count) + \(newRows.count)")
    var V = Array(count: (2 * MAX + 1), repeatedValue: 0)
    for D in 0...MAX {
        print("Finding \(D)-change paths:")
        for k in (-D).stride(through: D, by: 2) {
            print("  in diagonal \(k)")
            var x: Int
            if k == -D || (k != D && V[k-1 + MAX] < V[k+1 + MAX]) {
                x = V[k+1 + MAX]
                print("    the best predecessor comes from diagonal \(k+1)")
                print("    which reached point (\(x),\(x-k-1)))")
            } else {
                x = V[k-1 + MAX] + 1
                print("    the best predecessor comes from diagonal \(k-1)")
                print("    which reached point (\(x-1),\(x-k)))")
            }
            var y = x - k
            print("    so with one step we can reach point (\(x),\(y)))")
            while x < oldRows.count && y < newRows.count && rowsHaveSameIdentity(oldRows[x+1 - 1], newRows[y+1 - 1]) {
                (x, y) = (x+1, y+1)
                print("      which can slide to (\(x),\(y)))")
            }
            V[k + MAX] = x
            if x>=oldRows.count && y>=newRows.count {
                print("       taking us to our goal, with a \(D)-change path")
                return oldRows.indices.map({ .Delete(index: $0) }) + newRows.indices.map({ .Insert(index: $0) })
            }
        }
    }
    fatalError()
    return oldRows.indices.map({ .Delete(index: $0) }) + newRows.indices.map({ .Insert(index: $0) })
}

/*
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
*/
