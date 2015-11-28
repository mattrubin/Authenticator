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

func diff<Row>(from groupA: ArraySlice<Row>, to groupB: ArraySlice<Row>, comparator isSameRow: (Row, Row) -> Bool) -> [Change] {
    // Work from the end to preserve earlier indices when recursing
    switch (groupA.last, groupB.last) {
    case let (.Some(a), .Some(b)):
        if isSameRow(a, b) {
            // TODO: Don't update if the rows are truly equal
            let update = Change.Update(index: groupB.endIndex.predecessor())
            let remainingChanges = diff(from: groupA.dropLast(), to: groupB.dropLast(), comparator: isSameRow)
            return [update] + remainingChanges
        } else {
            let insertion = Change.Insert(index: groupB.endIndex.predecessor())
            let changesAfterInsertion = diff(from: groupA, to: groupB.dropLast(), comparator: isSameRow)
            let changesWithInsertion = [insertion] + changesAfterInsertion

            let deletion = Change.Delete(index: groupA.endIndex.predecessor())
            let changesAfterDeletion = diff(from: groupA.dropLast(), to: groupB, comparator: isSameRow)
            let changesWithDeletion = [deletion] + changesAfterDeletion

            return changesWithInsertion.count < changesWithDeletion.count
                ? changesWithInsertion
                : changesWithDeletion
        }
    case (.Some, .None):
        let deletion = Change.Delete(index: groupA.endIndex.predecessor())
        let remainingChanges = diff(from: groupA.dropLast(), to: groupB, comparator: isSameRow)
        return [deletion] + remainingChanges

    case (.None, .Some):
        let insertion = Change.Insert(index: groupB.endIndex.predecessor())
        let remainingChanges = diff(from: groupA, to: groupB.dropLast(), comparator: isSameRow)
        return [insertion] + remainingChanges

    case (.None, .None):
        return []
    }
}
