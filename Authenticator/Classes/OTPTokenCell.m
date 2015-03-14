//
//  OTPTokenCell.m
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

#import "OTPTokenCell.h"


// TODO: Show integrity check for counter-based tokens?
// TODO: Show warning when a TOTP is about to change?


@implementation OTPTokenCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self createSubviews];
    }
    return self;
}


#pragma mark - Subviews

- (void)createSubviews
{
    self.backgroundColor = [UIColor otpBackgroundColor];

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:15];
    self.titleLabel.textColor = [UIColor otpForegroundColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;

    self.passwordLabel = [UILabel new];
    self.passwordLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:50];
    self.passwordLabel.textColor = [UIColor otpForegroundColor];
    self.passwordLabel.textAlignment = NSTextAlignmentCenter;

    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.passwordLabel];

    self.nextPasswordButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.nextPasswordButton.tintColor = [UIColor otpForegroundColor];
    [self.nextPasswordButton addTarget:self action:@selector(generateNextPassword) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.nextPasswordButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect insetFrame = [self convertRect:self.bounds toView:self.contentView];
    insetFrame.origin.x = MIN(insetFrame.origin.x, self.contentView.bounds.origin.x);

    CGRect frame = insetFrame;
    frame.size.height = 20;
    self.titleLabel.frame = frame;

    frame = insetFrame;
    frame.origin.y += 20;
    frame.size.height -= 30;
    self.passwordLabel.frame = frame;

    self.nextPasswordButton.center = CGPointMake(CGRectGetMaxX(insetFrame) - 25,
                                                 CGRectGetMidY(self.passwordLabel.frame));
}

@end
