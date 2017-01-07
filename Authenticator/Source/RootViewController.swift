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

        navigationBar.translucent = false
        navigationBar.barTintColor = UIColor.otpBarBackgroundColor
        navigationBar.tintColor = UIColor.otpBarForegroundColor
        navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.otpBarForegroundColor,
            NSFontAttributeName: UIFont.systemFontOfSize(20, weight: UIFontWeightLight),
        ]

        toolbar.translucent = false
        toolbar.barTintColor = UIColor.otpBarBackgroundColor
        toolbar.tintColor = UIColor.otpBarForegroundColor
    }
}

class RootViewController: OpaqueNavigationController {
    private var currentViewModel: Root.ViewModel

    private var tokenListViewController: TokenListViewController
    private var modalNavController: UINavigationController?

    private let dispatchAction: (Root.Action) -> Void

    init(viewModel: Root.ViewModel, dispatchAction: (Root.Action) -> Void) {
        self.currentViewModel = viewModel
        self.dispatchAction = dispatchAction
        tokenListViewController = TokenListViewController(
            viewModel: viewModel.tokenList,
            dispatchAction: compose(Root.Action.TokenListAction, dispatchAction)
        )

        super.init(nibName: nil, bundle: nil)
        self.viewControllers = [tokenListViewController]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //

    private var displayLink: CADisplayLink?

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let selector = #selector(RootViewController.tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    //

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

    // MARK: Target Actions

    func tick() {
        if Process.isDemo {
            // If this is a demo, don't update the display time.
            return
        }

        // Dispatch an action to trigger a view model update.
        let newDisplayTime = DisplayTime(date: NSDate())
        dispatchAction(.UpdateDisplayTime(newDisplayTime))
    }
}

extension RootViewController {
    func updateWithViewModel(viewModel: Root.ViewModel) {
        tokenListViewController.updateWithViewModel(viewModel.tokenList)

        switch viewModel.modal {
        case .None:
            dismissViewController()

        case .Scanner:
            if case .Scanner = currentViewModel.modal,
                let _ = modalNavController?.topViewController as? TokenScannerViewController {
                // The scanner has no view model of its own to update
            } else {
                let scannerViewController = TokenScannerViewController(
                    dispatchAction: compose(Root.Action.TokenScannerEffect, dispatchAction)
                )
                presentViewController(scannerViewController)
            }

        case .EntryForm(let formViewModel):
            if case .EntryForm = currentViewModel.modal,
                let entryController = modalNavController?.topViewController as? TokenFormViewController<TokenEntryForm> {
                    entryController.updateWithViewModel(formViewModel)
            } else {
                let formController = TokenFormViewController(
                    viewModel: formViewModel,
                    dispatchAction: compose(Root.Action.TokenEntryFormAction, dispatchAction)
                )
                presentViewController(formController)
            }

        case .EditForm(let formViewModel):
            if case .EditForm = currentViewModel.modal,
                let editController = modalNavController?.topViewController as? TokenFormViewController<TokenEditForm> {
                    editController.updateWithViewModel(formViewModel)
            } else {
                let editController = TokenFormViewController(
                    viewModel: formViewModel,
                    dispatchAction: compose(Root.Action.TokenEditFormAction, dispatchAction)
                )
                presentViewController(editController)
            }
        }
        currentViewModel = viewModel
    }
}

private func compose<A, B, C>(transform: A -> B, _ handler: B -> C) -> A -> C {
    return { handler(transform($0)) }
}
