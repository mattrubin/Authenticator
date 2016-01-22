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

    let app = AppController()
    var store: TokenStore {
        return app.store
    }

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

        app.root.updateWithPersistentTokens(store.persistentTokens)
        app.rootViewController = RootViewController(viewModel: app.root.viewModel,
            dispatchAction: app.handleAction)

        self.window?.rootViewController = app.rootViewController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let token = Token.URLSerializer.deserialize(url)

        if let token = token {
            let message = "Do you want to add a token for “\(token.name)”?"

            let alert = UIAlertController(title: "Add Token", message: message, preferredStyle: .Alert)

            let acceptHandler: (UIAlertAction) -> Void = { [weak self] (_) in
                self?.app.handleEffect(.AddToken(token))
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: acceptHandler))

            window?.rootViewController?
                .presentViewController(alert, animated: true, completion: nil)

            return true
        }

        return false
    }
}
