//
//  OTPTokenListViewController.m
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

#import "OTPTokenListViewController.h"
#import <OneTimePassword/OneTimePassword.h>
#import "OTPTokenEntryViewController.h"
#import "OTPScannerViewController.h"
@import MobileCoreServices;


@interface _OTPTokenListViewController ()


@end


@implementation _OTPTokenListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tokenManager = [OTPTokenManager new];
    }
    return self;
}

- (void)update
{
    // Show the countdown ring only if a time-based token is active
    self.ring.hidden = !self.tokenManager.hasTimeBasedTokens;

    self.editButtonItem.enabled = !!self.tokenManager.numberOfTokens;
    self.noTokensLabel.hidden = !!self.tokenManager.numberOfTokens;
}

- (void)tick
{
    // TODO: only update cells for tokens whose passwords have changed
    for (OTPTokenCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[OTPTokenCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            OTPToken *token = [self.tokenManager tokenAtIndexPath:indexPath];
            [cell setPassword:token.password];
        }
    }

    NSTimeInterval period = [OTPToken defaultPeriod];
    self.ring.progress = fmod([NSDate date].timeIntervalSince1970, period) / period;
}


#pragma mark - Target actions

- (void)addToken
{
    UIViewController *entryController;
    if ([OTPScannerViewController deviceCanScan]) {
        entryController = [OTPScannerViewController new];
        ((OTPScannerViewController *)entryController).delegate = self;
    } else {
         entryController = [OTPTokenEntryViewController new];
        ((OTPTokenEntryViewController *)entryController).delegate = self;
    }
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:entryController];
    navController.navigationBar.translucent = NO;

    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Token source delegate

- (void)tokenSource:(id)tokenSource didCreateToken:(OTPToken *)token
{
    [self dismissViewControllerAnimated:YES completion:nil];

    if ([self.tokenManager addToken:token]) {
        [self.tableView reloadData];
        [self update];

        // Scroll to the new token (added at the bottom)
        NSInteger section = [self numberOfSectionsInTableView:self.tableView] - 1;
        NSInteger row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
    }
}

@end
