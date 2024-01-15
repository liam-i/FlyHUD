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
    /// Bar border line width. Defaults to 2.0.
    public private(set) var lineWidth: CGFloat = 2.0
    /// Bar border line spacing. Defaults to 2.0.
    public private(set) var spacing: CGFloat = 2.0

    // MARK: - Lifecycle

    /// Initialization method
    /// - Parameters:
    ///   - lineWidth: Bar border line width.
    ///   - spacing: Bar border line spacing.
    public convenience init(lineWidth: CGFloat, spacing: CGFloat) {
        let height = lineWidth * 3 + spacing * 2
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 12.0 * height, height: height))
        self.lineWidth = lineWidth
        self.spacing = spacing
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        let height = lineWidth * 3 + spacing * 2
        return CGSize(width: 12.0 * height, height: height)
    }

    // MARK: - Drawing

    // swiftlint:disable function_body_length
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let centerY = rect.height / 2.0
        var minX = lineWidth / 2.0
        var radius = centerY - minX
        var minY = centerY - radius
        var maxX = rect.width - minX
        var maxY = centerY + radius

        context.setLineWidth(lineWidth)
        context.setStrokeColor(lineColor.cgColor)
        context.setFillColor(trackTintColor.cgColor)

        // Draw background and Border
        context.move(to: CGPoint(x: minX, y: centerY))
        context.addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + radius, y: minY), radius: radius)
        context.addArc(tangent1End: CGPoint(x: maxX, y: minY), tangent2End: CGPoint(x: maxX, y: centerY), radius: radius)
        context.addArc(tangent1End: CGPoint(x: maxX, y: maxY), tangent2End: CGPoint(x: maxX - radius, y: maxY), radius: radius)
        context.addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX, y: maxY - radius), radius: radius)
        context.drawPath(using: .fillStroke)

        context.setFillColor(progressTintColor.cgColor)

        minX = lineWidth + spacing
        radius = centerY - minX
        minY = centerY - radius
        maxX = rect.width - minX
        maxY = centerY + radius

        let amount = progress * rect.width
        let amountRange = radius + minX
        let amountRangeUpperBound = rect.width - amountRange

        // Progress in the middle area
        if amount >= amountRange && amount <= amountRangeUpperBound {
            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + radius, y: minY), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: minY))
            context.addLine(to: CGPoint(x: amount, y: minY + radius))

            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX + radius, y: maxY), radius: radius)
            context.addLine(to: CGPoint(x: amount, y: maxY))
            context.addLine(to: CGPoint(x: amount, y: minY + radius))

            context.fillPath()
        }

        // Progress in the right arc
        else if amount > amountRange {
            let x = amount - amountRangeUpperBound
            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + radius, y: minY), radius: radius)
            context.addLine(to: CGPoint(x: amountRangeUpperBound, y: minY))

            var angle = -acos(x / radius)
            if angle.isNaN {
                angle = 0.0
            }
            context.addArc(center: CGPoint(x: amountRangeUpperBound, y: centerY), radius: radius, startAngle: .pi, endAngle: angle, clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: centerY))

            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX + radius, y: maxY), radius: radius)
            context.addLine(to: CGPoint(x: amountRangeUpperBound, y: maxY))

            angle = acos(x / radius)
            if angle.isNaN {
                angle = 0.0
            }
            context.addArc(center: CGPoint(x: amountRangeUpperBound, y: centerY), radius: radius, startAngle: -.pi, endAngle: angle, clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: centerY))

            context.fillPath()
        }

        // Progress is in the left arc
        else if amount < amountRange && amount > 0 {
            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + radius, y: minY), radius: radius)
            context.addLine(to: CGPoint(x: minX + radius, y: centerY))

            context.move(to: CGPoint(x: minX, y: centerY))
            context.addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX + radius, y: maxY), radius: radius)
            context.addLine(to: CGPoint(x: minX + radius, y: centerY))
            
            context.fillPath()
        }
    }
    // swiftlint:enable function_body_length
}
