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
    fileprivate let dispatchAction: (TokenList.Action) -> Void
    fileprivate var viewModel: TokenList.ViewModel
    fileprivate var ignoreTableViewUpdates = false

    init(viewModel: TokenList.ViewModel, dispatchAction: @escaping (TokenList.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate var searchBar = SearchField(
        frame: CGRect(
            origin: .zero,
            size: CGSize(width: 0, height: 44)
        )
    )

    fileprivate lazy var noTokensLabel: UILabel = {
        let title = "No Tokens"
        let message = "Tap + to add a new token"
        let titleAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20, weight: .light)]
        let messageAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17, weight: .light)]
        let plusAttributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 25, weight: .light)]

        let noTokenString = NSMutableAttributedString(string: title + "\n", attributes: titleAttributes)
        noTokenString.append(NSAttributedString(string: message, attributes: messageAttributes))
        noTokenString.addAttributes(plusAttributes, range: (noTokenString.string as NSString).range(of: "+"))

        let label = UILabel()
        label.numberOfLines = 2
        label.attributedText = noTokenString
        label.textAlignment = .center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    fileprivate lazy var noTokensButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(addToken), for: .touchUpInside)

        self.noTokensLabel.frame = button.bounds
        self.noTokensLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.addSubview(self.noTokensLabel)

        button.accessibilityLabel = "No Tokens"
        button.accessibilityHint = "Double-tap to add a new token."

        return button
    }()

    fileprivate let backupWarningLabel: UILabel = {
        let linkTitle = "Learn More →"
        let message = "For security reasons, tokens will be stored only on this \(UIDevice.current.model), and will not be included in iCloud or unencrypted backups.  \(linkTitle)"
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.paragraphSpacing = 5
        let attributedMessage = NSMutableAttributedString(string: message, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .light),
            .paragraphStyle: paragraphStyle,
            ])
        attributedMessage.addAttribute(.font, value: UIFont.italicSystemFont(ofSize: 15),
                                       range: (attributedMessage.string as NSString).range(of: "not"))
        attributedMessage.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 15),
                                       range: (attributedMessage.string as NSString).range(of: linkTitle))

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedMessage
        label.textAlignment = .center
        label.textColor = UIColor.otpForegroundColor
        return label
    }()

    fileprivate lazy var backupWarning: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(showBackupInfo), for: .touchUpInside)

        self.backupWarningLabel.frame = button.bounds
        self.backupWarningLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        button.addSubview(self.backupWarningLabel)

        button.accessibilityLabel = "For security reasons, tokens will be stored only on this \(UIDevice.current.model), and will not be included in iCloud or unencrypted backups."
        button.accessibilityHint = "Double-tap to learn more."

        return button
    }()

    private let infoButton = UIButton(type: .infoLight)

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.keyboardDismissMode = .interactive

        self.title = "Authenticator"
        self.view.backgroundColor = UIColor.otpBackgroundColor

        // Configure table view
        self.tableView.separatorStyle = .none
        self.tableView.indicatorStyle = .white
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        self.tableView.allowsSelectionDuringEditing = true

        // Configure navigation bar
        self.navigationItem.titleView = searchBar

        self.searchBar.delegate = self

        // Configure toolbar
        let addAction = #selector(TokenListViewController.addToken)
        self.toolbarItems = [
            self.editButtonItem,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(customView: infoButton),
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: addAction),
        ]
        self.navigationController?.isToolbarHidden = false

        // Configure empty state
        view.addSubview(noTokensButton)
        view.addSubview(backupWarning)

        infoButton.addTarget(self, action: #selector(TokenListViewController.showLicenseInfo), for: .touchUpInside)

        // Update with current viewModel
        self.updatePeripheralViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let searchSelector = #selector(TokenListViewController.filterTokens)
        searchBar.textField.addTarget(self, action: searchSelector, for: .editingChanged)
        searchBar.update(with: viewModel)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.isEditing = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let labelMargin: CGFloat = 20
        let insetBounds = view.bounds.insetBy(dx: labelMargin, dy: labelMargin)
        let noTokensLabelSize = noTokensLabel.sizeThatFits(insetBounds.size)
        let noTokensLabelOrigin = CGPoint(x: (view.bounds.width - noTokensLabelSize.width) / 2,
                                          y: (view.bounds.height * 0.6 - noTokensLabelSize.height) / 2)
        noTokensButton.frame = CGRect(origin: noTokensLabelOrigin, size: noTokensLabelSize)

        let labelSize = backupWarningLabel.sizeThatFits(insetBounds.size)
        let labelOrigin = CGPoint(x: labelMargin, y: view.bounds.maxY - labelMargin - labelSize.height)
        backupWarning.frame = CGRect(origin: labelOrigin, size: labelSize)
    }

    // MARK: Target Actions

    @objc
    func addToken() {
        dispatchAction(.beginAddToken)
    }

    @objc
    func filterTokens() {
        guard let filter = searchBar.text else {
            return dispatchAction(.clearFilter)
        }
        dispatchAction(.filter(filter))
    }

    @objc
    func showBackupInfo() {
        dispatchAction(.showBackupInfo)
    }

    @objc
    func showLicenseInfo() {
        dispatchAction(.showInfo)
    }
}

