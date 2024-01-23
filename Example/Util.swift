//
//  Util.swift
//  HUD_Example
//
//  Created by liam on 2024/1/23.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

enum Color: String, CaseIterable {
    case `default`, red, yellow, orange, purple, whiteAlpha, blackAlpha, clear

    var color: UIColor {
        switch self {
        case .default:      return .HUDContent
        case .red:          return .systemRed
        case .yellow:       return .systemYellow
        case .orange:       return .systemOrange
        case .purple:       return .systemPurple
        case .whiteAlpha:   return .white.withAlphaComponent(0.2)
        case .blackAlpha:   return .black.withAlphaComponent(0.7)
        case .clear:        return .clear
        }
    }

    static func make(_ rawValue: String) -> Color {
        Color(rawValue: rawValue) ?? .default
    }

    static var allCaseValues: [String] {
        allCases.map { String(describing: $0) }
    }
}

extension ViewController {
    func alertSwitch(_ title: String, selected: @escaping(_ isOn: Bool) -> Void, selected1: @escaping(Bool) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with {
            $0.addAction(UIAlertAction(title: "off", style: .destructive, handler: { _ in
                selected(false); selected1(false)
            }))
            $0.addAction(UIAlertAction(title: "on", style: .default, handler: { _ in
                selected(true); selected1(true)
            }))
            present($0, animated: true)
        }
    }
    func alertTextField(_ title: String, selected: @escaping(_ value: CGFloat) -> Void, selected1: @escaping(CGFloat) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with { alert in
            alert.addTextField { textField in
                textField.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                let value = alert.textFields?.first?.floatOfText ?? 0.0
                selected(value); selected1(value)
            }))
            present(alert, animated: true)
        }
    }
    func alertListPicker(_ title: String, list: [String], selected: @escaping(_ value: String) -> Void, selected1: @escaping(String) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with { alert in
            list.forEach {
                alert.addAction(UIAlertAction(title: $0, style: .default, handler: {
                    selected($0.title!); selected1($0.title!)
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: nil))
            present(alert, animated: true)
        }
    }
}

extension UITextField {
    var floatOfText: CGFloat {
        var value: CGFloat = 0.0
        if let text = text, let f = Float(text) {
            value = CGFloat(f)
        }
        return value
    }
}

extension UIApplication {
    static var getKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return UIApplication.shared.keyWindow
    }
}