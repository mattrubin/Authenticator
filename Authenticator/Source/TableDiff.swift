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
    case Update(oldIndex: Int, newIndex: Int)
    case Delete(index: Int)
    // TODO: Consolidate matching Inserts and Deletes into Moves
    case Move(fromIndex: Int, toIndex: Int)
}

func changesFrom<T>(oldArray: [T], to newArray: [T], hasSameIdentity: (T, T) -> Bool) -> [Change] {
    return changes(from: oldArray, to: newArray,
        comparator: hasSameIdentity, equation: { (_, _) in false })
}

func changesFrom<T: Identifiable where T: Equatable>(oldArray: [T], to newArray: [T]) -> [Change] {
    return changes(from: oldArray, to: newArray,
        comparator: { $0.hasSameIdentity($1) }, equation: ==)
}

private func changes<Row>(from oldRows: [Row], to newRows: [Row],
    comparator rowsHaveSameIdentity: (Row, Row) -> Bool, equation rowsAreEqual: (Row, Row) -> Bool)
    -> [Change]
{
    let MAX = oldRows.count + newRows.count
    if MAX == 0 {
        return []
    }
    let numDiagonals = (2 * MAX) + 1
    var V: [Int] = Array(count: numDiagonals, repeatedValue: 0)
    var changesInDiagonal: [[Change]] = Array(count: numDiagonals, repeatedValue: [])
    for D in 0...MAX {
        for k in (-D).stride(through: D, by: 2) {
            var x: Int
            var changes: [Change]
            if D == 0 {
                x = 0
                changes = []
            } else
            if k == -D || (k != D && V[k-1 + MAX] < V[k+1 + MAX]) {
                x = V[k+1 + MAX]
                changes = changesInDiagonal[k+1 + MAX]
                changes = changes + [.Insert(index: x-k - 1)]
            } else {
                x = V[k-1 + MAX] + 1
                changes = changesInDiagonal[k-1 + MAX]
                changes = changes + [.Delete(index: x - 1)]
            }
            var y = x - k
            while x < oldRows.count && y < newRows.count && rowsHaveSameIdentity(oldRows[x], newRows[y]) {
                if !rowsAreEqual(oldRows[x], newRows[y]) {
                    changes = changes + [.Update(oldIndex: x, newIndex: y)]
                }
                (x, y) = (x+1, y+1)
            }
            V[k + MAX] = x
            changesInDiagonal[k + MAX] = changes
            if x >= oldRows.count && y >= newRows.count {
                print(changes)
                return changes
            }
        }
    }
    // With MAX = oldRows.count + newRows.count, a solution must be found by the above algorithm
    // but here's a delete-and-insert-everything fallback, just in case.
    return oldRows.indices.map({ .Delete(index: $0) }) + newRows.indices.map({ .Insert(index: $0) })
}
