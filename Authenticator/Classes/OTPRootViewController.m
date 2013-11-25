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
#import "OTPTokenManager.h"
#import "OTPTokenCell.h"
#import "OTPToken+Persistence.h"
#import "UIColor+OTP.h"
#import "OTPClock.h"
#import "OTPTokenEntryViewController.h"


@interface OTPRootViewController ()

@property (nonatomic, strong) OTPClock *clock;
@property (nonatomic, strong) UIBarButtonItem *addButtonItem;
@property (nonatomic, strong) OTPTokenManager *tokenManager;

@end


@implementation OTPRootViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor otpBackgroundColor];
    
    self.title = @"Authenticator";
    
    self.clock = [[OTPClock alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.clock.period = [OTPToken defaultPeriod];
    UIBarButtonItem *clockItem = [[UIBarButtonItem alloc] initWithCustomView:self.clock];
    [self.navigationItem setLeftBarButtonItem:clockItem animated:NO];
    
    self.addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToken:)];
    self.addButtonItem.style = UIBarButtonItemStyleBordered;
    
    self.toolbarItems = @[self.editButtonItem,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.addButtonItem];
    self.navigationController.toolbarHidden = NO;
    
    self.tokenManager = [OTPTokenManager sharedManager];

    [self.tokenManager fetchTokensFromKeychain];
    [self updateUI];

    // Prepare table view
    [self.tableView registerClass:[OTPTokenCell class] forCellReuseIdentifier:NSStringFromClass([OTPTokenCell class])];
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
    for (OTPToken *token in self.tokenManager.tokens) {
        if (token.type == OTPTokenTypeTimer) {
            hidden = NO;
            break;
        }
    }
    self.clock.hidden = hidden;
    
    self.editButtonItem.enabled = (self.tokenManager.tokens.count > 0);
}


#pragma mark - Actions

- (void)addToken:(id)sender
{
    [self setEditing:NO animated:NO];
    
    OTPTokenEntryViewController *entryController = [[OTPTokenEntryViewController alloc] init];
    entryController.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:entryController];
    
    [self presentViewController:nc animated:YES completion:nil];
}


#pragma mark - OTPTokenSourceDelegate

- (void)tokenSource:(id)tokenSource didCreateToken:(OTPToken *)token
{
    if ([tokenSource isKindOfClass:[OTPTokenEntryViewController class]]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }

    if ([self.tokenManager addToken:token]) {
        [self updateUI];
        [self.tableView reloadData];
    }
}


#pragma mark - UITableViewDataSource
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wsign-conversion"

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tokenManager.tokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTPTokenCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([OTPTokenCell class]) forIndexPath:indexPath];
    cell.token = self.tokenManager.tokens[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)source toIndexPath:(NSIndexPath *)destination
{
    id object = (self.tokenManager.tokens)[source.row];
    [self.tokenManager.tokens removeObjectAtIndex:source.row];
    [self.tokenManager.tokens insertObject:object atIndex:destination.row];
    
    [self.tokenManager saveTokensToKeychain];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView beginUpdates];
        
        NSUInteger idx = indexPath.row;
        NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
        [tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
        
        OTPToken *token = (self.tokenManager.tokens)[idx];
        [token removeFromKeychain];
        [self.tokenManager.tokens removeObjectAtIndex:idx];
        [self.tokenManager saveTokensToKeychain];
        
        [tableView endUpdates];
        
        [self updateUI];
        if (!self.tokenManager.tokens.count) {
            [self setEditing:NO animated:YES];
        }
    }
}

#pragma clang diagnostic pop


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

@end
