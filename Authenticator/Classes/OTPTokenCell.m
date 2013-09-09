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
#import <MobileCoreServices/MobileCoreServices.h>


@interface OTPTokenCell () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nameLabel;
@property (nonatomic, strong) UILabel *passwordLabel;

@end


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
    self.nameLabel.returnKeyType = UIReturnKeyDone;
    self.nameLabel.delegate = self;
    self.nameLabel.enabled = NO;
    
    self.passwordLabel = [UILabel new];
    
    [self.contentView addSubview:self.nameLabel];
    [self.contentView addSubview:self.passwordLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = CGRectInset(self.bounds, 10, 5);
    frame.size.height = frame.size.height/2;
    self.nameLabel.frame = frame;
    frame.origin.y += frame.size.height;
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
    // TODO: show "Copied" notification
    NSLog(@"Copied %@!", self.token.name);
    [[UIPasteboard generalPasteboard] setValue:self.token.otpCode forPasteboardType:(__bridge NSString *)kUTTypeUTF8PlainText];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((object == self) && [keyPath isEqualToString:@"token"]) {
        [self refresh];
        
        OTPAuthURL *oldObject = change[NSKeyValueChangeOldKey];
        if (oldObject) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:OTPAuthURLDidGenerateNewOTPNotification
                                                          object:oldObject];
        }
        
        OTPAuthURL *newObject = change[NSKeyValueChangeNewKey];
        if (newObject) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(refresh)
                                                         name:OTPAuthURLDidGenerateNewOTPNotification
                                                       object:newObject];
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
    self.nameLabel.borderStyle = editing ? UITextBorderStyleLine : UITextBorderStyleNone;
    
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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIButton *nextPasswordButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [nextPasswordButton addTarget:self action:@selector(generateNextPassword) forControlEvents:UIControlEventTouchUpInside];
        self.accessoryView = nextPasswordButton;
    }
    return self;
}

- (void)generateNextPassword
{
    if ([self.token isKindOfClass:[HOTPAuthURL class]]) {
        [(HOTPAuthURL *)self.token generateNextOTPCode];
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
