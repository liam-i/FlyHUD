//
//  UIProgressView+Extension.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by liam on 2024/1/19.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A view that depicts the progress of a task over time.
///
/// The ProgressView class provides properties for managing the style of the progress bar and for getting and setting values that are pinned to the progress of a task.
///
/// - Note: For an indeterminate progress indicator — or a “spinner” — use an instance of the ActivityIndicatorView class.
public protocol ProgressViewable: AnyObject {
    /// The current progress of the progress view.
    ///
    /// - Note: 0.0 .. 1.0, default is 0.0. values outside are pinned.
    var progress: Float { get set }

    /// The color shown for the portion of the progress bar that’s filled.
    var progressTintColor: UIColor? { get set }

    /// The color shown for the portion of the progress bar that isn’t filled.
    var trackTintColor: UIColor? { get set }

    /// The Progress object feeding the progress information to the progress indicator.
    ///
    /// - Note: When this property is set, the progress view updates its progress value automatically using information it
    ///         receives from the [Progress](https://developer.apple.com/documentation/foundation/progress)
    ///         object. Set the property to nil when you want to update the progress manually.  `Defaults to nil`.
    var observedProgress: Progress? { get set }
}

extension UIProgressView: ProgressViewable {}

class iOSUIProgressView: UIProgressView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 120.0, height: 4.0)
    }

    deinit {
#if DEBUG
        print("👍👍👍 UIProgressView is released.")
#endif
    }
}
