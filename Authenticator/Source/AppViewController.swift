//
//  AppViewController.swift
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

class OpaqueNavigationController: UINavigationController {
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationBar.translucent = false
        toolbar.translucent = false
    }
}

class AppViewController: OpaqueNavigationController {
    private var tokenListViewController: TokenListViewController
    private var modalNavController: UINavigationController?
    private weak var actionHandler: ActionHandler?

    init(viewModel: AppViewModel, actionHandler: ActionHandler) {
        self.actionHandler = actionHandler
        let tokenList = viewModel.tokenList
        tokenListViewController = TokenListViewController(viewModel: tokenList.viewModel,
            delegate: tokenList)
        tokenList.presenter = tokenListViewController
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [tokenListViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func presentViewController(viewController: UIViewController) {
        if let navController = modalNavController {
            navController.setViewControllers([viewController], animated: true)
        } else {
            let navController = OpaqueNavigationController(rootViewController: viewController)
            presentViewController(navController, animated: true, completion: nil)
            modalNavController = navController
        }
    }

    private func dismissViewController() {
        if modalNavController != nil {
            modalNavController = nil
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
}

extension AppViewController: ActionHandler {
    func handleAction(action: AppAction) {
        actionHandler?.handleAction(action)
    }
}

extension AppViewController: AppPresenter {
    func updateWithViewModel(viewModel: AppViewModel) {
        let modalState = viewModel.modal
        switch modalState {
        case .None:
            dismissViewController()

        case .EntryScanner:
            let scannerViewController = TokenScannerViewController(actionHandler: self)
            presentViewController(scannerViewController)

        case .EntryForm(let form):
            let formController = TokenFormViewController(form: form)
            presentViewController(formController)

        case .EditForm(let form):
            let editController = TokenFormViewController(form: form)
            presentViewController(editController)
        }
    }
}
