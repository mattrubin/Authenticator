//
//  Root.swift
//  AuthenticatorTokenProvider
//
//  Created by Beau Collins on 11/11/17.
//  Copyright © 2017 Matt Rubin. All rights reserved.
//

import Foundation
import OneTimePassword
import MobileCoreServices

struct Picker: Component {

    enum Action {
        case cancel
        case tokenListAction(action: TokenList.Action)
    }

    enum Effect {

    }

    var tokenList: TokenList
    let extensionContext: NSExtensionContext

    init(extensionContext context: NSExtensionContext) {
        tokenList = TokenList()
        extensionContext = context
    }

    mutating func update(_ action: Picker.Action) -> Picker.Effect? {
        switch action {
        case .tokenListAction(let action):
            let effect = tokenList.update(action).flatMap { effect in handleTokenListEffect(effect) }
            switch action {
            case .copyPassword(let password):
                completeRequest(withPassword: password)
                return nil
            default:
                return effect
            }
        case .cancel:
            completeRequest()
            return nil
        }
    }

    private func handleTokenListEffect(_ effect: TokenList.Effect) -> Picker.Effect? {
        // honestly nothing needs to happen
        return nil
    }

    struct ViewModel {
        var pageContext: [String]
        var tokenList: TokenListViewModel;
    }

    func completeRequest(withPassword password: String? = nil) {
        guard let password = password else {
            extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        let item = NSExtensionItem()
        let contents: NSDictionary = [
            NSExtensionJavaScriptFinalizeArgumentKey: ["password" : password ]
        ]
        let passwordItemProvider = NSItemProvider(item: contents, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [passwordItemProvider]
        extensionContext.completeRequest(returningItems: [item])
    }
}

extension Picker {
    func viewModel(for tokens: [PersistentToken], at time: DisplayTime) -> (viewModel: ViewModel, nextRefreshTime: Date) {
        let (tokenListViewModel, nextRefreshTime) = tokenList.viewModel(for: tokens, at: time)
        let viewModel = ViewModel(
            pageContext: [],
            tokenList: tokenListViewModel
        )
        return (viewModel: viewModel, nextRefreshTime: nextRefreshTime)
    }
}

