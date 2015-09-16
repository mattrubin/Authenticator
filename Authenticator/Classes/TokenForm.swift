//
//  TokenForm.swift
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

import OneTimePasswordLegacy

protocol TableViewModel {
    var title: String { get }
    var sections: [Section] { get }

    var numberOfSections: Int { get }
    func numberOfRowsInSection(section: Int) -> Int
    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell?
    func viewForHeaderInSection(section:Int) -> UIView?
}

protocol TokenForm: TableViewModel {
    weak var presenter: TokenFormPresenter? { get set }

    func focusFirstField()
    func unfocus()

    var isValid: Bool { get }
    func submit()
}

protocol TokenFormPresenter: class {
    func formValuesDidChange(form: TokenForm)
    func form(form: TokenForm, didFailWithErrorMessage errorMessage: String)
    func form(form: TokenForm, didReloadSection section: Int)
}


extension TableViewModel {
    var numberOfSections: Int {
        return sections.count
    }

    func numberOfRowsInSection(section: Int) -> Int {
        guard sections.indices.contains(section)
            else { return 0 }
        return sections[section].rows.count
    }

    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell? {
        guard sections.indices.contains(indexPath.section)
            else { return nil }
        let section = sections[indexPath.section]
        guard section.rows.indices.contains(indexPath.row)
            else { return nil }
        return section.rows[indexPath.row]
    }

    func viewForHeaderInSection(section: Int) -> UIView? {
        guard sections.indices.contains(section)
            else { return nil }
        return sections[section].header
    }
}
