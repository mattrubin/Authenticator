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

class TokenFormViewController: UITableViewController {
    private var form: TokenForm?
    private var viewModel: TableViewModel = EmptyTableViewModel()

    init(form: TokenForm) {
        super.init(style: .Grouped)
        var presentedForm = form
        presentedForm.presenter = self
        self.form = presentedForm
        viewModel = presentedForm.viewModel;
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

    private func focusFirstField() {
        for cell in tableView.visibleCells {
            if let focusCell = cell as? FocusCell {
                focusCell.focus()
                break
            }
        }
    }

    private func nextFocusCellAfterIndexPath(currentIndexPath: NSIndexPath) -> FocusCell? {
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

    private func unfocus() {
        view.endEditing(false)
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
        return viewModel.cellForRowAtIndexPath(indexPath) ?? UITableViewCell()
    }

    // MARK: - UITableViewDelegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = .clearColor()
        cell.selectionStyle = .None

        cell.textLabel?.textColor = .otpForegroundColor
        if let cell = cell as? OTPTextFieldCell {
            cell.textField.backgroundColor = .otpLightColor
            cell.textField.tintColor = .otpDarkColor
            cell.delegate = self
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let cell = viewModel.cellForRowAtIndexPath(indexPath) as? OTPCell
            else { return 0 }
        return cell.preferredHeight
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerViewModel = viewModel.headerForSection(section)
            else { return CGFloat(FLT_EPSILON) }
        return OTPHeaderView.heightWithViewModel(headerViewModel)
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerViewModel = viewModel.headerForSection(section)
            else { return nil }
        return OTPHeaderView(viewModel: headerViewModel)
    }

    // MARK: - Update

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
}

extension TokenFormViewController: TokenFormPresenter {

    func formValuesDidChange(form: TokenForm) {
        viewModel = form.viewModel
        updateBarButtonItems()
    }

    func form(form: TokenForm, didFailWithErrorMessage errorMessage: String) {
        SVProgressHUD.showErrorWithStatus(errorMessage)
    }

    func form(form: TokenForm, didReloadSection section: Int) {
        viewModel = form.viewModel
        tableView.reloadSections(NSIndexSet(index: section), withRowAnimation: .Automatic)
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section),
            atScrollPosition: .Top,
            animated: true)
    }
}

extension TokenFormViewController: OTPTextFieldCellDelegate {
    func textFieldCellDidReturn(textFieldCell: OTPTextFieldCell) {
        if let currentIndexPath = tableView.indexPathForCell(textFieldCell) {
            if let nextFocusCell = nextFocusCellAfterIndexPath(currentIndexPath) {
                nextFocusCell.focus()
            } else {
                textFieldCell.unfocus()
                viewModel.doneKeyAction?()
            }
        }
    }
}

extension TokenFormViewController {
    static func entryControllerWithDelegate(delegate: TokenEntryFormDelegate) -> TokenFormViewController {
        let form = TokenEntryForm(delegate: delegate)
        return TokenFormViewController(form: form)
    }
}
