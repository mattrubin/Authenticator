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

struct ProgressRingViewModel {
    let startTime: Date
    let endTime: Date

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

class OTPProgressRing: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.layer.contentsScale = UIScreen.main.scale
        self.updateTintColor()
    }

    private var progressLayer: ProgressLayer? {
        get {
            if let _progressLayer = layer as? ProgressLayer {
                return _progressLayer
            }
            return nil
        }
    }

    override public class var layerClass: AnyClass {
        get {
            return ProgressLayer.self
        }
    }

    public var progress: CGFloat = 0 {
        didSet {
            self.progressLayer?.progress = progress
        }
    }

    override public var tintColor: UIColor! {
        didSet { updateTintColor() }
    }

    private func updateTintColor() {
        self.progressLayer?.ringColor = self.tintColor.cgColor
        self.progressLayer?.ringPartialColor = self.tintColor.withAlphaComponent(0.2).cgColor
    }

    func updateWithViewModel(_ viewModel: ProgressRingViewModel) {
        let path = #keyPath(ProgressLayer.progress)
        let animation = CABasicAnimation(keyPath: path)
        let now = layer.convertTime(CACurrentMediaTime(), from: nil)
        animation.beginTime = now + viewModel.startTime.timeIntervalSinceNow
        animation.duration = viewModel.duration
        animation.fromValue = 0
        animation.toValue = 1
        self.progressLayer?.add(animation, forKey: path)
    }

}

fileprivate class ProgressLayer: CALayer {
    @NSManaged var progress: CGFloat
    @NSManaged var ringColor: CGColor
    @NSManaged var ringPartialColor: CGColor

    private var lineWidth: CGFloat = 1.5 {
        didSet { setNeedsDisplay() }
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == #keyPath(progress) {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in context: CGContext) {
        let halfLineWidth = lineWidth / 2
        let ringRect = self.bounds.insetBy(dx: halfLineWidth, dy: halfLineWidth)

        context.setLineWidth(lineWidth)

        context.setStrokeColor(ringPartialColor)
        context.strokeEllipse(in: ringRect)

        context.setStrokeColor(ringColor)
        let startAngle: CGFloat = -.pi / 2
        context.addArc(center: CGPoint(x: ringRect.midX, y: ringRect.midY),
                       radius: ringRect.width / 2,
                       startAngle: startAngle,
                       endAngle: 2 * .pi * CGFloat(self.progress) + startAngle,
                       clockwise: true)
        context.strokePath()
    }
}
