//
//  ProgressRingView.swift
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

class ProgressRingView: UIView {
    private let backgroundRingLayer = RingLayer()
    private let foregroundRingLayer = RingLayer()

    // MARK: Initialize

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSublayers()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSublayers()
    }

    private func configureSublayers() {
        layer.addSublayer(backgroundRingLayer)
        layer.addSublayer(foregroundRingLayer)
        updateWithRingColor(tintColor)
    }

    // MARK: Layout

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        // Lay out the ring layers to fill the view's layer.
        if layer == self.layer {
            backgroundRingLayer.frame = layer.bounds
            foregroundRingLayer.frame = layer.bounds
        }
    }

    // MARK: Update

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateWithRingColor(tintColor)
    }

    private func updateWithRingColor(_ ringColor: UIColor) {
        foregroundRingLayer.strokeColor = ringColor.cgColor
        backgroundRingLayer.strokeColor = ringColor.withAlphaComponent(0.2).cgColor
    }

    func updateWithViewModel(_ viewModel: ProgressRingViewModel) {
        let path = #keyPath(RingLayer.strokeStart)
        let animation = CABasicAnimation(keyPath: path)
        let now = layer.convertTime(CACurrentMediaTime(), from: nil)
        animation.beginTime = now + viewModel.startTime.timeIntervalSinceNow
        animation.duration = viewModel.duration
        animation.fromValue = 0
        animation.toValue = 1
        foregroundRingLayer.add(animation, forKey: path)
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

        // Inset the ring to draw within the layer's bounds.
        let halfLineWidth = lineWidth / 2
        let ringRect = bounds.insetBy(dx: halfLineWidth, dy: halfLineWidth)

        // Transform the ring path to draw clockwise, starting at the top.
        let translationToOrigin = CGAffineTransform(translationX: -ringRect.midX, y: -ringRect.midY)
        let rotation = CGAffineTransform(rotationAngle: -.pi / 2)
        let translationFromOrigin = CGAffineTransform(translationX: ringRect.midX, y: ringRect.midY)
        var transform = translationToOrigin.concatenating(rotation).concatenating(translationFromOrigin)
        withUnsafePointer(to: &transform) { transform in
            path = CGPath(ellipseIn: ringRect, transform: transform)
        }
    }
}
