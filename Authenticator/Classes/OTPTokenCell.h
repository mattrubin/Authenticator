//
//  OTPTokenCell.h
//  Authenticator
//
//  Created by Matt Rubin on 9/8/13.
//  Copyright (c) 2013 Matt Rubin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTPAuthURL.h"


@interface OTPTokenCell : UITableViewCell

@end


#pragma mark - Shim

@interface OTPTableViewCell : OTPTokenCell
- (void)setAuthURL:(OTPAuthURL *)authURL;
- (void)showCopyMenu:(CGPoint)location;
@end

@interface HOTPTableViewCell : OTPTableViewCell
@end

@interface TOTPTableViewCell : OTPTableViewCell
@end
