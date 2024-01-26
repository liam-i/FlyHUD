//
//  ActivityIndicatorAnimation.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit
#if canImport(HUD)
import HUD
#endif

/// Animation Builder
public protocol ActivityIndicatorAnimationBuildable {
    func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat)
}

enum ActivityIndicatorAnimation {
    static let key: String = "com.indicator.animation.key"

    struct RingClipRotate: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let size = layer.bounds.size
            let duration: CFTimeInterval = 0.75

            let rotateAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z").with {
                $0.keyTimes = [0, 0.5, 1]
                $0.values = [0, Double.pi, 2 * Double.pi]
            }
            let animation = CAAnimationGroup().with {
                $0.animations = [rotateAnimation]
                $0.timingFunction = CAMediaTimingFunction(name: .linear)
                $0.duration = duration
                $0.repeatCount = .greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
            }
            ShapeBuilder.ring.make(with: size, color: trackColor, lineWidth: lineWidth).with {
                layer.addSublayer($0)
            }
            ShapeBuilder.ringOneThird.make(with: size, color: color, lineWidth: lineWidth).with {
                $0.add(animation, forKey: ActivityIndicatorAnimation.key)
                layer.addSublayer($0)
            }
        }
    }

    struct BallSpinFade: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let bounds = layer.bounds
            let minSize = min(bounds.width, bounds.height)
            let spacing: CGFloat = 3.0
            let dotSize = (minSize - 4.0 * spacing) / 3.5
            let radius = (minSize - dotSize) / 2.0
            let center = CGPoint(x: bounds.midX, y: bounds.midY)

            let duration: CFTimeInterval = 1.0
            let beginTime = CACurrentMediaTime()
            let beginTimes: [CFTimeInterval] = [0.84, 0.72, 0.6, 0.48, 0.36, 0.24, 0.12, 0]

            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale").with { 
                $0.keyTimes = [0, 0.5, 1]
                $0.values = [1, 0.4, 1]
                $0.duration = duration
            }
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity").with {
                $0.keyTimes = [0, 0.5, 1]
                $0.values = [1, 0.3, 1]
                $0.duration = duration
            }
            let animation = CAAnimationGroup().with {
                $0.animations = [scaleAnimation, opacityAnimation]
                $0.timingFunction = CAMediaTimingFunction(name: .linear)
                $0.duration = duration
                $0.repeatCount = .greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
            }
            beginTimes.enumerated().forEach { (i, element) in
                ShapeBuilder.circle.make(with: CGSize(width: dotSize, height: dotSize), color: color, lineWidth: 0).with {
                    let angle = .pi / 4 * CGFloat(i)
                    animation.beginTime = beginTime - element
                    $0.frame = CGRect(x: center.x + radius * cos(angle) - dotSize / 2.0,
                                      y: center.y + radius * sin(angle) - dotSize / 2.0, width: dotSize, height: dotSize)
                    $0.add(animation, forKey: ActivityIndicatorAnimation.key)
                    layer.addSublayer($0)
                }
            }
        }
    }

    struct CircleStrokeSpin: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let size = layer.bounds.size
            let beginTime: CFTimeInterval = 0.5
            let strokeStartDuration: CFTimeInterval = 1.2
            let strokeEndDuration: CFTimeInterval = 0.7

            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation").with {
                $0.byValue = Float.pi * 2
                $0.timingFunction = CAMediaTimingFunction(name: .linear)
            }
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd").with {
                $0.duration = strokeEndDuration
                $0.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
                $0.fromValue = 0
                $0.toValue = 1
            }
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart").with {
                $0.duration = strokeStartDuration
                $0.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
                $0.fromValue = 0
                $0.toValue = 1
                $0.beginTime = beginTime
            }
            let groupAnimation = CAAnimationGroup().with {
                $0.animations = [rotationAnimation, strokeEndAnimation, strokeStartAnimation]
                $0.duration = strokeStartDuration + beginTime
                $0.repeatCount = .greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
                $0.fillMode = .forwards
            }
            ShapeBuilder.stroke.make(with: size, color: color, lineWidth: lineWidth).with {
                $0.add(groupAnimation, forKey: ActivityIndicatorAnimation.key)
                layer.addSublayer($0)
            }
        }
    }

    struct CircleArcDotSpin: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
            let bounds = layer.bounds
            let minSize = min(bounds.width, bounds.height)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let lineWidth = minSize / 6.0
            let radius = (minSize - lineWidth) / 2.0
            let count = 8
            let dotSize = radius / 3.0

            for i in 0..<count {
                let angle = (CGFloat(i) / CGFloat(count)) * (2.0 * .pi)
                let circle = CALayer().with {
                    $0.frame = CGRect(x: center.x + radius * cos(angle) - dotSize / 2.0,
                                      y: center.y + radius * sin(angle) - dotSize / 2.0, width: dotSize, height: dotSize)
                    $0.backgroundColor = color.cgColor
                    $0.cornerRadius = dotSize / 2.0
                    layer.addSublayer($0)
                }
                let animation = CAKeyframeAnimation(keyPath: "position").with {
                    $0.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: angle, endAngle: angle + 2 * .pi, clockwise: true).cgPath
                    $0.duration = 4.0
                    $0.repeatCount = .greatestFiniteMagnitude
                    $0.isRemovedOnCompletion = false
                    $0.calculationMode = .paced
                }
                circle.add(animation, forKey: "circleAnimation")
            }

            let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation").with {
                $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                $0.byValue = 4 * Float.pi
                $0.duration = 1.6
            }
            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd").with {
                $0.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                $0.fromValue = 0.5
                $0.toValue = 1
                $0.duration = 0.8
                $0.autoreverses = true
            }
            let animation = CAAnimationGroup().with {
                $0.animations = [rotationAnimation, strokeEndAnimation]
                $0.duration = 1.6
                $0.repeatCount = .greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
                $0.fillMode = .forwards
            }
            ShapeBuilder.ringOneFour.make(with: bounds.size, color: color, lineWidth: lineWidth).with {
                $0.lineCap = .round
                $0.add(animation, forKey: ActivityIndicatorAnimation.key)
                layer.addSublayer($0)
            }
        }
    }
}
