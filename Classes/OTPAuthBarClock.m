//
//  OTPAuthBarClock.m
//
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

#import "OTPAuthBarClock.h"
#import "GTMDefines.h"
#import "UIColor+MobileColors.h"

@interface OTPAuthBarClock ()
@property (nonatomic, strong, readwrite) NSTimer *timer;
@property (nonatomic, assign, readwrite) NSTimeInterval period;
- (void)startUpTimer;
@end

@implementation OTPAuthBarClock

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
  [[UIColor clearColor] setFill];
  CGContextFillRect(context, rect);
  CGFloat midX = CGRectGetMidX(bounds);
  CGFloat midY = CGRectGetMidY(bounds);
  CGFloat radius = midY - 4;
  CGContextMoveToPoint(context, midX, midY);
  CGFloat start = - (float)M_PI_2;
  CGFloat end = 2 * (float)M_PI;
  CGFloat sweep = end * percent + start;
  CGContextAddArc(context, midX, midY, radius, start, sweep, 1);
  [[[UIColor googleBlueBackgroundColor] colorWithAlphaComponent:0.7f] setFill];
  CGContextFillPath(context);
  if (percent > .875) {
    CGContextMoveToPoint(context, midX, midY);
    CGContextAddArc(context, midX, midY, radius, start, sweep, 1);
    CGFloat alpha = (percent - .875f) / .125f;
    [[[UIColor redColor] colorWithAlphaComponent:alpha * 0.5f] setFill];
    CGContextFillPath(context);
  }

  // Draw top shadow
  CGFloat offset = 0.25;
  CGFloat x = midX + (radius - offset) * (float)cos(0 - M_PI_4);
  CGFloat y = midY + (radius - offset) * (float)sin(0 - M_PI_4);
  [[UIColor blackColor] setStroke];
  CGContextMoveToPoint(context, x , y);
  CGContextAddArc(context,
                  midX, midY, radius - offset, 0 - (float)M_PI_4, 5.0f * (float)M_PI_4, 1);
  CGContextStrokePath(context);

  // Draw bottom highlight
  x = midX + (radius + offset) * (float)cos(0 + M_PI_4);
  y = midY + (radius + offset) * (float)sin(0 + M_PI_4);
  [[UIColor whiteColor] setStroke];
  CGContextMoveToPoint(context, x , y);
  CGContextAddArc(context,
                  midX, midY, radius + offset, 0 + (float)M_PI_4, 3.0f * (float)M_PI_4, 0);
  CGContextStrokePath(context);

  // Draw face
  [[UIColor googleBlueTextColor] setStroke];
  CGContextMoveToPoint(context, midX + radius , midY);
  CGContextAddArc(context, midX, midY, radius, 0, 2.0 * (float)M_PI, 1);
  CGContextStrokePath(context);

  if (percent > .875) {
    CGFloat alpha = (percent - .875f) / .125f;
    [[[UIColor redColor] colorWithAlphaComponent:alpha] setStroke];
    CGContextStrokePath(context);
  }

  // Hand
  x = midX + radius * cosf(sweep);
  y = midY + radius * sinf(sweep);
  CGContextMoveToPoint(context, midX, midY);
  CGContextAddLineToPoint(context, x, y);
  CGContextStrokePath(context);
}

- (void)invalidate {
  [self.timer invalidate];
  self.timer = nil;
}

- (void)startUpTimer {
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1
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
