//
//  OTPAppDelegate.swift
//  Authenticator
//
//  Copyright (c) 2013-2017 Authenticator authors
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

import UIKit
import OneTimePassword
import SVProgressHUD

@UIApplicationMain
class OTPAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    let app = AppController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let barButtonItemFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.light)
        let fontAttributes = [NSAttributedStringKey.font: barButtonItemFont]
        UIBarButtonItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(fontAttributes, for: .highlighted)

        let disabledAttributes = [
            NSAttributedStringKey.font: barButtonItemFont,
            NSAttributedStringKey.foregroundColor: UIColor.otpBarForegroundColor.withAlphaComponent(0.3),
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(disabledAttributes, for: .disabled)

        // Restore white-on-black style
        SVProgressHUD.setForegroundColor(.otpLightColor)
        SVProgressHUD.setBackgroundColor(UIColor(white: 0, alpha: 0.95))
        SVProgressHUD.setMinimumDismissTimeInterval(1)

        self.window?.rootViewController = app.rootViewController
        self.window?.makeKeyAndVisible()

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Ensure the UI is updated with the latest view model whenever the app returns from the background.
        app.updateView()
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if let token = Token(url: url) {
            let message = "Do you want to add a token for “\(token.name)”?"

            let alert = UIAlertController(title: "Add Token", message: message, preferredStyle: .alert)

            let acceptHandler: (UIAlertAction) -> Void = { [weak app] (_) in
                app?.addTokenFromURL(token)
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: acceptHandler))

            // TODO: Fix the confirmation alert presentation when a modal is open.
            window?.rootViewController?.present(alert, animated: true)

            return true
        }

        return false
    }
}
