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
#import "UIColor+OTP.h"
#import "OTPClock.h"
#import <GTMDefines.h>


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@interface OTPRootViewController ()

@property (nonatomic, strong) OTPClock *clock;
@property (nonatomic, strong) UIBarButtonItem *addButtonItem;
@property (nonatomic, strong) NSMutableArray *authURLs;

@end


@implementation OTPRootViewController

@synthesize clock;
@synthesize addButtonItem;
@synthesize authURLs;


- (void)dealloc {
  [self.clock invalidate];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor otpBackgroundColor];
    
    self.title = @"Authenticator";
    
    self.clock = [[OTPClock alloc] initWithFrame:CGRectMake(0,0,30,30)
                                          period:[TOTPGenerator defaultPeriod]];
    UIBarButtonItem *clockItem = [[UIBarButtonItem alloc] initWithCustomView:self.clock];
    [self.navigationItem setLeftBarButtonItem:clockItem animated:NO];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showCopyMenu:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showCopyMenu:)];
    [self.view addGestureRecognizer:longPress];
    
    self.addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAuthURL:)];
    self.addButtonItem.style = UIBarButtonItemStyleBordered;
    
    self.toolbarItems = @[self.editButtonItem,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.addButtonItem];
    self.navigationController.toolbarHidden = NO;
    
    [self fetchKeychainArray];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateUI];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    self.addButtonItem.enabled = !editing;
}


#pragma mark - Actions

- (void)showCopyMenu:(UIGestureRecognizer *)recognizer
{
    BOOL isLongPress = [recognizer isKindOfClass:[UILongPressGestureRecognizer class]];
    if ((isLongPress && recognizer.state == UIGestureRecognizerStateBegan) ||
        (!isLongPress && recognizer.state == UIGestureRecognizerStateRecognized)) {
        CGPoint location = [recognizer locationInView:self.view];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        if ([cell respondsToSelector:@selector(showCopyMenu:)]) {
            location = [self.view convertPoint:location toView:cell];
            [(OTPTableViewCell*)cell showCopyMenu:location];
        }
    }
}

- (void)addAuthURL:(id)sender
{
    [self setEditing:NO animated:NO];
    
    OTPEntryController *entryController = [[OTPEntryController alloc] init];
    entryController.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:entryController];
    
    [self presentModalViewController:nc animated:YES];
}


#pragma mark - TEMP -

- (void)updateUI {
    BOOL hidden = YES;
    for (OTPAuthURL *url in self.authURLs) {
        if ([url isMemberOfClass:[TOTPAuthURL class]]) {
            hidden = NO;
            break;
        }
    }
    self.clock.hidden = hidden;
    self.editButtonItem.enabled = (self.authURLs.count > 0);
}


#pragma mark - Keychain

- (void)saveKeychainArray
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSArray *keychainReferences = [self valueForKeyPath:@"authURLs.keychainItemRef"];
    [ud setObject:keychainReferences forKey:kOTPKeychainEntriesArray];
    [ud synchronize];
}

- (void)fetchKeychainArray
{
    NSArray *savedKeychainReferences = [[NSUserDefaults standardUserDefaults] arrayForKey:kOTPKeychainEntriesArray];
    self.authURLs = [NSMutableArray arrayWithCapacity:[savedKeychainReferences count]];
    for (NSData *keychainRef in savedKeychainReferences) {
        OTPAuthURL *authURL = [OTPAuthURL authURLWithKeychainItemRef:keychainRef];
        if (authURL) {
            [self.authURLs addObject:authURL];
        }
    }
}


#pragma mark - OTPEntryControllerDelegate

- (void)entryController:(OTPEntryController*)controller
       didCreateAuthURL:(OTPAuthURL *)authURL {
    [authURL saveToKeychain];
    [self.authURLs addObject:authURL];
    [self saveKeychainArray];
    [self updateUI];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = nil;
    Class cellClass = Nil;
    
    NSUInteger idx = [indexPath row];
    OTPAuthURL *url = [self.authURLs objectAtIndex:idx];
    if ([url isMemberOfClass:[HOTPAuthURL class]]) {
        cellIdentifier = @"HOTPCell";
        cellClass = [HOTPTableViewCell class];
    } else if ([url isMemberOfClass:[TOTPAuthURL class]]) {
        cellIdentifier = @"TOTPCell";
        cellClass = [TOTPTableViewCell class];
    }
    UITableViewCell *cell
    = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault
                                reuseIdentifier:cellIdentifier];
    }
    [(OTPTableViewCell *)cell setAuthURL:url];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.authURLs.count;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)destination
{
    id object = [self.authURLs objectAtIndex:source.row];
    [self.authURLs removeObjectAtIndex:source.row];
    [self.authURLs insertObject:object atIndex:destination.row];
    
    [self saveKeychainArray];
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OTPTableViewCell *cell
        = (OTPTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell didEndEditing];
        [tableView beginUpdates];
        NSUInteger idx = [indexPath row];
        OTPAuthURL *authURL = [self.authURLs objectAtIndex:idx];
        
            NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
            NSArray *rows = [NSArray arrayWithObject:path];
            [tableView deleteRowsAtIndexPaths:rows
                             withRowAnimation:UITableViewRowAnimationFade];
        [authURL removeFromKeychain];
        [self.authURLs removeObjectAtIndex:idx];
        [self saveKeychainArray];
        [tableView endUpdates];
        [self updateUI];
        if (!self.authURLs.count) {
            [self setEditing:NO animated:YES];
        }
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView*)tableView
willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    OTPTableViewCell *cell
    = (OTPTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell willBeginEditing];
}

- (void)tableView:(UITableView*)tableView
didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    OTPTableViewCell *cell
    = (OTPTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell didEndEditing];
}

@end
