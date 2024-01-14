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

protocol WithType: AnyObject {}
extension WithType {
    func with(_ populator: (Self) -> Void) -> Self {
        populator(self)
        return self
    }
}
extension NSObject: WithType {}
