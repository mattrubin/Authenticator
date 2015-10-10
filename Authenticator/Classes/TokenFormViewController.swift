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
    private var doneButtonItem: UIBarButtonItem?

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
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("cancelAction"))
        doneButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("doneAction"))
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButtonItem
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        validateForm()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        form?.focusFirstField()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        form?.unfocus()
    }

    // MARK: - Target Actions

    func cancelAction() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func doneAction() {
        form?.submit()
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
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let cell = viewModel.cellForRowAtIndexPath(indexPath) as? OTPCell
            else { return 0 }
        return cell.preferredHeight
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerView = viewModel.viewForHeaderInSection(section) as? OTPCell
            else { return CGFloat(FLT_EPSILON) }
        return headerView.preferredHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.viewForHeaderInSection(section)
    }

    // MARK: - Validation

    func validateForm() {
        doneButtonItem?.enabled = viewModel.doneButtonViewModel.enabled
    }
}

extension TokenFormViewController: TokenFormPresenter {

    func formValuesDidChange(form: TokenForm) {
        viewModel = form.viewModel
        validateForm()
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

extension TokenFormViewController {
    static func entryControllerWithDelegate(delegate: TokenEntryFormDelegate) -> TokenFormViewController {
        let form = TokenEntryForm(delegate: delegate)
        return TokenFormViewController(form: form)
    }
}
