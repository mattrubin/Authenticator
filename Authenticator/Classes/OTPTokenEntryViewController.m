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


@interface OTPTokenEntryViewController ()
    <UITextFieldDelegate>

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@property (nonatomic, strong) IBOutlet UISegmentedControl *tokenTypeControl;
@property (nonatomic, strong) IBOutlet UITextField *accountNameField;
@property (nonatomic, strong) IBOutlet UITextField *secretKeyField;

@end


@implementation OTPTokenEntryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor otpBackgroundColor];

    self.title = @"Add Token";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];

    self.doneButtonItem = self.navigationItem.rightBarButtonItem;
    self.doneButtonItem.enabled = NO;

    // Style UI elements
    self.tokenTypeControl.tintColor = [UIColor otpBarColor];
    self.accountNameField.tintColor = [UIColor otpBarColor];
    self.secretKeyField.tintColor   = [UIColor otpBarColor];
}


#pragma mark - Target Actions

- (void)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)done
{
    // TODO: create a token and return it to the delegate
    OTPAuthURL *token = nil;

    id <OTPTokenSourceDelegate> delegate = self.delegate;
    [delegate tokenSource:self didCreateToken:token];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.accountNameField) {
        [self.secretKeyField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

@end
