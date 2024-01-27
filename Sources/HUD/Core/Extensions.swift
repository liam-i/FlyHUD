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

    func constraintsForCenter(equalTo view: UIView, offset: CGPoint, priority: Float, safeGuideEnabled: Bool) -> [NSLayoutConstraint] {
        let anchor: (x: NSLayoutXAxisAnchor, y: NSLayoutYAxisAnchor)
        if safeGuideEnabled {
            anchor = (view.safeAreaLayoutGuide.centerXAnchor, view.safeAreaLayoutGuide.centerYAnchor)
        } else {
            anchor = (view.centerXAnchor, view.centerYAnchor)
        }
        return [
            centerXAnchor.constraint(equalTo: anchor.x, constant: offset.x),
            centerYAnchor.constraint(equalTo: anchor.y, constant: offset.y)
        ].apply(priority: priority)
    }

    func constraintsForEdge(greaterOrEqualTo view: UIView, edge: UIEdgeInsets, priority: Float, safeGuideEnabled: Bool) -> [NSLayoutConstraint] {
        let anchor: (leading: NSLayoutXAxisAnchor, trailing: NSLayoutXAxisAnchor, top: NSLayoutYAxisAnchor, bottom: NSLayoutYAxisAnchor)
        if safeGuideEnabled {
            anchor = (view.safeAreaLayoutGuide.leadingAnchor, view.safeAreaLayoutGuide.trailingAnchor,
                      view.safeAreaLayoutGuide.topAnchor, view.safeAreaLayoutGuide.bottomAnchor)
        } else {
            anchor = (view.leadingAnchor, view.trailingAnchor, view.topAnchor, view.bottomAnchor)
        }
        return [
            leadingAnchor.constraint(greaterThanOrEqualTo: anchor.leading, constant: edge.left),
            trailingAnchor.constraint(lessThanOrEqualTo: anchor.trailing, constant: -edge.right),
            topAnchor.constraint(greaterThanOrEqualTo: anchor.top, constant: edge.top),
            bottomAnchor.constraint(lessThanOrEqualTo: anchor.bottom, constant: -edge.bottom),
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
