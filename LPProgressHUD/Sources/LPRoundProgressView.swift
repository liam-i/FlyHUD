//
//  LPRoundProgressView.swift
//  LPProgressHUD
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit

/// A progress view for showing definite progress by filling up a circle (pie chart).
public class LPRoundProgressView: UIView {
    
    // MARK: - Properties
    
    /// Display mode - false = round or true = annular. Defaults to round.
    public var isAnnular: Bool = false
    
    /// Progress (0.0 to 1.0)
    public var progress: CGFloat = 0.0 {
        didSet {
            if progress != oldValue { setNeedsDisplay() }
        }
    }
    
    /// Indicator progress color. Defaults to white UIColor.white.
    public var progressTintColor: UIColor = UIColor(white: 1.0, alpha: 1.0) {
        didSet {
            if progressTintColor != oldValue, !progressTintColor.isEqual(oldValue) { setNeedsDisplay() }
        }
    }
    
    /// Indicator background (non-progress) color. Defaults to translucent white (alpha 0.1).
    public var backgroundTintColor: UIColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            if backgroundTintColor != oldValue, !backgroundTintColor.isEqual(oldValue) { setNeedsDisplay() }
        }
    }
    
    // MARK: - Lifecycle
    
    public convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 37.0, height: 37.0))
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 37.0, height: 37.0)
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isAnnular {
            // Draw background
            let lineWidth: CGFloat = 2.0
            let processBackgroundPath = UIBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = (bounds.width - lineWidth) / 2.0
            let startAngle = -(CGFloat.pi / 2.0) // 90 degrees
            var endAngle = (2 * CGFloat.pi) + startAngle
            
            processBackgroundPath.addArc(withCenter: center,
                                         radius: radius,
                                         startAngle: startAngle,
                                         endAngle: endAngle,
                                         clockwise: true)
            backgroundTintColor.set()
            processBackgroundPath.stroke()
            
            // Draw progress
            let processPath = UIBezierPath()
            processPath.lineWidth = lineWidth
            processPath.lineCapStyle = .square
            
            endAngle = (progress * 2 * CGFloat.pi) + startAngle
            
            processPath.addArc(withCenter: center,
                               radius: radius,
                               startAngle: startAngle,
                               endAngle: endAngle,
                               clockwise: true)
            progressTintColor.set()
            processPath.stroke()
            
        } else {
            
            // Draw background
            let lineWidth: CGFloat = 2.0
            let allRect = bounds
            let circleRect = allRect.insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            
            progressTintColor.setStroke()
            backgroundTintColor.setFill()
            
            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: circleRect)
            
            let startAngle = -(CGFloat.pi / 2.0) // 90 degrees
            
            // Draw progress
            let processPath = UIBezierPath()
            processPath.lineWidth = lineWidth * 2.0
            processPath.lineCapStyle = .butt
            
            let radius = (bounds.width / 2.0) - (processPath.lineWidth / 2.0)
            let endAngle = (progress * 2.0 * CGFloat.pi) + startAngle
            
            processPath.addArc(withCenter: center,
                               radius: radius,
                               startAngle: startAngle,
                               endAngle: endAngle,
                               clockwise: true)
            
            // Ensure that we don't get color overlaping when progressTintColor alpha < 1.0.
            context.setBlendMode(.copy)
            progressTintColor.set()
            processPath.stroke()
        }
    }
    
}
