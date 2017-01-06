//
//  TokenFormViewController.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
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

class TokenFormViewController<Form: TableViewModelRepresentable where Form.HeaderModel == TokenFormHeaderModel<Form.Action>, Form.RowModel == TokenFormRowModel<Form.Action>>: UITableViewController {
    private let dispatchAction: (Form.Action) -> Void
    private var viewModel: TableViewModel<Form> {
        didSet {
            guard oldValue.sections.count == viewModel.sections.count else {
                // Automatic updates aren't implemented for changing number of sections
                tableView.reloadData()
                return
            }

            let changes = viewModel.sections.indices.flatMap { sectionIndex -> [Change<NSIndexPath>] in
                let oldSection = oldValue.sections[sectionIndex]
                let newSection = viewModel.sections[sectionIndex]
                let changes = changesFrom(oldSection.rows, to: newSection.rows)
                return changes.map({ change in
                    change.map({ row in
                        NSIndexPath(forRow: row, inSection: sectionIndex)
                    })
                })
            }
            tableView.applyChanges(changes, updateRow: updateRowAtIndexPath)
        }
    }

    init(viewModel: TableViewModel<Form>, dispatchAction: (Form.Action) -> Void) {
        self.viewModel = viewModel
        self.dispatchAction = dispatchAction
        super.init(style: .Grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .otpBackgroundColor
        view.tintColor = .otpForegroundColor
        tableView.separatorStyle = .None

        // Set up top bar
        title = viewModel.title
        updateBarButtonItems()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if Process.isDemo {
            // If this is a demo, don't show the keyboard.
            return
        }

        focusFirstField()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        unfocus()
    }

    // MARK: Focus

    private func focusFirstField() -> Bool {
        for cell in tableView.visibleCells {
            if let focusCell = cell as? FocusCell {
                return focusCell.focus()
            }
        }
        return false
    }

    private func nextVisibleFocusCellAfterIndexPath(currentIndexPath: NSIndexPath) -> FocusCell? {
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            for indexPath in visibleIndexPaths {
                if currentIndexPath.compare(indexPath) == .OrderedAscending {
                    if let focusCell = tableView.cellForRowAtIndexPath(indexPath) as? FocusCell {
                        return focusCell
                    }
                }
            }
        }
        return nil
    }

    private func unfocus() -> Bool {
        return view.endEditing(false)
    }

    // MARK: - Target Actions

    func leftBarButtonAction() {
        if let action = viewModel.leftBarButton?.action {
            dispatchAction(action)
        }
    }

    func rightBarButtonAction() {
        if let action = viewModel.rightBarButton?.action {
            dispatchAction(action)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let rowModel = viewModel.modelForRowAtIndexPath(indexPath) else {
            return UITableViewCell()
        }
        return cellForRowModel(rowModel, inTableView: tableView)
    }

    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
        cell.selectionStyle = .None

        cell.textLabel?.textColor = .otpForegroundColor
        if let cell = cell as? TextFieldRowCell<Form.Action> {
            cell.textField.backgroundColor = .otpLightColor
            cell.textField.tintColor = .otpDarkColor
            cell.delegate = self
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let rowModel = viewModel.modelForRowAtIndexPath(indexPath) else {
            return 0
        }
        return heightForRowModel(rowModel)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerModel = viewModel.modelForHeaderInSection(section) else {
            return CGFloat(FLT_EPSILON)
        }
        return heightForHeaderModel(headerModel)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerModel = viewModel.modelForHeaderInSection(section) else {
            return nil
        }
        return viewForHeaderModel(headerModel)
    }
}

// MARK: - View Model Helpers

extension TokenFormViewController {
    // MARK: Bar Button View Model

    private func barButtonItemForViewModel(viewModel: BarButtonViewModel<Form.Action>, target: AnyObject?, action: Selector) -> UIBarButtonItem {
        func systemItemForStyle(style: BarButtonStyle) -> UIBarButtonSystemItem {
            switch style {
            case .Done:
                return .Done
            case .Cancel:
                return .Cancel
            }
        }

        let barButtonItem = UIBarButtonItem(
            barButtonSystemItem: systemItemForStyle(viewModel.style),
            target: target,
            action: action
        )
        barButtonItem.enabled = viewModel.enabled
        return barButtonItem
    }

