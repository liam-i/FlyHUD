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

import Foundation

public enum HUDMode {
    /// UIActivityIndicatorView.
    case indeterminate
    /// A round, pie-chart like, progress view.
    case determinate
    /// Ring-shaped progress view.
    case annularDeterminate
    /// Horizontal progress bar.
    case determinateHorizontalBar
    /// Shows a custom view.
    case customView
    /// Shows only labels.
    case text
}

public enum HUDAnimation {
    /// Opacity animation
    case fade
    /// Opacity + scale animation (zoom in when appearing zoom out when disappearing)
    case zoom
    /// Opacity + scale animation (zoom out style)
    case zoomOut
    /// Opacity + scale animation (zoom in style)
    case zoomIn
}

public enum HUDBackgroundStyle {
    /// Solid color background
    case solidColor
    /// UIVisualEffectView or UIToolbar.layer background view
    case blur
}

public enum RoundedCorners {
    /// corner Radius
    case radius(CGFloat)
    /// Fully rounded corners
    case fully
}

public struct HUDLayoutConfiguration: Equatable {
    /// The bezel offset relative to the center of the view. You can use `HUDLayoutConfiguration.maxOffset` and `-HUDLayoutConfiguration.maxOffset`
    /// to move the HUD all the way to the screen edge in each direction.
    /// E.g., `CGPoint(x: 0.0, y: HUDLayoutConfiguration.maxOffset)` would position the HUD centered on the bottom edge.
    public var offset: CGPoint = .zero
    public static let maxOffset: CGFloat = 1000000.0

    /// The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
    /// This also represents the minimum bezel distance to the edge of the HUD view.
    /// Defaults to 20.0.
    public var margin: CGFloat = 20.0

    /// The space between HUD subviews.
    public var padding: CGFloat = 4.0

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