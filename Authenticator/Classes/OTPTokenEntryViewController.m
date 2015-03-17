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

typedef enum : NSUInteger {
    OTPTokenEntryBasicRowIssuer,
    OTPTokenEntryBasicRowName,
    OTPTokenEntryBasicRowSecret,
    OTPNumberOfTokenEntryBasicRows,
} OTPTokenEntryBasicRow;

typedef enum : NSUInteger {
    OTPTokenEntryAdvancedRowType,
    OTPTokenEntryAdvancedRowDigits,
    OTPTokenEntryAdvancedRowAlgorithm,
    OTPNumberOfTokenEntryAdvancedRows,
} OTPTokenEntryAdvancedRow;

typedef enum : NSUInteger {
    OTPTokenTypeIndexTimer,
    OTPTokenTypeIndexCounter,
} OTPTokenTypeIndex;

typedef enum : NSUInteger {
    OTPTokenDigitsIndex6,
    OTPTokenDigitsIndex7,
    OTPTokenDigitsIndex8,
} OTPTokenDigitsIndex;

typedef enum : NSUInteger {
    OTPTokenAlgorithmIndexSHA1,
    OTPTokenAlgorithmIndexSHA256,
    OTPTokenAlgorithmIndexSHA512,
} OTPTokenAlgorithmIndex;


@interface OTPTokenEntryViewController ()
    <UITextFieldDelegate>

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
    [super doneAction];
    [self createToken];
}

