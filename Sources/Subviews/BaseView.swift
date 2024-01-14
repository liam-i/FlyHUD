//
//  BaseView.swift
//  LPHUD
//
//  Created by 李鹏 on 2024/1/14.
//

import UIKit

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
