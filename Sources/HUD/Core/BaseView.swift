//
//  BaseView.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2024/1/14.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// A base view only provides one `commonInit` method.
open class BaseView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Common initialization method, allowing overriding
    open func commonInit() {
    }
}
