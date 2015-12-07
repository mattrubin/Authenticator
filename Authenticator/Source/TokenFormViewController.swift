//
//  TokenFormViewController.swift
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
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
import SVProgressHUD

class TokenFormViewController: UITableViewController {
    private var form: TokenForm?
    private var viewModel: TableViewModel<Form> = EmptyTableViewModel() {
        didSet {
            guard oldValue.sections.count == viewModel.sections.count else {
                // Automatic updates aren't implemented for changing number of sections
                tableView.reloadData()
                return
            }
            tableView.beginUpdates()
            for sectionIndex in oldValue.sections.indices {
                let oldSection = oldValue.sections[sectionIndex]
                let newSection = viewModel.sections[sectionIndex]
                let changes = changesFrom(oldSection.rows, to: newSection.rows)
                for change in changes {
                    switch change {
                    case .Insert(let rowIndex):
                        let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    case let .Update(rowIndex, _):
                        let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                        updateRowAtIndexPath(indexPath)
                    case .Delete(let rowIndex):
                        let indexPath = NSIndexPath(forRow: rowIndex, inSection: sectionIndex)
                        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    case let .Move(fromRowIndex, toRowIndex):
                        let origin = NSIndexPath(forRow: fromRowIndex, inSection: sectionIndex)
                        let destination = NSIndexPath(forRow: toRowIndex, inSection: sectionIndex)
                        tableView.moveRowAtIndexPath(origin, toIndexPath: destination)
                    }
                }
            }
            tableView.endUpdates()
        }
    }

    init(form: TokenForm) {
        super.init(style: .Grouped)
        var presentedForm = form
        presentedForm.presenter = self
        self.form = presentedForm
        viewModel = presentedForm.viewModel
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        viewModel.leftBarButton?.action()
    }

    func rightBarButtonAction() {
        viewModel.rightBarButton?.action()
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
        if let cell = cell as? TextFieldRowCell {
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

    private func barButtomItemForViewModel(viewModel: BarButtonViewModel, target: AnyObject?, action: Selector) -> UIBarButtonItem {
        func systemItemForStyle(style: BarButtonViewModel.Style) -> UIBarButtonSystemItem {
            switch style {
            case .Done: return .Done
            case .Cancel: return .Cancel
            }
        }

        let barButtomItem = UIBarButtonItem(
            barButtonSystemItem: systemItemForStyle(viewModel.style),
            target: target,
            action: action
        )
        barButtomItem.enabled = viewModel.enabled
        return barButtomItem
    }

    func updateBarButtonItems() {
        navigationItem.leftBarButtonItem = viewModel.leftBarButton.map { (viewModel) in
            barButtomItemForViewModel(viewModel, target: self, action: Selector("leftBarButtonAction"))
        }
        navigationItem.rightBarButtonItem = viewModel.rightBarButton.map { (viewModel) in
            barButtomItemForViewModel(viewModel, target: self, action: Selector("rightBarButtonAction"))
        }
    }

    // MARK: Row Model

    func cellForRowModel(rowModel: Form.RowModel, inTableView tableView: UITableView) -> UITableViewCell {
        switch rowModel {
        case .TextFieldRow(let viewModel):
            let cell = tableView.dequeueReusableCellWithClass(TextFieldRowCell.self)
            cell.updateWithViewModel(viewModel)
            cell.delegate = self
            return cell

        case .TokenTypeRow(let viewModel):
            let cell = tableView.dequeueReusableCellWithClass(SegmentedControlRowCell<TokenTypeRowModel>.self)
            cell.updateWithViewModel(viewModel)
            cell.delegate = self
            return cell

        case .DigitCountRow(let viewModel):
            let cell = tableView.dequeueReusableCellWithClass(SegmentedControlRowCell<DigitCountRowModel>.self)
            cell.updateWithViewModel(viewModel)
            cell.delegate = self
            return cell

        case .AlgorithmRow(let viewModel):
            let cell = tableView.dequeueReusableCellWithClass(SegmentedControlRowCell<AlgorithmRowModel>.self)
            cell.updateWithViewModel(viewModel)
            cell.delegate = self
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
        case .TextFieldRow(let viewModel):
            if let cell = cell as? TextFieldRowCell {
                cell.updateWithViewModel(viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .TokenTypeRow(let viewModel):
            if let cell = cell as? SegmentedControlRowCell<TokenTypeRowModel> {
                cell.updateWithViewModel(viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .DigitCountRow(let viewModel):
            if let cell = cell as? SegmentedControlRowCell<DigitCountRowModel> {
                cell.updateWithViewModel(viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        case .AlgorithmRow(let viewModel):
            if let cell = cell as? SegmentedControlRowCell<AlgorithmRowModel> {
                cell.updateWithViewModel(viewModel)
            } else {
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }

    func heightForRowModel(rowModel: Form.RowModel) -> CGFloat {
        switch rowModel {
        case .TextFieldRow(let viewModel):
            return TextFieldRowCell.heightWithViewModel(viewModel)
        case .TokenTypeRow(let viewModel):
            return SegmentedControlRowCell.heightWithViewModel(viewModel)
        case .DigitCountRow(let viewModel):
            return SegmentedControlRowCell.heightWithViewModel(viewModel)
        case .AlgorithmRow(let viewModel):
            return SegmentedControlRowCell.heightWithViewModel(viewModel)
        }
    }

    // MARK: Header Model

    func viewForHeaderModel(headerModel: Form.HeaderModel) -> UIView {
        switch headerModel {
        case .ButtonHeader(let viewModel):
            return ButtonHeaderView(viewModel: viewModel)
        }
    }

    func heightForHeaderModel(headerModel: Form.HeaderModel) -> CGFloat {
        switch headerModel {
        case .ButtonHeader(let viewModel):
            return ButtonHeaderView.heightWithViewModel(viewModel)
        }
    }
}

extension TokenFormViewController: TokenFormPresenter {
    func updateWithViewModel(viewModel: TableViewModel<Form>) {
        self.viewModel = viewModel
        updateBarButtonItems()
        if let errorMessage = viewModel.errorMessage {
            SVProgressHUD.showErrorWithStatus(errorMessage)
        }
    }
}

extension TokenFormViewController: TextFieldRowCellDelegate, SegmentedControlRowCellDelegate {
    func textFieldCellDidReturn(textFieldCell: TextFieldRowCell) {
        // Unfocus the field that returned
        textFieldCell.unfocus()

        if textFieldCell.textField.returnKeyType == .Next {
            // Try to focus the next text field cell
            if let currentIndexPath = tableView.indexPathForCell(textFieldCell) {
                if let nextFocusCell = nextVisibleFocusCellAfterIndexPath(currentIndexPath) {
                    nextFocusCell.focus()
                }
            }
        } else if textFieldCell.textField.returnKeyType == .Done {
            // Try to submit the form
            viewModel.doneKeyAction?()
        }
    }

    func handleAction(action: Form.Action) {
        form?.handleAction(action)
    }
}
