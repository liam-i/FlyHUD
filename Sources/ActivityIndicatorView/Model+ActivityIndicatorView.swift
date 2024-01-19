//
//  Model+ActivityIndicatorView.swift
//  LPHUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

extension HUD.Mode {
    public static func indicator(_ style: ActivityIndicatorView.Style) -> HUD.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }

    public static func indicator(_ style: ActivityIndicatorViewStyleable) -> HUD.Mode {
        .custom(ActivityIndicatorView(styleable: style))
    }
}
