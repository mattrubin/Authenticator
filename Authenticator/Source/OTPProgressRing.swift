//
//  OTPProgressRing.swift
//  Authenticator
//
//  Copyright (c) 2014-2016 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit

class OTPProgressRing: UIView {
    fileprivate let lineWidth: CGFloat = 1.5

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
    }

    var progress: Double = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let halfLineWidth = lineWidth / 2
        let ringRect = self.bounds.insetBy(dx: halfLineWidth, dy: halfLineWidth)

        context.setLineWidth(lineWidth)

        context.setStrokeColor(self.tintColor.withAlphaComponent(0.2).cgColor)
        context.strokeEllipse(in: ringRect)

        context.setStrokeColor(self.tintColor.cgColor)
        CGContextAddArc(context,
            ringRect.midX,
            ringRect.midY,
            ringRect.width / 2,
            CGFloat(-M_PI_2),
            CGFloat(2 * M_PI * self.progress - M_PI_2),
            1)
        context.strokePath()
    }
}
