//
//  OTPClock.m
//
//  Copyright 2013 Matt Rubin
//  Copyright 2011 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "OTPClock.h"


@interface OTPClock ()

@property (nonatomic, strong) NSTimer *timer;

@end


@implementation OTPClock

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = NO;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startTimer)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:[UIApplication sharedApplication]];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stopTimer)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:[UIApplication sharedApplication]];

        [self startTimer];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


#pragma mark - Timer

- (void)startTimer
{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(tick)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)tick
{
    [self setNeedsDisplay];
}

- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}


#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Set the line style
    CGContextSetLineWidth(context, 1.5);

    // Get the dimensions
    CGFloat midX = CGRectGetMidX(self.bounds);
    CGFloat midY = CGRectGetMidY(self.bounds);
    CGFloat radius = midY - 4;

    NSTimeInterval seconds = fmod([[NSDate date] timeIntervalSince1970], self.period);
    CGFloat percent = (CGFloat)(seconds / self.period);

    // Draw the time remaining
    [self.tintColor setStroke];
    CGFloat startAngle = -(CGFloat)M_PI_2;
    CGFloat endAngle = startAngle + percent * (CGFloat)(2 * M_PI);
    CGContextAddArc(context, midX, midY, radius, startAngle, endAngle, 1);
    CGContextStrokePath(context);

    // Draw the full circle
    [[self.tintColor colorWithAlphaComponent:0.2f] setStroke];
    CGContextAddArc(context, midX, midY, radius, 0, 2.0 * (CGFloat)M_PI, 1);
    CGContextStrokePath(context);
}

@end
