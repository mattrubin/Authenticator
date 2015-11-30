//
//  TokenListViewController.swift
//  Authenticator
//
//  Copyright (c) 2013-2015 Authenticator authors
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
import OneTimePassword
import SVProgressHUD

class TokenListViewController: UITableViewController, TokenRowDelegate {
    private weak var delegate: TokenListDelegate?
    private var viewModel: TokenListViewModel
    private var preventTableViewAnimations = false

    init(viewModel: TokenListViewModel, delegate: TokenListDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var displayLink: CADisplayLink?
    let ring: OTPProgressRing = OTPProgressRing(frame: CGRectMake(0, 0, 22, 22))
    let noTokensLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        self.tableView.registerClass(TokenRowCell.self, forCellReuseIdentifier: NSStringFromClass(TokenRowCell.self))

        self.tableView.separatorStyle = .None
        self.tableView.indicatorStyle = .White

        let ringBarItem = UIBarButtonItem(customView: self.ring)
        self.navigationItem.leftBarButtonItem = ringBarItem

        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("addToken"))
        self.toolbarItems = [
            self.editButtonItem(),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
            addButtonItem
        ]
        self.navigationController?.toolbarHidden = false

        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        self.tableView.allowsSelectionDuringEditing = true

        self.noTokensLabel.numberOfLines = 2
        let noTokenString = NSMutableAttributedString(string: "No Tokens\n",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)!])
        noTokenString.appendAttributedString(NSAttributedString(string: "Tap + to add a new token",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)!]))
        noTokenString.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!],
            range: (noTokenString.string as NSString).rangeOfString("+"))
        self.noTokensLabel.attributedText = noTokenString
        self.noTokensLabel.textAlignment = .Center
        self.noTokensLabel.textColor = UIColor.otpForegroundColor
        self.noTokensLabel.frame = CGRectMake(0, 0,
            self.view.bounds.size.width,
            self.view.bounds.size.height * 0.6)
        self.view.addSubview(self.noTokensLabel)

        self.updatePeripheralViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.displayLink = CADisplayLink(target: self, selector: Selector("tick"))
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

    // MARK: Update

    func updatePeripheralViews() {
        // Show the countdown ring only if a time-based token is active
        self.ring.hidden = (viewModel.ringPeriod == nil)

        let hasTokens = !viewModel.rowModels.isEmpty
        editButtonItem().enabled = hasTokens
        noTokensLabel.hidden = hasTokens

        // Exit editing mode if no tokens remain
        if self.editing && viewModel.rowModels.isEmpty {
            self.setEditing(false, animated: true)
        }
    }

    func tick() {
        // Update currently-visible cells
        delegate?.updateViewModel()

        if let period = viewModel.ringPeriod where period > 0 {
            self.ring.progress = fmod(NSDate().timeIntervalSince1970, period) / period
        } else {
            self.ring.progress = 0
        }
    }

    // MARK: Target actions

    func addToken() {
        delegate?.beginAddToken()
    }
}

extension TokenListViewController /* UITableViewDataSource */ {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(TokenRowCell.self), forIndexPath: indexPath)
        if let cell = cell as? TokenRowCell {
            updateCell(cell, forRowAtIndexPath: indexPath)
        }
        return cell
    }

    private func updateCell(cell: TokenRowCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
        cell.delegate = self
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            delegate?.deleteTokenAtIndex(indexPath.row)
        }
    }

    override func tableView(tableView: UITableView,
        moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath)
    {
        preventTableViewAnimations = true
        delegate?.moveTokenFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
        preventTableViewAnimations = false
    }

}

extension TokenListViewController /* UITableViewDelegate */ {

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }

    // MARK: TokenRowDelegate

    func handleAction(action: TokenRowModel.Action) {
        switch action {
        case .UpdatePersistentToken(let persistentToken):
            delegate?.updatePersistentToken(persistentToken)
        case .CopyPassword(let password):
            delegate?.copyPassword(password)
        case .EditPersistentToken(let persistentToken):
            delegate?.beginEditPersistentToken(persistentToken)
        }
    }
}

extension TokenListViewController: TokenListPresenter {
    func updateWithViewModel(viewModel: TokenListViewModel, ephemeralMessage: EphemeralMessage?) {
        let changes = changesFrom(self.viewModel.rowModels, to: viewModel.rowModels)
        self.viewModel = viewModel
        updateTableViewWithChanges(changes)
        updatePeripheralViews()
        // Show ephemeral message
        if let ephemeralMessage = ephemeralMessage {
            switch ephemeralMessage {
            case .Success(let message):
                SVProgressHUD.showSuccessWithStatus(message)
            case .Error(let message):
                SVProgressHUD.showErrorWithStatus(message)
            }
        }
    }

    func updateTableViewWithChanges(changes: [Change]) {
        if preventTableViewAnimations {
            return
        }

        tableView.beginUpdates()
        let sectionIndex = 0
        for change in changes {
            switch change {
            case .Insert(let rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            case .Update(let rowIndex):
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
}
