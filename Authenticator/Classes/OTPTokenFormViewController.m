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


@interface OTPTokenFormViewController ()

@property (nonatomic, strong) id<TokenForm> form;

@end


@implementation OTPTokenFormViewController


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
    if ([cell respondsToSelector:@selector(preferredHeight)]) {
        return [(id)cell preferredHeight];
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [self.form viewForHeaderInSection:section];
    if (headerView && [headerView respondsToSelector:@selector(preferredHeight)]) {
        return [(id)headerView preferredHeight];
    }
    return FLT_EPSILON;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self.form viewForHeaderInSection:section];
}


#pragma mark - Validation

- (void)validateForm
{
    self.doneButtonItem.enabled = self.form.isValid;
}


#pragma mark - Bridge

- (id)form_bridge {
    return self.form;
}

- (void)setForm_bridge:(id)form_bridge {
    self.form = form_bridge;
}

@end
