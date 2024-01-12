//
//  RoundProgressView.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A progress view for showing definite progress by filling up a circle (pie chart).
public class RoundProgressView: ProgressView {
    // MARK: - Properties

    /// Display mode - false = round or true = annular. Defaults to round.
    public var isAnnular: Bool = false

    /// Indicator line width. Defaults to 2.0.
    public var lineWidth: CGFloat = 2.0

    /// Indicator line size. Defaults to 37.0.
    public var lineSize: CGFloat = 37.0

    // MARK: - Lifecycle

    public convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
    }

    // MARK: - Layout

    public override var intrinsicContentSize: CGSize {
        CGSize(width: lineSize, height: lineSize)
    }

    // MARK: - Drawing

    public override func draw(_ rect: CGRect) {
        guard isAnnular else {
            return drawDeterminate(lineWidth)
        }
        drawAnnularDeterminate(lineWidth)
    }

    private func drawAnnularDeterminate(_ lineWidth: CGFloat) {
        // Draw background
        let processBackgroundPath = UIBezierPath()
        processBackgroundPath.lineWidth = lineWidth
        processBackgroundPath.lineCapStyle = .butt

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (bounds.width - lineWidth) / 2.0
        let startAngle = -(CGFloat.pi / 2.0) // 90 degrees
        var endAngle = (2 * CGFloat.pi) + startAngle

        processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        trackTintColor.set()
        processBackgroundPath.stroke()

        // Draw progress
        let processPath = UIBezierPath()
        processPath.lineWidth = lineWidth
        processPath.lineCapStyle = .square

        endAngle = (progress * 2 * CGFloat.pi) + startAngle

        processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        progressTintColor.set()
        processPath.stroke()
    }

    private func drawDeterminate(_ lineWidth: CGFloat) {
        guard let context = UIGraphicsGetCurrentContext() else { return assertionFailure() }

        // Draw background
        let lineWidthHalf = lineWidth / 2.0
        let circleRect = bounds.insetBy(dx: lineWidthHalf, dy: lineWidthHalf)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        progressTintColor.setStroke()
        trackTintColor.setFill()

        context.setLineWidth(lineWidth)
        context.strokeEllipse(in: circleRect)

        // 90 degrees
        let startAngle = -(CGFloat.pi / 2.0)

        // Draw progress
        let processPath = UIBezierPath()
        processPath.lineWidth = lineWidth * 2.0
        processPath.lineCapStyle = .butt

        let radius = (bounds.width - processPath.lineWidth) / 2.0
        let endAngle = (progress * 2.0 * CGFloat.pi) + startAngle

        processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        // Ensure that we don't get color overlaping when progressTintColor alpha < 1.0.
        context.setBlendMode(.copy)
        progressTintColor.set()
        processPath.stroke()
    }
}
