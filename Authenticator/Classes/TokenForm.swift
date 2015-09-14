//
//  TokenForm.swift
//  Authenticator
//
//  Created by Matt Rubin on 8/29/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePasswordLegacy

@objc
protocol TableViewModel {
    var title: String { get }
    var numberOfSections: Int { get }
    func numberOfRowsInSection(section: Int) -> Int
    func cellForRowAtIndexPath(indexPath: NSIndexPath) -> UITableViewCell?
    func viewForHeaderInSection(section:Int) -> UIView?
}

@objc
protocol TokenForm: TableViewModel {
    weak var presenter: TokenFormPresenter? { get set }

    func focusFirstField()
    func unfocus()

    var isValid: Bool { get }
    func submit()
}

@objc
protocol TokenFormPresenter: class {
    func formValuesDidChange(form: TokenForm)
    func form(form: TokenForm, didFailWithErrorMessage errorMessage: String)
    func form(form: TokenForm, didReloadSection section: Int)
}
