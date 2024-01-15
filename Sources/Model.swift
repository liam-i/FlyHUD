//
//  HUDEnum.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

public enum HUDMode: Equatable {
    /// Shows only labels.
    case text
    /// UIActivityIndicatorView. `Defalut to .large`.
    case indeterminate(UIActivityIndicatorView.Style = {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return .large
        } else {
            return .whiteLarge
        }
    }())
    /// Progress view.
    /// - Parameters:
    ///   - isAnnular:Display mode. (false, A round, pie-chart like; true, Ring-shaped). `Defaults to false (round)`.
    ///   - lineWidth: Indicator line width. `Defaults to 2.0`.
    ///   - radius: Indicator line size. `Defaults to 37.0`.
    case determinate(isAnnular: Bool = false, lineWidth: CGFloat = 2.0, lineSize: CGFloat = 37.0)
    /// Horizontal progress bar.
    /// - Parameters:
    ///   - lineWidth: Bar border line width. `Defaults to 2.0`.
    ///   - spacing: Bar border line spacing. `Defaults to 2.0`.
    case determinateHorizontalBar(lineWidth: CGFloat = 2.0, spacing: CGFloat = 2.0)
    /// Shows a custom view. e.g., a UIImageView. The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
    case customView(UIView)
}

public enum HUDAnimation {
    /// Opacity animation
    case fade
    /// Opacity + scale animation (zoom in when appearing zoom out when disappearing)
    case zoomInOut
    /// Opacity + scale animation (zoom out when appearing zoom in when disappearing)
    case zoomOutIn
    /// Opacity + scale animation (zoom in style)
    case zoomIn
    /// Opacity + scale animation (zoom out style)
    case zoomOut
}

public enum HUDBackgroundStyle: Equatable {
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

public enum RoundedCorners: Equatable {
    /// corner Radius
    case radius(CGFloat)
    /// Fully rounded corners
    case fully
}

extension CGFloat {
    public static let HUDMaxOffset: CGFloat = 1000000.0
}
public struct HUDLayoutConfiguration: Equatable {
    /// The bezel offset relative to the center of the view. You can use `.HUDMaxOffset` and `-.HUDMaxOffset` to move the HUD all the way to the screen edge in each direction.
    /// E.g., `CGPoint(x: 0.0, y: .HUDMaxOffset)` would position the HUD centered on the bottom edge.
    public var offset: CGPoint = .zero
    /// This also represents the minimum bezel distance to the edge of the HUD view. Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
    public var edgeInsets: UIEdgeInsets = .init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)

    /// The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
    public var hMargin: CGFloat = 20.0

    /// The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
    public var vMargin: CGFloat = 20.0

    /// The space between HUD elements (labels, indicators or custom views). Defaults to 4.0.
    public var spacing: CGFloat = 4.0

    /// The minimum size of the HUD bezel. Defaults to CGSize.zero (no minimum size).
    public var minSize: CGSize = .zero

    /// Force the HUD dimensions to be equal if possible.
    public var isSquare: Bool = false

    /// Executes the given block passing the `HUDLayoutConfiguration` in as its sole `inout` argument.
    /// - Parameter populator: A block or function that populates the `HUDLayoutConfiguration`, which is passed into the block as an `inout` argument.
    /// - Note: This method is recommended for assigning values to properties.
    public mutating func with(_ populator: (inout HUDLayoutConfiguration) -> Void) {
        populator(&self)
    }
}

enum HUDAnimationOptions {
    case animation(HUDAnimation)
    case none

    init(animated: Bool, animation: @autoclosure () -> HUDAnimation) {
        self = animated ? .animation(animation()) : .none
    }
}
