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
#import <OneTimePassword/OneTimePassword.h>


@interface OTPTokenCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *passwordLabel;
@property (nonatomic, strong) UIButton *nextPasswordButton;

@end


// TODO: Show integrity check for counter-based tokens?
// TODO: Show warning when a TOTP is about to change?


@implementation OTPTokenCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        [self createSubviews];

        [self addObserver:self forKeyPath:@"token.password" options:0 context:nil];

        // Ensure that TOTPs are updated when the app returns from the background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"token.password"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)generateNextPassword
{
    [self.token updatePassword];
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


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self refresh];
}

- (void)refresh
{
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] init];
    if (self.token.issuer.length) {
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:self.token.issuer attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:15]}]];
    }
    if (self.token.issuer.length && self.token.name.length) {
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    }
    if (self.token.name.length) {
        [titleString appendAttributedString:[[NSAttributedString alloc] initWithString:self.token.name]];
    }
    self.titleLabel.attributedText = titleString;

    self.passwordLabel.attributedText = [[NSAttributedString alloc] initWithString:self.token.password attributes:@{NSKernAttributeName: @2}];
    self.nextPasswordButton.hidden = self.token.type != OTPTokenTypeCounter;
}


#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    [UIView animateWithDuration:0.3 animations:^{
        self.passwordLabel.alpha = !editing ? 1 : (CGFloat)0.2;
        self.nextPasswordButton.alpha = !editing ? 1 : 0;
    }];
}

@end
