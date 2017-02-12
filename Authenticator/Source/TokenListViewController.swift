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

class TokenListViewController: UITableViewController {
    private let dispatchAction: (TokenList.Action) -> Void
    private var viewModel: TokenList.ViewModel
    private var ignoreTableViewUpdates = false

    init(viewModel: TokenList.ViewModel, dispatchAction: (TokenList.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var searchBar = SearchField(
        frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: 44)
        )
    )

    private lazy var noTokensLabel: UILabel = {
        let title = "No Tokens"
        let message = "Tap + to add a new token"
        let titleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(20, weight: UIFontWeightLight)]
        let messageAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(17, weight: UIFontWeightLight)]
        let plusAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(25, weight: UIFontWeightLight)]

        let noTokenString = NSMutableAttributedString(string: title + "\n", attributes: titleAttributes)
        noTokenString.appendAttributedString(NSAttributedString(string: message, attributes: messageAttributes))
        noTokenString.addAttributes(plusAttributes, range: (noTokenString.string as NSString).rangeOfString("+"))

        let label = UILabel()
        label.numberOfLines = 2
        label.attributedText = noTokenString
        label.textAlignment = .Center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    private let warningLabel: UILabel = {
        let linkTitle = "Learn More →"
        let message = "For security reasons, tokens will be stored only on this \(UIDevice.currentDevice().model), and will not be included in iCloud or unencrypted backups.  \(linkTitle)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.paragraphSpacing = 5
        let attributedMessage = NSMutableAttributedString(string: message, attributes: [
            NSFontAttributeName: UIFont.systemFontOfSize(15, weight: UIFontWeightLight),
            NSParagraphStyleAttributeName: paragraphStyle,
            ])
        attributedMessage.addAttribute(NSFontAttributeName, value: UIFont.italicSystemFontOfSize(15),
                                       range: (attributedMessage.string as NSString).rangeOfString("not"))
        attributedMessage.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(15),
                                       range: (attributedMessage.string as NSString).rangeOfString(linkTitle))

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedMessage
        label.textAlignment = .Center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    private let warningButton: UIButton = {
        let button = UIButton(type: .Custom)
        return button
    }()

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.keyboardDismissMode = .Interactive

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        // Configure table view
        self.tableView.separatorStyle = .None
        self.tableView.indicatorStyle = .White
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelectionDuringEditing = true

        // Configure navigation bar
        self.navigationItem.titleView = searchBar

        self.searchBar.delegate = self

        // Configure toolbar
        let addAction = #selector(TokenListViewController.addToken)
        self.toolbarItems = [
            self.editButtonItem(),
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: addAction),
        ]
        self.navigationController?.toolbarHidden = false

        // Configure "no tokens" label
        self.noTokensLabel.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.bounds.size.width,
            height: self.view.bounds.size.height * 0.6
        )
        self.view.addSubview(self.noTokensLabel)

        let labelMargin: CGFloat = 20
        let labelSize = warningLabel.sizeThatFits(view.bounds.insetBy(dx: labelMargin, dy: labelMargin).size)
        let labelOrigin = CGPoint(x: labelMargin, y: view.bounds.maxY - labelMargin - labelSize.height)
        warningLabel.frame = CGRect(origin: labelOrigin, size: labelSize)
        warningLabel.autoresizingMask = [.FlexibleTopMargin, .FlexibleWidth]
        view.addSubview(warningLabel)

        let warningButton = UIButton()
        warningButton.frame = warningLabel.frame
        warningButton.autoresizingMask = warningLabel.autoresizingMask
        warningButton.addTarget(self, action: #selector(showBackupInfo), forControlEvents: .TouchUpInside)
        view.addSubview(warningButton)

        // Update with current viewModel
        self.updatePeripheralViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let searchSelector = #selector(TokenListViewController.filterTokens)
        searchBar.textField.addTarget(self,
                                      action: searchSelector,
                                      forControlEvents: .EditingChanged)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.editing = false
    }

    // MARK: Target Actions

    func addToken() {
        dispatchAction(.BeginAddToken)
    }

    func filterTokens() {
        guard let filter = searchBar.text else {
            return dispatchAction(.ClearFilter)
        }
        dispatchAction(.Filter(filter))
    }

    func showBackupInfo() {
        dispatchAction(.ShowBackupInfo)
    }
}

// MARK: UITableViewDataSource
extension TokenListViewController {

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithClass(TokenRowCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    private func updateCell(cell: TokenRowCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.updateWithRowModel(rowModel)
        cell.dispatchAction = dispatchAction
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        if editingStyle == .Delete {
            dispatchAction(rowModel.deleteAction)
        }
    }

    override func tableView(tableView: UITableView, moveRowAtIndexPath source: NSIndexPath, toIndexPath destination: NSIndexPath) {
        ignoreTableViewUpdates = true
        dispatchAction(.MoveToken(fromIndex: source.row, toIndex: destination.row))
        ignoreTableViewUpdates = false
    }

}

// MARK: UITableViewDelegate
extension TokenListViewController {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }
}

// MARK: TokenListPresenter
extension TokenListViewController {
    func updateWithViewModel(viewModel: TokenList.ViewModel) {
        let changes = changesFrom(self.viewModel.rowModels, to: viewModel.rowModels)
        let filtering = viewModel.isFiltering || self.viewModel.isFiltering
        self.viewModel = viewModel

        if filtering && !changes.isEmpty {
            tableView.reloadData()
        } else if !ignoreTableViewUpdates {
            let sectionIndex = 0
            let tableViewChanges = changes.map({ change in
                change.map({ row in
                    NSIndexPath(forRow: row, inSection: sectionIndex)
                })
            })
            tableView.applyChanges(tableViewChanges, updateRow: { indexPath in
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TokenRowCell {
                    updateCell(cell, forRowAtIndexPath: indexPath)
                }
            })
        }
        updatePeripheralViews()
    }

    private func updatePeripheralViews() {

        searchBar.updateWithViewModel(viewModel)

        editButtonItem().enabled = viewModel.hasTokens
        noTokensLabel.hidden = viewModel.hasTokens
        warningLabel.hidden = viewModel.hasTokens

        // Exit editing mode if no tokens remain
        if self.editing && viewModel.rowModels.isEmpty {
            self.setEditing(false, animated: true)
        }
    }
}

extension TokenListViewController: UITextFieldDelegate {
    // Dismisses keyboard when return is pressed
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
