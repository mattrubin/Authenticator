//
//  OTPRootViewController.m
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

#import "OTPRootViewController.h"
#import "OTPAuthURL.h"
#import "OTPTableViewCell.h"
#import "TOTPGenerator.h"
#import "OTPTempManager.h"


@interface OTPRootViewController ()
@property(nonatomic, readwrite, strong) OTPClock *clock;
- (void)showCopyMenu:(UIGestureRecognizer *)recognizer;
@end

@implementation OTPRootViewController

@synthesize manager;
@synthesize delegate = delegate_;
@synthesize clock = clock_;
@synthesize addItem = addItem_;

- (void)dealloc {
  [self.clock invalidate];
  self.delegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // On an iPad, support both portrait modes and landscape modes.
    return UIInterfaceOrientationIsLandscape(interfaceOrientation) ||
           UIInterfaceOrientationIsPortrait(interfaceOrientation);
  }
  // On a phone/pod, don't support upside-down portrait.
  return interfaceOrientation == UIInterfaceOrientationPortrait ||
         UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)viewDidLoad {
  UITableView *view = (UITableView *)self.view;
  view.dataSource = self.delegate;
  view.delegate = self.delegate;
  view.backgroundColor = [UIColor otpBackgroundColor];

  UIButton *titleButton = [[UIButton alloc] init];
  [titleButton setTitle:@"Authenticator"
               forState:UIControlStateNormal];
  UILabel *titleLabel = [titleButton titleLabel];
  titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
  titleLabel.shadowOffset = CGSizeMake(0.0, -1.0);
  [titleButton setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.5]
                          forState:UIControlStateNormal];
  titleButton.adjustsImageWhenHighlighted = NO;
  [titleButton sizeToFit];

  UINavigationItem *navigationItem = self.navigationItem;
  navigationItem.titleView = titleButton;
  self.clock = [[OTPClock alloc] initWithFrame:CGRectMake(0,0,30,30)
                                                period:[TOTPGenerator defaultPeriod]];
  UIBarButtonItem *clockItem
    = [[UIBarButtonItem alloc] initWithCustomView:clock_];
  [navigationItem setLeftBarButtonItem:clockItem animated:NO];
    
    [[UINavigationBar appearance] setTintColor:[UIColor otpBarColor]];
    [[UIToolbar appearance] setTintColor:[UIColor otpBarColor]];
    [[UISegmentedControl appearance] setTintColor:[UIColor otpBarColor]];

    UILongPressGestureRecognizer *gesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(showCopyMenu:)];
    [view addGestureRecognizer:gesture];
    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                 action:@selector(showCopyMenu:)];
    doubleTap.numberOfTapsRequired = 2;
    [view addGestureRecognizer:doubleTap];
    
    self.addItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAuthURL:)];
    self.addItem.style = UIBarButtonItemStyleBordered;
    
    self.toolbarItems = @[self.editButtonItem,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.addItem];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.manager updateUI];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  self.addItem.enabled = !editing;
}

- (void)showCopyMenu:(UIGestureRecognizer *)recognizer {
  BOOL isLongPress =
      [recognizer isKindOfClass:[UILongPressGestureRecognizer class]];
  if ((isLongPress && recognizer.state == UIGestureRecognizerStateBegan) ||
      (!isLongPress && recognizer.state == UIGestureRecognizerStateRecognized)) {
    CGPoint location = [recognizer locationInView:self.view];
    UITableView *view = (UITableView*)self.view;
    NSIndexPath *indexPath = [view indexPathForRowAtPoint:location];
    UITableViewCell* cell = [view cellForRowAtIndexPath:indexPath];
    if ([cell respondsToSelector:@selector(showCopyMenu:)]) {
      location = [view convertPoint:location toView:cell];
      [(OTPTableViewCell*)cell showCopyMenu:location];
    }
  }
}


#pragma mark -
#pragma mark Actions

- (void)addAuthURL:(id)sender
{
    [self setEditing:NO animated:NO];
    
    OTPEntryController *entryController = [[OTPEntryController alloc] init];
    entryController.delegate = self.manager;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:entryController];
    
    [self presentModalViewController:nc animated:YES];
}

@end

