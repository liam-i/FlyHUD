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

import UIKit

public class BackgroundView: UIView {
    public var roundedCorners: RoundedCorners = .radius(5.0)

    // MARK: - Properties

    /// The background style. Defaults to .blur
    public var style: HUDBackgroundStyle = .blur {
        didSet {
            if style != oldValue { updateForBackgroundStyle() }
        }
    }

    /// The blur effect style, when using .blur. Defaults to .light.
    public var blurEffectStyle: UIBlurEffect.Style = {
        if #available(iOS 13.0, *) {
            return .systemThickMaterial
        } else {
            return .light
        }
    }() {
        didSet {
            if blurEffectStyle != oldValue { updateForBackgroundStyle() }
        }
    }

    /// The background color or the blur tint color.
    ///  - Note: Defaults to nil on iOS 13 and later and. UIColor(white: 0.8, alpha: 0.6) on older systems.
    public var color: UIColor? = {
        if #available(iOS 13.0, *) {
            return nil
        } else {
            return UIColor(white: 0.8, alpha: 0.6)
        }
    }() {
        didSet {
            if color != oldValue { backgroundColor = color }
        }
    }

    var effectView: UIVisualEffectView?

    // MARK: - Lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

        updateForBackgroundStyle()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        // Smallest size possible. Content pushes against this.
        return .zero
    }

    // MARK: - Views

    private func updateForBackgroundStyle() {
        effectView?.removeFromSuperview()
        effectView = nil

        if style == .blur {
            let effect = UIBlurEffect(style: blurEffectStyle)
            let effectview = UIVisualEffectView(effect: effect)
            insertSubview(effectview, at: 0)
            effectview.frame = bounds
            effectview.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
            effectView = effectview
        } else {
            backgroundColor = color
        }
    }
}
