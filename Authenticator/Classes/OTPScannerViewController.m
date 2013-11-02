//
//  OTPScannerViewController.m
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

#import "OTPScannerViewController.h"
@import AVFoundation;
#import "OTPScannerOverlayView.h"
#import "OTPToken+Serialization.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#import <SVProgressHUD/SVProgressHUD.h>
#pragma clang diagnostic pop


@interface OTPScannerViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoLayer;

@end


@implementation OTPScannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self createCaptureSession];
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    self.videoLayer = [AVCaptureVideoPreviewLayer layer];
    self.videoLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.videoLayer];
    self.videoLayer.frame = self.view.layer.bounds;

    OTPScannerOverlayView *overlayView = [[OTPScannerOverlayView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:overlayView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.captureSession startRunning];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.captureSession stopRunning];
}


#pragma mark - Video Capture

- (void)createCaptureSession
{
    dispatch_queue_t async_queue = dispatch_queue_create("OTPScannerViewController createCaptureSession", NULL);
    dispatch_async(async_queue, ^{
        AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];

        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        NSError *error = nil;
        AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        if (!captureInput) {
            NSLog(@"Error: %@", error);
            [self showErrorWithStatus:@"Capture Failed"];
            return;
        }
        [captureSession addInput:captureInput];

        AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
        [captureSession addOutput:captureOutput];
        if (![captureOutput.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [self showErrorWithStatus:@"Not Supported"];
            return;
        }
        captureOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

        [captureSession startRunning];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.captureSession = captureSession;
            self.videoLayer.session = captureSession;
        });
    });
}

- (void)showErrorWithStatus:(NSString *)statusString
{
    // Ensure this executes on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:statusString];
    });
}


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    NSString *decodedText = nil;
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            decodedText = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            break;
        }
    }
    [self handleDecodedText:decodedText];
}

- (void)handleDecodedText:(NSString *)decodedText
{
    // Attempt to create an auth URL from the decoded text
    NSURL *url = [NSURL URLWithString:decodedText];
    OTPToken *authURL = [OTPToken tokenWithURL:url secret:nil];

    if (authURL) {
        // Halt the video capture
        [self.captureSession stopRunning];

        // Inform the delegate that an auth URL was captured
        id <OTPTokenSourceDelegate> delegate = self.delegate;
        [delegate tokenSource:self didCreateToken:authURL];
    } else {
        // Show an error message
        [SVProgressHUD showErrorWithStatus:@"Invalid Token"];
    }
}


#pragma mark - Class Methods

+ (BOOL)deviceCanScan
{
    return !![AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
}

@end
