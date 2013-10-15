//
//  OTPEntryController.m
//
//  Copyright 2013 Matt Rubin
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "OTPEntryController.h"
#import "OTPAuthURL.h"
#import "OTPScannerViewController.h"
#import <AVFoundation/AVFoundation.h>


@interface OTPEntryController () <UITextFieldDelegate, OTPScannerViewControllerDelegate>
@property(nonatomic, readwrite, unsafe_unretained) UITextField *activeTextField;
@property(nonatomic, readwrite, unsafe_unretained) UIBarButtonItem *doneButtonItem;

- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;
@end

@implementation OTPEntryController
@synthesize delegate = delegate_;
@synthesize doneButtonItem = doneButtonItem_;
@synthesize accountName = accountName_;
@synthesize accountKey = accountKey_;
@synthesize accountNameLabel = accountNameLabel_;
@synthesize accountKeyLabel = accountKeyLabel_;
@synthesize accountType = accountType_;
@synthesize scanBarcodeButton = scanBarcodeButton_;
@synthesize scrollView = scrollView_;
@synthesize activeTextField = activeTextField_;

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  self.delegate = nil;
  self.doneButtonItem = nil;
}

- (void)viewDidLoad {
    self.title = @"Add Token";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    
  self.accountName.placeholder = @"user@example.com";
  self.accountNameLabel.text = @"Account:";
  self.accountKey.placeholder = @"Enter your key";
  self.accountKeyLabel.text = @"Key:";
  [self.scanBarcodeButton setTitle:@"Scan Barcode"
                          forState:UIControlStateNormal];
  [self.accountType setTitle:@"Time Based"
           forSegmentAtIndex:0];
  [self.accountType setTitle:@"Counter Based"
      forSegmentAtIndex:1];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(keyboardWasShown:)
             name:UIKeyboardDidShowNotification object:nil];

  [nc addObserver:self
         selector:@selector(keyboardWillBeHidden:)
             name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
  self.accountName.text = @"";
  self.accountKey.text = @"";
  self.doneButtonItem
    = self.navigationController.navigationBar.topItem.rightBarButtonItem;
  self.doneButtonItem.enabled = NO;
  self.scrollView.backgroundColor = [UIColor otpBackgroundColor];

  // Hide the Scan button if we don't have a camera that will support video.
  AVCaptureDevice *device = nil;
  if ([AVCaptureDevice class]) {
    // AVCaptureDevice is not supported on iOS 3.1.3
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  }
  if (!device) {
    [self.scanBarcodeButton setHidden:YES];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  self.doneButtonItem = nil;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  CGFloat offset = 0;

    NSValue *sizeValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [sizeValue CGRectValue].size;
    BOOL isLandscape
      = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
    offset = isLandscape ? keyboardSize.width : keyboardSize.height;

  UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, offset, 0.0);
  self.scrollView.contentInset = contentInsets;
  self.scrollView.scrollIndicatorInsets = contentInsets;

  // If active text field is hidden by keyboard, scroll it so it's visible.
  CGRect aRect = self.view.frame;
  aRect.size.height -= offset;
  if (self.activeTextField) {
    CGPoint origin = self.activeTextField.frame.origin;
    origin.y += CGRectGetHeight(self.activeTextField.frame);
    if (!CGRectContainsPoint(aRect, origin) ) {
      CGPoint scrollPoint =
          CGPointMake(0.0, - (self.activeTextField.frame.origin.y - offset));
      [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
  }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
  UIEdgeInsets contentInsets = UIEdgeInsetsZero;
  self.scrollView.contentInset = contentInsets;
  self.scrollView.scrollIndicatorInsets = contentInsets;
}


#pragma mark - Actions

- (IBAction)accountNameDidEndOnExit:(id)sender {
  [self.accountKey becomeFirstResponder];
}

- (IBAction)accountKeyDidEndOnExit:(id)sender {
  [self done:sender];
}

- (IBAction)done:(id)sender {
  // Force the keyboard away.
  [self.activeTextField resignFirstResponder];

  NSString *encodedSecret = self.accountKey.text;
  NSData *secret = [OTPAuthURL base32Decode:encodedSecret];

  if ([secret length]) {
    Class authURLClass = Nil;
    if ([self.accountType selectedSegmentIndex] == 0) {
      authURLClass = [TOTPAuthURL class];
    } else {
      authURLClass = [HOTPAuthURL class];
    }
    NSString *name = self.accountName.text;
    OTPAuthURL *authURL
      = [[authURLClass alloc] initWithSecret:secret
                                         name:name];
    NSString *checkCode = authURL.checkCode;
    if (checkCode) {
      [self.delegate entryController:self didCreateAuthURL:authURL];
      [self dismissViewControllerAnimated:NO completion:nil];
    }
  } else {
    NSString *title = @"Invalid Key";
    NSString *message = nil;
    if ([encodedSecret length]) {
      message = [NSString stringWithFormat:@"The key '%@' is invalid.", encodedSecret];
    } else {
      message = @"You must enter a key.";
    }
    NSString *button = @"Try Again";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:nil
                                           cancelButtonTitle:button
                                           otherButtonTitles:nil];
    [alert show];
  }
}

- (IBAction)cancel:(id)sender {
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)scanBarcode:(id)sender {
    OTPScannerViewController *scanner = [[OTPScannerViewController alloc] init];
    scanner.delegate = self;
    [self.navigationController pushViewController:scanner animated:YES];
}


#pragma mark - OTPScannerViewControllerDelegate

- (void)scannerViewController:(OTPScannerViewController *)controller didCaptureAuthURL:(OTPAuthURL *)authURL
{
    [self.delegate entryController:self didCreateAuthURL:authURL];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextField Delegate Methods

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
    replacementString:(NSString *)string {
  if (textField == self.accountKey) {
    NSMutableString *key
      = [NSMutableString stringWithString:self.accountKey.text];
    [key replaceCharactersInRange:range withString:string];
    self.doneButtonItem.enabled = [key length] > 0;
  }
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
  self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  self.activeTextField = nil;
}

@end
