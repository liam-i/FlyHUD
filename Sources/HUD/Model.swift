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

extension HUDExtension where ExtendedType == CGFloat {
    public static let maxOffset: CGFloat = 1000000.0
}
extension HUDExtension where ExtendedType == CGPoint {
    public static let vMinOffset: CGPoint = .init(x: 0.0, y: -.h.maxOffset)
    public static let vMaxOffset: CGPoint = .init(x: 0.0, y: .h.maxOffset)
}
extension HUD {
    public struct Layout: Equatable, HUDExtended {
        /// The contentView offset relative to the center of the view. You can use `.h.maxOffset` and `-.h.maxOffset` to move
        /// the HUD all the way to the screen edge in each direction. `Default to .zero`
        ///
        /// - Note: If set to `.h.vMaxOffset` would position the HUD centered on the bottom edge. If set to `.zero` would position the HUD centered.
        public var offset: CGPoint
        /// This also represents the minimum contentView distance to the edge of the HUD. Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
        public var edgeInsets: UIEdgeInsets

        /// The layout guide representing the portion of your view that is unobscured by bars and other content.
        /// - Warning: This property setting only takes effect after the HUD is initialized and before `show` is executed for the first time.
        public var isSafeAreaLayoutGuideEnabled: Bool

        /// Creates a new Layout.
        ///
        /// - Parameters:
        ///   - offset: The contentView offset relative to the center of the view. You can use `.maxOffset` and `-.maxOffset` to move
        ///             the HUD all the way to the screen edge in each direction. `Default to .zero`
        ///   - edgeInsets: This also represents the minimum contentView distance to the edge of the HUD.
        ///                 Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
        ///   - isSafeAreaLayoutGuideEnabled: The layout guide representing the portion of your view that is unobscured by bars and other content.
        /// - Warning: The `isSafeAreaLayoutGuideEnabled` property setting only takes effect after the HUD is initialized and before `show` is executed for the first time.
        public init(offset: CGPoint = .zero,
                    edgeInsets: UIEdgeInsets = .init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0),
                    isSafeAreaLayoutGuideEnabled: Bool = true) {
            self.offset = offset
            self.edgeInsets = edgeInsets
            self.isSafeAreaLayoutGuideEnabled = isSafeAreaLayoutGuideEnabled
        }
    }

    public struct Animation: Equatable, HUDExtended {
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
            /// Opacity + slide animation (slide right when appearing slide left when disappearing)
            case slideRightLeft
            /// Opacity + slide animation (slide left when appearing slide right when disappearing)
            case slideLeftRight
            /// Opacity + slide animation (Slide out style right)
            case slideRight
            /// Opacity + slide animation (Slide out style left)
            case slideLeft

            // Automatically determine the correct animation style
            func corrected(_ showing: Bool) -> Style {
                switch self {
                case .zoomInOut:        return showing ? .zoomIn : .zoomOut
                case .zoomOutIn:        return showing ? .zoomOut : .zoomIn
                case .slideUpDown:      return showing ? .slideUp : .slideDown
                case .slideDownUp:      return showing ? .slideDown : .slideUp
                case .slideRightLeft:   return showing ? .slideRight : .slideLeft
                case .slideLeftRight:   return showing ? .slideLeft : .slideRight
                default:                return self
                }
            }

            var reversed: Style? {
                switch self {
                case .zoomIn:       return .zoomOut
                case .zoomOut:      return .zoomIn
                case .slideUp:      return .slideDown
                case .slideDown:    return .slideUp
                case .slideRight:   return .slideLeft
                case .slideLeft:    return .slideRight
                default:            return nil
                }
            }
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

        /// The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
        public var style: Animation.Style
        /// The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        public var damping: Animation.Damping
        /// The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public var duration: TimeInterval

        /// Creates a new Animation.
        ///
        /// - Parameters:
        ///   - style: The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
        ///   - damping: The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        ///   - duration: The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public init(style: Animation.Style = .fade,
                    damping: Animation.Damping = .disable,
                    duration: TimeInterval = 0.3) {
            self.style = style
            self.duration = duration
            self.damping = damping
        }

        /// Creates a new Animation.
        ///
        /// - Parameters:
        ///   - style: The animation type that should be used when the HUD is shown and hidden.
        ///   - damping: The damping ratio for the spring animation as it approaches its quiescent state. `Defaults to .disable`.
        ///   - duration: The animation duration that should be used when the HUD is shown and hidden. `Defaults to 0.3`.
        public static func animation(
            _ style: Animation.Style,
            damping: Animation.Damping = .disable,
            duration: TimeInterval = 0.3
        ) -> Animation {
            .init(style: style, damping: damping, duration: duration)
        }
    }

#if !os(tvOS)
    /// A layout guide that tracks the keyboard’s position in your app’s layout.
    public enum KeyboardGuide: Equatable, HUDExtended {
        /// Disable keyboard tracking.
        case disable
        /// Center alignment.
        /// - Parameter offsetY: The vertical offset of the contentView view relative to the center of the empty area. `Default to 0`.
        case center(_ offsetY: CGFloat = 0.0)
        /// Content view bottom relative to keyboard top layout.
        /// - Parameter spacing: The spacing between the bottom of the contentView view and the top of the keyboard. `Default to 8`.
        case bottom(_ spacing: CGFloat = 8.0)
    }
#endif
}
