//
//  RootViewController.swift
//  Authenticator
//
//  Copyright (c) 2015-2016 Authenticator authors
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
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.isTranslucent = false
        navigationBar.barTintColor = UIColor.otpBarBackgroundColor
        navigationBar.tintColor = UIColor.otpBarForegroundColor
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.otpBarForegroundColor,
            NSFontAttributeName: UIFont.systemFont(ofSize: 20, weight: UIFontWeightLight),
        ]

        toolbar.isTranslucent = false
        toolbar.barTintColor = UIColor.otpBarBackgroundColor
        toolbar.tintColor = UIColor.otpBarForegroundColor
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

class RootViewController: OpaqueNavigationController {
    fileprivate var currentViewModel: Root.ViewModel

    fileprivate var tokenListViewController: TokenListViewController
    fileprivate var modalNavController: UINavigationController?

    fileprivate let dispatchAction: (Root.Action) -> Void

    init(viewModel: Root.ViewModel, dispatchAction: (Root.Action) -> Void) {
        self.currentViewModel = viewModel
        self.dispatchAction = dispatchAction
        tokenListViewController = TokenListViewController(
            viewModel: viewModel.tokenList,
            dispatchAction: compose(Root.Action.tokenListAction, dispatchAction)
        )

        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [tokenListViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func presentViewController(_ viewController: UIViewController) {
        if let navController = modalNavController {
            navController.setViewControllers([viewController], animated: true)
        } else {
            let navController = OpaqueNavigationController(rootViewController: viewController)
            present(navController, animated: true, completion: nil)
            modalNavController = navController
        }
    }

    fileprivate func dismissViewController() {
        if modalNavController != nil {
            modalNavController = nil
            dismiss(animated: true, completion: nil)
        }
    }
}

extension RootViewController {
    func updateWithViewModel(_ viewModel: Root.ViewModel) {
        tokenListViewController.updateWithViewModel(viewModel.tokenList)

        switch viewModel.modal {
        case .none:
            dismissViewController()

        case .scanner(let scannerViewModel):
            if case .scanner = currentViewModel.modal,
                let scannerViewController = modalNavController?.topViewController as? TokenScannerViewController {
                scannerViewController.updateWithViewModel(scannerViewModel)
            } else {
                let scannerViewController = TokenScannerViewController(
                    viewModel: scannerViewModel,
                    dispatchAction: compose(Root.Action.tokenScannerAction, dispatchAction)
                )
                presentViewController(scannerViewController)
            }

        case .entryForm(let formViewModel):
            if case .entryForm = currentViewModel.modal,
                let entryController = modalNavController?.topViewController as? TokenFormViewController<TokenEntryForm> {
                    entryController.updateWithViewModel(formViewModel)
            } else {
                let formController = TokenFormViewController(
                    viewModel: formViewModel,
                    dispatchAction: compose(Root.Action.tokenEntryFormAction, dispatchAction)
                )
                presentViewController(formController)
            }

        case .editForm(let formViewModel):
            if case .editForm = currentViewModel.modal,
                let editController = modalNavController?.topViewController as? TokenFormViewController<TokenEditForm> {
                    editController.updateWithViewModel(formViewModel)
            } else {
                let editController = TokenFormViewController(
                    viewModel: formViewModel,
                    dispatchAction: compose(Root.Action.tokenEditFormAction, dispatchAction)
                )
                presentViewController(editController)
            }

        case .info(let infoViewModel):
            updateWithInfoViewModel(infoViewModel)
        }
        currentViewModel = viewModel
    }

    fileprivate func updateWithInfoViewModel(_ infoViewModel: Info.ViewModel) {
        if case .info = currentViewModel.modal,
            let infoViewController = modalNavController?.topViewController as? InfoViewController {
            infoViewController.updateWithViewModel(infoViewModel)
        } else {
            let infoViewController = InfoViewController(
                viewModel: infoViewModel,
                dispatchAction: compose(Root.Action.infoEffect, dispatchAction)
            )
            presentViewController(infoViewController)
        }
    }
}

private func compose<A, B, C>(_ transform: (A) -> B, _ handler: (B) -> C) -> (A) -> C {
    return { handler(transform($0)) }
}
