//
//  UIActivityIndicatorView+Extension.swift
//  LPHUD
//
//  Created by liam on 2024/1/19.
//

import Foundation

public protocol ActivityIndicatorViewable: AnyObject {
    /// The color of the activity indicator.
    /// - Note: If you set a color for an activity indicator, it overrides the color provided by the style property.
    var color: UIColor! { get set }
    var trackColor: UIColor? { get set }

    var hidesWhenStopped: Bool { get set }

    func startAnimating()
    func stopAnimating()

    var isAnimating: Bool { get }
}

extension UIActivityIndicatorView: ActivityIndicatorViewable {
    public var trackColor: UIColor? {
        get { nil }
        set { }
    }
}

extension UIActivityIndicatorView.Style {
    /// Defaults to UIActivityIndicatorView.Style.large
    public static var largeOfHUD: UIActivityIndicatorView.Style {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return .large
        } else {
            return .whiteLarge
        }
    }
}
