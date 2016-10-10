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
    private var searchBar = SearchField(frame: CGRect(
        origin: .zero,
        size: CGSize(width: 0, height: 44 )))
    private var ring: OTPProgressRing {
        get { return searchBar.ring }
    }
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

        NSNotificationCenter
            .defaultCenter()
            .addObserver(self,
                         selector: #selector(onTextFieldUpdated),
                         name: UITextFieldTextDidChangeNotification,
                         object: searchBar.textField)

        let selector = #selector(TokenListViewController.tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        NSNotificationCenter.defaultCenter().removeObserver(self)

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
        preventTableViewAnimations = true
        dispatchAction(.MoveToken(fromIndex: source.row, toIndex: destination.row))
        preventTableViewAnimations = false
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
        updateTableViewWithChanges(changes, whileFiltering: filtering )
        updatePeripheralViews()
    }

    private func updateTableViewWithChanges(changes: [Change],
                                            whileFiltering isFiltering: Bool = false) {
        // TODO: Scroll to a newly added token (added at the bottom)
        if changes.isEmpty || preventTableViewAnimations {
            return
        }

        if isFiltering {
            tableView.reloadData()
            return
        }

        tableView.beginUpdates()
        let sectionIndex = 0
        for change in changes {
            switch change {
            case .Insert(let rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            case let .Update(_, rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TokenRowCell {
                    updateCell(cell, forRowAtIndexPath: indexPath)
                } else {
                    tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            case .Delete(let rowIndex):
                let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
        tableView.endUpdates()
    }

    private func updatePeripheralViews() {
        let hasTokens = viewModel.totalTokens > 0
        // Show the countdown ring only if a time-based token is active
        searchBar.textField.leftViewMode = hasTokens ? .Always : .Never
        searchBar.textField.enabled = hasTokens
        searchBar.textField.backgroundColor = hasTokens ?
            UIColor.otpLightColor.colorWithAlphaComponent(0.1) : UIColor.clearColor()
        if let ringProgress = viewModel.ringProgress {
            ring.progress = ringProgress
        }

        editButtonItem().enabled = hasTokens
        noTokensLabel.hidden = hasTokens

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

    // Responds to NSNotification posted by the textField when the content is changed
    func onTextFieldUpdated(notification: NSNotification) {
        if let filter = self.searchBar.text {
            dispatchAction(.Filter(filter))
        } else {
            dispatchAction(.ClearFilter())
        }
    }

}

// MARK: Custom search field for navigation bar

class SearchField: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTextField()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTextField()
    }

    var delegate: UITextFieldDelegate? {
        get { return textField.delegate }
        set { textField.delegate = newValue }
    }

    var text: String? {
        get { return textField.text }
    }

    let ring = OTPProgressRing(
        frame: CGRect(origin: .zero, size: CGSize(width: 22, height: 22))
    )

    let textField: UITextField = SearchTextField()

    private func setupTextField() {
        ring.tintColor = UIColor.otpLightColor
        let placeHolderAttributes = [
            NSForegroundColorAttributeName: UIColor.otpLightColor,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 16)!
        ]
        textField.attributedPlaceholder = NSAttributedString(
            string: "Authenticator",
            attributes: placeHolderAttributes
        )
        textField.textColor = UIColor.otpLightColor
        textField.backgroundColor = UIColor.otpLightColor.colorWithAlphaComponent(0.2)
        textField.leftView = ring
        textField.leftViewMode = .Always
        textField.borderStyle = .RoundedRect
        textField.clearButtonMode = .WhileEditing
        textField.autocorrectionType = .No
        textField.autocapitalizationType = .None
        textField.keyboardAppearance = .Dark
        textField.sizeToFit()
        addSubview(textField)
    }

    override func intrinsicContentSize() -> CGSize {
        return ring.frame.union(textField.frame).size
    }

    override func alignmentRectForFrame(frame: CGRect) -> CGRect {
        return super.alignmentRectForFrame(frame)
    }

    override func sizeThatFits(size: CGSize) -> CGSize {
        let fieldSize = textField.frame.size
        let fits = CGSize(width: max(size.width, fieldSize.width), height: fieldSize.height)
        return fits
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // center the text field
        var textFieldFrame = textField.frame
        textFieldFrame.size.width = bounds.size.width
        textField.frame = textFieldFrame
        textField.center = CGPoint(x: bounds.size.width * 0.5, y: bounds.size.height * 0.5)
    }

}

class SearchTextField: UITextField {
    override func leftViewRectForBounds(bounds: CGRect) -> CGRect {
        return super.leftViewRectForBounds(bounds).offsetBy(dx: 6, dy: 0)
    }

    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        if self.isFirstResponder() {
            return .zero
        }
        var rect = super.placeholderRectForBounds(bounds)
        if let size = attributedPlaceholder?.size() {
            rect.size.width = size.width
            rect.origin.x = ( bounds.size.width - rect.size.width ) * 0.5
        }
        return rect
    }
}
