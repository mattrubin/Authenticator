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
#import "OTPScannerViewController.h"
#import "OTPToken+Generation.h"
#import <Base32/MF_Base32Additions.h>


@interface OTPTokenEntryViewController ()
    <UITextFieldDelegate, OTPTokenSourceDelegate>

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@property (nonatomic, strong) IBOutlet UISegmentedControl *tokenTypeControl;
@property (nonatomic, strong) IBOutlet UITextField *accountNameField;
@property (nonatomic, strong) IBOutlet UITextField *secretKeyField;

@property (nonatomic, strong) IBOutlet UIButton *scanBarcodeButton;

@end


@implementation OTPTokenEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor otpBackgroundColor];

    self.title = @"Add Token";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(createToken)];

    self.doneButtonItem = self.navigationItem.rightBarButtonItem;
    self.doneButtonItem.enabled = NO;

    // Style UI elements
    self.tokenTypeControl.tintColor = [UIColor otpBarBackgroundColor];
    self.accountNameField.tintColor = [UIColor otpBarBackgroundColor];
    self.secretKeyField.tintColor   = [UIColor otpBarBackgroundColor];
    self.scanBarcodeButton.tintColor = [UIColor otpBarBackgroundColor];

    // Only show the scan button if the device is capable of scanning
    self.scanBarcodeButton.hidden = ![OTPScannerViewController deviceCanScan];
}


#pragma mark - Target Actions

- (void)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)createToken
{
    if (!self.accountNameField.text.length || !self.secretKeyField.text.length) {
        return;
    }

    NSData *secret = [NSData dataWithBase32String:self.secretKeyField.text];

    if (secret.length) {
        OTPTokenType tokenType = (self.tokenTypeControl.selectedSegmentIndex == 0) ? OTPTokenTypeTimer : OTPTokenTypeCounter;
        OTPToken *token = [OTPToken tokenWithType:tokenType
                                               secret:secret
                                                 name:self.accountNameField.text];

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


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.accountNameField) {
        [self.secretKeyField becomeFirstResponder];
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
    if (textField == self.accountNameField) {
        self.doneButtonItem.enabled = newText.length && self.secretKeyField.text.length;
    } else if (textField == self.secretKeyField) {
        self.doneButtonItem.enabled = newText.length && self.accountNameField.text.length;
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
