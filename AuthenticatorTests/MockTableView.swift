//
//  MockTableView.swift
//  Authenticator
//
//  Copyright (c) 2016-2018 Authenticator authors
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

class MockTableView: UITableView {
    enum ChangeType: Equatable {
        case beginUpdates
        case endUpdates
        case insert(indexPath: IndexPath)
        case remove(indexPath: IndexPath)
        case reload(indexPath: IndexPath)
        case move(fromIndexPath: IndexPath, toIndexPath: IndexPath)
        case scroll(indexPath: IndexPath)
    }

    var changes: [ChangeType] = []

    override func beginUpdates() {
        super.beginUpdates()
        changes.append(.beginUpdates)
    }

    override func endUpdates() {
        super.endUpdates()
        changes.append(.endUpdates)
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        for indexPath in indexPaths {
            changes.append(.insert(indexPath: indexPath))
        }
    }

    override func deleteRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        super.deleteRows(at: indexPaths, with: animation)
        for indexPath in indexPaths {
            changes.append(.remove(indexPath: indexPath))
        }
    }

    override func reloadRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        super.reloadRows(at: indexPaths, with: animation)
        for indexPath in indexPaths {
            changes.append(.reload(indexPath: indexPath))
        }
    }

    override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        super.moveRow(at: indexPath, to: newIndexPath)
        changes.append(.move(fromIndexPath: indexPath, toIndexPath: newIndexPath))
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: ScrollPosition, animated: Bool) {
        super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        changes.append(.scroll(indexPath: indexPath))
    }
}
