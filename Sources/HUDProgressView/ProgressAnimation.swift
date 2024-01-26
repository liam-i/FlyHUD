//
//  ProgressAnimation.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit
#if canImport(HUD)
import HUD
#endif

/// Animation Builder
public protocol ProgressAnimationBuildable {
    func makeShape(in layer: CALayer, progress: CGFloat, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat)
    func makeLabel(in layer: CALayer, progress: CGFloat, color: UIColor, font: UIFont)
}

extension ProgressAnimationBuildable {
    public func makeLabel(in layer: CALayer, progress: CGFloat, color: UIColor, font: UIFont) {
        let size = layer.bounds.size
        let text = NSAttributedString(string: "\(Int(progress * 100))%", attributes: [.font: font, .foregroundColor: color])
        let textSize = text.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
        text.draw(in: CGRect(x: (size.width - textSize.width) / 2.0, y: (size.height - textSize.height) / 2.0, width: size.width, height: size.height))
    }
}

enum ProgressAnimation {
    /// A flat bar progress view.
    struct Bar: ProgressAnimationBuildable {
        let isRound: Bool

        func makeShape(in layer: CALayer, progress: CGFloat, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let size = layer.frame.size

            let lineWidthHalf = lineWidth / 2.0
            let borderRect = CGRect(x: lineWidthHalf, y: lineWidthHalf, width: size.width - lineWidth, height: size.height - lineWidth)

            // bar border
            UIBezierPath(roundedRect: borderRect, cornerRadius: (size.height - lineWidth) / 2.0).with {
                $0.lineWidth = lineWidth
                color.set()
                $0.stroke()
            }

            guard isRound else {
                return makeButtBar(in: size, progress: progress, color: color, lineWidth: lineWidth)
            }

            let spacing = (min(size.height, size.width) - lineWidth * 3) / 2
            let centerY = size.height / 2.0
            let minX = lineWidth + lineWidthHalf + spacing
            let end = (size.width - minX * 2) * progress + minX

            // bar progress
            UIBezierPath().with {
                $0.lineWidth = lineWidth
                $0.lineCapStyle = .round
                $0.move(to: CGPoint(x: minX, y: centerY))
                $0.addLine(to: CGPoint(x: end, y: centerY))
                color.set()
                $0.stroke()
            }
        }

        private func makeButtBar(in size: CGSize, progress: CGFloat, color: UIColor, lineWidth: CGFloat) {
            guard let context = UIGraphicsGetCurrentContext() else { return }

            let spacing = (min(size.height, size.width) - lineWidth * 3) / 2
            let centerY = size.height / 2.0
            let minX = lineWidth + spacing
            let radius = centerY - minX
            let minY = centerY - radius
            let maxY = centerY + radius

            let amount = progress * size.width
            let amountRange = radius + minX
            let amountRangeUpperBound = size.width - amountRange

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
            }
            // Progress is in the left arc
            else if amount < amountRange && amount > 0 {
                context.move(to: CGPoint(x: minX, y: centerY))
                context.addArc(tangent1End: CGPoint(x: minX, y: minY), tangent2End: CGPoint(x: minX + radius, y: minY), radius: radius)
                context.addLine(to: CGPoint(x: minX + radius, y: centerY))

                context.move(to: CGPoint(x: minX, y: centerY))
                context.addArc(tangent1End: CGPoint(x: minX, y: maxY), tangent2End: CGPoint(x: minX + radius, y: maxY), radius: radius)
                context.addLine(to: CGPoint(x: minX + radius, y: centerY))
            } else { return }

            context.setLineWidth(lineWidth)
            context.setStrokeColor(color.cgColor)
            context.setFillColor(color.cgColor)
            context.fillPath()
        }
    }

    /// A progress view for showing definite progress by filling up a circle (pie chart).
    struct Round: ProgressAnimationBuildable {
        /// Display mode - false = round or true = annular. Defaults to round.
        let isAnnular: Bool

        func makeShape(in layer: CALayer, progress: CGFloat, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let (trackColor, bounds) = (trackColor ?? .clear, layer.bounds)

            guard isAnnular else {
                return makeRound(in: bounds, progress: progress, color: color, trackColor: trackColor, lineWidth: lineWidth)
            }

            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = (min(bounds.width, bounds.height) - lineWidth) / 2.0
            let startAngle = -(CGFloat.pi / 2.0) // 90 degrees
            var endAngle = (2 * CGFloat.pi) + startAngle
            let lineCapStyle: CGLineCap = trackColor == .clear ? .round : .square

            // Draw background
            UIBezierPath().with {
                $0.lineWidth = lineWidth
                $0.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                trackColor.set()
                $0.stroke()
            }

            endAngle = (progress * 2 * CGFloat.pi) + startAngle

            // Draw progress
            UIBezierPath().with {
                $0.lineWidth = lineWidth
                $0.lineCapStyle = lineCapStyle
                $0.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
                color.set()
                $0.stroke()
            }
        }

        private func makeRound(in bounds: CGRect, progress: CGFloat, color: UIColor, trackColor: UIColor, lineWidth: CGFloat) {
            guard let context = UIGraphicsGetCurrentContext() else { return assertionFailure() }

            // Draw background
            let minSize = min(bounds.width, bounds.height)
            let lineWidthHalf = lineWidth / 2.0
            let circleRect = CGRect(x: (bounds.width - minSize) / 2.0, y: (bounds.height - minSize) / 2.0,
                                    width: minSize, height: minSize).insetBy(dx: lineWidthHalf, dy: lineWidthHalf)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)

            color.setStroke()
            trackColor.setFill()

            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: circleRect)

            // 90 degrees
            let startAngle = -(CGFloat.pi / 2.0)
            let lineWidth = lineWidth * 2.0
            let radius = (min(bounds.width, bounds.height) - lineWidth) / 2.0
            let endAngle = (progress * 2.0 * CGFloat.pi) + startAngle

            // Draw progress
            UIBezierPath().with {
                $0.lineWidth = lineWidth
                $0.lineCapStyle = .butt
                $0.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)

                // Ensure that we don't get color overlaping when progressTintColor alpha < 1.0.
                context.setBlendMode(.copy)
                color.set()
                $0.stroke()
            }
        }
    }

    struct Pie: ProgressAnimationBuildable {
        func makeShape(in layer: CALayer, progress: CGFloat, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let size = layer.bounds.size
            let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
            let radius = min(size.width, size.height) / 2.0 - lineWidth

            UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: false).with {
                $0.lineWidth = lineWidth
                trackColor?.setFill()
                $0.fill()
                color.set()
                $0.stroke()
            }

            let startAngle = -(CGFloat.pi / 2.0)
            let endAngle = startAngle + CGFloat.pi * 2.0 * progress
            UIBezierPath(arcCenter: center, radius: radius / 2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true).with {
                $0.lineWidth = radius
                $0.stroke()
            }
        }
    }
}
