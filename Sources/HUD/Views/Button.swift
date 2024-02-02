//
//  Button.swift
//  HUD <https://github.com/liam-i/HUD>
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

public class Button: UIButton {
    /// The rounded corner mode of the button. `Default to .full`.
    public var roundedCorners: RoundedCorners = .full {
        didSet {
            roundedCorners.h.notEqual(oldValue, do: setNeedsLayout())
        }
    }
    /// Button border width. `Default to 1`.
    public var borderWidth: CGFloat = 1.0 {
        didSet {
            borderWidth.h.notEqual(oldValue, do: layer.borderWidth = borderWidth)
        }
    }

    // MARK: - Lifecycle

    convenience init(fontSize: CGFloat, textColor: UIColor?) {
        self.init(type: .custom)
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.font = .boldSystemFont(ofSize: fontSize)
        self.setTitleColor(textColor, for: .normal)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = borderWidth
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.borderWidth = borderWidth
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        switch roundedCorners {
        case .radius(let value):
            layer.cornerRadius = ceil(value)
        case .full:
            layer.cornerRadius = ceil(bounds.midY) // Fully rounded corners
        }
    }

    public override var intrinsicContentSize: CGSize {
        if isEmptyOfText && allControlEvents.rawValue <= 0 {
            return .zero // Only show if we have associated control events and a title
        }
        var size = super.intrinsicContentSize
        size.width += 20.0 // Add some side padding
        return size
    }

    public override var bounds: CGRect {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }

    public override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        isHiddenInStackView = isEmptyOfText
    }

    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors
        isHighlighted = isHighlighted
        layer.borderColor = color?.cgColor
    }

    public override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? titleColor(for: .selected)?.withAlphaComponent(0.1) : .clear
        }
    }

    var isEmptyOfText: Bool {
        guard let text = title(for: .normal), text.isEmpty == false else { return true }
        return false
    }
}
