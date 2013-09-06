//
//  OTPEntryController.h
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

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "DecoderDelegate.h"

@class OTPAuthURL;
@protocol OTPEntryControllerDelegate;

@interface OTPEntryController : UIViewController
    <UITextFieldDelegate,
     UINavigationControllerDelegate,
     DecoderDelegate,
     UIAlertViewDelegate,
     AVCaptureVideoDataOutputSampleBufferDelegate> {
 @private
  dispatch_queue_t queue_;
}

@property(nonatomic, readwrite, unsafe_unretained) id<OTPEntryControllerDelegate> delegate;
@property(nonatomic, readwrite, strong) IBOutlet UITextField *accountName;
@property(nonatomic, readwrite, strong) IBOutlet UITextField *accountKey;
@property(nonatomic, readwrite, strong) IBOutlet UILabel *accountNameLabel;
@property(nonatomic, readwrite, strong) IBOutlet UILabel *accountKeyLabel;
@property(nonatomic, readwrite, strong) IBOutlet UISegmentedControl *accountType;
@property(nonatomic, readwrite, strong) IBOutlet UIButton *scanBarcodeButton;
@property(nonatomic, readwrite, strong) IBOutlet UIScrollView *scrollView;

- (IBAction)accountNameDidEndOnExit:(id)sender;
- (IBAction)accountKeyDidEndOnExit:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)scanBarcode:(id)sender;

@end

@protocol OTPEntryControllerDelegate

- (void)entryController:(OTPEntryController*)controller
       didCreateAuthURL:(OTPAuthURL *)authURL;

@end

