//
//  BarProgressView.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A flat bar progress view.
public class BarProgressView: ProgressView {
    // MARK: - Properties

    /// Bar border line color. Defaults to white UIColor(white: 1.0, alpha: 1.0).
    public var lineColor: UIColor = UIColor(white: 1.0, alpha: 1.0)

    // MARK: - Lifecycle

    public convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: 10.0))
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 120.0, height: 10.0)
    }

    // MARK: - Drawing

    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(2.0)
        context.setStrokeColor(lineColor.cgColor)
        context.setFillColor(trackTintColor.cgColor)

        // Draw background and Border

        var radius = (rect.height / 2.0) - 2.0
        context.move(to: CGPoint(x: 2.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 2.0, y: 2.0),
                       tangent2End: CGPoint(x: radius + 2.0, y: 2.0),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: 2.0),
                       tangent2End: CGPoint(x: rect.width - 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: rect.width - radius - 2.0, y: rect.height - 2.0),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.drawPath(using: .fillStroke)

        context.setFillColor(progressTintColor.cgColor)
        radius -= 2
        let amount = progress * rect.width

        // Progress in the middle area
        if amount >= radius + 4 && amount <= (rect.size.width - radius - 4) {
            drawMiddleAreaProgress(context, rect: rect, radius: radius, amount: amount)
        }

        // Progress in the right arc
        else if amount > radius + 4 {
            drawRightArcProgress(context, rect: rect, radius: radius, amount: amount)
        }

        // Progress is in the left arc
        else if amount < radius + 4 && amount > 0 {
            drawLeftArcProgress(context, rect: rect, radius: radius)
        }
    }

    private func drawMiddleAreaProgress(_ context: CGContext, rect: CGRect, radius: CGFloat, amount: CGFloat) {
        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                       tangent2End: CGPoint(x: radius + 4, y: 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: amount, y: 4.0))
        context.addLine(to: CGPoint(x: amount, y: radius + 4.0))

        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                       tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: amount, y: rect.height - 4.0))
        context.addLine(to: CGPoint(x: amount, y: radius + 4.0))

        context.fillPath()
    }

    private func drawRightArcProgress(_ context: CGContext, rect: CGRect, radius: CGFloat, amount: CGFloat) {
        let x = amount - (rect.width - radius - 4.0)
        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                       tangent2End: CGPoint(x: 4.0, y: radius + 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: rect.width - radius - 4.0, y: 4.0))

        var angle = -acos(x / radius)
        if angle.isNaN {
            angle = 0.0
        }
        context.addArc(center: CGPoint(x: rect.width - radius - 4.0, y: rect.height / 2.0),
                       radius: radius,
                       startAngle: CGFloat.pi,
                       endAngle: angle,
                       clockwise: false)
        context.addLine(to: CGPoint(x: amount, y: rect.height / 2.0))

        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                       tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: rect.width - radius - 4.0, y: rect.height - 4.0))

        angle = acos(x / radius)
        if angle.isNaN {
            angle = 0.0
        }
        context.addArc(center: CGPoint(x: rect.width - radius - 4.0, y: rect.height / 2.0),
                       radius: radius,
                       startAngle: -CGFloat.pi,
                       endAngle: angle,
                       clockwise: true)
        context.addLine(to: CGPoint(x: amount, y: rect.height / 2.0))

        context.fillPath()
    }

    private func drawLeftArcProgress(_ context: CGContext, rect: CGRect, radius: CGFloat) {
        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                       tangent2End: CGPoint(x: radius + 4, y: 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: radius + 4.0, y: rect.height / 2.0))

        context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                       tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: radius + 4.0, y: rect.height / 2.0))

        context.fillPath()
    }
}
