//
//  RoundedButton.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

public class RoundedButton: UIButton {
    /// The rounded corner mode of the button. `Default to .fully`.
    public var roundedCorners: BackgroundView.RoundedCorners = .fully {
        didSet {
            roundedCorners.notEqual(oldValue, do: setNeedsLayout())
        }
    }
    /// Button border width. `Default to 1`.
    public var borderWidth: CGFloat = 1.0 {
        didSet {
            borderWidth.notEqual(oldValue, do: layer.borderWidth = borderWidth)
        }
    }

    // MARK: - Lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderWidth = borderWidth
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = borderWidth
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        switch roundedCorners {
        case .radius(let value):
            layer.cornerRadius = ceil(value)
        case .fully:
            layer.cornerRadius = ceil(bounds.height / 2.0) // Fully rounded corners
        }
    }

    public override var intrinsicContentSize: CGSize {
        // Only show if we have associated control events and a title
        if let title = title(for: .normal), !title.isEmpty, allControlEvents.rawValue > 0 {
            var size = super.intrinsicContentSize
            size.width += 20.0 // Add some side padding
            return size
        }
        return .zero
    }

    // MARK: - Color

    public override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors
        let highlighted = isHighlighted
        isHighlighted = highlighted
        layer.borderColor = color?.cgColor
    }

    public override var isHighlighted: Bool {
        didSet {
            let baseColor = titleColor(for: .selected)
            backgroundColor = isHighlighted ? baseColor?.withAlphaComponent(0.1) : .clear
        }
    }
}
