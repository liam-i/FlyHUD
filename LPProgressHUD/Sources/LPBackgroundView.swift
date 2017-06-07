//
//  LPBackgroundView.swift
//  LPProgressHUD
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit

public class LPBackgroundView: UIView {
    
    // MARK: - Properties
    
    /// The background style. Defaults to LPProgressHUDBackgroundStyle.blur
    public var style: LPProgressHUDBackgroundStyle = .blur {
        didSet {
            if style != oldValue { updateForBackgroundStyle() }
        }
    }
    
    /// The background color or the blur tint color.
    public var color: UIColor = UIColor(white: 0.8, alpha: 0.6) {
        didSet {
            if color != oldValue, !color.isEqual(oldValue) { backgroundColor = color }
        }
    }
    
    var effectView: UIVisualEffectView?
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        
        updateForBackgroundStyle()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clipsToBounds = true
        
        updateForBackgroundStyle()
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        // Smallest size possible. Content pushes against this.
        return .zero
    }
}

extension LPBackgroundView {
    
    // MARK: - Views
    
    fileprivate func updateForBackgroundStyle() {
        if style == .blur {
            
            let effect = UIBlurEffect(style: .light)
            let effectview = UIVisualEffectView(effect: effect)
            addSubview(effectview)
            effectview.frame = bounds
            effectview.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
            effectView = effectview
        } else {
            
            effectView?.removeFromSuperview()
            effectView = nil
            backgroundColor = color
        }
    }
    
}
