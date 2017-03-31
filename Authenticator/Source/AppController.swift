//
//  AppController.swift
//  Authenticator
//
//  Copyright (c) 2016 Authenticator authors
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

import Foundation
import UIKit
import SafariServices
import OneTimePassword
import SVProgressHUD

class AppController {
    fileprivate let store: TokenStore
    fileprivate var component: Root {
        didSet {
            // TODO: Fix the excessive updates of bar button items so that the tick can run while they are on screen.
            if case .none = component.viewModel.modal {
                if displayLink == nil {
                    startTick()
                }
            } else {
                if displayLink != nil {
                    stopTick()
                }
            }
            view.updateWithViewModel(component.viewModel)
        }
    }
    fileprivate lazy var view: RootViewController = {
        return RootViewController(
            viewModel: self.component.viewModel,
            dispatchAction: self.handleAction
        )
    }()

    init() {
        do {
            if CommandLine.isDemo {
                // If this is a demo, use a token store of mock data, not backed by the keychain.
                store = DemoTokenStore()
            } else {
                store = try KeychainTokenStore(
                    keychain: Keychain.sharedInstance,
                    userDefaults: UserDefaults.standardUserDefaults()
                )
            }
        } catch {
            // If the TokenStore could not be created, the app is unusable.
            fatalError("Failed to load token store: \(error)")
        }

        // If this is a demo, show the scanner even in the simulator.
        let deviceCanScan = QRScanner.deviceCanScan || CommandLine.isDemo
        component = Root(
            persistentTokens: store.persistentTokens,
            displayTime: .currentDisplayTime(),
            deviceCanScan: deviceCanScan
        )

        startTick()
    }

    // MARK: - Tick

    fileprivate var displayLink: CADisplayLink?

    fileprivate func startTick() {
        let selector = #selector(tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
    }

    fileprivate func stopTick() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    @objc
    func tick() {
        // Dispatch an event to trigger a view model update.
        handleEvent(.updateDisplayTime(.currentDisplayTime()))
    }

    // MARK: - Update

    fileprivate func handleAction(_ action: Root.Action) {
        do {
            let sideEffect = try component.update(action)
            if let effect = sideEffect {
                handleEffect(effect)
            }
        } catch {
            print("ERROR: \(error)")
        }
    }

    fileprivate func handleEvent(_ event: Root.Event) {
        let sideEffect = component.update(event)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    fileprivate func handleEffect(_ effect: Root.Effect) {
        switch effect {
        case let .addToken(token, success, failure):
            do {
                try store.addToken(token)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .saveToken(token, persistentToken, success, failure):
            do {
                try store.saveToken(token, toPersistentToken: persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .updatePersistentToken(persistentToken, success, failure):
            do {
                try store.updatePersistentToken(persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .moveToken(fromIndex, toIndex, success):
            store.moveTokenFromIndex(fromIndex, toIndex: toIndex)
            handleEvent(success(store.persistentTokens))

        case let .deletePersistentToken(persistentToken, success, failure):
            do {
                try store.deletePersistentToken(persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .showErrorMessage(message):
            SVProgressHUD.showError(withStatus: message)

        case let .showSuccessMessage(message):
            SVProgressHUD.showSuccess(withStatus: message)

        case let .openURL(url):
            if #available(iOS 9.0, *) {
                let safariViewController = SFSafariViewController(url: url)
                let presenter = topViewController(presentedFrom: rootViewController)
                presenter.present(safariViewController, animated: true, completion: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
    }

    fileprivate func topViewController(presentedFrom viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        return topViewController(presentedFrom: presentedViewController)
    }

    // MARK: - Public

    var rootViewController: UIViewController {
        return view
    }

    func addTokenFromURL(_ token: Token) {
        handleAction(.addTokenFromURL(token))
    }
}

private extension DisplayTime {
    static func currentDisplayTime() -> DisplayTime {
        if CommandLine.isDemo {
            // If this is a demo, use a constant time.
            return DisplayTime.demoTime
        }
        return DisplayTime(date: Date())
    }
}
