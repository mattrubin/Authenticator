//
//  OTPTokenListViewController.m
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

#import "OTPTokenListViewController.h"
#import "OTPTokenManager.h"
#import "OTPTokenCell.h"
#import "OTPClock.h"
#import "OTPToken.h"
#import "OTPTokenEntryViewController.h"


@interface OTPTokenListViewController ()

@property (nonatomic, strong) OTPTokenManager *tokenManager;
@property (nonatomic, strong) OTPClock *clock;
@property (nonatomic, strong) UIBarButtonItem *addButtonItem;

@end


@implementation OTPTokenListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tokenManager = [OTPTokenManager sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Authenticator";
    self.view.backgroundColor = [UIColor otpBackgroundColor];

    self.clock = [[OTPClock alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.clock.period = [OTPToken defaultPeriod];
    UIBarButtonItem *clockBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.clock];
    self.navigationItem.leftBarButtonItem = clockBarItem;

    self.addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToken)];
    self.toolbarItems = @[self.editButtonItem,
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          self.addButtonItem];
    self.navigationController.toolbarHidden = NO;

    [self update];
}

- (void)update
{
    // Show the countdown clock only if a time-based token is active
    self.clock.hidden = YES;
    for (OTPToken *token in self.tokenManager.tokens) {
        if (token.type == OTPTokenTypeTimer) {
            self.clock.hidden = NO;
            break;
        }
    }

    self.editButtonItem.enabled = !!self.tokenManager.tokens.count;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger) self.tokenManager.tokens.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OTPTokenCell *cell = [OTPTokenCell cellForTableView:tableView];
    cell.token = self.tokenManager.tokens[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if ([self.tokenManager removeTokenAtIndex:(NSUInteger)indexPath.row]) {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self update];

            if (!self.tokenManager.tokens.count) {
                [self setEditing:NO animated:YES];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    [self.tokenManager moveTokenFromIndex:(NSUInteger)fromIndexPath.row toIndex:(NSUInteger)toIndexPath.row];
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}


#pragma mark - Target actions

- (void)addToken
{
    OTPTokenEntryViewController *entryController = [OTPTokenEntryViewController new];
    entryController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:entryController];

    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - Token source delegate

- (void)tokenSource:(id)tokenSource didCreateToken:(OTPToken *)token
{
    [self dismissViewControllerAnimated:YES completion:nil];

    if ([self.tokenManager addToken:token]) {
        [self.tableView reloadData];
        [self update];
    }
}

@end
