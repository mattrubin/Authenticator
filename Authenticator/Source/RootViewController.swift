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
import LocalAuthentication

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
    fileprivate var authController: UIViewController?

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

protocol ModelBased {
    associatedtype ViewModel
    associatedtype Action

    init(viewModel: ViewModel, dispatchAction: @escaping (Action) -> Void)
    func update(with viewModel: ViewModel)
}

typealias ModelBasedViewController = UIViewController & ModelBased

extension TokenScannerViewController: ModelBased {}
extension TokenFormViewController: ModelBased {}
extension InfoListViewController: ModelBased {}
extension InfoViewController: ModelBased {}
extension DisplayOptionsViewController: ModelBased {}

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

extension RootViewController {
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

        case let .menu(menuViewModel):
            switch menuViewModel.child {
            case .info(let infoViewModel):
                presentViewModels(menuViewModel.infoList,
                                  using: InfoListViewController.self,
                                  actionTransform: Root.Action.infoListEffect,
                                  and: infoViewModel,
                                  using: InfoViewController.self,
                                  actionTransform: Root.Action.infoEffect)

            case .displayOptions(let displayOptionsViewModel):
                presentViewModels(menuViewModel.infoList,
                                  using: InfoListViewController.self,
                                  actionTransform: Root.Action.infoListEffect,
                                  and: displayOptionsViewModel,
                                  using: DisplayOptionsViewController.self,
                                  actionTransform: Root.Action.displayOptionsEffect)

            case .none:
                presentViewModel(menuViewModel.infoList,
                                 using: InfoListViewController.self,
                                 actionTransform: Root.Action.infoListEffect)
            }
        }
        updateWithAuthViewModel(viewModel.privacy)

        currentViewModel = viewModel
    }

    private func presentViewModel<ViewController: ModelBasedViewController>(_ viewModel: ViewController.ViewModel, using _: ViewController.Type, actionTransform: @escaping ((ViewController.Action) -> Root.Action)) {
        let viewController: ViewController = reify(
            modalNavController?.topViewController,
            viewModel: viewModel,
            dispatchAction: compose(actionTransform, dispatchAction)
        )
        presentViewControllers([viewController])
    }

    // swiftlint:disable:next function_parameter_count
    private func presentViewModels<A: ModelBasedViewController, B: ModelBasedViewController>(
        _ viewModelA: A.ViewModel, using _: A.Type, actionTransform actionTransformA: @escaping ((A.Action) -> Root.Action),
        and viewModelB: B.ViewModel, using _: B.Type, actionTransform actionTransformB: @escaping ((B.Action) -> Root.Action)) {
        let viewControllerA: A = reify(
            modalNavController?.viewControllers.first,
            viewModel: viewModelA,
            dispatchAction: compose(actionTransformA, dispatchAction)
        )
        let viewControllerB: B = reify(
            modalNavController?.topViewController,
            viewModel: viewModelB,
            dispatchAction: compose(actionTransformB, dispatchAction)
        )
        presentViewControllers([viewControllerA, viewControllerB])
    }

    private func updateWithAuthViewModel(_ viewModel: AuthViewModel) {
        if viewModel.enabled == currentViewModel.privacy.enabled {
            return
        }
        if viewModel.enabled {
            if authController == nil {
                authController = UIViewController()
                authController?.view.backgroundColor = UIColor.otpBackgroundColor
                let button = UIButton(type: .roundedRect)
                button.setTitleColor(UIColor.otpForegroundColor, for: .normal)
                button.setTitle("Unlock", for: .normal)
                button.addTarget(self, action: #selector(authChallenge), for: .touchUpInside)
                button.sizeToFit()
                authController?.view.addSubview(button)
                button.center = authController!.view.center
                authController?.modalPresentationStyle = .overFullScreen
            }

            guard let controller = authController else {
                return
            }
            if let presented = presentedViewController {
                presented.present(controller, animated: false)
                return
            } else {
                present(controller, animated: false)
            }
        }
        if !viewModel.enabled {
            authController?.presentingViewController?.dismiss(animated: true)
            authController = nil
        }
    }

    @objc private func authChallenge() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "LOLZ") { (reply, error) in
            DispatchQueue.main.async {
                self.dispatchAction(.authAction(.authResult(reply: reply, error: error)))
            }
        }
    }
}

private func compose<A, B, C>(_ transform: @escaping (A) -> B, _ handler: @escaping (B) -> C) -> (A) -> C {
    return { handler(transform($0)) }
}

extension RootViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if case .menu(let menu) = currentViewModel.modal,
            viewController is InfoListViewController {
            switch menu.child {
            case .info:
                // If the current modal state is the menu with an Info child, and the just-shown view controller is
                // an InfoList, then the user has popped the Info view controller.
                dispatchAction(.dismissInfo)
            case .displayOptions:
                // If the current modal state is the menu with a DisplayOptions child, and the just-shown view
                // controller is an InfoList, then the user has popped the DisplayOptions view controller.
                dispatchAction(.dismissDisplayOptions)
            default:
                break
            }
        }
    }
}
