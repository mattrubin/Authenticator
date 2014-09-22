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
#import <OneTimePassword/OneTimePassword.h>
#import "OTPTokenEntryViewController.h"


@interface _OTPTokenListViewController ()


@end


@implementation _OTPTokenListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.tokenManager = [OTPTokenManager new];
    }
    return self;
}


- (void)tick
{
    // TODO: only update cells for tokens whose passwords have changed
    for (OTPTokenCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[OTPTokenCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            OTPToken *token = [self.tokenManager tokenAtIndexPath:indexPath];
            [cell setPassword:token.password];
        }
    }

    NSTimeInterval period = [OTPToken defaultPeriod];
    self.ring.progress = fmod([NSDate date].timeIntervalSince1970, period) / period;
}

@end
