//
//  UIProgressView+Extension.swift
//  HUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

/// The methods adopted by the object you use to manage user interactions in a progress view.
public protocol ProgressViewDelegate: AnyObject {
    /// Tells the delegate that the progress was updated. Refreshing the progress only every frame draw.
    func updateProgress(from observedProgress: Progress)
}

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

    /// The Progress object feeding the progress information to the progress indicator.
    /// - Note: When this property is set, the progress view updates its progress value automatically using information it receives from the [Progress](https://developer.apple.com/documentation/foundation/progress) object. Set the property to nil when you want to update the progress manually.  `Defaults to nil`.
    var observedProgress: Progress? { get set }

    /// The object that acts as the delegate of the progress view. The delegate must adopt the ProgressViewDelegate protocol.
    var delegate: ProgressViewDelegate? { get set }
}

extension UIProgressView: ProgressViewable {
    // FIXME: How to implement delegation?
    public weak var delegate: ProgressViewDelegate? {
        get { nil }
        set { }
    }
}

class iOSUIProgressView: UIProgressView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 120.0, height: 4.0)
    }
}
