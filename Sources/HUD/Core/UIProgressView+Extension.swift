//
//  UIProgressView+Extension.swift
//  LPHUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

/// A view that depicts the progress of a task over time.
/// - Note: The ProgressView class provides properties for managing the style of the progress bar and for getting and setting values that are pinned to the progress of a task.
/// - Note: For an indeterminate progress indicator — or a “spinner” — use an instance of the ActivityIndicatorView class.
public protocol ProgressViewable: AnyObject {
    /// The current progress of the progress view.
    /// - Note: 0.0 .. 1.0, default is 0.0. values outside are pinned.
    var progress: Float { get set }

    /// The color shown for the portion of the progress bar that’s filled.
    var progressTintColor: UIColor? { get set }

    /// The color shown for the portion of the progress bar that isn’t filled.
    var trackTintColor: UIColor? { get set }
}

extension UIProgressView: ProgressViewable {}

class iOSUIProgressView: UIProgressView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 120.0, height: 4.0)
    }
}