// MARK: UITableViewDataSource
extension TokenListViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.rowModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: TokenRowCell.self)
        updateCell(cell, forRowAtIndexPath: indexPath)
        return cell
    }

    fileprivate func updateCell(_ cell: TokenRowCell, forRowAtIndexPath indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        cell.update(with: rowModel)
        cell.dispatchAction = dispatchAction
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if tableView.isEditing {
            return .delete
        }
        // Disable swipe-to-delete when the table view is not in editing mode.
        return .none
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        switch editingStyle {
        case .delete:
            dispatchAction(rowModel.deleteAction)
        default:
            print("Unexpected edit style \(editingStyle.rawValue) for row at \(indexPath)")
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        ignoreTableViewUpdates = true
        dispatchAction(.moveToken(fromIndex: source.row, toIndex: destination.row))
        ignoreTableViewUpdates = false
    }

}

// MARK: UITableViewDelegate
extension TokenListViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rowModel = viewModel.rowModels[indexPath.row]
        if isEditing {
            dispatchAction(rowModel.editAction)
        } else {
            dispatchAction(rowModel.selectAction)
        }
    }
}

// MARK: TokenListPresenter
extension TokenListViewController {
    func update(with viewModel: TokenList.ViewModel) {
        let changes = changesFrom(self.viewModel.rowModels, to: viewModel.rowModels)
        let filtering = viewModel.isFiltering || self.viewModel.isFiltering
        self.viewModel = viewModel

        if filtering && !changes.isEmpty {
            tableView.reloadData()
        } else if !ignoreTableViewUpdates {
            let sectionIndex = 0
            let tableViewChanges = changes.map({ change in
                change.map({ row in
                    IndexPath(row: row, section: sectionIndex)
                })
            })
            tableView.applyChanges(tableViewChanges, updateRow: { indexPath in
                if let cell = tableView.cellForRow(at: indexPath) as? TokenRowCell {
                    updateCell(cell, forRowAtIndexPath: indexPath)
                }
            })
        }
        updatePeripheralViews()
    }

    fileprivate func updatePeripheralViews() {
        searchBar.update(with: viewModel)

        tableView.isScrollEnabled = viewModel.hasTokens
        editButtonItem.isEnabled = viewModel.hasTokens
        noTokensButton.isHidden = viewModel.hasTokens
        backupWarning.isHidden = viewModel.hasTokens

        // Exit editing mode if no tokens remain
        if self.isEditing && viewModel.rowModels.isEmpty {
            self.setEditing(false, animated: true)
        }
    }
}

extension TokenListViewController: UITextFieldDelegate {
    // Dismisses keyboard when return is pressed
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

}
