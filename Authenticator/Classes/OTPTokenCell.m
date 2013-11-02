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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#import <SVProgressHUD/SVProgressHUD.h>
#pragma clang diagnostic pop


@interface OTPTokenCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nameLabel;
@property (nonatomic, strong) UILabel *passwordLabel;

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
        
        [self addObserver:self forKeyPath:@"token" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"token"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Subviews

- (void)createSubviews
{
    self.nameLabel = [UITextField new];
    self.nameLabel.font = [UIFont systemFontOfSize:15];
    self.nameLabel.returnKeyType = UIReturnKeyDone;
    self.nameLabel.delegate = self;
    self.nameLabel.enabled = NO;
    
    self.passwordLabel = [UILabel new];
    self.passwordLabel.font = [UIFont systemFontOfSize:50];
    self.passwordLabel.backgroundColor = [UIColor otpBackgroundColor];
    
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.passwordLabel];
    
    CGRect frame = CGRectInset(self.contentView.bounds, 10, 5);
    frame.size.height = 20;
    self.nameLabel.frame = frame;
    frame.origin.y += frame.size.height;
    self.passwordLabel.frame = frame;
    
    self.nameLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.passwordLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    [[UIPasteboard generalPasteboard] setValue:self.token.otpCode forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];

    [SVProgressHUD showSuccessWithStatus:@"Copied"];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self) && [keyPath isEqualToString:@"token"]) {
        [self refresh];
        
        OTPAuthURL *oldObject = change[NSKeyValueChangeOldKey];
        if (oldObject && ![oldObject isKindOfClass:[NSNull class]]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:OTPTokenDidUpdateNotification
                                                          object:oldObject.token];
        }
        
        OTPAuthURL *newObject = change[NSKeyValueChangeNewKey];
        if (newObject && ![newObject isKindOfClass:[NSNull class]]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(refresh)
                                                         name:OTPTokenDidUpdateNotification
                                                       object:newObject.token];
        }
    }
}

- (void)refresh
{
    self.nameLabel.text = self.token.name;
    self.passwordLabel.text = self.token.otpCode;
}


#pragma mark - Editing

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.nameLabel.enabled = editing;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.nameLabel.textColor = editing ? [UIColor blackColor] : [UIColor otpBarColor];
        self.passwordLabel.alpha = !editing ? 1 : 0.2;
    }];
    
    if (!editing) {
        [self.nameLabel resignFirstResponder];
        
        if (![self.token.name isEqualToString:self.nameLabel.text]) {
            self.token.name = self.nameLabel.text;
            [self.token saveToKeychain];
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end


#pragma mark -

@implementation HOTPTokenCell

- (void)createSubviews
{
    [super createSubviews];
    
    UIButton *nextPasswordButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
    [nextPasswordButton addTarget:self action:@selector(generateNextPassword) forControlEvents:UIControlEventTouchUpInside];
    self.accessoryView = nextPasswordButton;
}

- (void)generateNextPassword
{
    if (self.token.token.type == OTPTokenTypeCounter) {
        [self.token generateNextOTPCode];
    }
}

@end


#pragma mark -

@implementation TOTPTokenCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Ensure that TOTPs are updated when the app returns from the background
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}
@end
