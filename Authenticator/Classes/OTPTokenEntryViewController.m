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
@import OneTimePasswordLegacy;
@import Base32;


typedef enum : NSUInteger {
    OTPTokenEntrySectionBasic,
    OTPTokenEntrySectionAdvanced,
    OTPNumberOfTokenEntrySections,
} OTPTokenEntrySection;


@interface OTPTokenEntryViewController ()
    <OTPTextFieldCellDelegate>

@property (nonatomic, strong) TokenEntryForm *form;

@property (nonatomic, strong) OTPTextFieldCell *issuerCell;
@property (nonatomic, strong) OTPTextFieldCell *accountNameCell;
@property (nonatomic, strong) OTPTextFieldCell *secretKeyCell;

@property (nonatomic) BOOL showsAdvancedOptions;
@property (nonatomic, strong) OTPSegmentedControlCell *tokenTypeCell;
@property (nonatomic, strong) OTPSegmentedControlCell *digitCountCell;
@property (nonatomic, strong) OTPSegmentedControlCell *algorithmCell;

@end


@implementation OTPTokenEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Add Token";
}


#pragma mark - Target Actions

- (void)doneAction
{
    [self createToken];
}

- (void)createToken
{
    if (!self.formIsValid) return;

    NSData *secret = [NSData dataWithBase32String:self.secretKeyCell.textField.text];

    if (secret.length) {
        OTPToken *token = [OTPToken new];
        token.type = (self.tokenTypeCell.value == OTPTokenTypeOptionTimer) ? OTPTokenTypeTimer : OTPTokenTypeCounter;
        token.secret = secret;
        token.name = self.accountNameCell.textField.text;
        token.issuer = self.issuerCell.textField.text;

        switch (self.digitCountCell.value) {
            case OTPTokenDigitsOptionSix:
                token.digits = 6;
                break;
            case OTPTokenDigitsOptionSeven:
                token.digits = 7;
                break;
            case OTPTokenDigitsOptionEight:
                token.digits = 8;
                break;
        }

        switch (self.algorithmCell.value) {
            case OTPTokenAlgorithmOptionSHA1:
                token.algorithm = OTPAlgorithmSHA1;
                break;
            case OTPTokenAlgorithmOptionSHA256:
                token.algorithm = OTPAlgorithmSHA256;
                break;
            case OTPTokenAlgorithmOptionSHA512:
                token.algorithm = OTPAlgorithmSHA512;
                break;
        }

        if (token.password) {
            id <OTPTokenSourceDelegate> delegate = self.delegate;
            [delegate tokenSource:self didCreateToken:token];
            return;
        }
    }

    // If the method hasn't returned by this point, token creation failed
    [SVProgressHUD showErrorWithStatus:@"Invalid Token"];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.form.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.form numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.form cellForRowAtIndexPath:indexPath];
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case OTPTokenEntrySectionBasic:
            return [OTPTextFieldCell preferredHeight];
        case OTPTokenEntrySectionAdvanced:
            return [OTPSegmentedControlCell preferredHeight];
    }
    return 0;
}


#pragma mark - Cells

- (TokenEntryForm *)form {
    if (!_form) {
        NSArray *cells = @[
                           @[ self.issuerCell, self.accountNameCell , self.secretKeyCell ],
                           self.showsAdvancedOptions ? @[ self.tokenTypeCell, self.digitCountCell, self.algorithmCell ] : @[],
                           ];
        _form = [[TokenEntryForm alloc] initWithCells:cells];
    }
    return _form;
}

- (OTPSegmentedControlCell *)tokenTypeCell
{
    if (!_tokenTypeCell) {
        _tokenTypeCell = [OTPSegmentedControlCell tokenTypeCell];
    }
    return _tokenTypeCell;
}

- (OTPTextFieldCell *)issuerCell
{
    if (!_issuerCell) {
        _issuerCell = [OTPTextFieldCell issuerCellWithDelegate:self];
    }
    return _issuerCell;
}

- (OTPTextFieldCell *)accountNameCell
{
    if (!_accountNameCell) {
        _accountNameCell = [OTPTextFieldCell nameCellWithDelegate:self
                                                    returnKeyType:UIReturnKeyNext];
    }
    return _accountNameCell;
}

- (OTPTextFieldCell *)secretKeyCell
{
    if (!_secretKeyCell) {
        _secretKeyCell = [OTPTextFieldCell secretCellWithDelegate:self];
    }
    return _secretKeyCell;
}

- (OTPSegmentedControlCell *)digitCountCell
{
    if (!_digitCountCell) {
        _digitCountCell = [OTPSegmentedControlCell digitCountCell];
    }
    return _digitCountCell;
}

- (OTPSegmentedControlCell *)algorithmCell
{
    if (!_algorithmCell) {
        _algorithmCell = [OTPSegmentedControlCell algorithmCell];
    }
    return _algorithmCell;
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
    if (!self.showsAdvancedOptions) {
        self.showsAdvancedOptions = YES;
        self.form = nil; // Rebuild the form
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:OTPTokenEntrySectionAdvanced] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self.form numberOfRowsInSection:OTPTokenEntrySectionAdvanced] - 1)
                                                                  inSection:OTPTokenEntrySectionAdvanced]
                              atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark - OTPTextFieldCellDelegate

- (void)textFieldCellDidChange:(nonnull OTPTextFieldCell *)textFieldCell
{
    [self validateForm];
}

- (void)textFieldCellDidReturn:(nonnull OTPTextFieldCell *)textFieldCell
{
    if (textFieldCell == self.issuerCell) {
        [self.accountNameCell.textField becomeFirstResponder];
    } else if (textFieldCell == self.accountNameCell) {
        [self.secretKeyCell.textField becomeFirstResponder];
    } else {
        [textFieldCell.textField resignFirstResponder];
        [self createToken];
    }
}


#pragma mark - Validation

- (BOOL)formIsValid
{
    return ((self.issuerCell.textField.text.length ||
             self.accountNameCell.textField.text.length) &&
            self.secretKeyCell.textField.text.length);
}

@end
