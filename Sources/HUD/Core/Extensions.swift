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
    fileprivate func apply(priority: Float) -> Self {
        let priority = UILayoutPriority(priority)
        forEach {
            $0.priority = priority
        }
        return self
    }
}

extension UIView {
    func setContentCompressionResistancePriorityForAxis(_ priority: Float) {
        let priority = UILayoutPriority(priority)
        translatesAutoresizingMaskIntoConstraints = false
        setContentCompressionResistancePriority(priority, for: .horizontal)
        setContentCompressionResistancePriority(priority, for: .vertical)
    }

    func constraintsForCenter(equalTo view: UIView, offset: CGPoint, priority: Float, useSafeGuide: Bool) -> [NSLayoutConstraint] {
        let safeArea = view.safeAreaInsets
        let constant: (x: CGFloat, y: CGFloat)
        if useSafeGuide {
            constant = (offset.x + safeArea.left - safeArea.right, offset.y + safeArea.top - safeArea.bottom)
        } else {
            constant = (offset.x, offset.y)
        }
        return [
            centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant.x),
            centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant.y)
        ].apply(priority: priority)
    }

    func constraintsForEdge(greaterOrEqualTo view: UIView, edge: UIEdgeInsets, priority: Float, useSafeGuide: Bool) -> [NSLayoutConstraint] {
        let safeArea = view.safeAreaInsets
        let constant: (left: CGFloat, right: CGFloat, top: CGFloat, bottom: CGFloat)
        if useSafeGuide {
            constant = (edge.left + safeArea.left, edge.right + safeArea.right, edge.top + safeArea.top, edge.bottom + safeArea.bottom)
        } else {
            constant = (edge.left, edge.right, edge.top, edge.bottom)
        }
        return [
            leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: constant.left),
            trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -constant.right),
            topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: constant.top),
            bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -constant.bottom),
        ].apply(priority: priority)
    }

    func constraintsForSize(greaterOrEqualTo size: CGSize, priority: Float) -> [NSLayoutConstraint] {
        [
            widthAnchor.constraint(greaterThanOrEqualToConstant: size.width),
            heightAnchor.constraint(greaterThanOrEqualToConstant: size.height)
        ].apply(priority: priority)
    }

    func constraintForSquare(priority: Float) -> NSLayoutConstraint {
        heightAnchor.constraint(equalTo: widthAnchor).h.then {
            $0.priority = UILayoutPriority(priority)
        }
    }

    func constraintsForH(equalTo view: UIView, margin: CGFloat) -> [NSLayoutConstraint] {
        [
            // Center in bezel
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // Ensure the minimum edge margin is kept
            leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: margin),
            trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -margin)
        ]
    }

    func constraintForTop(greaterOrEqualTo view: UIView, margin: CGFloat) -> NSLayoutConstraint {
        topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: margin)
    }

    func constraintForBottom(greaterOrEqualTo view: UIView, margin: CGFloat) -> NSLayoutConstraint {
        bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -margin)
    }

    func constraintForTopToBottom(equalTo view: UIView) -> NSLayoutConstraint {
        topAnchor.constraint(equalTo: view.bottomAnchor)
    }
}
