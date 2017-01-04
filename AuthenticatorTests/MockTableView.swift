//
//  MockTableView.swift
//  Authenticator
//
//  Copyright (c) 2016 Authenticator authors
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

    enum ChangeType {
        case Insert(indexPath: NSIndexPath)
        case Remove(indexPath: NSIndexPath)
        case Reload(indexPath: NSIndexPath)
        case Move(fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    }

    var changes: [ChangeType] = []

    var didBeginUpdates = false
    var didEndUpdates = false
    override func beginUpdates() {
        super.beginUpdates()
        didBeginUpdates = true
    }

    override func endUpdates() {
        super.endUpdates()
        didEndUpdates = true
    }

    override func insertRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)

        for indexPath in indexPaths {
            changes.append(.Insert(indexPath: indexPath))
        }
    }

    override func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        for indexPath in indexPaths {
            changes.append(.Remove(indexPath: indexPath))
        }
    }

    override func reloadRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        super.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        for indexPath in indexPaths {
            changes.append(.Reload(indexPath: indexPath))
        }
    }

    override func moveRowAtIndexPath(indexPath: NSIndexPath, toIndexPath newIndexPath: NSIndexPath) {
        super.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        changes.append(.Move(fromIndexPath: indexPath, toIndexPath: newIndexPath))
    }
    
}
