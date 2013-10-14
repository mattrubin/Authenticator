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
#import "OTPScannerOverlayView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
#import <ZXingObjC/ZXingObjC.h>
#pragma clang diagnostic pop


@interface OTPEntryController ()
@property(nonatomic, readwrite, unsafe_unretained) UITextField *activeTextField;
@property(nonatomic, readwrite, unsafe_unretained) UIBarButtonItem *doneButtonItem;
@property(nonatomic, readwrite, strong) id <ZXReader> decoder;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, strong) AVCaptureSession *avSession;
@property (atomic) BOOL handleCapture;

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
@synthesize decoder = decoder_;
@synthesize avSession = avSession_;
@synthesize handleCapture = handleCapture_;

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

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
  self.decoder = [ZXMultiFormatReader reader];
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
  self.handleCapture = NO;
  [self.avSession stopRunning];
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


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)orientation {
  // Scrolling is only enabled when in landscape.
  if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
    self.scrollView.contentSize = self.view.bounds.size;
  } else {
    self.scrollView.contentSize = CGSizeZero;
  }
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
  self.handleCapture = NO;
  [self.avSession stopRunning];
  [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)scanBarcode:(id)sender {
  if (!self.avSession) {
    self.avSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *device =
      [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *captureInput =
      [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    [self.avSession addInput:captureInput];
    self.queue = dispatch_queue_create("OTPEntryController", 0);
    AVCaptureVideoDataOutput *captureOutput =
      [[AVCaptureVideoDataOutput alloc] init];
    [captureOutput setAlwaysDiscardsLateVideoFrames:YES];
    [captureOutput setSampleBufferDelegate:self
                                     queue:self.queue];
    NSNumber *bgra = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   bgra, kCVPixelBufferPixelFormatTypeKey,
                                   nil];
    [captureOutput setVideoSettings:videoSettings];
    [self.avSession addOutput:captureOutput];
  }

  AVCaptureVideoPreviewLayer *previewLayer
    = [AVCaptureVideoPreviewLayer layerWithSession:self.avSession];
  [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];

  UIButton *cancelButton =
    [UIButton buttonWithType:UIButtonTypeRoundedRect];
  NSString *cancelString = @"Cancel";
  cancelButton.accessibilityLabel = @"Cancel";
  CGFloat height = [UIFont systemFontSize];
  CGSize size
    = [cancelString sizeWithFont:[UIFont systemFontOfSize:height]];
  [cancelButton setTitle:cancelString forState:UIControlStateNormal];

  UIViewController *previewController
    = [[UIViewController alloc] init];
  [previewController.view.layer addSublayer:previewLayer];

  CGRect frame = previewController.view.bounds;
  previewLayer.frame = frame;
  OTPScannerOverlayView *overlayView
    = [[OTPScannerOverlayView alloc] initWithFrame:frame];
  [previewController.view addSubview:overlayView];

  // Center the cancel button horizontally, and put it
  // kBottomPadding from the bottom of the view.
  static const int kBottomPadding = 10;
  static const int kInternalXMargin = 10;
  static const int kInternalYMargin = 10;
  frame = CGRectMake(CGRectGetMidX(frame)
                            - ((size.width / 2) + kInternalXMargin),
                            CGRectGetHeight(frame)
                            - (height + (2 * kInternalYMargin) + kBottomPadding),
                            (2  * kInternalXMargin) + size.width,
                            height + (2 * kInternalYMargin));
  [cancelButton setFrame:frame];

  // Set it up so that if the view should resize, the cancel button stays
  // h-centered and v-bottom-fixed in the view.
  cancelButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                   UIViewAutoresizingFlexibleLeftMargin |
                                   UIViewAutoresizingFlexibleRightMargin);
  [cancelButton addTarget:self
                   action:@selector(cancel:)
         forControlEvents:UIControlEventTouchUpInside];
  [overlayView addSubview:cancelButton];

  [self presentViewController:previewController animated:NO completion:nil];
  self.handleCapture = YES;
  [self.avSession startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
  if (!self.handleCapture) return;
  @autoreleasepool {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (imageBuffer) {
    CVReturn ret = CVPixelBufferLockBaseAddress(imageBuffer, 0);
    if (ret == kCVReturnSuccess) {
      uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
      size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
      size_t width = CVPixelBufferGetWidth(imageBuffer);
      size_t height = CVPixelBufferGetHeight(imageBuffer);
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      CGContextRef context
        = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace,
                                kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
      CGColorSpaceRelease(colorSpace);
      CGImageRef cgImage = CGBitmapContextCreateImage(context);
      CGContextRelease(context);
        ZXLuminanceSource* source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:cgImage];
        ZXBinaryBitmap* bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
      CFRelease(cgImage);
      CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        NSError* error = nil;
        
        // There are a number of hints we can give to the reader, including
        // possible formats, allowed lengths, and the string encoding.
        ZXDecodeHints* hints = [ZXDecodeHints hints];
        [hints addPossibleFormat:kBarcodeFormatQRCode];
        
        ZXResult* result = [self.decoder decode:bitmap
                                          hints:hints
                                          error:&error];
        if (result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self didDecodeImageWithResult:result];
            });
        }
    } else {
      NSLog(@"Unable to lock buffer %d", ret);
    }
  } else {
    NSLog(@"Unable to get imageBuffer from %@", sampleBuffer);
  }
  }
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


#pragma mark - DecoderDelegate

- (void)didDecodeImageWithResult:(ZXResult *)twoDResult
{
  if (self.handleCapture) {
    self.handleCapture = NO;
    NSString *urlString = twoDResult.text;
    NSURL *url = [NSURL URLWithString:urlString];
    OTPAuthURL *authURL = [OTPAuthURL authURLWithURL:url
                                              secret:nil];
    [self.avSession stopRunning];
    if (authURL) {
      [self.delegate entryController:self didCreateAuthURL:authURL];
      [self dismissViewControllerAnimated:NO completion:nil];
    } else {
      NSString *title = @"Invalid Barcode";
      NSString *message = [NSString stringWithFormat: @"The barcode '%@' is not a valid authentication token barcode.", urlString];
      NSString *button = @"Try Again";
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:button
                                             otherButtonTitles:nil];
      [alert show];
    }
  }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView
    didDismissWithButtonIndex:(NSInteger)buttonIndex {
  self.handleCapture = YES;
  [self.avSession startRunning];
}

@end
