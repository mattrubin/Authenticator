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
import OneTimePassword
import SVProgressHUD

class AppController {
    private let store: TokenStore
    private var component: Root {
        didSet {
            if case .None = component.viewModel.modal {
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
    private lazy var view: RootViewController = {
        return RootViewController(
            viewModel: self.component.viewModel,
            dispatchAction: {
                print("👆")
                self.handleAction($0)
            }
        )
    }()

    init() {
        do {
            if Process.isDemo {
                // If this is a demo, use a token store of mock data, not backed by the keychain.
                store = DemoTokenStore()
            } else {
                store = try KeychainTokenStore(
                    keychain: Keychain.sharedInstance,
                    userDefaults: NSUserDefaults.standardUserDefaults()
                )
            }
        } catch {
            // If the TokenStore could not be created, the app is unusable.
            fatalError("Failed to load token store: \(error)")
        }

        let displayTime = makeCurrentDisplayTime()
        component = Root(persistentTokens: store.persistentTokens, displayTime: displayTime)

        startTick()
    }

    // MARK: - Tick

    private var displayLink: CADisplayLink?

    private func startTick() {
        let selector = #selector(tick)
        self.displayLink = CADisplayLink(target: self, selector: selector)
        self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }

    private func stopTick() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    @objc
    func tick() {
        // Dispatch an action to trigger a view model update.
        let newDisplayTime = makeCurrentDisplayTime()
        print("🕑")
        handleEvent(.UpdateDisplayTime(newDisplayTime))
    }

    // MARK: - Update

    private func handleAction(action: Root.Action) {
        let sideEffect = component.update(action)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    private func handleEvent(event: Root.Event) {
        let sideEffect = component.update(event)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    private func handleEffect(effect: Root.Effect) {
        print("< Root.Effect: \(effect)")
        switch effect {
        case let .AddToken(token, success, failure):
            do {
                try store.addToken(token)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .SaveToken(token, persistentToken, success, failure):
            do {
                try store.saveToken(token, toPersistentToken: persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .UpdatePersistentToken(persistentToken, success, failure):
            do {
                try store.updatePersistentToken(persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .MoveToken(fromIndex, toIndex, success):
            store.moveTokenFromIndex(fromIndex, toIndex: toIndex)
            handleEvent(success(store.persistentTokens))

        case let .DeletePersistentToken(persistentToken, success, failure):
            do {
                try store.deletePersistentToken(persistentToken)
                handleEvent(success(store.persistentTokens))
            } catch {
                handleEvent(failure(error))
            }

        case let .ShowErrorMessage(message):
            SVProgressHUD.showErrorWithStatus(message)

        case let .ShowSuccessMessage(message):
            SVProgressHUD.showSuccessWithStatus(message)
        }
    }

    // MARK: - Public

    var rootViewController: UIViewController {
        return view
    }

    func addTokenFromURL(token: Token) {
        handleAction(.AddTokenFromURL(token))
    }
}

private func makeCurrentDisplayTime() -> DisplayTime {
    if Process.isDemo {
        // If this is a demo, use a constant time.
        return DisplayTime.demoTime
    }

    return DisplayTime(date: NSDate())
}
