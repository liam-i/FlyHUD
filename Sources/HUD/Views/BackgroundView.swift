//
//  BackgroundView.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//
//  Forked from https://github.com/liam-i/HUD
//  Version 1.2.5
//

import UIKit

extension BackgroundView {
    public enum Style: Equatable {
        /// Solid color background
        case solidColor
        /// UIVisualEffectView background view. `Defaults to .light`.
        case blur(UIBlurEffect.Style = {
            if #available(iOS 13.0, *) {
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
extension BackgroundView.Style: HUDExtended {}

public class BackgroundView: BaseView {
    /// The rounded corner mode of the button. `Default to .radius(0.0)`.
    public var roundedCorners: RoundedCorners = .radius(0.0) {
        didSet {
            roundedCorners.h.notEqual(oldValue, do: setNeedsLayout())
        }
    }

    // MARK: - Properties

    /// The background style. `Defaults to .solidColor`.
    public var style: Style = .solidColor {
        didSet {
            style.h.notEqual(oldValue, do: updateForBackgroundStyle())
        }
    }

    /// The background color or the blur tint color. `Defaults to .clear`.
    public var color: UIColor? = .clear {
        didSet {
            color.h.notEqual(oldValue, do: backgroundColor = color)
        }
    }

    private var effectView: UIVisualEffectView?

    // MARK: - Lifecycle

    public override func commonInit() {
        clipsToBounds = true
        updateForBackgroundStyle()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        switch roundedCorners {
        case .radius(let value):
            layer.cornerRadius = ceil(value)
        case .fully:
            layer.cornerRadius = ceil(bounds.height / 2.0) // Fully rounded corners
        }
    }

    public override var intrinsicContentSize: CGSize {
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
