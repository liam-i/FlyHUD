//
//  Util.swift
//  Example iOS
//
//  Created by Liam on 2024/1/23.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit

enum Color: String, CaseIterable {
    case `default`, red, yellow, orange, purple, whiteAlpha, blackAlpha, clear

    var color: UIColor {
        switch self {
        case .default:      return .h.content
        case .red:          return .systemRed
        case .yellow:       return .systemYellow
        case .orange:       return .systemOrange
        case .purple:       return .systemPurple
        case .whiteAlpha:   return .white.withAlphaComponent(0.2)
        case .blackAlpha:   return .black.withAlphaComponent(0.7)
        case .clear:        return .clear
        }
    }
}

extension UIImageView {
    convenience init(named: String) {
        self.init(image: UIImage(named: named)?.withRenderingMode(.alwaysTemplate))
        isAccessibilityElement = false
    }
}

extension UITextField {
    var floatOfText: CGFloat {
        var value: CGFloat = 0.0
        if let text, let floatValue = Float(text) {
            value = CGFloat(floatValue)
        }
        return value
    }
}

extension UIApplication {
    static var getKeyWindow: UIWindow? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .compactMap { $0.keyWindow }
                .first
        } else {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
    }
}

extension Bool {
    var isOn: String {
        self ? "on" : "off"
    }
}
