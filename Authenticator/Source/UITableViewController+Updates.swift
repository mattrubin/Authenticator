//
//  UITableViewController+Updates.swift
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

import UIKit

extension UITableViewController {
    enum Change {
        case Insert(index: NSIndexPath)
        case Update(oldIndex: NSIndexPath, newIndex: NSIndexPath)
        case Delete(index: NSIndexPath)
    }

    func updateTableViewWithChanges(changes: [Change], @noescape updateRow: (NSIndexPath) -> Void) {
        if changes.isEmpty {
            return
        }

        // In a single animated group, apply any changes which alter the ordering of the table.
        applyOrderChanges(fromChanges: changes)
        // After applying the changes which require animations, update in place any visible cells
        // whose contents have changed.
        applyRowUpdates(fromChanges: changes, updateRow: updateRow)
        // If any tokens were inserted, scroll to the first inserted row.
        scrollToFirstInsertedRow(fromChanges: changes)
    }

    /// From among the given `Change`s, applies any changes which modify the order of cells in the
    /// table view. These insertions, deletions, and moves will be performed in a single
    /// animated table view updates group. If there are no changes which require animations, this
    /// method will not perform an empty updates group.
    /// - parameter changes: An `Array` of `Change`s, from which animated changes will be applied.
    func applyOrderChanges(fromChanges changes: [Change]) {
        // Determine if there are any changes that require insert/delete/move animations.
        // If there are none, tableView.beginUpdates and tableView.endUpdates are not required.
        let changesNeedAnimations = changes.contains { change in
            switch change {
            case .Insert, .Delete:
                return true
            case .Update:
                return false
            }
        }

        // Only perform a table view updates group if there are changes which require animations.
        if changesNeedAnimations {
            tableView.beginUpdates()
            for change in changes {
                switch change {
                case let .Insert(indexPath):
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                case let .Delete(indexPath):
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                case .Update:
                    break
                }
            }
            tableView.endUpdates()
        }
    }

    /// From among the given `Change`s, applies the `Update`s to cells at the new row indexes in the
    /// table view. This method should be used only *after* insertions, deletions, and moves
    /// have been applied.
    /// - parameter changes: An `Array` of `Change`s, from which `Update`s will be applied.
    /// - parameter updateRow: A closure which takes an NSIndexPath and updates the corresponding row.
    func applyRowUpdates(fromChanges changes: [Change], @noescape updateRow: (NSIndexPath) -> Void) {
        for change in changes {
            switch change {
            case let .Update(_, indexPath):
                updateRow(indexPath)
            case .Insert, .Delete:
                break
            }
        }
    }

    /// From among the given `Change`s, finds the first `Insert` and scrolls to that row in the
    /// table view. This method should be used only *after* the changes have been applied.
    /// - parameter changes: An `Array` of `Change`s, in which the first `Insert` will be found.
    func scrollToFirstInsertedRow(fromChanges changes: [Change]) {
        let firstInsertedRow = changes.reduce(nil, combine: { (firstInsertedRow, change) -> NSIndexPath? in
            switch change {
            case let .Insert(row):
                guard let prevFirstInsertedRow = firstInsertedRow else {
                    return row
                }
                return min(row, prevFirstInsertedRow)
            case .Delete, .Update:
                return firstInsertedRow
            }
        })

        if let indexPath = firstInsertedRow {
            // Scrolls to the newly inserted token at the smallest row index in the tableView
            // using the minimum amount of scrolling necessary (.None)
            tableView.scrollToRowAtIndexPath(indexPath,
                                             atScrollPosition: .None,
                                             animated: true)
        }
    }
}

private func min(lhs: NSIndexPath, _ rhs: NSIndexPath) -> NSIndexPath {
    if lhs.section < rhs.section {
        return lhs
    } else if (lhs.section == rhs.section) && (lhs.row < rhs.row) {
        return lhs
    } else {
        return rhs
    }
}
