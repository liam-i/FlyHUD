//
//  LPRoundedButton.swift
//  LPProgressHUD
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit

class LPRoundedButton: UIButton {
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderWidth = 1.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = 1.0
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Fully rounded corners
        layer.cornerRadius = ceil(bounds.height / 2.0)
    }
    
    override var intrinsicContentSize: CGSize {
        
        // Only show if we have associated control events
        if allControlEvents == UIControlEvents(rawValue: 0) {
            return .zero
        }
        
        var size = super.intrinsicContentSize
        
        // Add some side padding
        size.width += 20.0
        
        return size
    }
    
    // MARK: - Color
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        super.setTitleColor(color, for: state)
        
        // Update related colors
        let highlighted = isHighlighted
        isHighlighted = highlighted
        layer.borderColor = color?.cgColor
    }
    
    override var isHighlighted: Bool {
        didSet {
            let baseColor = titleColor(for: .selected)
            backgroundColor = isHighlighted ? baseColor?.withAlphaComponent(0.1) : UIColor.clear
        }
    }
}
