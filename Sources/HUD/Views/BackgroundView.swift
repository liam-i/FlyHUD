//
//  BackgroundView.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

extension BackgroundView {
    public enum Style: Equatable, HUDExtended {
        /// Solid color background
        case solidColor
        /// UIVisualEffectView background view. `Defaults to .light`.
        case blur(UIBlurEffect.Style = {
            if #available(iOS 13.0, visionOS 1.0, *) {
                #if os(tvOS)
                return .regular
                #else
                return .systemThickMaterial
                #endif
            } else {
                return .light
            }
        }())
    }
}

/// The view to use as the background of the HUD.
/// HUD adds the background view as a subview behind all other views and uses its current frame location.
open class BackgroundView: BaseView {
    /// The rounded corner mode of the button. `Default to .radius(0.0)`.
    open var roundedCorners: RoundedCorners = .radius(0.0) {
        didSet {
            roundedCorners.h.notEqual(oldValue, do: setNeedsLayout())
        }
    }

    // MARK: - Properties

    /// The background style. `Defaults to .solidColor`.
    open var style: Style = .solidColor {
        didSet {
            style.h.notEqual(oldValue, do: updateForBackgroundStyle())
        }
    }

    /// The background color or the blur tint color. `Defaults to .clear`.
    open var color: UIColor? = .clear {
        didSet {
            color.h.notEqual(oldValue, do: backgroundColor = color)
        }
    }

    private var effectView: UIVisualEffectView?

    // MARK: - Lifecycle

    /// Common initialization method.
    open override func commonInit() {
        clipsToBounds = true
        updateForBackgroundStyle()
    }

    // MARK: - Layout

    /// Lays out subviews.
    open override func layoutSubviews() {
        super.layoutSubviews()
        switch roundedCorners {
        case .radius(let value):
            layer.cornerRadius = ceil(value)
        case .full:
            layer.cornerRadius = ceil(bounds.midY) // Fully rounded corners
        }
    }

    /// The natural size for the receiving view, considering only properties of the view itself.
    open override var intrinsicContentSize: CGSize {
        .zero // Smallest size possible. Content pushes against this.
    }

    // MARK: - Views

    private func updateForBackgroundStyle() {
        effectView?.removeFromSuperview()
        effectView = nil

        switch style {
        case .solidColor:
            backgroundColor = color
        case .blur(let effectStyle):
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: effectStyle)).h.then {
                $0.frame = bounds
                $0.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                insertSubview($0, at: 0)
            }
            backgroundColor = color
            layer.allowsGroupOpacity = false
        }
    }
}
