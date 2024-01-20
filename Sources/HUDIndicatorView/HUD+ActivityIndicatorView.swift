//
//  Model+ActivityIndicatorView.swift
//  HUD
//
//  Created by liam on 2024/1/19.
//

import UIKit
#if canImport(HUD)
import HUD
#endif

extension HUD.Mode {
    /// Creates an activity indicator view with the specified style.
    /// - Parameter style: A constant that specifies the style of the object to be created. See ActivityIndicatorView.Style for descriptions of the style constants.
    /// - Returns: An initialized HUD.Mode constant.
    public static func indicator(_ style: ActivityIndicatorView.Style) -> HUD.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }

    /// Creates an activity indicator view with the specified style.
    /// - Parameter style: A constant that specifies the style of the object to be created.
    /// - Returns: An initialized HUD.Mode constant.
    public static func indicator(_ style: ActivityIndicatorViewStyleable) -> HUD.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }
}
