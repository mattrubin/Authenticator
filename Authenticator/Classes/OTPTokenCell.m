//
//  OTPTokenCell.m
//  Authenticator
//
//  Created by Matt Rubin on 9/8/13.
//  Copyright (c) 2013 Matt Rubin. All rights reserved.
//

#import "OTPTokenCell.h"
#import <MobileCoreServices/MobileCoreServices.h>


@implementation OTPTokenCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self addObserver:self forKeyPath:@"token" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    }
    return self;
}

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
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:OTPAuthURLDidGenerateNewOTPNotification
                                                      object:change[NSKeyValueChangeOldKey]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refresh)
                                                     name:OTPAuthURLDidGenerateNewOTPNotification
                                                   object:change[NSKeyValueChangeNewKey]];
    }
}

- (void)refresh
{
    self.textLabel.text = self.token.otpCode;
}

@end


#pragma mark - Shim

@implementation OTPTableViewCell
- (void)setAuthURL:(OTPAuthURL *)authURL {
    [self setToken:authURL];
}
- (void)showCopyMenu:(CGPoint)location {}
@end

@implementation HOTPTableViewCell
@end

@implementation TOTPTableViewCell
@end
