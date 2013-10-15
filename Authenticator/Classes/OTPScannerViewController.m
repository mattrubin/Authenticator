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
#import <AVFoundation/AVFoundation.h>
#import "OTPScannerOverlayView.h"


@interface OTPScannerViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

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
        AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:nil];
        [captureSession addInput:captureInput];

        AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init];
        dispatch_queue_t sampleBufferQueue = dispatch_queue_create("OTPScannerViewController sampleBufferQueue", NULL);
        [captureOutput setSampleBufferDelegate:self queue:sampleBufferQueue];
        captureOutput.alwaysDiscardsLateVideoFrames = YES;
        captureOutput.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
        [captureSession addOutput:captureOutput];

        [captureSession startRunning];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.captureSession = captureSession;
            self.videoLayer.session = captureSession;
        });
    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!imageBuffer) return;

    CVReturn resultCode = CVPixelBufferLockBaseAddress(imageBuffer, 0);
    if (resultCode == kCVReturnSuccess) {
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        if (colorSpace) {
            CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                                         (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
            if (context) {
                CGImageRef cgImage = CGBitmapContextCreateImage(context);
                if (cgImage) {
                    // Decode the image
                    //[self readBarcodeFromCGImage:cgImage];

                    // Clean up
                    CGImageRelease(cgImage);
                }
                CGContextRelease(context);
            }
            CGColorSpaceRelease(colorSpace);
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
}

@end
