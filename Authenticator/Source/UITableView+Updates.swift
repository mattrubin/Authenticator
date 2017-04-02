//
//  UITableView+Updates.swift
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

extension UITableView {
    /// Applies the given `Change`s to the table view, then scrolls to show the last inserted row.
    /// - parameter changes: An `Array` of `Change`s to apply.
    /// - parameter updateRow: A closure which takes an `IndexPath` and updates the corresponding row.
    func applyChanges(_ changes: [Change<IndexPath>], updateRow: (IndexPath) -> Void) {
        if changes.isEmpty {
            return
        }

        // In a single animated group, apply any changes which alter the ordering of the table.
        applyOrderChanges(fromChanges: changes)
        // After applying the changes which require animations, update in place any cells whose contents have changed.
        applyRowUpdates(fromChanges: changes, updateRow: updateRow)
        // If any tokens were inserted, scroll to the last inserted row.
        scrollToLastInsertedRow(fromChanges: changes)
    }

    /// From among the given `Change`s, applies any changes which modify the order of cells in the table view. These
    /// insertions, deletions, and moves will be performed in a single animated table view updates group. If there are
    /// no changes which require animations, this method will not perform an empty updates group.
    /// - parameter changes: An `Array` of `Change`s, from which animated changes will be applied.
    private func applyOrderChanges(fromChanges changes: [Change<IndexPath>]) {
        // Determine if there are any changes that require insert/delete/move animations.
        // If there are none, tableView.beginUpdates and tableView.endUpdates are not required.
        let changesNeedAnimations = changes.contains { change in
            switch change {
            case .insert, .delete:
                return true
            case .update:
                return false
            }
        }

        // Only perform a table view updates group if there are changes which require animations.
        if changesNeedAnimations {
            beginUpdates()
            for change in changes {
                switch change {
                case let .insert(indexPath):
                    insertRows(at: [indexPath], with: .automatic)
                case let .delete(indexPath):
                    deleteRows(at: [indexPath], with: .automatic)
                case .update:
                    break
                }
            }
            endUpdates()
        }
    }

    /// From among the given `Change`s, applies the `Update`s to cells at the new row indexes in the table view. This
    /// method should be used only *after* insertions, deletions, and moves have been applied.
    /// - parameter changes: An `Array` of `Change`s, from which `Update`s will be applied.
    /// - parameter updateRow: A closure which takes an `IndexPath` and updates the corresponding row.
    private func applyRowUpdates(fromChanges changes: [Change<IndexPath>], updateRow: (IndexPath) -> Void) {
        for change in changes {
            switch change {
            case let .update(_, indexPath):
                updateRow(indexPath)
            case .insert, .delete:
                break
            }
        }
    }

    /// From among the given `Change`s, finds the last `Insert` and scrolls to that row in the table view. This method
    /// should be used only *after* the changes have been applied.
    /// - parameter changes: An `Array` of `Change`s, in which the last `Insert` will be found.
    private func scrollToLastInsertedRow(fromChanges changes: [Change<IndexPath>]) {
        let lastInsertedRow = changes.reduce(nil, { (lastInsertedRow, change) -> IndexPath? in
            switch change {
            case let .insert(row):
                guard let prevInsertedRow = lastInsertedRow else {
                    return row
                }
                return max(row, prevInsertedRow)
            case .delete, .update:
                return lastInsertedRow
            }
        })

        if let indexPath = lastInsertedRow {
            // Scrolls to the newly inserted token at the smallest row index in the tableView using the minimum amount
            // of scrolling necessary (.none)
            scrollToRow(at: indexPath, at: .none, animated: true)
        }
    }
}
