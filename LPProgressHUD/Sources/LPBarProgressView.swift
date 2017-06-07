//
//  LPBarProgressView.swift
//  LPProgressHUD
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit

/// A flat bar progress view.
public class LPBarProgressView: UIView {
    
    // MARK: - Properties
    
    /// Progress (0.0 to 1.0)
    public var progress: CGFloat = 0.0 {
        didSet {
            if progress != oldValue { setNeedsDisplay() }
        }
    }
    
    /// Bar border line color. Defaults to white UIColor.white.
    public var lineColor: UIColor = UIColor.white
    
    /// Bar background color. Defaults to clear UIColor.clear.
    public var progressRemainingColor: UIColor = UIColor.clear {
        didSet {
            if progressRemainingColor != oldValue, !progressRemainingColor.isEqual(oldValue) { setNeedsDisplay() }
        }
    }
    
    /// Bar progress color. Defaults to white UIColor.white.
    public var progressColor: UIColor = UIColor.white {
        didSet {
            if progressColor != oldValue, !progressColor.isEqual(oldValue) { setNeedsDisplay() }
        }
    }
    
    // MARK: - Lifecycle
    
    public convenience init() {
        self.init(frame: CGRect(x: 0.0, y: 0.0, width: 120.0, height: 20.0))
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
        return CGSize(width: 120, height: 10.0)
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(2.0)
        context.setStrokeColor(lineColor.cgColor)
        context.setFillColor(progressRemainingColor.cgColor)
        
        // Draw background
        var radius = (rect.height / 2.0) - 2.0
        context.move(to: CGPoint(x: 2.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 2.0, y: 2.0),
                       tangent2End: CGPoint(x: radius + 2.0, y: 2.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: rect.width - radius - 2.0, y: 2.0))
        
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: 2.0),
                       tangent2End: CGPoint(x: rect.width - 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: rect.width - radius - 2.0, y: rect.height - 2.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: radius + 2.0, y: rect.height - 2.0))
        context.addArc(tangent1End: CGPoint(x: 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.fillPath()
        
        // Draw border
        context.move(to: CGPoint(x: 2.0, y: rect.height / 2.0))
        context.addArc(tangent1End: CGPoint(x: 2.0, y: 2.0),
                       tangent2End: CGPoint(x: radius + 2.0, y: 2.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: rect.width - radius - 2.0, y: 2.0))
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: 2.0),
                       tangent2End: CGPoint(x: rect.width - 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: rect.width - radius - 2.0, y: rect.height - 2.0),
                       radius: radius)
        context.addLine(to: CGPoint(x: radius + 2.0, y: rect.height - 2.0))
        context.addArc(tangent1End: CGPoint(x: 2.0, y: rect.height - 2.0),
                       tangent2End: CGPoint(x: 2.0, y: rect.height / 2.0),
                       radius: radius)
        context.strokePath()
        
        context.setFillColor(progressColor.cgColor)
        
        radius -= 2
        let amount = progress * rect.width
        
        // Progress in the middle area
        if amount >= radius + 4 && amount <= (rect.size.width - radius - 4) {
            
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                           tangent2End: CGPoint(x: radius + 4, y: 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: amount, y: 4.0))
            context.addLine(to: CGPoint(x: amount, y: radius + 4.0))
            
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                           tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: amount, y: rect.height - 4.0))
            context.addLine(to: CGPoint(x: amount, y: radius + 4.0))
            
            context.fillPath()
        }
        
        // Progress in the right arc
        else if amount > radius + 4 {
            
            let x = amount - (rect.width - radius - 4.0)
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                           tangent2End: CGPoint(x: 4.0, y: radius + 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: rect.width - radius - 4.0, y: 4.0))
            
            var angle = -acos(x / radius)
            if angle.isNaN {
                angle = 0.0
            }
            context.addArc(center: CGPoint(x: rect.width - radius - 4.0, y: rect.height / 2.0),
                           radius: radius,
                           startAngle: CGFloat.pi,
                           endAngle: angle,
                           clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: rect.height / 2.0))
            
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                           tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: rect.width - radius - 4.0, y: rect.height - 4.0))
            
            angle = acos(x / radius)
            if angle.isNaN {
                angle = 0.0
            }
            context.addArc(center: CGPoint(x: rect.width - radius - 4.0, y: rect.height / 2.0),
                           radius: radius,
                           startAngle: -CGFloat.pi,
                           endAngle: angle,
                           clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: rect.height / 2.0))
            
            context.fillPath()
        }
        
        // Progress is in the left arc
        else if amount < radius + 4 && amount > 0 {
            
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: 4.0),
                           tangent2End: CGPoint(x: radius + 4, y: 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: radius + 4.0, y: rect.height / 2.0))
            
            context.move(to: CGPoint(x: 4.0, y: rect.height / 2.0))
            context.addArc(tangent1End: CGPoint(x: 4.0, y: rect.height - 4.0),
                           tangent2End: CGPoint(x: radius + 4.0, y: rect.height - 4.0),
                           radius: radius)
            context.addLine(to: CGPoint(x: radius + 4.0, y: rect.height / 2.0))
            
            context.fillPath()
        }
    }
}
