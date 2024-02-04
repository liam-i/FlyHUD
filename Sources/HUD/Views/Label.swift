//
//  Label.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by liam on 2024/1/31.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A view that displays one or more lines of informational text.
open class Label: UILabel {
    /// Creates a new label.
    /// - Parameters:
    ///   - fontSize: The size (in points) for the bold font. This value must be greater than 0.0.
    ///   - numberOfLines: The maximum number of lines for rendering text. To remove any maximum limit, and use as many lines as needed, set the value of this property to 0.
    ///   - textColor: The color of the text.
    public convenience init(fontSize: CGFloat, numberOfLines: Int, textColor: UIColor?) {
        self.init(frame: .zero)
        self.adjustsFontSizeToFitWidth = false
        self.textAlignment = .center
        self.textColor = textColor
        self.numberOfLines = numberOfLines
        self.font = .boldSystemFont(ofSize: fontSize)
        self.isOpaque = false
        self.backgroundColor = .clear
    }

    /// Whether the text displayed by the label is nil and empty.
    open var isEmptyOfText: Bool {
        guard let text = text, text.isEmpty == false else { return true }
        return false
    }

    /// The natural size for the receiving view, considering only properties of the view itself.
    open override var intrinsicContentSize: CGSize {
        guard isEmptyOfText else {
            return super.intrinsicContentSize
        }
        return .zero
    }

    /// The text that the label displays.
    open override var text: String? {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }

    /// The bounds rectangle, which describes the label’s location and size in its own coordinate system.
    open override var bounds: CGRect {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }
}
