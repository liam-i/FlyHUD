//
//  Model+ActivityIndicatorView.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by liam on 2024/1/19.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

#if !COCOAPODS && canImport(FlyHUD)
import FlyHUD
#endif

extension ContentView.Mode {
    /// Creates an activity indicator view with the specified style.
    /// - Parameter style: A constant that specifies the style of the object to be created. See ActivityIndicatorView.Style for descriptions of the style constants.
    /// - Returns: An initialized ContentView.Mode constant.
    public static func indicator(_ style: ActivityIndicatorView.Style) -> ContentView.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }

    /// Creates an activity indicator view with the specified style.
    /// - Parameter style: A constant that specifies the style of the object to be created.
    /// - Returns: An initialized ContentView.Mode constant.
    public static func indicator(_ style: ActivityIndicatorViewStyleable) -> ContentView.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }
}
