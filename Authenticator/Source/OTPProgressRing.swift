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
        progressLayer.updateTintColor(tintColor)
    }

    // MARK: Layer

    override public class var layerClass: AnyClass {
        return ProgressLayer.self
    }

    private var progressLayer: ProgressLayer {
        return layer as! ProgressLayer // swiftlint:disable:this force_cast
    }

    // MARK: Update

    override func tintColorDidChange() {
        super.tintColorDidChange()
        progressLayer.updateTintColor(tintColor)
    }

    func updateWithViewModel(_ viewModel: ProgressRingViewModel) {
        let path = #keyPath(RingLayer.strokeStart)
        let animation = CABasicAnimation(keyPath: path)
        let now = layer.convertTime(CACurrentMediaTime(), from: nil)
        animation.beginTime = now + viewModel.startTime.timeIntervalSinceNow
        animation.duration = viewModel.duration
        animation.fromValue = 0
        animation.toValue = 1
        progressLayer.foregroundRingLayer.add(animation, forKey: path)
    }
}

private class ProgressLayer: CALayer {
    let backgroundRingLayer = RingLayer()
    let foregroundRingLayer = RingLayer()

    override init() {
        super.init()
        addSublayer(backgroundRingLayer)
        addSublayer(foregroundRingLayer)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addSublayer(backgroundRingLayer)
        addSublayer(foregroundRingLayer)
    }

    fileprivate func updateTintColor(_ tintColor: UIColor) {
        foregroundRingLayer.strokeColor = tintColor.cgColor
        backgroundRingLayer.strokeColor = tintColor.withAlphaComponent(0.2).cgColor
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        backgroundRingLayer.frame = bounds
        foregroundRingLayer.frame = bounds
    }
}

private class RingLayer: CAShapeLayer {
    override init() {
        super.init()
        lineWidth = 1.5
        fillColor = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSublayers() {
        super.layoutSublayers()
        let halfLineWidth = lineWidth / 2
        let ringRect = bounds.insetBy(dx: halfLineWidth, dy: halfLineWidth)

        let translationToOrigin = CGAffineTransform(translationX: -ringRect.midX, y: -ringRect.midY)
        let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
        let translationFromOrigin = CGAffineTransform(translationX: ringRect.midX, y: ringRect.midY)
        var transform = translationToOrigin.concatenating(rotation).concatenating(translationFromOrigin)
        withUnsafePointer(to: &transform) { transform in
            path = CGPath(ellipseIn: ringRect, transform: transform)
        }
    }
}
