//
//  OTPToken+Timer.m
//  Authenticator
//
//  Created by Matt Rubin on 10/31/13.
//  Copyright (c) 2013 Matt Rubin. All rights reserved.
//

#import "OTPToken+Timer.h"


static NSString *const OTPTokenTimerNotification = @"OTPTokenTimerNotification";


@implementation OTPToken (Timer)

+ (void)load
{
    static NSTimer *sharedTimer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTimer = [NSTimer scheduledTimerWithTimeInterval:.01
                                                       target:self
                                                     selector:@selector(updateAllTokens)
                                                     userInfo:nil
                                                      repeats:YES];
    });
}

+ (void)updateAllTokens
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPTokenTimerNotification object:self];
}

@end
