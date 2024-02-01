//
//  Extensions.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2024/1/14.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

extension UIView {
    /// UIStackView isHidden bug fixed: - http://www.openradar.me/25087688
    var isHiddenInStackView: Bool {
        get { isHidden }
        set {
            guard isHidden != newValue else { return }
            isHidden = newValue
        }
    }

    func setContentCompressionResistancePriorityForAxis(_ priority: Float) {
        let priority = UILayoutPriority(priority)
        translatesAutoresizingMaskIntoConstraints = false
        setContentCompressionResistancePriority(priority, for: .horizontal)
        setContentCompressionResistancePriority(priority, for: .vertical)
    }
}
