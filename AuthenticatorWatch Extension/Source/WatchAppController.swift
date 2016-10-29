//
//  WatchAppController.swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

class WatchAppController {
    private let store: TokenStore
    private var component: WatchRoot {
        didSet {
            view.updateWithViewModel(component.viewModel)
        }
    }
    private lazy var view: WatchRootViewController = {
        return WatchRootViewController(
            viewModel: self.component.viewModel,
            dispatchAction: self.handleAction
        )
    }()

    init() {
        do {
            try store = TokenStore(
                keychain: Keychain.sharedInstance,
                userDefaults: NSUserDefaults.standardUserDefaults()
            )
        } catch {
            // If the TokenStore could not be created, the watch app is unusable.
            fatalError("Failed to load token store: \(error)")
        }
        component = WatchRoot(persistentTokens: store.persistentTokens)

        // store changes trigger refresh of everything
        store.onChangeCallback = { [weak self] in
            if let tokens = self?.store.persistentTokens {
                self?.handleAction(.TokenStoreUpdated(tokens))
            }
        }

    }

    func activateWCSession() {
        store.activateWCSession()
    }

    private func handleAction(action: WatchRoot.Action) {
        let sideEffect = component.update(action)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    private func handleEffect(effect: WatchRoot.Effect) {
    }


}
