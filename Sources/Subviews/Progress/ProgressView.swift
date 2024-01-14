//
//  ProgressView.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2021/7/9.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

public protocol Progressive: AnyObject {
    var progress: CGFloat { get set }
}

public class ProgressView: BaseView, Progressive {
    // MARK: - Properties

    /// Progress (0.0 to 1.0)
    public var progress: CGFloat = 0.0 {
        didSet {
            guard progress != oldValue else { return }
            setNeedsDisplay()
        }
    }

    /// Progress color. Defaults to white UIColor(white: 1.0, alpha: 1.0).
    public var progressTintColor: UIColor = UIColor(white: 1.0, alpha: 1.0) {
        didSet {
            guard progressTintColor != oldValue && !progressTintColor.isEqual(oldValue) else { return }
            setNeedsDisplay()
        }
    }

    /// background (non-progress) color. Defaults to clear UIColor.clear.
    public var trackTintColor: UIColor = UIColor.clear {
        didSet {
            guard trackTintColor != oldValue && !trackTintColor.isEqual(oldValue) else { return }
            setNeedsDisplay()
        }
    }

    // MARK: - Lifecycle

    public override func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }
}
