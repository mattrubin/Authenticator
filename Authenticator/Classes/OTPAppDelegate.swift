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

class OTPAppDelegate: UIResponder, UIApplicationDelegate {
    let window = UIWindow(frame: UIScreen.mainScreen().bounds)
    let rootViewController = OTPTokenListViewController()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        UINavigationBar.appearance().barTintColor = UIColor.otpBarBackgroundColor
        UINavigationBar.appearance().tintColor = UIColor.otpBarForegroundColor
        UINavigationBar.appearance().titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.otpBarForegroundColor,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20)
        ]

        UIToolbar.appearance().barTintColor = UIColor.otpBarBackgroundColor
        UIToolbar.appearance().tintColor = UIColor.otpBarForegroundColor

        UIBarButtonItem.appearance().setTitleTextAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 17)], forState: .Normal)

        // Restore white-on-black style
        SVProgressHUD.appearance().hudBackgroundColor = UIColor.blackColor()
        SVProgressHUD.appearance().hudForegroundColor = UIColor.whiteColor()
        SVProgressHUD.appearance().hudErrorImage   = UIImage(named: "SVProgressHUD.bundle/error")
        SVProgressHUD.appearance().hudSuccessImage = UIImage(named: "SVProgressHUD.bundle/success")

        let navController = UINavigationController(rootViewController: self.rootViewController)
        navController.navigationBar.translucent = false
        navController.toolbar.translucent = false

        self.window.rootViewController = navController
        self.window.makeKeyAndVisible()

        return true
    }

}

/*

#pragma mark - URL Handling

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    OTPToken *token = [OTPToken tokenWithURL:url];
    if (token) {
        NSString *message = [NSString stringWithFormat: @"Do you want to add a token for “%@”?", token.name];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Token"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self.rootViewController tokenSource:self didCreateToken:token];
        }]];

        [self.rootViewController presentViewController:alert animated:YES completion:nil];
    }
    return !!token; // Return NO if the url was not a valid token
}

@end
*/
