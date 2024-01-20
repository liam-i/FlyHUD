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

extension HUD {
    public enum Mode: Equatable {
        /// Shows only labels.
        case text
        /// UIActivityIndicatorView. Style `Defalut to .large`.
        case indicator(UIActivityIndicatorView.Style = .largeOfHUD)
        /// UIProgressView.  Style `Defalut to .default`.
        case progress(UIProgressView.Style = .default)
        /// Shows a custom view. e.g., a UIImageView. The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
        case custom(UIView)
    }

    public struct Animation {
        /// The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
        public var style: Animation.Style = .fade
        /// The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public var duration: TimeInterval = 0.3
        /// The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        public var springDamping: Animation.SpringDamping = .disable

        /// Executes the given block passing the `Animation` in as its sole `inout` argument.
        /// - Parameter populator: A block or function that populates the `Animation`, which is passed into the block as an `inout` argument.
        /// - Note: This method is recommended for assigning values to properties.
        public mutating func with(_ populator: (inout Animation) -> Void) {
            populator(&self)
        }

        mutating func set(style: Animation.Style?) -> Animation {
            guard let style = style else { return self }
            self.style = style
            return self
        }
    }
}

extension CGFloat {
    public static let HUDMaxOffset: CGFloat = 1000000.0
}
extension CGPoint {
    public static let HUDVMaxOffset: CGPoint = .init(x: 0.0, y: .HUDMaxOffset)
}
extension HUD {
    public struct Layout: Equatable {
        /// The bezel offset relative to the center of the view. You can use `.HUDMaxOffset` and `-.HUDMaxOffset` to move the HUD all the way to the screen edge in each direction.
        /// - Note: If set to `.HUDVMaxOffset` would position the HUD centered on the bottom edge. If set to `.zero` would position the HUD centered.
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

        /// Executes the given block passing the `Layout` in as its sole `inout` argument.
        /// - Parameter populator: A block or function that populates the `Layout`, which is passed into the block as an `inout` argument.
        /// - Note: This method is recommended for assigning values to properties.
        public mutating func with(_ populator: (inout Layout) -> Void) {
            populator(&self)
        }

        var isOffsetMinY: Bool { offset.y == -.HUDMaxOffset }
        var isOffsetMaxY: Bool { offset.y == .HUDMaxOffset }
    }
}

extension HUD.Animation {
    public enum Style {
        /// Disable animation. The HUD will not use animations while appearing and disappearing
        case none
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
        /// Opacity + slide animation (slide up when appearing slide down when disappearing)
        case slideUpDown
        /// Opacity + slide animation (slide down when appearing slide up when disappearing)
        case slideDownUp
        /// Opacity + slide animation (slide up style)
        case slideUp
        /// Opacity + slide animation (slide down style)
        case slideDown
    }

    public enum SpringDamping {
        /// To smoothly decelerate the animation without oscillation.
        case disable
        /// Employ a damping ratio closer to zero to increase oscillation. `Defaults to 0.65`.
        ///  - Note: If set to `1.0` the HUD will smoothly decelerate the animation without oscillation.
        case dampingRatio(CGFloat = 0.65)

        /// The damping ratio for the spring animation as it approaches its quiescent state.
        public var value: CGFloat {
            switch self {
            case .disable: return 1.0
            case .dampingRatio(let value): return value
            }
        }
    }
}
