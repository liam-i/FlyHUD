//
//  Extensions.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/1/14.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

extension UIView {
    static var isRTL: Bool {
        UIView.userInterfaceLayoutDirection(for: UIView.appearance().semanticContentAttribute) == .rightToLeft
    }

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

    class EdgeConstraint {
        let x, y, top, bottom, left, right: NSLayoutConstraint

        init(_ from: UIView, to: UIView, useSafeGuide: Bool, center: UILayoutPriority, edge: UILayoutPriority) {
            let centerPriority: (NSLayoutConstraint) -> Void = { $0.priority = center }
            let edgePriority: (NSLayoutConstraint) -> Void = { $0.priority = edge }

            let xAnchor, leftAnchor, rightAnchor: NSLayoutXAxisAnchor, yAnchor, topAnchor, bottomAnchor: NSLayoutYAxisAnchor
            if useSafeGuide {
                (xAnchor, yAnchor, leftAnchor, rightAnchor, topAnchor, bottomAnchor) = (
                    to.safeAreaLayoutGuide.centerXAnchor, to.safeAreaLayoutGuide.centerYAnchor,
                    to.safeAreaLayoutGuide.leadingAnchor, to.safeAreaLayoutGuide.trailingAnchor,
                    to.safeAreaLayoutGuide.topAnchor, to.safeAreaLayoutGuide.bottomAnchor)
            } else {
                (xAnchor, yAnchor, leftAnchor, rightAnchor, topAnchor, bottomAnchor) = (
                    to.centerXAnchor, to.centerYAnchor,
                    to.leadingAnchor, to.trailingAnchor, to.topAnchor, to.bottomAnchor)
            }

            (x, y, left, right, top, bottom) = (
                from.centerXAnchor.constraint(equalTo: xAnchor).h.then(centerPriority),
                from.centerYAnchor.constraint(equalTo: yAnchor).h.then(centerPriority),

                from.leadingAnchor.constraint(greaterThanOrEqualTo: leftAnchor).h.then(edgePriority),
                from.trailingAnchor.constraint(lessThanOrEqualTo: rightAnchor).h.then(edgePriority),
                from.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).h.then(edgePriority),
                from.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).h.then(edgePriority))
            NSLayoutConstraint.activate([x, y, top, left, bottom, right])
        }

        func update(offset: CGPoint, edge: UIEdgeInsets) {
            (x.constant, y.constant, left.constant, right.constant, top.constant, bottom.constant) = (
                offset.x, offset.y, edge.left, -edge.right, edge.top, -edge.bottom)
        }

        func update(hMargin: CGFloat, vMargin: CGFloat) {
            (left.constant, right.constant, top.constant, bottom.constant) = (
                hMargin, -hMargin, vMargin, -vMargin)
        }
    }
}
