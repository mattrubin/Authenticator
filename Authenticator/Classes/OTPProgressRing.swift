//
//  OTPProgressRing.swift
//  Authenticator
//
//  Copyright (c) 2014 Matt Rubin
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

import UIKit


private let OTPProgressRingLineWidth: CGFloat = 1.5


class OTPProgressRing: UIView {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    var period: NSTimeInterval = 30
    private var timer: NSTimer?

    private func configureView() {
        self.opaque = false
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "setNeedsDisplay", userInfo: nil, repeats: true)
    }

    deinit {
        self.timer?.invalidate()
    }

    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, OTPProgressRingLineWidth)
        let ringRect = CGRectInset(self.bounds, OTPProgressRingLineWidth/2, OTPProgressRingLineWidth/2)

        CGContextSetStrokeColorWithColor(context, self.tintColor.colorWithAlphaComponent(0.2).CGColor)
        CGContextStrokeEllipseInRect(context, ringRect);

        let progress = fmod(NSDate().timeIntervalSince1970, self.period) / self.period

        CGContextSetStrokeColorWithColor(context, self.tintColor.CGColor);
        CGContextAddArc(context,
            CGRectGetMidX(ringRect),
            CGRectGetMidY(ringRect),
            CGRectGetWidth(ringRect)/2,
            CGFloat(-M_PI_2),
            CGFloat(2 * M_PI * progress - M_PI_2),
            1);
        CGContextStrokePath(context);
    }
}
