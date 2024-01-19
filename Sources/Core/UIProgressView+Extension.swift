//
//  UIProgressView+Extension.swift
//  LPHUD
//
//  Created by liam on 2024/1/19.
//

import UIKit

public protocol ProgressViewable: AnyObject {
    var progress: Float { get set }
    var progressTintColor: UIColor? { get set }
    var trackTintColor: UIColor? { get set }
}

extension UIProgressView: ProgressViewable {
}

class iOSUIProgressView: UIProgressView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: 120.0, height: 4.0)
    }
}
