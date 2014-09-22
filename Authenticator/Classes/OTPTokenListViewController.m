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
#import "OTPTokenManager.h"
#import "OTPTokenCell.h"
#import <OneTimePassword/OneTimePassword.h>
#import "OTPTokenEntryViewController.h"
#import "OTPScannerViewController.h"
@import MobileCoreServices;
#import "OTPTokenEditViewController.h"


@interface _OTPTokenListViewController () <OTPTokenCellDelegate, OTPTokenEditorDelegate>

@property (nonatomic, strong) OTPTokenManager *tokenManager;
@property (nonatomic, strong) CADisplayLink *displayLink;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.displayLink invalidate];
    self.displayLink = nil;
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger) self.tokenManager.numberOfTokens;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTPTokenCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([OTPTokenCell class]) forIndexPath:indexPath];

    cell.delegate = self;

    OTPToken *token = [self.tokenManager tokenAtIndexPath:indexPath];
    [cell setName:token.name issuer:token.issuer];
    [cell setPassword:token.password];
    [cell setShowsButton:(token.type == OTPTokenTypeCounter)];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([self.tokenManager removeTokenAtIndexPath:indexPath]) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self update];

            if (!self.tokenManager.numberOfTokens) {
                [self setEditing:NO animated:YES];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.tokenManager moveTokenFromIndexPath:fromIndexPath toIndexPath:toIndexPath];
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 85;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing) {
        self.editing = NO;

        OTPTokenEditViewController *editController = [OTPTokenEditViewController new];
        editController.token = [self.tokenManager tokenAtIndexPath:indexPath];
        editController.delegate = self;

        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editController];
        navController.navigationBar.translucent = NO;

        [self presentViewController:navController animated:YES completion:nil];
    } else {
        OTPToken *token = [self.tokenManager tokenAtIndexPath:indexPath];
        [[UIPasteboard generalPasteboard] setValue:token.password forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];
        [SVProgressHUD showSuccessWithStatus:@"Copied"];
    }
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


#pragma mark - OTPTokenCellDelegate

- (void)buttonTappedForCell:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (indexPath) {
        OTPToken *token = [self.tokenManager tokenAtIndexPath:indexPath];
        [token updatePassword];
        [self.tableView reloadData];
    }
}


#pragma mark - OTPTokenEditorDelegate

- (void)tokenEditor:(id)tokenEditor didEditToken:(OTPToken *)token
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.tableView reloadData];
}

@end
