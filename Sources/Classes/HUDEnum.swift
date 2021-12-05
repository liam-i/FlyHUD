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
    /// Horizontal progress bar.
    case determinateHorizontalBar
    /// Ring-shaped progress view.
    case annularDeterminate
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
