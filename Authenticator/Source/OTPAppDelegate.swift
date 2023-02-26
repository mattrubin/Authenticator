//
//  OTPAppDelegate.swift
//  Authenticator
//
//  Copyright (c) 2013-2023 Authenticator authors
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
import MessageUI

@UIApplicationMain
class OTPAppDelegate: UIResponder, UIApplicationDelegate {
    private let backgroundErrorKey = "__backgroudError"

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    var app: AppController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let fontAttributes = [NSAttributedString.Key.font: UIFont.otpBarButtonFont]
        UIBarButtonItem.appearance().setTitleTextAttributes(fontAttributes, for: .normal)
        UIBarButtonItem.appearance().setTitleTextAttributes(fontAttributes, for: .highlighted)

        let disabledAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.otpBarButtonFont,
            .foregroundColor: UIColor.otpBarForegroundColor.withAlphaComponent(0.3),
        ]
        UIBarButtonItem.appearance().setTitleTextAttributes(disabledAttributes, for: .disabled)

        // Restore white-on-black style
        SVProgressHUD.setForegroundColor(.otpLightColor)
        SVProgressHUD.setBackgroundColor(UIColor(white: 0, alpha: 0.95))
        SVProgressHUD.setMinimumDismissTimeInterval(1)

        do {
            app = try AppController()
            self.window?.rootViewController = app?.rootViewController
            self.window?.makeKeyAndVisible()

            checkForBackgroundErrors(application: application, launchOptions: launchOptions)
        } catch {
            print("Failed to load token store: \(error)")

            let errorReport = ErrorReport(
                application: application,
                launchOptions: launchOptions,
                error: error,
                message: "Failed to load token store")
            if application.applicationState == .background {
                // If the app is in the background, save the error to send later.
                UserDefaults.standard.set(errorReport.toString(), forKey: backgroundErrorKey)
            }
            self.window?.rootViewController = ErrorViewController(errorReport: errorReport)
            self.window?.makeKeyAndVisible()
        }

        return true
    }

    private func checkForBackgroundErrors(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let previousErrorReportString = UserDefaults.standard.string(forKey: backgroundErrorKey) {
            UserDefaults.standard.removeObject(forKey: backgroundErrorKey)
            let alert = UIAlertController(
                title: "An error occured while Authenticator was in the background.",
                message: "Do you want to send an error report?",
                preferredStyle: .alert)

            let acceptHandler: (UIAlertAction) -> Void = { [weak window] (_) in
                let errorReport: ErrorReport
                do {
                    errorReport = try ErrorReport.fromString(previousErrorReportString)
                } catch {
                    // If we can't decode the error report, send a report on the decoding error instead.
                    errorReport = ErrorReport(
                        application: application,
                        launchOptions: launchOptions,
                        error: error,
                        message: "Failed to decode error report")
                }

                let mailComposeViewController = errorReport.mailComposeViewController()
                mailComposeViewController.mailComposeDelegate = self
                window?.rootViewController?.present(mailComposeViewController, animated: true)
            }

            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel))
            alert.addAction(UIAlertAction(title: "Send", style: .default, handler: acceptHandler))

            window?.rootViewController?.present(alert, animated: true)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Ensure the UI is updated with the latest view model whenever the app returns from the background.
        app?.updateView()
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let token = try? Token(url: url) {
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

extension OTPAppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        window?.rootViewController?.dismiss(animated: true)
    }
}
