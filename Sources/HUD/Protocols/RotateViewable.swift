//
//  Rotatable.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by liam on 2024/1/23.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A rotate view that shows that a task is in progress.
public protocol RotateViewable: AnyObject where Self: UIView {
    /// Specifies the basic duration of the animation, in seconds.
    var duration: CFTimeInterval { get }

    /// Starts the animation of the rotate view.
    ///
    /// - Note: When the rotate view is animated, the view is animated until stopRotation() is called.
    func startRotating()
    /// Stops the animation of the rotate view.
    ///
    /// - Note: Call this method to stop the animation of the rotate view started with a call to startRotation().
    func stopRotating()
}

extension RotateViewable {
    /// Specifies the basic duration of the animation, in seconds. `Default to 0.25`
    public var duration: CFTimeInterval { 0.25 }

    public func startRotating() {
        layer.add(CABasicAnimation(keyPath: "transform").h.then {
            $0.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
            $0.toValue = NSValue(caTransform3D: CATransform3DMakeRotation(.pi / 2.0, 0.0, 0.0, 1.0))
            $0.duration = duration
            $0.isCumulative = true
            $0.repeatCount = .greatestFiniteMagnitude
            $0.isRemovedOnCompletion = false
        }, forKey: HUD.viewRotationAnimationKey)
    }

    public func stopRotating() {
        layer.removeAnimation(forKey: HUD.viewRotationAnimationKey)
    }
}

extension HUD {
    fileprivate static let viewRotationAnimationKey = "com.HUD.rotationAnimation.key"
}
