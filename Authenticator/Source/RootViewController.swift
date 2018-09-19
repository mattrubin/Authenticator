//
//  RootViewController.swift
//  Authenticator
//
//  Copyright (c) 2015-2018 Authenticator authors
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
            .foregroundColor: UIColor.otpBarForegroundColor,
            .font: UIFont.systemFont(ofSize: 20, weight: .light),
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
            navController.delegate = self
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
    func update(with viewModel: ViewModel)
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
            viewController.update(with: viewModel)
            return viewController
        } else {
            let viewController = ViewController(
                viewModel: viewModel,
                dispatchAction: dispatchAction
            )
            return viewController
        }
    }

    func update(with viewModel: Root.ViewModel) {
        tokenListViewController.update(with: viewModel.tokenList)

        switch viewModel.modal {
        case .none:
            dismissViewController()

        case .scanner(let scannerViewModel):
            presentViewModel(scannerViewModel,
                             using: TokenScannerViewController.self,
                             actionTransform: Root.Action.tokenScannerAction)

        case .entryForm(let formViewModel):
            presentViewModel(formViewModel,
                             using: TokenFormViewController.self,
                             actionTransform: Root.Action.tokenEntryFormAction)

        case .editForm(let formViewModel):
            presentViewModel(formViewModel,
                             using: TokenFormViewController.self,
                             actionTransform: Root.Action.tokenEditFormAction)

        case let .info(infoListViewModel, infoViewModel):
            updateWithInfoViewModels(infoListViewModel, infoViewModel)
        }
        currentViewModel = viewModel
    }

    private func presentViewModel<ViewController: UIViewController & ModelBasedViewController>(_ viewModel: ViewController.ViewModel, using _: ViewController.Type, actionTransform: @escaping ((ViewController.Action) -> Root.Action)) {
        let viewController: ViewController = reify(
            viewModel: viewModel,
            dispatchAction: compose(actionTransform, dispatchAction)
        )
        presentViewController(viewController)
    }

    // swiftlint:disable:next function_parameter_count
    private func presentViewModels<A: UIViewController & ModelBasedViewController, B: UIViewController & ModelBasedViewController>(
        _ viewModelA: A.ViewModel, using _: A.Type, actionTransform actionTransformA: @escaping ((A.Action) -> Root.Action),
        and viewModelB: B.ViewModel, using _: B.Type, actionTransform actionTransformB: @escaping ((B.Action) -> Root.Action)) {
        let viewControllerA: A = reify(
            modalNavController?.viewControllers.first,
            viewModel: viewModelA,
            dispatchAction: compose(actionTransformA, dispatchAction)
        )
        let viewControllerB: B = reify(
            viewModel: viewModelB,
            dispatchAction: compose(actionTransformB, dispatchAction)
        )
        presentViewControllers([viewControllerA, viewControllerB])
    }

    private func updateWithInfoViewModels(_ infoListViewModel: InfoList.ViewModel, _ infoViewModel: Info.ViewModel?) {
        guard let infoViewModel = infoViewModel else {
            presentViewModel(infoListViewModel,
                             using: InfoListViewController.self,
                             actionTransform: Root.Action.infoListEffect)
            return
        }

        presentViewModels(infoListViewModel,
                          using: InfoListViewController.self,
                          actionTransform: Root.Action.infoListEffect,
                          and: infoViewModel,
                          using: InfoViewController.self,
                          actionTransform: Root.Action.infoEffect)
    }
}

private func compose<A, B, C>(_ transform: @escaping (A) -> B, _ handler: @escaping (B) -> C) -> (A) -> C {
    return { handler(transform($0)) }
}

extension RootViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if case .info(_, .some) = currentViewModel.modal,
            viewController is InfoListViewController {
            // If the view model modal state has an Info.ViewModel and the just-shown view controller is an info list,
            // then the user has popped the info view controller.
            dispatchAction(.dismissInfo)
        }
    }
}
