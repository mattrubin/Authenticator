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
#import "OTPTextFieldCell.h"
#import "OTPToken.h"


@interface OTPTokenEntryViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@property (nonatomic, strong) OTPTextFieldCell *issuerCell;
@property (nonatomic, strong) OTPTextFieldCell *accountNameCell;

@end


@implementation OTPTokenEditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Edit Token";

    // Override the done button
    self.doneButtonItem.action = @selector(updateToken);

    self.accountNameCell.textField.returnKeyType = UIReturnKeyDone;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.issuerCell.textField becomeFirstResponder];
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
    NSLog(@"!!!");

}


#pragma mark - UITableViewDataSource

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


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.issuerCell.textField) {
        [self.accountNameCell.textField becomeFirstResponder];
    } else if (textField == self.accountNameCell.textField) {
        [textField resignFirstResponder];
        [self updateToken];
    }
    return NO;
}


#pragma mark - Validation

- (BOOL)formIsValid
{
    return (self.issuerCell.textField.text.length ||
            self.accountNameCell.textField.text.length);
}

@end
