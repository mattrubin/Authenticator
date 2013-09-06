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
#import "GTMDefines.h"


@interface OTPClock ()
@property (nonatomic, strong, readwrite) NSTimer *timer;
@property (nonatomic, assign, readwrite) NSTimeInterval period;
- (void)startUpTimer;
@end

@implementation OTPClock

@synthesize timer = timer_;
@synthesize period = period_;

- (id)initWithFrame:(CGRect)frame period:(NSTimeInterval)period {
  if ((self = [super initWithFrame:frame])) {
    [self startUpTimer];
    self.opaque = NO;
    self.period = period;
    UIApplication *app = [UIApplication sharedApplication];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(applicationDidBecomeActive:)
               name:UIApplicationDidBecomeActiveNotification
             object:app];
    [nc addObserver:self
           selector:@selector(applicationWillResignActive:)
               name:UIApplicationWillResignActiveNotification
             object:app];
  }
  return self;
}

- (void)dealloc {
  _GTMDevAssert(!self.timer, @"Need to call invalidate on clock!");
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)redrawTimer:(NSTimer *)timer {
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  NSTimeInterval seconds = [[NSDate date] timeIntervalSince1970];
  NSTimeInterval mod =  fmod(seconds, self.period);
  CGFloat percent = (float)(mod / self.period);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect bounds = self.bounds;

  // Clear the context
  [[UIColor clearColor] setFill];
  CGContextFillRect(context, rect);

  // Set the color
  UIColor *drawColor = [UIColor otpBackgroundColor];
  CGFloat redBuffer = 0.2f;
  if (percent > (1-redBuffer)) {
    CGFloat percentRed = (percent - (1-redBuffer)) / redBuffer;
    drawColor = [UIColor colorWithRed:1.0f green:1.0f-percentRed blue:1.0f-percentRed alpha:1];
  }
  [drawColor setFill];
  [drawColor setStroke];

  // Draw the wedge
  CGFloat midX = CGRectGetMidX(bounds);
  CGFloat midY = CGRectGetMidY(bounds);
  CGFloat radius = midY - 4;
  CGContextMoveToPoint(context, midX, midY);
  CGFloat start = - (float)M_PI_2;
  CGFloat end = 2 * (float)M_PI;
  CGFloat sweep = end * percent + start;
  CGContextAddArc(context, midX, midY, radius, start, sweep, 1);
  CGContextFillPath(context);

  // Draw the border
  CGContextMoveToPoint(context, midX + radius , midY);
  CGContextAddArc(context, midX, midY, radius, 0, 2.0 * (float)M_PI, 1);
  CGContextStrokePath(context);

}

- (void)invalidate {
  [self.timer invalidate];
  self.timer = nil;
}

- (void)startUpTimer {
  self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                target:self
                                              selector:@selector(redrawTimer:)
                                              userInfo:nil
                                               repeats:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self startUpTimer];
  [self redrawTimer:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
  [self invalidate];
}

@end
