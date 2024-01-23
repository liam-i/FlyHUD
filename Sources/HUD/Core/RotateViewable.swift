//
//  Rotatable.swift
//  LPHUD
//
//  Created by liam on 2024/1/23.
//

import Foundation

public protocol RotateViewable: AnyObject where Self: UIView {
    /// Specifies the basic duration of the animation, in seconds.
    var duration: CFTimeInterval { get }
    /// Starts the animation of the rotate view.
    /// - Note: When the rotate view is animated, the view is animated until stopRotation() is called.
    func startRotation()
    /// Stops the animation of the rotate view.
    /// - Note: Call this method to stop the animation of the rotate view started with a call to startRotation().
    func stopRotation()
}

extension RotateViewable {
    /// Specifies the basic duration of the animation, in seconds. `Default to 0.25`
    public var duration: CFTimeInterval { 0.25 }

    public func startRotation() {
        CABasicAnimation(keyPath: "transform").with {
            $0.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
            $0.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(.pi / 2.0, 0.0, 0.0, 1.0))
            $0.duration = duration
            $0.isCumulative = true
            $0.repeatCount = .greatestFiniteMagnitude
            layer.add($0, forKey: HUD.viewRotationAnimationKey)
        }
    }

    public func stopRotation() {
        layer.removeAnimation(forKey: HUD.viewRotationAnimationKey)
    }
}
extension HUD {
    fileprivate static let viewRotationAnimationKey = "com.HUD.rotationAnimation.key"
}