    func updateBarButtonItems() {
        navigationItem.leftBarButtonItem = viewModel.leftBarButton.map { (viewModel) in
            let action = #selector(TokenFormViewController.leftBarButtonAction)
            return barButtonItemForViewModel(viewModel, target: self, action: action)
        }
        navigationItem.rightBarButtonItem = viewModel.rightBarButton.map { (viewModel) in
            let action = #selector(TokenFormViewController.rightBarButtonAction)
            return barButtonItemForViewModel(viewModel, target: self, action: action)
        }
    }

    // MARK: Row Model

    func cellForRowModel(rowModel: Form.RowModel, inTableView tableView: UITableView) -> UITableViewCell {
        switch rowModel {
        case let .TextFieldRow(row):
            let cell = tableView.dequeueReusableCellWithClass(TextFieldRowCell<Form.Action>.self)
            cell.updateWithViewModel(row.viewModel)
            cell.dispatchAction = dispatchAction
            cell.delegate = self
            return cell

        case let .SegmentedControlRow(row):
            let cell = tableView.dequeueReusableCellWithClass(SegmentedControlRowCell<Form.Action>.self)
            cell.updateWithViewModel(row.viewModel)
            cell.dispatchAction = dispatchAction
            return cell
        }
    }

    func updateRowAtIndexPath(indexPath: NSIndexPath) {
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else {
            // If the given row is not visible, the table view will have no cell for it, and it
            // doesn't need to be updated.
            return
        }
        guard let rowModel = viewModel.modelForRowAtIndexPath(indexPath) else {
            // If there is no row model for the given index path, just tell the table view to
            // reload it and hope for the best.
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            return
        }

        switch rowModel {
        case let .TextFieldRow(row):
            if let cell = cell as? TextFieldRowCell<Form.Action> {
                cell.updateWithViewModel(row.viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case let .SegmentedControlRow(row):
            if let cell = cell as? SegmentedControlRowCell<Form.Action> {
                cell.updateWithViewModel(row.viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }

    func heightForRowModel(rowModel: Form.RowModel) -> CGFloat {
        switch rowModel {
        case let .TextFieldRow(row):
            return TextFieldRowCell<Form.Action>.heightWithViewModel(row.viewModel)
        case let .SegmentedControlRow(row):
            return SegmentedControlRowCell<Form.Action>.heightWithViewModel(row.viewModel)
        }
    }

    // MARK: Header Model

    func viewForHeaderModel(headerModel: Form.HeaderModel) -> UIView {
        switch headerModel {
        case let .ButtonHeader(header):
            return ButtonHeaderView(viewModel: header.viewModel, dispatchAction: dispatchAction)
        }
    }

    func heightForHeaderModel(headerModel: Form.HeaderModel) -> CGFloat {
        switch headerModel {
        case let .ButtonHeader(header):
            return ButtonHeaderView.heightWithViewModel(header.viewModel)
        }
    }
}

extension TokenFormViewController {
    func updateWithViewModel(viewModel: TableViewModel<Form>) {
        self.viewModel = viewModel
        updateBarButtonItems()
    }
}

extension TokenFormViewController: TextFieldRowCellDelegate {
    func textFieldCellDidReturn<Action>(textFieldCell: TextFieldRowCell<Action>) {
        // Unfocus the field that returned
        textFieldCell.unfocus()

        // Avoid a SwiftLint bug (https://github.com/realm/SwiftLint/issues/784)
        // swiftlint:disable:next conditional_returns_on_newline
        if textFieldCell.textField.returnKeyType == .Next {
            // Try to focus the next text field cell
            if let currentIndexPath = tableView.indexPathForCell(textFieldCell) {
                if let nextFocusCell = nextVisibleFocusCellAfterIndexPath(currentIndexPath) {
                    nextFocusCell.focus()
                }
            }
            // Avoid a SwiftLint bug (https://github.com/realm/SwiftLint/issues/784)
            // swiftlint:disable:next conditional_returns_on_newline
        } else if textFieldCell.textField.returnKeyType == .Done {
            // Try to submit the form
            dispatchAction(viewModel.doneKeyAction)
        }
    }
}
