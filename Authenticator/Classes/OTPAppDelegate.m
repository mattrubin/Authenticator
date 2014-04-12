//
//  OTPAppDelegate.m
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

#import "OTPAppDelegate.h"
#import "OTPToken+Serialization.h"
#import "OTPTokenListViewController.h"
#import "UIAlertView+Blocks.h"


@interface OTPAppDelegate ()

@property (nonatomic, strong) OTPTokenListViewController *rootViewController;

@end


@implementation OTPAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor otpBarBackgroundColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor otpBarForegroundColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor otpBarForegroundColor]}];

    [[UIToolbar appearance] setBarTintColor:[UIColor otpBarBackgroundColor]];
    [[UIToolbar appearance] setTintColor:[UIColor otpBarForegroundColor]];

    // Restore white-on-black style
    [SVProgressHUD appearance].hudBackgroundColor = [UIColor blackColor];
    [SVProgressHUD appearance].hudForegroundColor = [UIColor whiteColor];
    [SVProgressHUD appearance].hudErrorImage   = [UIImage imageNamed:@"SVProgressHUD.bundle/error"];
    [SVProgressHUD appearance].hudSuccessImage = [UIImage imageNamed:@"SVProgressHUD.bundle/success"];

    self.rootViewController = [OTPTokenListViewController new];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.rootViewController];
    navController.navigationBar.translucent = NO;
    navController.toolbar.translucent = NO;

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = navController;
    [self.window makeKeyAndVisible];
    return YES;
}


#pragma mark - URL Handling

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    OTPToken *token = [OTPToken tokenWithURL:url];
    if (token) {
        NSString *message = [NSString stringWithFormat: @"Do you want to add a token for “%@”?", token.name];

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Token"
                                                        message:message
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];

        alert.clickedButtonHandler = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == alertView.firstOtherButtonIndex) {
                [self.rootViewController tokenSource:self didCreateToken:token];
            }
        };

        [alert show];
    }
    return !!token; // Return NO if the url was not a valid token
}

@end
