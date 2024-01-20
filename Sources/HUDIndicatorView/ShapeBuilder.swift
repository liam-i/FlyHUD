//
//  ShapeBuilder.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit

protocol ShapeBuildable {
    func make(with size: CGSize, color: UIColor?, lineWidth: CGFloat) -> CAShapeLayer
}

enum ShapeBuilder: ShapeBuildable {
    case ring
    case ringOneThird
    case ringOneFour
    case circle(_ radius: CGFloat)
    case stroke

    func make(with size: CGSize, color: UIColor?, lineWidth: CGFloat) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2.0, y: size.height / 2.0)
        let radius = (size.height - lineWidth) / 2.0

        switch self {
        case .ring:
            path.addArc(withCenter: center, radius: radius, startAngle: 0.0, endAngle: 2.0 * .pi, clockwise: false)
            layer.setStroke(color, line: lineWidth)
        case .ringOneThird:
            path.addArc(withCenter: center, radius: radius, startAngle: -.pi / 3.0, endAngle: .pi / 3.0, clockwise: true)
            layer.setStroke(color, line: lineWidth)
        case .ringOneFour:
            path.addArc(withCenter: center, radius: radius, startAngle: -.pi / 2.0, endAngle: 0.0, clockwise: true)
            layer.setStroke(color, line: lineWidth)
        case .circle(let radius):
            path.addArc(withCenter: CGPoint(x: radius, y: radius), radius: radius, startAngle: 0.0, endAngle: 2 * .pi, clockwise: false)
            layer.fillColor = color?.cgColor
        case .stroke:
            path.addArc(withCenter: center, radius: radius, startAngle: -(.pi / 2.0), endAngle: .pi + .pi / 2.0, clockwise: true)
            layer.setStroke(color, line: lineWidth)
        }

        layer.backgroundColor = nil
        layer.path = path.cgPath
        layer.frame = CGRect(origin: .zero, size: size)
        return layer
    }
}

extension CAShapeLayer {
    fileprivate func setStroke(_ color: UIColor?, line width: CGFloat) {
        fillColor = nil
        strokeColor = color?.cgColor
        lineWidth = width
    }
}
