//
//  OTPTokenEditViewController.m
//  Authenticator
//
//  Copyright (c) 2014 Matt Rubin
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

#import "OTPTokenEditViewController.h"
@import OneTimePasswordLegacy;


@interface OTPTokenEditViewController () <OTPTextFieldCellDelegate>

@property (nonatomic, strong) OTPTextFieldCell *issuerCell;
@property (nonatomic, strong) OTPTextFieldCell *accountNameCell;

@end


@implementation OTPTokenEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Edit Token";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.issuerCell.textField becomeFirstResponder];
}


#pragma mark - Target Actions

- (void)doneAction
{
    [self updateToken];
}


#pragma mark - Token

- (void)setToken:(OTPToken *)token
{
    if (_token != token) {
        _token = token;
    }
    self.issuerCell.textField.text = token.issuer;
    self.accountNameCell.textField.text = token.name;
}

- (void)updateToken
{
    if (!self.formIsValid) return;

    if (![self.token.name isEqualToString:self.accountNameCell.textField.text] ||
        ![self.token.issuer isEqualToString:self.issuerCell.textField.text]) {
        self.token.name = self.accountNameCell.textField.text;
        self.token.issuer = self.issuerCell.textField.text;
        [self.token saveToKeychain];
    }

    id <OTPTokenEditorDelegate> delegate = self.delegate;
    [delegate tokenEditor:self didEditToken:self.token];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            return self.issuerCell;
        case 1:
            return self.accountNameCell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74;
}


#pragma mark - Cells

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
                                                    returnKeyType:UIReturnKeyDone];
    }
    return _accountNameCell;
}


#pragma mark - OTPTextFieldCellDelegate

- (void)textFieldCellDidReturn:(nonnull OTPTextFieldCell *)textFieldCell
{
    if (textFieldCell == self.issuerCell) {
        [self.accountNameCell.textField becomeFirstResponder];
    } else if (textFieldCell == self.accountNameCell) {
        [textFieldCell.textField resignFirstResponder];
        [self updateToken];
    }
}


#pragma mark - Validation

- (BOOL)formIsValid
{
    return (self.issuerCell.textField.text.length ||
            self.accountNameCell.textField.text.length);
}

@end
