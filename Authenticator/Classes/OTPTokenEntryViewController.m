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
#import "OTPSegmentedControlCell.h"
#import "OTPTextFieldCell.h"
#import "OTPButtonCell.h"
#import "OTPScannerViewController.h"
#import "OTPToken+Generation.h"
#import <Base32/MF_Base32Additions.h>


@interface OTPTokenEntryViewController ()
    <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, OTPTokenSourceDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@property (nonatomic, strong) OTPSegmentedControlCell *tokenTypeCell;
@property (nonatomic, strong) OTPTextFieldCell *issuerCell;
@property (nonatomic, strong) OTPTextFieldCell *accountNameCell;
@property (nonatomic, strong) OTPTextFieldCell *secretKeyCell;
@property (nonatomic, strong) OTPButtonCell *scanBarcodeButtonCell;

@end


@implementation OTPTokenEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor otpBackgroundColor];

    // Set up top bar
    self.title = @"Add Token";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createToken)];

    self.doneButtonItem = self.navigationItem.rightBarButtonItem;
    self.doneButtonItem.enabled = NO;

    // Set up table view
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.alwaysBounceVertical = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.tableView];

    // Style UI elements
    self.view.tintColor = [UIColor otpForegroundColor];
    self.issuerCell.textLabel.textColor      = [UIColor otpForegroundColor];
    self.accountNameCell.textLabel.textColor = [UIColor otpForegroundColor];
    self.secretKeyCell.textLabel.textColor   = [UIColor otpForegroundColor];
    self.issuerCell.textField.tintColor      = [UIColor otpBackgroundColor];
    self.accountNameCell.textField.tintColor = [UIColor otpBackgroundColor];
    self.secretKeyCell.textField.tintColor   = [UIColor otpBackgroundColor];

    // Only show the scan button if the device is capable of scanning
    self.scanBarcodeButtonCell.button.hidden = ![OTPScannerViewController deviceCanScan];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
}


#pragma mark - Target Actions

- (void)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)createToken
{
    if (!self.accountNameCell.textField.text.length || !self.secretKeyCell.textField.text.length) {
        return;
    }

    NSData *secret = [NSData dataWithBase32String:self.secretKeyCell.textField.text];

    if (secret.length) {
        OTPTokenType tokenType = (self.tokenTypeCell.segmentedControl.selectedSegmentIndex == 0) ? OTPTokenTypeTimer : OTPTokenTypeCounter;
        OTPToken *token = [OTPToken tokenWithType:tokenType
                                               secret:secret
                                                 name:self.accountNameCell.textField.text];
        token.issuer = self.issuerCell.textField.text;

        if (token.password) {
            id <OTPTokenSourceDelegate> delegate = self.delegate;
            [delegate tokenSource:self didCreateToken:token];
            return;
        }
    }

    // If the method hasn't returned by this point, token creation failed
    [SVProgressHUD showErrorWithStatus:@"Invalid Token"];
}

- (IBAction)scanBarcode:(id)sender
{
    OTPScannerViewController *scanner = [[OTPScannerViewController alloc] init];
    scanner.delegate = self;
    [self.navigationController pushViewController:scanner animated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return self.tokenTypeCell;
        case 1:
            return self.issuerCell;
        case 2:
            return self.accountNameCell;
        case 3:
            return self.secretKeyCell;
        case 4:
            return self.scanBarcodeButtonCell;
        default:
            return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return 44;
        case 1:
            return 74;
        case 2:
            return 74;
        case 3:
            return 74;
        case 4:
            return 50;
        default:
            return 0;
    }
}


#pragma mark - Cells

- (OTPSegmentedControlCell *)tokenTypeCell
{
    if (!_tokenTypeCell) {
        _tokenTypeCell = [OTPSegmentedControlCell cellForTableView:self.tableView];
        [_tokenTypeCell.segmentedControl insertSegmentWithTitle:@"Time Based" atIndex:0 animated:NO];
        [_tokenTypeCell.segmentedControl insertSegmentWithTitle:@"Counter Based" atIndex:1 animated:NO];
        _tokenTypeCell.segmentedControl.selectedSegmentIndex = 0;
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
        _accountNameCell = [OTPTextFieldCell cellForTableView:self.tableView];
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
        _secretKeyCell = [OTPTextFieldCell cellForTableView:self.tableView];
        _secretKeyCell.textLabel.text = @"Secret Key";
        _secretKeyCell.textField.placeholder = @"•••• •••• •••• ••••";
        _secretKeyCell.textField.delegate = self;
        _secretKeyCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _secretKeyCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _secretKeyCell.textField.returnKeyType = UIReturnKeyDone;
    }
    return _secretKeyCell;
}

- (OTPButtonCell *)scanBarcodeButtonCell
{
    if (!_scanBarcodeButtonCell) {
        _scanBarcodeButtonCell = [OTPButtonCell new];
        [_scanBarcodeButtonCell.button setTitle:@"Scan Barcode" forState:UIControlStateNormal];
        [_scanBarcodeButtonCell.button addTarget:self action:@selector(scanBarcode:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scanBarcodeButtonCell;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.issuerCell.textField) {
        [self.accountNameCell.textField becomeFirstResponder];
        return NO;
    } else if (textField == self.accountNameCell.textField) {
        [self.secretKeyCell.textField becomeFirstResponder];
        return NO;
    } else {
        [textField resignFirstResponder];
        [self createToken];
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Ensure both fields (will) have text in them
    NSString *newText = [[textField.text mutableCopy] stringByReplacingCharactersInRange:range withString:string];
    if (textField == self.accountNameCell.textField) {
        self.doneButtonItem.enabled = newText.length && self.secretKeyCell.textField.text.length;
    } else if (textField == self.secretKeyCell.textField) {
        self.doneButtonItem.enabled = newText.length && self.accountNameCell.textField.text.length;
    }

    return YES;
}


#pragma mark - OTPTokenSourceDelegate

- (void)tokenSource:(id)tokenSource didCreateToken:(OTPToken *)token
{
    id <OTPTokenSourceDelegate> delegate = self.delegate;
    [delegate tokenSource:self didCreateToken:token];
}

@end
