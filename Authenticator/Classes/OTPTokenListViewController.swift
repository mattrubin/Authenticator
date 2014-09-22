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

class OTPTokenListViewController: _OTPTokenListViewController {

    var displayLink: CADisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        self.tableView.registerClass(OTPTokenCell.self, forCellReuseIdentifier: NSStringFromClass(OTPTokenCell.self))

        self.tableView.separatorStyle = .None
        self.tableView.indicatorStyle = .White

        self.ring = OTPProgressRing(frame: CGRectMake(0, 0, 22, 22))
        let ringBarItem = UIBarButtonItem(customView: self.ring)
        self.navigationItem.leftBarButtonItem = ringBarItem

        self.addButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addToken")
        self.toolbarItems = [
            self.editButtonItem(),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
            self.addButtonItem
        ]
        self.navigationController?.toolbarHidden = false

        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        self.tableView.allowsSelectionDuringEditing = true

        self.noTokensLabel = UILabel()
        self.noTokensLabel.numberOfLines = 2
        let noTokenString = NSMutableAttributedString(string: "No Tokens\n",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)])
        noTokenString.appendAttributedString(NSAttributedString(string: "Tap + to add a new token",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)]))
        noTokenString.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)],
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

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.displayLink?.invalidate()
        self.displayLink = nil
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.tokenManager.numberOfTokens)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(OTPTokenCell.self), forIndexPath: indexPath) as OTPTokenCell
        cell.delegate = self

        let token = self.tokenManager.tokenAtIndexPath(indexPath)
        cell.setName(token.name, issuer: token.issuer)
        cell.setPassword(token.password)
        cell.setShowsButton((token.type == .Counter))

        return cell
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

extension OTPTokenListViewController: OTPTokenCellDelegate {

    func buttonTappedForCell(cell: UITableViewCell!) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            let token = self.tokenManager.tokenAtIndexPath(indexPath)
            token.updatePassword()
            self.tableView.reloadData()
        }
    }

}
