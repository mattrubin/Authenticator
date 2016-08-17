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
            view.updateWithViewModel(component.viewModel)
        }
    }
    private lazy var view: RootViewController = {
        return RootViewController(
            viewModel: self.component.viewModel,
            dispatchAction: self.handleAction
        )
    }()

    init() {
        store = TokenStore(
            keychain: Keychain.sharedInstance,
            userDefaults: NSUserDefaults.standardUserDefaults()
        )
        let currentTime = DisplayTime(date: NSDate())
        component = Root(persistentTokens: store.persistentTokens, displayTime: currentTime)
    }

    // MARK: - Update

    private func handleAction(action: Root.Action) {
        let sideEffect = component.update(action)
        if let effect = sideEffect {
            handleEffect(effect)
        }
    }

    private func handleEffect(effect: Root.Effect) {
        switch effect {
        case let .AddToken(token, success, failure):
            do {
                try store.addToken(token)
                handleAction(success(store.persistentTokens))
            } catch {
                handleAction(failure(error))
            }

        case let .SaveToken(token, persistentToken, success, failure):
            do {
                try store.saveToken(token, toPersistentToken: persistentToken)
                handleAction(success(store.persistentTokens))
            } catch {
                handleAction(failure(error))
            }

        case let .UpdatePersistentToken(persistentToken, success, failure):
            do {
                try store.updatePersistentToken(persistentToken)
                handleAction(success(store.persistentTokens))
            } catch {
                handleAction(failure(error))
            }

        case let .MoveToken(fromIndex, toIndex, success):
            store.moveTokenFromIndex(fromIndex, toIndex: toIndex)
            handleAction(success(store.persistentTokens))

        case let .DeletePersistentToken(persistentToken, success):
            store.deletePersistentToken(persistentToken)
            handleAction(success(store.persistentTokens))

        case let .ShowErrorMessage(error):
            SVProgressHUD.showErrorWithStatus("Error: \(error)")
        }
    }

    // MARK: - Public

    var rootViewController: UIViewController {
        return view
    }

    func addTokenFromURL(token: Token) {
        // TODO: Add Root.Action.AddTokenFromURL
        handleEffect(.AddToken(token, success: Root.Action.UpdateWithPersistentTokens,
            failure: Root.Action._AddTokenFailed))
    }
}
