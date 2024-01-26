//
//  ActivityIndicatorViewable.swift
//  HUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

/// A view that shows that a task is in progress.
/// - Note: You control when an activity indicator animates by calling the startAnimating() and stopAnimating() methods. To automatically hide the activity indicator when animation stops, set the hidesWhenStopped property to true. You can set the color of the activity indicator by using the color property.
public protocol ActivityIndicatorViewable: AnyObject {
    /// The color of the activity indicator.
    /// - Note: If you set a color for an activity indicator, it overrides the color provided by the style property.
    var color: UIColor! { get set }
    /// The track color of the activity indicator.
    var trackColor: UIColor? { get set }

    /// A Boolean value that controls whether the activity indicator is hidden when the animation is stopped.
    /// - Note: If the value of this property is true (the default), the receiver sets its isHidden property (UIView) to true when receiver is not animating. If the hidesWhenStopped property is false, the receiver is not hidden when animation stops. You stop an animating activity indicator with the stopAnimating() method.
    var hidesWhenStopped: Bool { get set }
    /// A Boolean value indicating whether the activity indicator is currently running its animation.
    var isAnimating: Bool { get }

    /// Starts the animation of the activity indicator.
    /// - Note: When the activity indicator is animated, the gear spins to indicate indeterminate progress. The indicator is animated until stopAnimating() is called.
    func startAnimating()
    /// Stops the animation of the activity indicator.
    /// - Note: Call this method to stop the animation of the activity indicator started with a call to startAnimating(). When animating is stopped, the indicator is hidden, unless hidesWhenStopped is false.
    func stopAnimating()
}

extension UIActivityIndicatorView: ActivityIndicatorViewable {
    public var trackColor: UIColor? {
        get { nil }
        set { }
    }
}

extension UIActivityIndicatorView.Style {
    /// Defaults to UIActivityIndicatorView.Style.large
    public static var HUDLarge: UIActivityIndicatorView.Style {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return .large
        } else {
            return .whiteLarge
        }
    }
}
