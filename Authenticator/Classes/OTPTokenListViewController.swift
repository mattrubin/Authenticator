//
//  OTPTokenListViewController.swift
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import MobileCoreServices
import OneTimePasswordLegacy

class OTPTokenListViewController: UITableViewController {

    let tokenManager = OTPTokenManager()
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
        self.ring.hidden = !self.tokenManager.hasTimeBasedTokens

        self.editButtonItem().enabled = (self.tokenManager.numberOfTokens > 0)
        self.noTokensLabel.hidden = (self.tokenManager.numberOfTokens > 0)
    }

    func tick() {
        // Update currently-visible cells
        for cell in self.tableView.visibleCells as! [TokenRowCell] {
            if let indexPath = self.tableView.indexPathForCell(cell) {
                updateCell(cell, forRowAtIndexPath: indexPath)
            }
        }

        let period = OTPToken.defaultPeriod
        self.ring.progress = fmod(NSDate().timeIntervalSince1970, period) / period;
    }

    // MARK: Target actions

    func addToken() {
        var entryController: UIViewController
        if Scanner.deviceCanScan {
            let scanner = OTPScannerViewController()
            scanner.delegate = self
            entryController = scanner
        } else {
            let form = TokenEntryForm(delegate: self)
            let formController = TokenFormViewController(form: form)
            entryController = formController
        }
        let navController = UINavigationController(rootViewController: entryController)
        navController.navigationBar.translucent = false

        self.presentViewController(navController, animated: true, completion: nil)
    }

}

extension OTPTokenListViewController /* UITableViewDataSource */ {

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.tokenManager.numberOfTokens)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(TokenRowCell.self), forIndexPath: indexPath) as! TokenRowCell
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    private func updateCell(cell: TokenRowCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let token = self.tokenManager.tokenAtIndexPath(indexPath)
        let rowModel = TokenRowModel(token: token, buttonAction: {
            token.updatePassword()
            self.tableView.reloadData()
        })
        cell.updateWithRowModel(rowModel)
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == .Delete) {
            if self.tokenManager.removeTokenAtIndexPath(indexPath) {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self.update()

                if (self.tokenManager.numberOfTokens == 0) {
                    self.setEditing(false, animated: true)
                }
            }
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        self.tokenManager.moveTokenFromIndexPath(sourceIndexPath, toIndexPath: destinationIndexPath)
    }

}

extension OTPTokenListViewController /* UITableViewDelegate */ {

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.editing {
            let token = self.tokenManager.tokenAtIndexPath(indexPath)
            let form = TokenEditForm(token: token, delegate: self)
            let editController = TokenFormViewController(form: form)
            let navController = UINavigationController(rootViewController: editController)
            navController.navigationBar.translucent = false

            self.presentViewController(navController, animated: true, completion: nil)
        } else {
            let token = self.tokenManager.tokenAtIndexPath(indexPath)
            if let password = token.password {
                UIPasteboard.generalPasteboard().setValue(password, forPasteboardType: kUTTypeUTF8PlainText as String)
                SVProgressHUD.showSuccessWithStatus("Copied")
            }
        }
    }

}

extension OTPTokenListViewController: TokenEditFormDelegate {
    func editFormDidCancel(form: TokenEditForm) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func form(form: TokenEditForm, didEditToken token: OTPToken) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.tableView.reloadData()
    }

}

extension OTPTokenListViewController: TokenEntryFormDelegate {
    func entryFormDidCancel(form: TokenEntryForm) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func form(form: TokenEntryForm, didCreateToken token: OTPToken) {
        self.tokenSource(form, didCreateToken: token)
    }
}

extension OTPTokenListViewController: OTPTokenSourceDelegate {
    func tokenSourceDidCancel(tokenSource: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func tokenSource(tokenSource: AnyObject, didCreateToken token: OTPToken) {
        self.dismissViewControllerAnimated(true, completion: nil)

        if self.tokenManager.addToken(token) {
            self.tableView.reloadData()
            self.update()

            // Scroll to the new token (added at the bottom)
            let section = self.numberOfSectionsInTableView(self.tableView) - 1
            let row = self.tableView(self.tableView, numberOfRowsInSection: section) - 1
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: row, inSection: section), atScrollPosition: .Middle, animated: true)
        }
    }

}
