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
        case indicator(UIActivityIndicatorView.Style = .HUDLarge)
        /// UIProgressView.  Style `Defalut to .default`.
        case progress(UIProgressView.Style = .default)
        /// Shows a custom view. e.g., a UIImageView. The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
        case custom(UIView)

        /// Whether to show only labels.
        public var isText: Bool {
            self == .text
        }

        /// Whether UIActivityIndicatorView or ActivityIndicatorViewable.
        public var isIndicator: Bool {
            if case .indicator = self { return true }
            if case let .custom(view) = self, view is ActivityIndicatorViewable { return true }
            return false
        }

        /// Whether UIProgressView or ProgressViewable.
        public var isProgress: Bool {
            if case .progress = self { return true }
            if case let .custom(view) = self, view is ProgressViewable { return true }
            return false
        }

        /// Not text, indicator and progress.
        public var isCustom: Bool {
            isText == false && isIndicator == false && isProgress == false
        }
    }

    public struct Animation {
        /// The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
        public var style: Animation.Style
        /// The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        public var damping: Animation.Damping
        /// The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public var duration: TimeInterval

        /// Creates a new Animation.
        /// - Parameters:
        ///   - style: The animation type that should be used when the HUD is shown and hidden.
        ///   - damping: The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        ///   - duration: The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public static func animation(_ style: Animation.Style, damping: Animation.Damping = .disable, duration: TimeInterval = 0.3) -> Animation {
            .init(style: style, damping: damping, duration: duration)
        }

        /// Creates a new Animation.
        /// - Parameters:
        ///   - style: The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
        ///   - damping: The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        ///   - duration: The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public init(style: Animation.Style = .fade, damping: Animation.Damping = .disable, duration: TimeInterval = 0.3) {
            self.style = style
            self.duration = duration
            self.damping = damping
        }

        /// Executes the given block passing the `Animation` in as its sole `inout` argument.
        /// - Parameter populator: A block or function that populates the `Animation`, which is passed into the block as an `inout` argument.
        /// - Note: This method is recommended for assigning values to properties.
        @discardableResult
        public mutating func with(_ populator: (inout Animation) -> Void) -> Animation {
            populator(&self)
            return self
        }
    }
}

extension CGFloat {
    public static let HUDMaxOffset: CGFloat = 1000000.0
}
extension CGPoint {
    public static let HUDVMinOffset: CGPoint = .init(x: 0.0, y: -.HUDMaxOffset)
    public static let HUDVMaxOffset: CGPoint = .init(x: 0.0, y: .HUDMaxOffset)
}
extension HUD {
    public struct Layout: Equatable {
        /// The bezel offset relative to the center of the view. You can use `.HUDMaxOffset` and `-.HUDMaxOffset` to move the HUD all the way to the screen edge in each direction. `Default to .zero`
        /// - Note: If set to `.HUDVMaxOffset` would position the HUD centered on the bottom edge. If set to `.zero` would position the HUD centered.
        public var offset: CGPoint
        /// This also represents the minimum bezel distance to the edge of the HUD view. Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
        public var edgeInsets: UIEdgeInsets

        /// The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        public var hMargin: CGFloat
        /// The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        public var vMargin: CGFloat

        /// The space between HUD elements (labels, indicators or custom views). Defaults to 4.0.
        public var spacing: CGFloat

        /// The minimum size of the HUD bezel. Defaults to CGSize.zero (no minimum size).
        public var minSize: CGSize

        /// Force the HUD dimensions to be equal if possible.
        public var isSquare: Bool

        /// The layout guide representing the portion of your view that is unobscured by bars and other content.
        public var isSafeAreaLayoutGuideEnabled: Bool

        /// Creates a new Layout.
        /// - Parameters:
        ///   - offset: The bezel offset relative to the center of the view. You can use `.HUDMaxOffset` and `-.HUDMaxOffset` to move the HUD all the way to the screen edge in each direction. `Default to .zero`
        ///   - edgeInsets: This also represents the minimum bezel distance to the edge of the HUD view. Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
        ///   - hMargin: The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        ///   - vMargin: The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        ///   - spacing: The space between HUD elements (labels, indicators or custom views). Defaults to 4.0.
        ///   - minSize: The minimum size of the HUD bezel. Defaults to CGSize.zero (no minimum size).
        ///   - isSquare: Force the HUD dimensions to be equal if possible.
        ///   - isSafeAreaLayoutGuideEnabled: The layout guide representing the portion of your view that is unobscured by bars and other content.
        public init(offset: CGPoint = .zero,
             edgeInsets: UIEdgeInsets = .init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0),
             hMargin: CGFloat = 20.0, 
             vMargin: CGFloat = 20.0,
             spacing: CGFloat = 4.0,
             minSize: CGSize = .zero,
             isSquare: Bool = false,
             isSafeAreaLayoutGuideEnabled: Bool = true) {
            self.offset = offset
            self.edgeInsets = edgeInsets
            self.hMargin = hMargin
            self.vMargin = vMargin
            self.spacing = spacing
            self.minSize = minSize
            self.isSquare = isSquare
            self.isSafeAreaLayoutGuideEnabled = isSafeAreaLayoutGuideEnabled
        }

        /// Executes the given block passing the `Layout` in as its sole `inout` argument.
        /// - Parameter populator: A block or function that populates the `Layout`, which is passed into the block as an `inout` argument.
        /// - Note: This method is recommended for assigning values to properties.
        @discardableResult
        public mutating func with(_ populator: (inout Layout) -> Void) -> Layout {
            populator(&self)
            return self
        }
    }

#if !os(tvOS)
    /// A layout guide that tracks the keyboard’s position in your app’s layout.
    public enum KeyboardGuide: Equatable {
        /// Disable keyboard tracking.
        case disable
        /// Center alignment.
        /// - Parameter offsetY: The vertical offset of the bezel view relative to the center of the empty area. `Default to 0`.
        case center(_ offsetY: CGFloat = 0.0)
        /// Bezel view bottom relative to keyboard top layout.
        /// - Parameter spacing: The spacing between the bottom of the bezel view and the top of the keyboard. `Default to 8`.
        case bottom(_ spacing: CGFloat = 8.0)
    }
#endif
}

extension HUD.Animation {
    public enum Style: CaseIterable {
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

    public enum Damping: Equatable {
        /// To smoothly decelerate the animation without oscillation.
        case disable
        /// Employ a damping ratio closer to zero to increase oscillation. `Defaults to 0.65`.
        case `default`
        /// Employ a damping ratio closer to zero to increase oscillation.
        ///  - Note: If set to `1.0` the HUD will smoothly decelerate the animation without oscillation.
        case ratio(CGFloat)

        /// The damping ratio for the spring animation as it approaches its quiescent state.
        public var value: CGFloat {
            switch self {
            case .disable: return 1.0
            case .default: return 0.65
            case .ratio(let value): return value
            }
        }
    }
}
