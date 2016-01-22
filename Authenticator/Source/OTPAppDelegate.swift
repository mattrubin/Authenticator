//
//  OTPAppDelegate.swift
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import OneTimePassword
import SVProgressHUD

@UIApplicationMain
class OTPAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.mainScreen().bounds)

    let store = TokenStore(
        keychain: Keychain.sharedInstance,
        userDefaults: NSUserDefaults.standardUserDefaults()
    )
    lazy var root: Root = {
        Root(persistentTokens: self.store.persistentTokens)
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        UINavigationBar.appearance().barTintColor = UIColor.otpBarBackgroundColor
        UINavigationBar.appearance().tintColor = UIColor.otpBarForegroundColor
        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.otpBarForegroundColor,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)!
        ]

        UIToolbar.appearance().barTintColor = UIColor.otpBarBackgroundColor
        UIToolbar.appearance().tintColor = UIColor.otpBarForegroundColor

        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)!], forState: UIControlState.Normal)

        // Restore white-on-black style
        SVProgressHUD.setDefaultStyle(.Dark)

        let navController = RootViewController(viewModel: root.viewModel,
            dispatchAction: handleAction)
        root.presenter = navController
        self.window?.rootViewController = navController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let token = Token.URLSerializer.deserialize(url)

        if let token = token {
            let message = "Do you want to add a token for “\(token.name)”?"

            let alert = UIAlertController(title: "Add Token", message: message, preferredStyle: .Alert)

            let acceptHandler: (UIAlertAction) -> Void = { [weak self] (_) in
                self?.handleEffect(.AddToken(token))
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: acceptHandler))

            window?.rootViewController?
                .presentViewController(alert, animated: true, completion: nil)

            return true
        }

        return false
    }

    private func handleAction(action: Root.Action) {
        let sideEffect = root.handleAction(action)
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
        root.updateWithPersistentTokens(store.persistentTokens)
    }
}
