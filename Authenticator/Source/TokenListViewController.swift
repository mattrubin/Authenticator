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
    private let dispatchAction: (TokenList.Action) -> ()
    private var viewModel: TokenList.ViewModel
    private var ignoreTableViewUpdates = false

    init(viewModel: TokenList.ViewModel, dispatchAction: (TokenList.Action) -> ()) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var displayLink: CADisplayLink?
    private var searchBar = SearchField(
        frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: 44)
        )
    )

    private lazy var noTokensLabel: UILabel = {
        // swiftlint:disable force_unwrapping
        let noTokenString = NSMutableAttributedString(string: "No Tokens\n",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)!])
        noTokenString.appendAttributedString(NSAttributedString(string: "Tap + to add a new token",
            attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)!]))
        noTokenString.addAttributes(
            [NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 25)!],
            range: (noTokenString.string as NSString).rangeOfString("+"))
        // swiftlint:enable force_unwrapping

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
            UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: addAction)
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

        // Update with current viewModel
        self.updatePeripheralViews()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let searchSelector = #selector(TokenListViewController.filterTokens)
        searchBar.textField.addTarget(self,
                                      action: searchSelector,
                                      forControlEvents: .EditingChanged)

        let selector = #selector(TokenListViewController.tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
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

    func filterTokens() {
        guard let filter = searchBar.text else {
            return dispatchAction(.ClearFilter)
        }
        dispatchAction(.Filter(filter))
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

        if filtering {
            tableView.reloadData()
        } else {
            updateTableViewWithChanges(changes)
        }
        updatePeripheralViews()
    }

    private func updateTableViewWithChanges(changes: [Change]) {
        if changes.isEmpty || ignoreTableViewUpdates {
            return
        }

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

        let sectionIndex = 0

        // Only perform a table view updates group if there are changes which require animations.
        if changesNeedAnimations {
            tableView.beginUpdates()
            for change in changes {
                switch change {
                case .Insert(let rowIndex):
                    let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                    tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                case .Delete(let rowIndex):
                    let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                case .Update:
                    break
                }
            }
            tableView.endUpdates()
        }

        // After applying the changes which require animations, update any visible cells whose
        // contents have changed.
        applyRowUpdates(fromChanges: changes, inSection: sectionIndex)

        scrollToFirstInsertedRow(fromChanges: changes, inSection: sectionIndex)
    }

    /// From among the given `Change`s, applies the `Update`s to cells at the new row indexes in the
    /// given `section`. This method should be used only *after* insertions, deletions, and moves
    /// have been applied.
    /// - parameter changes: An `Array` of `Change`s, from which `Update`s will be applied.
    /// - parameter section: The index of the table view section which contains the changes.
    private func applyRowUpdates(fromChanges changes: [Change], inSection section: Int) {
        for change in changes {
            switch change {
            case let .Update(_, row):
                let indexPath = NSIndexPath(forRow: row, inSection: section)
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TokenRowCell {
                    updateCell(cell, forRowAtIndexPath: indexPath)
                }
            case .Insert, .Delete:
                break
            }
        }
    }

    /// From among the given `Change`s, finds the first `Insert` and scrolls to that row in the
    /// given `section` in the table view. This method should be used only *after* the changes have
    /// been applied.
    /// - parameter changes: An `Array` of `Change`s, in which the first `Insert` will be found.
    /// - parameter section: The index of the table view section which contains the changes.
    private func scrollToFirstInsertedRow(fromChanges changes: [Change], inSection section: Int) {
        var firstInsertRow = -1

        for change in changes {
            switch change {
            case let .Insert(row):
                if firstInsertRow == -1 || row < firstInsertRow {
                    firstInsertRow = row
                }
            case .Delete, .Update:
                break
            }
        }

        // If firstInsertRow has a value > -1 then a row was inserted
        if firstInsertRow > -1 {
            let indexPath = NSIndexPath(forRow: firstInsertRow, inSection: section)
            // Scrolls to the newly inserted token at the smallest row index in the tableView
            // using the minimum amount of scrolling necessary (.None)
            tableView.scrollToRowAtIndexPath(indexPath,
                                             atScrollPosition: .None,
                                             animated: true)
        }
    }

    private func updatePeripheralViews() {

        searchBar.updateWithViewModel(viewModel)

        editButtonItem().enabled = viewModel.hasTokens
        noTokensLabel.hidden = viewModel.hasTokens

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
