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

class AppController {
    private let store: TokenStore
    private var component: Root {
        didSet {
            view.updateWithViewModel(component.viewModel)
        }
    }
    private lazy var view: RootViewController = {
        return RootViewController(viewModel: self.component.viewModel,
            dispatchAction: self.handleAction)
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
        case .AddToken(let token):
            store.addToken(token)

        case let .SaveToken(token, persistentToken):
            store.saveToken(token, toPersistentToken: persistentToken)

        case .UpdatePersistentToken(let persistentToken):
            store.updatePersistentToken(persistentToken)

        case let .MoveToken(fromIndex, toIndex):
            store.moveTokenFromIndex(fromIndex, toIndex: toIndex)

        case .DeletePersistentToken(let persistentToken):
            store.deletePersistentToken(persistentToken)
        }
        component.updateWithPersistentTokens(store.persistentTokens)
    }

    // MARK: - Public

    var rootViewController: UIViewController {
        return view
    }

    func addTokenFromURL(token: Token) {
        handleEffect(.AddToken(token))
    }
}
