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

class Label: UILabel {
    convenience init(fontSize: CGFloat, numberOfLines: Int, textColor: UIColor?) {
        self.init(frame: .zero)
        self.adjustsFontSizeToFitWidth = false
        self.textAlignment = .center
        self.textColor = textColor
        self.numberOfLines = numberOfLines
        self.font = .boldSystemFont(ofSize: fontSize)
        self.isOpaque = false
        self.backgroundColor = .clear
    }

    override var intrinsicContentSize: CGSize {
        guard isEmptyOfText else {
            return super.intrinsicContentSize
        }
        return .zero
    }

    override var text: String? {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }

    override var bounds: CGRect {
        didSet {
            isHiddenInStackView = isEmptyOfText
        }
    }

    var isEmptyOfText: Bool {
        guard let text = text, text.isEmpty == false else { return true }
        return false
    }
}
