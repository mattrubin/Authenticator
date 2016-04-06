//
//  TokenListViewController.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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
import SVProgressHUD

class TokenListViewController: UITableViewController {
    private let dispatchAction: (TokenList.Action) -> ()
    private var viewModel: TokenList.ViewModel
    private var preventTableViewAnimations = false

    init(viewModel: TokenList.ViewModel, dispatchAction: (TokenList.Action) -> ()) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var displayLink: CADisplayLink?
    private let ring: OTPProgressRing = OTPProgressRing(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
    private lazy var noTokensLabel: UILabel = {
        let noTokenString = NSMutableAttributedString(string: "No Tokens\n",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)!])
        noTokenString.appendAttributedString(NSAttributedString(string: "Tap + to add a new token",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)!]))
        noTokenString.addAttributes(
            [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!],
            range: (noTokenString.string as NSString).rangeOfString("+"))

        let label = UILabel()
        label.numberOfLines = 2
        label.attributedText = noTokenString
        label.textAlignment = .Center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        // Configure table view
        self.tableView.separatorStyle = .None
        self.tableView.indicatorStyle = .White
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelectionDuringEditing = true

        // Configure navigation bar
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.ring)

        // Configure toolbar
        let addAction = #selector(TokenListViewController.addToken)
        self.toolbarItems = [
            self.editButtonItem(),
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: addAction)
        ]
        self.navigationController?.toolbarHidden = false

        // Configure "no tokens" label
        self.noTokensLabel.frame = CGRect(x: 0, y: 0,
            width: self.view.bounds.size.width,
            height: self.view.bounds.size.height * 0.6)
        self.view.addSubview(self.noTokensLabel)

        // Update with current viewModel
        self.updatePeripheralViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let selector = #selector(TokenListViewController.tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.editing = false
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    // MARK: Target Actions

    func tick() {
        // Dispatch an action to trigger a view model update.
        let newDisplayTime = DisplayTime(date: NSDate())
        dispatchAction(.UpdateViewModel(newDisplayTime))
    }

    func addToken() {
        dispatchAction(.BeginAddToken)
    }
}

// MARK: UITableViewDataSource
extension TokenListViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithClass(TokenRowCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    private func updateCell(cell: TokenRowCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
        cell.dispatchAction = dispatchAction
    }

    override func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
    {
        let rowModel = viewModel.rowModels[indexPath.row]
        if editingStyle == .Delete {
            dispatchAction(rowModel.deleteAction)
        }
    }

    override func tableView(tableView: UITableView,
        moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath)
    {
        preventTableViewAnimations = true
        dispatchAction(.MoveToken(fromIndex: sourceIndexPath.row,
            toIndex: destinationIndexPath.row))
        preventTableViewAnimations = false
    }

}

// MARK: UITableViewDelegate
extension TokenListViewController {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath)
        -> CGFloat
    {
        return 85
    }
}

// MARK: TokenListPresenter
extension TokenListViewController {
    func updateWithViewModel(viewModel: TokenList.ViewModel) {
        let changes = changesFrom(self.viewModel.rowModels, to: viewModel.rowModels)
        self.viewModel = viewModel
        updateTableViewWithChanges(changes)
        updatePeripheralViews()
        // Show ephemeral message
        if let ephemeralMessage = viewModel.ephemeralMessage {
            switch ephemeralMessage {
            case .Success(let message):
                SVProgressHUD.showSuccessWithStatus(message)
            case .Error(let message):
                SVProgressHUD.showErrorWithStatus(message)
            }
        }
    }

    private func updateTableViewWithChanges(changes: [Change]) {
        if changes.isEmpty || preventTableViewAnimations {
            return
        }

        tableView.beginUpdates()
        let sectionIndex = 0
        for change in changes {
            switch change {
            case .Insert(let rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            case let .Update(rowIndex, _):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TokenRowCell {
                    updateCell(cell, forRowAtIndexPath: indexPath)
                } else {
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            case .Delete(let rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            case let .Move(fromRowIndex, toRowIndex):
                let origin = NSIndexPath(forRow: fromRowIndex, inSection: sectionIndex)
                let destination = NSIndexPath(forRow: toRowIndex, inSection: sectionIndex)
                tableView.moveRowAtIndexPath(origin, toIndexPath: destination)
            }
        }
        tableView.endUpdates()
    }

    private func updatePeripheralViews() {
        // Show the countdown ring only if a time-based token is active
        self.ring.hidden = (viewModel.ringProgress == nil)
        if let ringProgress = viewModel.ringProgress {
            ring.progress = ringProgress
        }

        let hasTokens = !viewModel.rowModels.isEmpty
        editButtonItem().enabled = hasTokens
        noTokensLabel.hidden = hasTokens

        // Exit editing mode if no tokens remain
        if self.editing && viewModel.rowModels.isEmpty {
            self.setEditing(false, animated: true)
        }
    }
}
