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
    private let tokenList = TokenList()

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

        tokenList.delegate = self
        let rootViewController = OTPTokenListViewController(viewModel: tokenList.viewModel, delegate: tokenList)
        tokenList.presenter = rootViewController
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.navigationBar.translucent = false
        navController.toolbar.translucent = false

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
                self?.tokenList.addToken(token)
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

extension OTPAppDelegate: MasterPresenter {
    func beginAddToken() {
        if QRScanner.deviceCanScan {
            let scannerViewController = TokenScannerViewController() { [weak self] (event) in
                switch event {
                case .Save(let token):
                    self?.tokenList.addToken(token)
                case .Close:
                    self?.dismissViewController()
                }
            }
            presentViewController(scannerViewController)
        } else {
            let form = TokenEntryForm() { [weak self] (event) in
                switch event {
                case .Save(let token):
                    self?.tokenList.addToken(token)
                case .Close:
                    self?.dismissViewController()
                }
            }
            let formController = TokenFormViewController(form: form)
            presentViewController(formController)
        }
    }

    func beginEditPersistentToken(persistentToken: PersistentToken) {
        let form = TokenEditForm(token: persistentToken.token) { [weak self] (event) in
            switch event {
            case .Save(let token):
                self?.tokenList.saveToken(token, toPersistentToken: persistentToken)
            case .Close:
                self?.dismissViewController()
            }
        }
        let editController = TokenFormViewController(form: form)
        presentViewController(editController)
    }

    private func presentViewController(viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        navController.navigationBar.translucent = false
        window?.rootViewController?
            .presentViewController(navController, animated: true, completion: nil)
    }

    private func dismissViewController() {
        window?.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}
