//
//  OTPTokenEntryViewController.m
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

#import "OTPTokenEntryViewController.h"
#import "OTPTokenFormViewController+Private.h"
@import OneTimePasswordLegacy;
@import Base32;


typedef enum : NSUInteger {
    OTPTokenEntrySectionBasic,
    OTPTokenEntrySectionAdvanced,
    OTPNumberOfTokenEntrySections,
} OTPTokenEntrySection;


@interface OTPTokenEntryViewController ()

@property (nonatomic, strong) TokenEntryForm *form;

@end


@implementation OTPTokenEntryViewController

@synthesize form = _form;

- (TokenEntryForm *)form {
    if (!_form) {
        _form = [[TokenEntryForm alloc] init];
        _form.delegate = self;
    }
    return _form;
}


#pragma mark - Target Actions

- (void)formDidSubmit
{
    [self createToken];
    [super formDidSubmit];
}

- (void)createToken
{
    if (!self.form.isValid) return;

    NSData *secret = [NSData dataWithBase32String:self.form.secretKey];

    if (secret.length) {
        OTPToken *token = [OTPToken new];
        token.type = self.form.tokenType;
        token.secret = secret;
        token.name = self.form.accountName;
        token.issuer = self.form.issuer;
        token.digits = self.form.digitCount;
        token.algorithm = self.form.algorithm;

        if (token.password) {
            id <OTPTokenSourceDelegate> delegate = self.delegate;
            [delegate tokenSource:self didCreateToken:token];
            return;
        }
    }

    // If the method hasn't returned by this point, token creation failed
    [SVProgressHUD showErrorWithStatus:@"Invalid Token"];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == OTPTokenEntrySectionAdvanced) {
        return 54;
    }
    return 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == OTPTokenEntrySectionAdvanced) {
        UIButton *headerView = [UIButton new];
        [headerView setTitle:@"Advanced Options" forState:UIControlStateNormal];
        headerView.titleLabel.textAlignment = NSTextAlignmentCenter;
        headerView.titleLabel.textColor = [UIColor otpForegroundColor];
        headerView.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        [headerView addTarget:self action:@selector(revealAdvancedOptions) forControlEvents:UIControlEventTouchUpInside];
        return headerView;
    }
    return nil;
}

- (void)revealAdvancedOptions
{
    if (!self.form.showsAdvancedOptions) {
        self.form.showsAdvancedOptions = YES;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:OTPTokenEntrySectionAdvanced] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.form numberOfRowsInSection:OTPTokenEntrySectionAdvanced] - 1)
                                                                  inSection:OTPTokenEntrySectionAdvanced]
                              atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

@end
