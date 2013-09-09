//
//  OTPTokenCell.m
//  Authenticator
//
//  Created by Matt Rubin on 9/8/13.
//  Copyright (c) 2013 Matt Rubin. All rights reserved.
//

#import "OTPTokenCell.h"
#import <MobileCoreServices/MobileCoreServices.h>


@interface OTPTokenCell ()

@property (nonatomic, strong) UILabel *nameLabel;
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
    self.nameLabel = [UILabel new];
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

@end


#pragma mark - Shim

@implementation OTPTableViewCell
@end

@implementation HOTPTableViewCell

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

@implementation TOTPTableViewCell
@end
