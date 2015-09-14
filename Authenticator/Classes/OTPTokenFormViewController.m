//
//  OTPTokenFormViewController.m
//  Authenticator
//
//  Copyright (c) 2015 Matt Rubin
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

#import "OTPTokenFormViewController.h"
#import "OTPTokenFormViewController+Private.h"


@interface OTPTokenFormViewController ()

@property (nonatomic, strong) UIBarButtonItem *doneButtonItem;

@end


@implementation OTPTokenFormViewController

- (instancetype)init
{
    return [super initWithStyle:UITableViewStyleGrouped];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor otpBackgroundColor];
    self.view.tintColor = [UIColor otpForegroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    // Set up top bar
    self.title = self.form.title;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction)];
    self.doneButtonItem = self.navigationItem.rightBarButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self validateForm];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.form focusFirstField];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.form unfocus];
}


#pragma mark - Target Actions

- (void)cancelAction
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction
{
    // Override in subclass
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.form.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.form numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.form cellForRowAtIndexPath:indexPath];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.textColor = [UIColor otpForegroundColor];
    if ([cell isKindOfClass:[OTPTextFieldCell class]]) {
        ((OTPTextFieldCell *)cell).textField.backgroundColor = [UIColor otpLightColor];
        ((OTPTextFieldCell *)cell).textField.tintColor = [UIColor otpDarkColor];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.form cellForRowAtIndexPath:indexPath];
    if ([[cell class] respondsToSelector:@selector(preferredHeight)]) {
        return [[cell class] preferredHeight];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return FLT_EPSILON;
}


#pragma mark - Validation

- (void)validateForm
{
    self.doneButtonItem.enabled = self.form.isValid;
}


#pragma mark - TokenEditFormDelegate

- (void)formValuesDidChange:(nonnull TokenEditForm *)form {
    [self validateForm];
}

- (void)formDidSubmit:(nonnull TokenEditForm *)form {
    [self doneAction];
}

@end
