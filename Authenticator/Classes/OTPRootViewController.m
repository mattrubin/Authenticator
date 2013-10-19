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
#import "OTPTokenCell.h"
#import "TOTPGenerator.h"
#import "UIColor+OTP.h"
#import "OTPClock.h"
#import "OTPTokenEntryViewController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundef"
#import <GTMDefines.h>
#pragma clang diagnostic pop


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@interface OTPRootViewController ()

@property (nonatomic, strong) OTPClock *clock;
@property (nonatomic, strong) UIBarButtonItem *addButtonItem;
@property (nonatomic, strong) NSMutableArray *authURLs;

@end


@implementation OTPRootViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor otpBackgroundColor];
    
    self.title = @"Authenticator";
    
    self.clock = [[OTPClock alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.clock.period = [TOTPGenerator defaultPeriod];
    UIBarButtonItem *clockItem = [[UIBarButtonItem alloc] initWithCustomView:self.clock];
    [self.navigationItem setLeftBarButtonItem:clockItem animated:NO];
    
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

- (void)updateUI
{
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


#pragma mark - Actions

- (void)addAuthURL:(id)sender
{
    [self setEditing:NO animated:NO];
    
    OTPTokenEntryViewController *entryController = [[OTPTokenEntryViewController alloc] init];
    entryController.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:entryController];
    
    [self presentViewController:nc animated:YES completion:nil];
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


#pragma mark - OTPTokenSourceDelegate

- (void)tokenSource:(id)tokenSource didCreateToken:(OTPAuthURL *)authURL
{
    if ([tokenSource isKindOfClass:[OTPTokenEntryViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    [authURL saveToKeychain];
    [self.authURLs addObject:authURL];
    [self saveKeychainArray];
    [self updateUI];
    [self.tableView reloadData];
}

- (void)tokenSourceDidCancel:(id)tokenSource
{
    if ([tokenSource isKindOfClass:[OTPTokenEntryViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.authURLs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Class cellClass = Nil;
    
    OTPAuthURL *url = (self.authURLs)[indexPath.row];
    if ([url isMemberOfClass:[HOTPAuthURL class]]) {
        cellClass = [HOTPTokenCell class];
    } else if ([url isMemberOfClass:[TOTPAuthURL class]]) {
        cellClass = [TOTPTokenCell class];
    }
    NSString *cellIdentifier = NSStringFromClass(cellClass);
    
    OTPTokenCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.token = url;
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)destination
{
    id object = (self.authURLs)[source.row];
    [self.authURLs removeObjectAtIndex:source.row];
    [self.authURLs insertObject:object atIndex:destination.row];
    
    [self saveKeychainArray];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        
        NSUInteger idx = indexPath.row;
        NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
        [tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
        
        OTPAuthURL *authURL = (self.authURLs)[idx];
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

@end
