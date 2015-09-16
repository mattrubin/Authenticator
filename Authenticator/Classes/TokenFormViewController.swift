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

class TokenFormViewController: OTPTokenFormViewController {
    var doneButtonItem: UIBarButtonItem?


    init(form: TokenForm) {
        super.init(style: .Grouped)
        self.form_bridge = form
        form.presenter = self
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
        let form = form_bridge as! TokenForm
        title = form.title
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
        let form = form_bridge as! TokenForm
        form.focusFirstField()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        let form = form_bridge as! TokenForm
        form.unfocus()
    }

    // MARK: - Target Actions

    func cancelAction() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }

    func doneAction() {
        let form = form_bridge as! TokenForm
        form.submit()
    }


    // MARK: - UITableViewDataSource

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let form = form_bridge as! TokenForm
        return form.numberOfSections;
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let form = form_bridge as! TokenForm
        return form.numberOfRowsInSection(section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let form = form_bridge as! TokenForm
        return form.cellForRowAtIndexPath(indexPath)!
    }


    // MARK: - Validation

    func validateForm() {
        let form = form_bridge as! TokenForm
        doneButtonItem?.enabled = form.isValid
    }

}

extension TokenFormViewController: TokenFormPresenter {

    func formValuesDidChange(form: TokenForm) {
        validateForm()
    }

    func form(form: TokenForm, didFailWithErrorMessage errorMessage: String) {
        SVProgressHUD.showErrorWithStatus(errorMessage)
    }

    func form(form: TokenForm, didReloadSection section: Int) {
        tableView.reloadSections(NSIndexSet(index: section), withRowAnimation: .Automatic)
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section),
            atScrollPosition: .Top,
            animated: true)
    }
}
