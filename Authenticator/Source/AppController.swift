//
//  AppController.swift
//  Authenticator
//
//  Copyright (c) 2016-2017 Authenticator authors
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
    private let store: TokenStore
    private var component: Root {
        didSet {
            updateView()
        }
    }
    private lazy var view: RootViewController = {
        let (currentViewModel, nextRefreshTime) = self.component.viewModel(with: self.store.persistentTokens,
                                                                           at: .currentDisplayTime())
        self.setTimer(withNextRefreshTime: nextRefreshTime)
        return RootViewController(
            viewModel: currentViewModel,
            dispatchAction: self.handleAction
        )
    }()
    private var refreshTimer: Timer? {
        willSet {
            // Invalidate the old timer
            refreshTimer?.invalidate()
        }
    }

    init() {
        do {
            if CommandLine.isDemo {
                // If this is a demo, use a token store of mock data, not backed by the keychain.
                store = DemoTokenStore()
            } else {
                store = try KeychainTokenStore(
                    keychain: Keychain.sharedInstance,
                    userDefaults: UserDefaults.standard
                )
            }
        } catch {
            // If the TokenStore could not be created, the app is unusable.
            fatalError("Failed to load token store: \(error)")
        }

        // If this is a demo, show the scanner even in the simulator.
        let deviceCanScan = QRScanner.deviceCanScan || CommandLine.isDemo
        component = Root(deviceCanScan: deviceCanScan)
    }

    @objc
    func updateView() {
        let (currentViewModel, nextRefreshTime) = component.viewModel(with: store.persistentTokens,
                                                                      at: .currentDisplayTime())
        setTimer(withNextRefreshTime: nextRefreshTime)
        view.update(with: currentViewModel)
    }

    private func setTimer(withNextRefreshTime nextRefreshTime: Date) {
        let timer = Timer(fireAt: nextRefreshTime,
                          interval: 0,
                          target: self,
                          selector: #selector(updateView),
                          userInfo: nil,
                          repeats: false)
        // Add the new timer to the main run loop
        RunLoop.main.add(timer, forMode: .commonModes)
        refreshTimer = timer
    }

    // MARK: - Update

    private func handleAction(_ action: Root.Action) {
        do {
            let sideEffect = try component.update(with: action)
            if let effect = sideEffect {
                handleEffect(effect)
            }
        } catch {
            print("ERROR: \(error)")
        }
    }

    private func handleEvent(_ event: Root.Event) {
        let sideEffect = component.update(with: event)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    private func handleEffect(_ effect: Root.Effect) {
        switch effect {
        case let .addToken(token, success, failure):
            do {
                try store.addToken(token)
                handleEvent(success)
            } catch {
                handleEvent(failure(error))
            }

        case let .saveToken(token, persistentToken, success, failure):
            do {
                try store.saveToken(token, toPersistentToken: persistentToken)
                handleEvent(success)
            } catch {
                handleEvent(failure(error))
            }

        case let .updatePersistentToken(persistentToken, failure):
            do {
                try store.updatePersistentToken(persistentToken)
                updateView()
            } catch {
                handleEvent(failure(error))
            }

        case let .moveToken(fromIndex, toIndex, failure):
            do {
                try store.moveTokenFromIndex(fromIndex, toIndex: toIndex)
                updateView()
            } catch {
                handleEvent(failure(error))
            }

        case let .deletePersistentToken(persistentToken, failure):
            confirmDeletion(of: persistentToken, failure: failure)

        case let .showErrorMessage(message):
            SVProgressHUD.showError(withStatus: message)
            generateHapticFeedback(for: .error)

        case let .showSuccessMessage(message):
            SVProgressHUD.showSuccess(withStatus: message)
            generateHapticFeedback(for: .success)

        case .showApplicationSettings:
            guard let applicationSettingsURL = URL(string: UIApplicationOpenSettingsURLString) else {
                handleEffect(.showErrorMessage("Failed to open application settings."))
                return
            }
            UIApplication.shared.openURL(applicationSettingsURL)

        case let .openURL(url):
            if #available(iOS 9.0, *) {
                let safariViewController = SFSafariViewController(url: url)
                let presenter = topViewController(presentedFrom: rootViewController)
                presenter.present(safariViewController, animated: true)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(url)
            }
        }
    }

    private func topViewController(presentedFrom viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        return topViewController(presentedFrom: presentedViewController)
    }

    private func generateHapticFeedback(for notificationFeedbackType: UINotificationFeedbackType) {
        if #available(iOS 10.0, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(notificationFeedbackType)
        }
    }

    // MARK: - Public

    var rootViewController: UIViewController {
        return view
    }

    func addTokenFromURL(_ token: Token) {
        handleAction(.addTokenFromURL(token))
    }

    private func confirmDeletion(of persistentToken: PersistentToken, failure: @escaping (Error) -> Root.Event) {
        let messagePrefix = persistentToken.token.displayName.map({ "The token “\($0)”" }) ?? "The unnamed token"
        let message = messagePrefix + " will be permanently deleted from this device."

        let alert = UIAlertController(title: "Delete Token?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            self?.permanentlyDelete(persistentToken, failure: failure)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        let presenter = topViewController(presentedFrom: rootViewController)
        presenter.present(alert, animated: true)
    }

    private func permanentlyDelete(_ persistentToken: PersistentToken, failure: @escaping (Error) -> Root.Event) {
        do {
            try self.store.deletePersistentToken(persistentToken)
            self.updateView()
        } catch {
            self.handleEvent(failure(error))
        }
    }
}

private extension Token {
    var displayName: String? {
        switch (!name.isEmpty, !issuer.isEmpty) {
        case (true, true):
            return "\(issuer): \(name)"
        case (true, false):
            return name
        case (false, true):
            return issuer
        case (false, false):
            return nil
        }
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
