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
    private var currentViewModel: AppViewModel

    private var tokenListViewController: TokenListViewController
    private var modalNavController: UINavigationController?
    private weak var actionHandler: ActionHandler?

    init(viewModel: AppViewModel, actionHandler: ActionHandler) {
        self.currentViewModel = viewModel
        self.actionHandler = actionHandler
        tokenListViewController = TokenListViewController(viewModel: viewModel.tokenList,
            dispatchAction: { [weak actionHandler] in
                actionHandler?.handleAction(.TokenListAction($0))
            })

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
        tokenListViewController.updateWithViewModel(viewModel.tokenList)

        switch viewModel.modal {
        case .None:
            dismissViewController()

        case .Scanner:
            let scannerViewController = TokenScannerViewController(actionHandler: self)
            presentViewController(scannerViewController)

        case .EntryForm(let formViewModel):
            if case .EntryForm = currentViewModel.modal,
                let entryController = modalNavController?.topViewController as? TokenFormViewController<TokenEntryForm> {
                    entryController.updateWithViewModel(formViewModel)
            } else {
                let formController = TokenFormViewController(viewModel: formViewModel,
                    dispatchAction: { [weak actionHandler] in
                        actionHandler?.handleAction(.TokenEntryFormAction($0))
                    })
                presentViewController(formController)
            }

        case .EditForm(let formViewModel):
            if case .EditForm = currentViewModel.modal,
                let editController = modalNavController?.topViewController as? TokenFormViewController<TokenEditForm> {
                    editController.updateWithViewModel(formViewModel)
            } else {
                let editController = TokenFormViewController(viewModel: formViewModel,
                    dispatchAction: { [weak actionHandler] in
                        actionHandler?.handleAction(.TokenEditFormAction($0))
                    })
                presentViewController(editController)
            }
        }
        currentViewModel = viewModel
    }
}