- (void)createToken
{
    if (!self.formIsValid) return;

    NSData *secret = [NSData dataWithBase32String:self.secretKeyCell.textField.text];

    if (secret.length) {
        OTPToken *token = [OTPToken new];
        token.type = (self.tokenTypeCell.segmentedControl.selectedSegmentIndex == OTPTokenTypeIndexTimer) ? OTPTokenTypeTimer : OTPTokenTypeCounter;
        token.secret = secret;
        token.name = self.accountNameCell.textField.text;
        token.issuer = self.issuerCell.textField.text;

        switch (self.digitCountCell.segmentedControl.selectedSegmentIndex) {
            case OTPTokenDigitsIndex6:
                token.digits = 6;
                break;
            case OTPTokenDigitsIndex7:
                token.digits = 7;
                break;
            case OTPTokenDigitsIndex8:
                token.digits = 8;
                break;
        }

        switch (self.algorithmCell.segmentedControl.selectedSegmentIndex) {
            case OTPTokenAlgorithmIndexSHA1:
                token.algorithm = OTPAlgorithmSHA1;
                break;
            case OTPTokenAlgorithmIndexSHA256:
                token.algorithm = OTPAlgorithmSHA256;
                break;
            case OTPTokenAlgorithmIndexSHA512:
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
    return OTPNumberOfTokenEntrySections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case OTPTokenEntrySectionBasic:
            return OTPNumberOfTokenEntryBasicRows;
        case OTPTokenEntrySectionAdvanced:
            return self.showsAdvancedOptions ? OTPNumberOfTokenEntryAdvancedRows : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case OTPTokenEntrySectionBasic:
            switch (indexPath.row) {
                case OTPTokenEntryBasicRowIssuer:
                    return self.issuerCell;
                case OTPTokenEntryBasicRowName:
                    return self.accountNameCell;
                case OTPTokenEntryBasicRowSecret:
                    return self.secretKeyCell;
            }
            break;
        case OTPTokenEntrySectionAdvanced:
            switch (indexPath.row) {
                case OTPTokenEntryAdvancedRowType:
                    return self.tokenTypeCell;
                case OTPTokenEntryAdvancedRowDigits:
                    return self.digitCountCell;
                case OTPTokenEntryAdvancedRowAlgorithm:
                    return self.algorithmCell;
            }
            break;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case OTPTokenEntrySectionBasic:
            return 74;
        case OTPTokenEntrySectionAdvanced:
            return 54;
    }
    return 0;
}


#pragma mark - Cells

- (OTPSegmentedControlCell *)tokenTypeCell
{
    if (!_tokenTypeCell) {
        _tokenTypeCell = [OTPSegmentedControlCell new];
        [_tokenTypeCell.segmentedControl insertSegmentWithTitle:@"Time Based" atIndex:OTPTokenTypeIndexTimer animated:NO];
        [_tokenTypeCell.segmentedControl insertSegmentWithTitle:@"Counter Based" atIndex:OTPTokenTypeIndexCounter animated:NO];
        _tokenTypeCell.segmentedControl.selectedSegmentIndex = OTPTokenTypeIndexTimer;
    }
    return _tokenTypeCell;
}

- (OTPTextFieldCell *)issuerCell
{
    if (!_issuerCell) {
        _issuerCell = [OTPTextFieldCell new];
        _issuerCell.textLabel.text = @"Issuer";
        _issuerCell.textField.placeholder = @"Some Website";
        _issuerCell.textField.delegate = self;
        _issuerCell.textField.returnKeyType = UIReturnKeyNext;
    }
    return _issuerCell;
}

- (OTPTextFieldCell *)accountNameCell
{
    if (!_accountNameCell) {
        _accountNameCell = [OTPTextFieldCell new];
        _accountNameCell.textLabel.text = @"Account Name";
        _accountNameCell.textField.placeholder = @"user@example.com";
        _accountNameCell.textField.delegate = self;
        _accountNameCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _accountNameCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _accountNameCell.textField.keyboardType = UIKeyboardTypeEmailAddress;
        _accountNameCell.textField.returnKeyType = UIReturnKeyNext;
    }
    return _accountNameCell;
}

- (OTPTextFieldCell *)secretKeyCell
{
    if (!_secretKeyCell) {
        _secretKeyCell = [OTPTextFieldCell new];
        _secretKeyCell.textLabel.text = @"Secret Key";
        _secretKeyCell.textField.placeholder = @"•••• •••• •••• ••••";
        _secretKeyCell.textField.delegate = self;
        _secretKeyCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _secretKeyCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _secretKeyCell.textField.returnKeyType = UIReturnKeyDone;
    }
    return _secretKeyCell;
}

- (OTPSegmentedControlCell *)digitCountCell
{
    if (!_digitCountCell) {
        _digitCountCell = [OTPSegmentedControlCell new];
        [_digitCountCell.segmentedControl insertSegmentWithTitle:@"6 Digits" atIndex:OTPTokenDigitsIndex6 animated:NO];
        [_digitCountCell.segmentedControl insertSegmentWithTitle:@"7 Digits" atIndex:OTPTokenDigitsIndex7 animated:NO];
        [_digitCountCell.segmentedControl insertSegmentWithTitle:@"8 Digits" atIndex:OTPTokenDigitsIndex8 animated:NO];
        _digitCountCell.segmentedControl.selectedSegmentIndex = OTPTokenDigitsIndex6;
    }
    return _digitCountCell;
}

- (OTPSegmentedControlCell *)algorithmCell
{
    if (!_algorithmCell) {
        _algorithmCell = [OTPSegmentedControlCell new];
        [_algorithmCell.segmentedControl insertSegmentWithTitle:@"SHA-1"   atIndex:OTPTokenAlgorithmIndexSHA1   animated:NO];
        [_algorithmCell.segmentedControl insertSegmentWithTitle:@"SHA-256" atIndex:OTPTokenAlgorithmIndexSHA256 animated:NO];
        [_algorithmCell.segmentedControl insertSegmentWithTitle:@"SHA-512" atIndex:OTPTokenAlgorithmIndexSHA512 animated:NO];
        _algorithmCell.segmentedControl.selectedSegmentIndex = OTPTokenAlgorithmIndexSHA1;
    }
    return _algorithmCell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.textColor = [UIColor otpForegroundColor];
    if ([cell isKindOfClass:[OTPTextFieldCell class]]) {
        ((OTPTextFieldCell *)cell).textField.backgroundColor = [UIColor otpLightColor];
        ((OTPTextFieldCell *)cell).textField.tintColor = [UIColor otpDarkColor];
    }
}

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
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:OTPTokenEntrySectionAdvanced] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(OTPNumberOfTokenEntryAdvancedRows - 1)
                                                                  inSection:OTPTokenEntrySectionAdvanced]
                              atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.issuerCell.textField) {
        [self.accountNameCell.textField becomeFirstResponder];
    } else if (textField == self.accountNameCell.textField) {
        [self.secretKeyCell.textField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self createToken];
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Delay validation slightly to allow the text field time to commit the new value
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self validateForm];
    });

    return YES;
}


#pragma mark - Validation

- (BOOL)formIsValid
{
    return ((self.issuerCell.textField.text.length ||
             self.accountNameCell.textField.text.length) &&
            self.secretKeyCell.textField.text.length);
}

@end
