//
//  Button.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

public enum RoundedCorners: Equatable, HUDExtended {
    /// corner Radius
    case radius(CGFloat)
    /// Fully rounded corners
    case full
}

/// A control that executes your custom code in response to user interactions.
open class Button: UIButton {
    /// The rounded corner mode of the button. `Default to .full`.
    open var roundedCorners: RoundedCorners = .full {
        didSet {
            roundedCorners.h.notEqual(oldValue, do: setNeedsLayout())
        }
    }
    /// Button border width. `Default to 1`.
    open var borderWidth: CGFloat = 1.0 {
        didSet {
            borderWidth.h.notEqual(oldValue, do: layer.borderWidth = borderWidth)
        }
    }

    // MARK: - Lifecycle

    /// Creates a new button.
    /// - Parameters:
    ///   - fontSize: The size (in points) for the bold font. This value must be greater than 0.0.
    ///   - textColor: The title color used in normal state..
    public convenience init(fontSize: CGFloat, textColor: UIColor?) {
        self.init(type: .custom)
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.font = .boldSystemFont(ofSize: fontSize)
        self.setTitleColor(textColor, for: .normal)
    }

    /// Creates a new button with the specified frame.
    /// - Parameter frame: The frame rectangle for the view, measured in points.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = borderWidth
    }

    /// Creates a new button with data in an unarchiver.
    /// - Parameter aDecoder: An unarchiver object.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.borderWidth = borderWidth
    }

    // MARK: - Layout

    /// Lays out subviews.
    open override func layoutSubviews() {
        super.layoutSubviews()
        switch roundedCorners {
        case .radius(let value):
            layer.cornerRadius = ceil(value)
        case .full:
            layer.cornerRadius = ceil(bounds.midY) // Fully rounded corners
        }
    }

    /// The natural size for the receiving view, considering only properties of the view itself.
    open override var intrinsicContentSize: CGSize {
        if isEmptyOfText && allControlEvents.rawValue <= 0 {
            return .zero // Only show if we have associated control events and a title
        }
        var size = super.intrinsicContentSize
        size.width += 20.0 // Add some side padding
        return size
    }

    /// The bounds rectangle, which describes the button’s location and size in its own coordinate system.
    open override var bounds: CGRect {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }

    /// Sets the title to use for the specified state.
    /// - Parameters:
    ///   - title: The title to use for the specified state.
    ///   - state: The state that uses the specified title. UIControl.State describes the possible values.
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        isHiddenInStackView = isEmptyOfText
    }

    /// Sets the color of the title to use for the specified state.
    /// - Parameters:
    ///   - color: The color of the title to use for the specified state.
    ///   - state: The state that uses the specified color. The possible values are described in UIControl.State.
    open override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors
        isHighlighted = isHighlighted
        layer.borderColor = color?.cgColor
    }

    /// A Boolean value indicating whether the control draws a highlight.
    open override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? titleColor(for: .selected)?.withAlphaComponent(0.1) : .clear
        }
    }

    /// Whether the text displayed by the button is nil and empty.
    open var isEmptyOfText: Bool {
        guard let text = title(for: .normal), text.isEmpty == false else { return true }
        return false
    }
}
