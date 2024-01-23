//
//  Util.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2024/1/14.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

extension Array where Element == NSLayoutConstraint {
    func apply(_ priority: UILayoutPriority) -> Self {
        forEach {
            $0.priority = priority
        }
        return self
    }
}

extension NSLayoutConstraint {
    func apply(_ priority: UILayoutPriority) -> Self {
        self.priority = priority
        return self
    }
}

extension UIView {
    func setContentCompressionResistancePriorityForAxis(_ priority: UILayoutPriority) {
        translatesAutoresizingMaskIntoConstraints = false
        setContentCompressionResistancePriority(priority, for: .horizontal)
        setContentCompressionResistancePriority(priority, for: .vertical)
    }
}

extension UIColor {
    /// Defaults to UIColor.label.withAlphaComponent(0.7)
    public static let HUDContent: UIColor = {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return UIColor.label.withAlphaComponent(0.7)
        } else {
            return UIColor(white: 0.0, alpha: 0.7)
        }
    }()

    /// The background color or the blur tint color. Defaults to nil on iOS 13 and later and. UIColor(white: 0.8, alpha: 0.6) on older systems.
    public static let HUDBackground: UIColor? = {
        if #available(iOS 13.0, *) {
            return nil
        } else {
            return UIColor(white: 0.8, alpha: 0.6)
        }
    }()
}

extension Equatable {
    public func notEqual(_ value: Self, do block: @autoclosure() -> Void?) {
        guard self != value else { return }
        block()
    }
}
extension Equatable where Self: NSObjectProtocol {
    public func notEqual(_ value: Self?, do block: @autoclosure() -> Void?) {
        guard self != value, isEqual(value) == false else { return }
        block()
    }
}

public protocol WithType: AnyObject {}
extension WithType {
    @discardableResult
    public func with(_ populator: (Self) -> Void) -> Self {
        populator(self)
        return self
    }
}
extension NSObject: WithType {}
