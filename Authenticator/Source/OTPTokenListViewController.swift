//
//  OTPTokenListViewController.swift
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
import MobileCoreServices
import OneTimePassword
import SVProgressHUD

class OTPTokenListViewController: UITableViewController, TokenRowDelegate {

    let tokenManager = TokenManager()
    var displayLink: CADisplayLink?
    let ring: OTPProgressRing = OTPProgressRing(frame: CGRectMake(0, 0, 22, 22))
    private var ringPeriod: NSTimeInterval?
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

        self.update()
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

    func update() {
        // Show the countdown ring only if a time-based token is active
        ringPeriod = self.tokenManager.timeBasedTokenPeriods.first
        self.ring.hidden = (ringPeriod == nil)

        let hasTokens = (self.tokenManager.numberOfTokens > 0)
        editButtonItem().enabled = hasTokens
        noTokensLabel.hidden = hasTokens
    }

    func tick() {
        // Update currently-visible cells
        for cell in self.tableView.visibleCells {
            if let cell = cell as? TokenRowCell,
                let indexPath = self.tableView.indexPathForCell(cell) {
                    updateCell(cell, forRowAtIndexPath: indexPath)
            }
        }

        if let period = ringPeriod where period > 0 {
            self.ring.progress = fmod(NSDate().timeIntervalSince1970, period) / period
        } else {
            self.ring.progress = 0
        }
    }

    // MARK: Target actions

    func addToken() {
        if QRScanner.deviceCanScan {
            let scannerViewController = TokenScannerViewController() { [weak self] (event) in
                switch event {
                case .Save(let token):
                    self?.saveNewToken(token)
                case .Close:
                    self?.dismissViewController()
                }
            }
            presentViewController(scannerViewController)
        } else {
            let form = TokenEntryForm() { [weak self] (event) in
                switch event {
                case .Save(let token):
                    self?.saveNewToken(token)
                case .Close:
                    self?.dismissViewController()
                }
            }
            let formController = TokenFormViewController(form: form)
            presentViewController(formController)
        }
    }

}

extension OTPTokenListViewController /* UITableViewDataSource */ {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tokenManager.numberOfTokens
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(TokenRowCell.self), forIndexPath: indexPath)
        if let cell = cell as? TokenRowCell {
            updateCell(cell, forRowAtIndexPath: indexPath)
        }
        return cell
    }

    private func updateCell(cell: TokenRowCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let persistentToken = tokenManager.persistentTokenAtIndex(indexPath.row)
        let rowModel = TokenRowModel(persistentToken: persistentToken)
        cell.updateWithRowModel(rowModel)
        cell.delegate = self
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            do {
                try tokenManager.removeTokenAtIndex(indexPath.row)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.update()

                if self.tokenManager.numberOfTokens == 0 {
                    self.setEditing(false, animated: true)
                }
            } catch {
                // TODO: Handle the removeTokenAtIndex(_:) failure
            }
        }
    }

    override func tableView(tableView: UITableView,
        moveRowAtIndexPath sourceIndexPath: NSIndexPath,
        toIndexPath destinationIndexPath: NSIndexPath)
    {
        self.tokenManager.moveTokenFromIndex(sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }

}

extension OTPTokenListViewController /* UITableViewDelegate */ {

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }

    // MARK: TokenRowDelegate

    func handleAction(action: TokenRowModel.Action) {
        switch action {
        case .UpdatePersistentToken(let persistentToken):
            updatePersistentToken(persistentToken)
        case .CopyPassword(let password):
            copyPassword(password)
        case .EditPersistentToken(let persistentToken):
            editPersistentToken(persistentToken)
        }
    }

    private func updatePersistentToken(persistentToken: PersistentToken) {
        let newToken = persistentToken.token.updatedToken()
        saveToken(newToken, toPersistentToken: persistentToken)
    }

    private func copyPassword(password: String) {
        let pasteboard = UIPasteboard.generalPasteboard()
        pasteboard.setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
        SVProgressHUD.showSuccessWithStatus("Copied")
    }

    private func editPersistentToken(persistentToken: PersistentToken) {
        let form = TokenEditForm(token: persistentToken.token) { [weak self] (event) in
            switch event {
            case .Save(let token):
                self?.saveToken(token, toPersistentToken: persistentToken)
            case .Close:
                self?.dismissViewController()
            }
        }
        let editController = TokenFormViewController(form: form)
        presentViewController(editController)
    }

    private func saveToken(token: Token, toPersistentToken persistentToken: PersistentToken) {
        do {
            try tokenManager.saveToken(token, toPersistentToken: persistentToken)
            tableView.reloadData()
        } catch {
            // TODO: Handle the saveToken(_:toPersistentToken:) failure
        }
    }

    func saveNewToken(token: Token) {
        do {
            try tokenManager.addToken(token)
            self.tableView.reloadData()
            self.update()

            // Scroll to the new token (added at the bottom)
            let section = self.numberOfSectionsInTableView(self.tableView) - 1
            let row = self.tableView(self.tableView, numberOfRowsInSection: section) - 1
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: row, inSection: section), atScrollPosition: .Middle, animated: true)
        } catch {
            // TODO: Handle the addToken(_:) failure
        }
    }

    // MARK: Modals

    func presentViewController(viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.translucent = false
        presentViewController(navController, animated: true, completion: nil)
    }

    func dismissViewController() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
