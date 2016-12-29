//
//  ScannerOverlayView.Swift
//  Authenticator
//
//  Copyright (c) 2013-2016 Authenticator authors
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

class ScannerOverlayView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.needsDisplayOnBoundsChange = true
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
        self.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.layer.needsDisplayOnBoundsChange = true
    }

    override func drawRect(rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        UIColor(white: 0, alpha: 0.5).setFill()
        UIColor(white: 1, alpha: 0.2).setStroke()

        let smallestDimension = min(self.bounds.width, self.bounds.height)
        let windowSize = 0.9 * smallestDimension
        let window = CGRect(
            x: rect.midX - (windowSize / 2),
            y: rect.midY - (windowSize / 2),
            width: windowSize,
            height: windowSize
        )

        CGContextFillRect(context, rect)
        CGContextClearRect(context, window)
        CGContextStrokeRect(context, window)
    }
}
