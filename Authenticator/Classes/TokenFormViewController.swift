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

    // FIXME: Replace AnyObject with TokenForm
    override init(form: AnyObject) {
        let form = form as! TokenForm
        super.init(form: form)
        form.presenter = self
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
