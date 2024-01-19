//
//  ActivityIndicatorAnimation.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import Foundation

public protocol ActivityIndicatorAnimationBuildable {
    func make(in layer: CALayer, color: UIColor?, trackColor: UIColor?, lineWidth: CGFloat)
}

enum ActivityIndicatorAnimation {
    static let key: String = "animation"

    struct RingClipRotate: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor?, trackColor: UIColor?, lineWidth: CGFloat) {
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
        func make(in layer: CALayer, color: UIColor?, trackColor: UIColor?, lineWidth: CGFloat) {
            let size = layer.bounds.size
            let spacing: CGFloat = 3.0
            let radius = (size.width - 4 * spacing) / 3.5
            let radiusX = (size.width - radius) / 2
            let radiusCenter = radius / 2.0

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
                $0.repeatCount = .infinity
                $0.isRemovedOnCompletion = false
            }

            beginTimes.enumerated().forEach { (i, element) in
                ShapeBuilder.circle(radiusCenter).make(with: size, color: color, lineWidth: lineWidth).with {
                    let angle = .pi / 4 * CGFloat(i)
                    animation.beginTime = beginTime - element

                    $0.frame = CGRect(x: radiusX * (cos(angle) + 1), y: radiusX * (sin(angle) + 1), width: radius, height: radius)
                    $0.add(animation, forKey: ActivityIndicatorAnimation.key)
                    layer.addSublayer($0)
                }
            }
        }
    }

    struct CircleStrokeSpin: ActivityIndicatorAnimationBuildable {
        func make(in layer: CALayer, color: UIColor?, trackColor: UIColor?, lineWidth: CGFloat) {
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
                $0.repeatCount = .infinity
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
        func make(in layer: CALayer, color: UIColor?, trackColor: UIColor?, lineWidth: CGFloat) {
            var bounds = layer.bounds
            let space = bounds.width / 8.0

            let container = CALayer().with {
                $0.frame = CGRect(x: bounds.minX + space / 2.0,
                                  y: bounds.minY + space / 2.0, width: bounds.width - space, height: bounds.height - space)
                layer.addSublayer($0)
            }

            bounds = container.bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let lineWidth = bounds.width / 6.0
            let radius = (bounds.width - lineWidth) / 2.0
            let count = 8
            let size = radius / 3.0

            for i in 0..<count {
                let angle = (CGFloat(i) / CGFloat(count)) * (2.0 * .pi)
                let circle = CALayer().with {
                    $0.frame = CGRect(x: center.x + radius * cos(angle) - size / 2.0,
                                      y: center.y + radius * sin(angle) - size / 2.0, width: size, height: size)
                    $0.backgroundColor = color?.cgColor
                    $0.cornerRadius = size / 2.0
                    container.addSublayer($0)
                }
                let animation = CAKeyframeAnimation(keyPath: "position").with {
                    $0.path = UIBezierPath(arcCenter: center, radius: radius, startAngle: angle, endAngle: angle + 2 * .pi, clockwise: true).cgPath
                    $0.duration = 4.0
                    $0.repeatCount = .infinity
                    $0.calculationMode = .paced
                }
                circle.add(animation, forKey: "circleAnimation")
            }

            animateArcRotation(container, color: color, lineWidth: lineWidth)
        }

        private func animateArcRotation(_ container: CALayer, color: UIColor?, lineWidth: CGFloat) {
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
                $0.isRemovedOnCompletion = false
            }
            let animation = CAAnimationGroup().with {
                $0.animations = [rotationAnimation, strokeEndAnimation]
                $0.duration = 1.6
                $0.repeatCount = .infinity
                $0.fillMode = .forwards
            }
            ShapeBuilder.ringOneFour.make(with: container.bounds.size, color: color, lineWidth: lineWidth).with {
                $0.lineCap = .round
                $0.add(animation, forKey: ActivityIndicatorAnimation.key)
                container.addSublayer($0)
            }
        }
    }
}
