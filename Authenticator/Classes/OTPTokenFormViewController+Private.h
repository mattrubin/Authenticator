//
//  OTPTokenFormViewController+Subclassing.h
//  Authenticator
//
//  Created by Matt Rubin on 9/13/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

#import "OTPTokenFormViewController.h"


@interface OTPTokenFormViewController () <TokenFormPresenter>

@property (nonatomic, strong) id<TokenForm> form;

@end
