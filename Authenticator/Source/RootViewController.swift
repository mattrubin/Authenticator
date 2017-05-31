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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class RootViewController: OpaqueNavigationController {
    fileprivate var currentViewModel: Root.ViewModel

    fileprivate var tokenListViewController: TokenListViewController
    fileprivate var modalNavController: UINavigationController?

    fileprivate let dispatchAction: (Root.Action) -> Void

    init(viewModel: Root.ViewModel, dispatchAction: @escaping (Root.Action) -> Void) {
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
        presentViewControllers([viewController])
    }

    fileprivate func presentViewControllers(_ viewControllersToPresent: [UIViewController]) {
        // If there is currently no modal, create one.
        guard let navController = modalNavController else {
            let navController = OpaqueNavigationController()
            navController.setViewControllers(viewControllersToPresent, animated: false)
            present(navController, animated: true)
            modalNavController = navController
            return
        }
        // If the current modal already contains the correct view controller, do nothing.
        guard navController.viewControllers != viewControllersToPresent else {
            return
        }
        // Present the desired view controller.
        navController.setViewControllers(viewControllersToPresent, animated: true)
    }

    fileprivate func dismissViewController() {
        if modalNavController != nil {
            modalNavController = nil
            dismiss(animated: true)
        }
    }
}

protocol ModelBasedViewController {
    associatedtype ViewModel
    associatedtype Action

    init(viewModel: ViewModel, dispatchAction: @escaping (Action) -> Void)
    func updateWithViewModel(_ viewModel: ViewModel)
}

extension TokenScannerViewController: ModelBasedViewController {}
extension TokenFormViewController: ModelBasedViewController {}
extension InfoListViewController: ModelBasedViewController {}
extension InfoViewController: ModelBasedViewController {}

extension RootViewController {
    private func reify<ViewController: ModelBasedViewController>(viewModel: ViewController.ViewModel, dispatchAction: @escaping (ViewController.Action) -> Void) -> ViewController {
        return reify(modalNavController?.topViewController, viewModel: viewModel, dispatchAction: dispatchAction)
    }

    private func reify<ViewController: ModelBasedViewController>(_ existingViewController: UIViewController?, viewModel: ViewController.ViewModel, dispatchAction: @escaping (ViewController.Action) -> Void) -> ViewController {
        if let viewController = existingViewController as? ViewController {
            viewController.updateWithViewModel(viewModel)
            return viewController
        } else {
            let viewController = ViewController(
                viewModel: viewModel,
                dispatchAction: dispatchAction
            )
            return viewController
        }
    }

    func updateWithViewModel(_ viewModel: Root.ViewModel) {
        tokenListViewController.updateWithViewModel(viewModel.tokenList)

        switch viewModel.modal {
        case .none:
            dismissViewController()

        case .scanner(let scannerViewModel):
            let scannerViewController: TokenScannerViewController = reify(
                viewModel: scannerViewModel,
                dispatchAction: compose(Root.Action.tokenScannerAction, dispatchAction)
            )
            presentViewController(scannerViewController)

        case .entryForm(let formViewModel):
            let formController: TokenFormViewController = reify(
                viewModel: formViewModel,
                dispatchAction: compose(Root.Action.tokenEntryFormAction, dispatchAction)
            )
            presentViewController(formController)

        case .editForm(let formViewModel):
            let editController: TokenFormViewController = reify(
                viewModel: formViewModel,
                dispatchAction: compose(Root.Action.tokenEditFormAction, dispatchAction)
            )
            presentViewController(editController)

        case .info(let infoListViewModel, let infoViewModel):
            updateWithInfoViewModels(infoListViewModel, infoViewModel)
        }
        currentViewModel = viewModel
    }

    private func updateWithInfoViewModels(_ infoListViewModel: InfoList.ViewModel, _ infoViewModel: Info.ViewModel?) {
        guard let infoViewModel = infoViewModel else {
            let infoListViewController: InfoListViewController = reify(
                viewModel: infoListViewModel,
                dispatchAction: compose(Root.Action.infoListEffect, dispatchAction)
            )
            presentViewController(infoListViewController)
            return
        }

        let infoListViewController: InfoListViewController = reify(
            modalNavController?.viewControllers.first,
            viewModel: infoListViewModel,
            dispatchAction: compose(Root.Action.infoListEffect, dispatchAction)
        )
        let infoViewController: InfoViewController = reify(
            viewModel: infoViewModel,
            dispatchAction: compose(Root.Action.infoEffect, dispatchAction)
        )
        presentViewControllers([infoListViewController, infoViewController])
    }
}

private func compose<A, B, C>(_ transform: @escaping (A) -> B, _ handler: @escaping (B) -> C) -> (A) -> C {
    return { handler(transform($0)) }
}
