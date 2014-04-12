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
@import MobileCoreServices;
#import "OTPToken+Persistence.h"
#import "OTPToken+Generation.h"


@interface OTPTokenCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nameLabel;
@property (nonatomic, strong) UITextField *issuerLabel;
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

    self.nameLabel = [UITextField new];
    self.nameLabel.font = [UIFont systemFontOfSize:15];
    self.nameLabel.textColor = [UIColor otpForegroundColor];
    self.nameLabel.returnKeyType = UIReturnKeyDone;
    self.nameLabel.delegate = self;
    self.nameLabel.enabled = NO;

    self.issuerLabel = [UITextField new];
    self.issuerLabel.font = [UIFont boldSystemFontOfSize:15];
    self.issuerLabel.textColor = [UIColor otpForegroundColor];
    self.issuerLabel.returnKeyType = UIReturnKeyNext;
    self.issuerLabel.delegate = self;
    self.issuerLabel.enabled = NO;

    self.passwordLabel = [UILabel new];
    self.passwordLabel.font = [UIFont systemFontOfSize:50];
    self.passwordLabel.textColor = [UIColor otpForegroundColor];

    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.issuerLabel];
    [self.contentView addSubview:self.passwordLabel];

    self.nextPasswordButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    self.nextPasswordButton.tintColor = [UIColor otpForegroundColor];
    [self.nextPasswordButton addTarget:self action:@selector(generateNextPassword) forControlEvents:UIControlEventTouchUpInside];
    self.accessoryView = self.nextPasswordButton;
}

- (void)generateNextPassword
{
    [self.token updatePassword];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect insetFrame = CGRectInset(self.contentView.bounds, 10, 5);

    CGRect frame = insetFrame;
    frame.size.height = 20;
    frame.size.width = (self.issuerLabel.text.length || self.editing) ? [self.issuerLabel sizeThatFits:frame.size].width : 0;
    self.issuerLabel.frame = frame;

    frame.origin.x += frame.size.width;
    frame.size.width = CGRectGetMaxX(insetFrame) - frame.origin.x;
    self.nameLabel.frame = frame;

    frame = insetFrame;
    frame.origin.y += 20;
    frame.size.height -= 20;
    self.passwordLabel.frame = frame;
}


#pragma mark - Copying

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    if (selected) {
        [self copyPassword];
    }
}

- (void)copyPassword
{
    [[UIPasteboard generalPasteboard] setValue:self.token.password forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];

    [SVProgressHUD showSuccessWithStatus:@"Copied"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self refresh];
}

- (void)refresh
{
    if (!self.editing) {
        self.nameLabel.text = self.token.name;
        self.issuerLabel.text = self.token.issuer;
    }
    self.passwordLabel.text = self.token.password;
    self.nextPasswordButton.hidden = self.token.type != OTPTokenTypeCounter;
}


#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    self.nameLabel.enabled = editing;
    self.issuerLabel.enabled = self.nameLabel.enabled;

    self.nameLabel.placeholder = editing ? @"Name" : nil;
    self.issuerLabel.placeholder = editing ? @"Issuer" : nil;

    [UIView animateWithDuration:0.3 animations:^{
        self.passwordLabel.alpha = !editing ? 1 : (CGFloat)0.2;
    }];

    if (!editing) {
        [self.nameLabel resignFirstResponder];
        [self.issuerLabel resignFirstResponder];

        [self commitChanges];
    }
}

- (void)commitChanges
{
    if (![self.token.name isEqualToString:self.nameLabel.text] ||
        ![self.token.issuer isEqualToString:self.issuerLabel.text]) {
        self.token.name = self.nameLabel.text;
        self.token.issuer = self.issuerLabel.text;
        [self.token saveToKeychain];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.issuerLabel) {
        [self.nameLabel becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

@end
