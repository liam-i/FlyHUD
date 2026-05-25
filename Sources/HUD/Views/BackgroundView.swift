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
        /// UIVisualEffectView background view. `Defaults to .systemThickMaterial`.
        case blur(UIBlurEffect.Style = {
            #if os(tvOS)
            return .regular
            #else
            return .systemThickMaterial
            #endif
        }())
        #if compiler(>=6.2)
        /// Liquid Glass material background (iOS 26+, tvOS 26+).
        ///
        /// Uses `UIGlassEffect` for a translucent, dynamic glass appearance that adapts to underlying content.
        /// The `color` property is applied as the glass tint color when set to a non-clear value.
        ///
        /// - Note: Available on iOS 26.0+, tvOS 26.0+. Not available on visionOS.
        #if !os(visionOS)
        @available(iOS 26.0, tvOS 26.0, *)
        case glass
        #endif
        #endif
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

    /// The background color or the blur tint color. For glass style, this is the glass tint color. `Defaults to .clear`.
    open var color: UIColor? = .clear {
        didSet {
            color.h.notEqual(oldValue, do: updateColor())
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
        let radius: CGFloat
        switch roundedCorners {
        case .radius(let value):
            radius = ceil(value)
        case .full:
            radius = ceil(min(bounds.midX, bounds.midY)) // Fully rounded corners
        }

        #if compiler(>=6.2) && !os(visionOS)
        if #available(iOS 26.0, tvOS 26.0, *), case .glass = style {
            // Use continuous corner curve to match glass superellipse rendering
            layer.cornerRadius = radius
            layer.cornerCurve = .continuous
            effectView?.cornerConfiguration = .corners(radius: .fixed(radius))
        } else {
            layer.cornerRadius = radius
        }
        #else
        layer.cornerRadius = radius
        #endif
    }

    /// The natural size for the receiving view, considering only properties of the view itself.
    open override var intrinsicContentSize: CGSize {
        .zero // Smallest size possible. Content pushes against this.
    }

    // MARK: - Views

    private func updateColor() {
        #if compiler(>=6.2) && !os(visionOS)
        if #available(iOS 26.0, tvOS 26.0, *), case .glass = style {
            // For glass style, update tint on the glass effect (keep backgroundColor clear)
            let glassEffect = UIGlassEffect()
            if let tintColor = color, tintColor != .clear {
                glassEffect.tintColor = tintColor
            }
            effectView?.effect = glassEffect
            return
        }
        #endif
        backgroundColor = color
    }

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
        #if compiler(>=6.2) && !os(visionOS)
        case .glass:
            if #available(iOS 26.0, tvOS 26.0, *) {
                let glassEffect = UIGlassEffect()
                if let tintColor = color, tintColor != .clear {
                    glassEffect.tintColor = tintColor
                }
                effectView = UIVisualEffectView(effect: glassEffect).h.then {
                    $0.frame = bounds
                    $0.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                    insertSubview($0, at: 0)
                }
                backgroundColor = .clear
                layer.allowsGroupOpacity = false
            }
        #endif
        }
    }
}
