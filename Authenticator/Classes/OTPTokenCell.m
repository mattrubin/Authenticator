//
//  OTPTokenCell.m
//  Authenticator
//
//  Created by Matt Rubin on 9/8/13.
//  Copyright (c) 2013 Matt Rubin. All rights reserved.
//

#import "OTPTokenCell.h"


@implementation OTPTokenCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end


#pragma mark - Shim

@implementation OTPTableViewCell
- (void)setAuthURL:(OTPAuthURL *)authURL {}
- (void)showCopyMenu:(CGPoint)location {}
@end

@implementation HOTPTableViewCell
@end

@implementation TOTPTableViewCell
@end
