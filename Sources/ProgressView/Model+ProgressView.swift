//
//  Model+ProgressView.swift
//  LPHUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

extension HUD.Mode {
    public static func progress(_ style: ProgressView.Style) -> HUD.Mode {
        .custom(ProgressView(styleable: style))
    }

    public static func progress(_ style: ProgressViewStyleable) -> HUD.Mode {
        .custom(ProgressView(styleable: style))
    }
}
