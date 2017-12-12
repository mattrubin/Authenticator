//
//  AppController.swift
//  AuthenticatorTokenProvider
//
//  Created by Beau Collins on 11/11/17.
//  Copyright © 2017 Matt Rubin. All rights reserved.
//

import Foundation
import OneTimePassword
import MobileCoreServices

class ExtensionController {

    var component: Picker {
        didSet { updateView() }
    }

    let store: TokenStore

    var nextRefreshTime: Date = Date.distantPast {
        willSet {
            self.timer?.invalidate()
        }
        didSet {
            switch self.nextRefreshTime {
            case .distantPast:
                return
            case .distantFuture:
                return
            default:
                let timer = Timer(fireAt: self.nextRefreshTime,
                                  interval: 0,
                                  target: self,
                                  selector: #selector(updateView),
                                  userInfo: nil,
                                  repeats: false)
                // Add the new timer to the main run loop
                RunLoop.main.add(timer, forMode: .commonModes)
                self.timer = timer
            }
        }
    }

    var timer: Timer?

    lazy var rootViewController: OpaqueNavigationController = {
        return OpaqueNavigationController(rootViewController: self.passwordPicker)
    }();

    lazy var passwordPicker: PasswordPickerViewController = {
        let (viewModel, nextRefreshTime) = self.component.viewModel(for: self.store.persistentTokens, at: self.now())
        self.nextRefreshTime = nextRefreshTime
        return PasswordPickerViewController(viewModel: viewModel, dispatchAction: self.handleAction)
    }()

    init(withContext context: NSExtensionContext) {
        do {
            store = try KeychainTokenStore(
                keychain: Keychain.sharedInstance,
                userDefaults: UserDefaults.standard
            )
        } catch {
            // If the TokenStore could not be created, the app is unusable.
            fatalError("Failed to load token store: \(error)")
        }
        component = Picker(extensionContext: context)
        prepareContext()
    }

    func handleAction(_ action: Picker.Action) {
        print("handle action \(action)")
        if let effect = component.update(action) {
            print("handle side effect \(effect)")
            handleEffect(effect)
        }
    }

    func handleEffect(_ effect: Picker.Effect) {
    }

    @objc
    func updateView() {
        let (viewModel, nextRefreshTime) = component.viewModel(for: store.persistentTokens, at: now())
        self.nextRefreshTime = nextRefreshTime
        passwordPicker.updateWithViewModel(viewModel)
    }

    func prepareContext() {
        for item in self.component.extensionContext.inputItems as! [NSExtensionItem] {
            print("Input item \(item.attachments ?? [])")
            if let provider = item.attachments?.first as? NSItemProvider {
                provider.loadItem(forTypeIdentifier: kUTTypePropertyList as String, options: nil) { (data, error) in
                    guard error == nil else {
                        print("failure \(error)")
                        return
                    }
                    guard let result = data as? NSDictionary else {
                        print("not valid data")
                        return;
                    }
                    print("Provider: \(result["baseURI"] ?? "no uri")")
                }
            }
        }
    }

    func now() -> DisplayTime {
        return DisplayTime(date: Date())
    }
}
