//
//  LPProgressHUD.swift
//  LPProgressHUD
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit

public let LPProgressMaxOffset: CGFloat = 1000000.0

private let LPDefaultPadding: CGFloat = 4.0
private let LPDefaultLabelFontSize: CGFloat = 16.0
private let LPDefaultDetailsLabelFontSize: CGFloat = 12.0

public protocol LPProgressHUDDelegate: NSObjectProtocol {
    /// Called after the HUD was fully hidden from the screen.
    func hudWasHidden(_ hud: LPProgressHUD) -> Void
}


/// Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
///
/// NOTE: To still allow touches to pass through the HUD, you can set hud.userInteractionEnabled = NO.
/// ATTENTION: MBProgressHUD is a UI class and should therefore only be accessed on the main thread.
public class LPProgressHUD: UIView {
    
    // MARK: - Properties
    
    /// The HUD delegate object. Receives HUD state notifications.
    public weak var delegate: LPProgressHUDDelegate? = nil
    
    /// Called after the HUD is hiden.
    public var completionBlock: ((Void) -> Void)?
    
    /// The minimum time (in seconds) that the HUD is shown.
    /// This avoids the problem of the HUD being shown and than instantly hidden.
    /// Defaults to 0 (no minimum show time).
    public var graceTime: TimeInterval = 0.0
    
    /// The minimum time (in seconds) that the HUD is shown.
    /// This avoids the problem of the HUD being shown and than instantly hidden.
    /// Defaults to 0 (no minimum show time).
    public var minShowTime: TimeInterval = 0.0
    
    /// Removes the HUD from its parent view when hidden. Defaults to false.
    public var removeFromSuperViewOnHide: Bool = false
    
    
    // MARK: -
    // MARK: - Appearance
    
    /// LPProgressHUD operation mode. The default is indeterminate.
    public var mode: LPProgressHUDMode = .indeterminate {
        didSet {
            if mode != oldValue { updateIndicators() }
        }
    }
    
    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views.
    /// Defaults to semi-translucent black.
    public dynamic var contentColor: UIColor = UIColor(white: 0.0, alpha: 0.7) {
        didSet {
            if contentColor != oldValue, !contentColor.isEqual(oldValue) { updateViews(for: contentColor) }
        }
    }
    
    /// The animation type that should be used when the HUD is shown and hidden.
    public /*dynamic*/ var animationType: LPProgressHUDAnimation = .fade
    
    /// The bezel offset relative to the center of the view. You can use LPProgressMaxOffset
    /// and -LPProgressMaxOffset to move the HUD all the way to the screen edge in each direction.
    /// E.g., CGPoint(x: 0.0, y: LPProgressMaxOffset) would position the HUD centered on the bottom edge.
    public dynamic var offset: CGPoint = .zero {
        didSet {
            if !offset.equalTo(oldValue) { setNeedsUpdateConstraints() }
        }
    }
    
    /// The amount of space between the HUD edge and the HUD elements (labels, indicators or custom views).
    /// This also represents the minimum bezel distance to the edge of the HUD view.
    /// Defaults to 20.0
    public dynamic var margin: CGFloat = 20.0 {
        didSet {
            if margin != oldValue { setNeedsUpdateConstraints() }
        }
    }
    
    /// The minimum size of the HUD bezel. Defaults to CGSize.zero (no minimum size).
    public var minSize: CGSize = .zero {
        didSet {
            if !minSize.equalTo(oldValue) { setNeedsUpdateConstraints() }
        }
    }
    
    /// Force the HUD dimensions to be equal if possible.
    public dynamic var isSquare: Bool = false {
        didSet {
            if isSquare != oldValue { setNeedsUpdateConstraints() }
        }
    }
 
    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. Defaults to true.
    public dynamic var isMotionEffectsEnabled: Bool = true {
        didSet {
            if isMotionEffectsEnabled != oldValue { updateBezelMotionEffects() }
        }
    }
    
    // MARK: - 
    // MARK: - Progress
    
    /// The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0.
    public var progress: CGFloat = 0.0 {
        didSet {
            if progress != oldValue, let indicator = indicator, indicator.responds(to: #selector(setter: progress)) {
                indicator.setValue(progress, forKey: "progress")
            }
        }
    }
    
    /// The NSProgress object feeding the progress information to the progress indicator.
    public var progressObject: Progress? {
        didSet {
            if progressObject != oldValue { setNSProgressDisplayLink(enabled: true) }
        }
    }
    
    // MARK: -
    // MARK: - Views
    
    /// The view containing the labels and indicator (or customView).
    public lazy var bezelView: LPBackgroundView = LPBackgroundView(frame: .zero)
    
    /// View covering the entire HUD area, placed behind bezelView.
    public lazy var backgroundView: LPBackgroundView = LPBackgroundView(frame: self.bounds)
    
    /// The UIView (e.g., a UIImageView) to be shown when the HUD is in LPProgressHUDModeCustomView.
    /// The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
    public var customView: UIView? {
        didSet {
            if customView != oldValue, mode == .customView { updateIndicators() }
        }
    }
    
    /// A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    public lazy var label: UILabel = UILabel(frame: .zero)
    
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public lazy var detailsLabel: UILabel = UILabel(frame: .zero)
    
    /// A button that is placed below the labels. Visible only if a target / action is added.
    public lazy var button: UIButton = LPRoundedButton(frame: .zero)
    
    
    fileprivate var useAnimation: Bool = false
    fileprivate var isFinished: Bool = false
    fileprivate var indicator: UIView?
    fileprivate var showStarted: Date?
    fileprivate var paddingConstraints: [NSLayoutConstraint]?
    fileprivate var bezelConstraints: [NSLayoutConstraint]?
    fileprivate lazy var topSpacer: UIView = UIView(frame: .zero)
    fileprivate lazy var bottomSpacer: UIView = UIView(frame: .zero)
    fileprivate var graceTimer: Timer?
    fileprivate var minShowTimer: Timer?
    fileprivate var hideDelayTimer: Timer?
    fileprivate var progressObjectDisplayLink: CADisplayLink? {
        didSet {
            if progressObjectDisplayLink != oldValue {
                oldValue?.invalidate()
                progressObjectDisplayLink?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    public convenience init(with view: UIView) {
        self.init(frame: view.bounds)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        unregisterFromNotifications()
#if DEBUG
        print("LPProgressHUD -> release memory.")
#endif
    }
}

extension LPProgressHUD {
    
    // MARK: - Class methods, Show & hide
    
    public class func show(to view: UIView, animated: Bool) -> LPProgressHUD {
        let hud = LPProgressHUD(with: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }
    
    public class func hide(for view: UIView, animated: Bool) -> Bool {
        guard let hud = hud(for: view) else { return false }
        
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: animated)
        return true
    }
    
    public class func hud(for view: UIView) -> LPProgressHUD? {
        let subviewsCollection = view.subviews.reversed()
        for subView in subviewsCollection {
            if subView is LPProgressHUD, let hud = subView as? LPProgressHUD {
                if hud.isFinished == false {
                    return hud
                }
            }
        }
        return nil
    }
    
    // MARK: - Show & hide
    
    public func show(animated: Bool) {
        assert(Thread.isMainThread, "LPProgressHUD needs to be accessed on the main thread.")
        
        minShowTimer?.invalidate()
        useAnimation = animated
        isFinished = false
        
        // If the grace time is set, postpone the HUD display
        if graceTime > 0.0 {
            let timer = Timer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .commonModes)
            graceTimer = timer
            return
        }
        
        // ... otherwise show the HUD immediately
        show(usingAnimation: useAnimation)
    }
    
    public func hide(animated: Bool) {
        assert(Thread.isMainThread, "LPProgressHUD needs to be accessed on the main thread.")
        
        graceTimer?.invalidate()
        useAnimation = animated
        isFinished = true
        
        // If the minShow time is set, calculate how long the HUD was shown, and postpone the hiding operation if necessary
        if let showStarted = showStarted, minShowTime > 0.0 {
            let interv = Date().timeIntervalSince(showStarted)
            if interv < minShowTime {
                let timer = Timer(timeInterval: minShowTime - interv, target: self, selector: #selector(handleMinShowTimer), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: .commonModes)
                minShowTimer = timer
                return
            }
        }
        
        // ... otherwise hide the HUD immediately
        hide(usingAnimation: useAnimation)
    }
    
    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(handleHideTimer), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: .commonModes)
        hideDelayTimer = timer
    }
    
    // MARK: - Internal show & hide operations
    
    func show(usingAnimation animated: Bool) {
        // Cancel any previous animations
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()
        
        // Cancel any scheduled hideDelayed: calls
        hideDelayTimer?.invalidate()
        
        showStarted = Date()
        alpha = 1.0
        
        // Needed in case we hide and re-show with the same NSProgress object attached.
        setNSProgressDisplayLink(enabled: true)
        
        if animated {
            animate(in: true, type: animationType, completion: nil)
        } else {
            bezelView.alpha = 1.0 // self.opacity
            backgroundView.alpha = 1.0
        }
    }
    
    func hide(usingAnimation animated: Bool) {
        if animated && showStarted != nil {
            showStarted = nil
            animate(in: false, type: animationType, completion: { (finished) in
                self.done()
            })
        } else {
            showStarted = nil
            bezelView.alpha = 0.0
            backgroundView.alpha = 1.0
            done()
        }
    }
    
    func animate(in animating: Bool, type: LPProgressHUDAnimation, completion: ((Bool) -> Void)?) {
        var type = type
        // Automatically determine the correct zoom animation type
        if type == .zoom {
            type = animating ? .zoomIn : .zoomOut
        }
        
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        // Set starting state
        if animating && bezelView.alpha == 0.0 && type == .zoomIn {
            bezelView.transform = small
        } else if animating && bezelView.alpha == 0.0 && type == .zoomOut {
            bezelView.transform = large
        }

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: {
            if animating {
                self.bezelView.transform = CGAffineTransform.identity
            } else if !animating && type == .zoomIn {
                self.bezelView.transform = large
            } else if !animating && type == .zoomOut {
                self.bezelView.transform = small
            }
            
            self.bezelView.alpha = animating ? 1.0 : 0.0 // self.opacity
            self.backgroundView.alpha = animating ? 1.0 : 0.0
        }, completion: completion)
    }
    
    func done() {
        // Cancel any scheduled hideDelayed: calls
        hideDelayTimer?.invalidate()
        setNSProgressDisplayLink(enabled: false)
        
        if isFinished {
            alpha = 0.0
            if removeFromSuperViewOnHide {
                removeFromSuperview()
            }
        }
        
        completionBlock?()
        delegate?.hudWasHidden(self)
    }
}

// MARK: -
// MARK: - Timer callbacks

extension LPProgressHUD {
    
    func handleHideTimer(_ timer: Timer) {
        let animated = timer.userInfo as? Bool ?? true
        hide(animated: animated)
    }
    
    func handleGraceTimer(_ timer: Timer) {
        // Show the HUD only if the task is still running
        if !isFinished {
            show(usingAnimation: useAnimation)
        }
    }
    
    func handleMinShowTimer(_ timer: Timer) {
        hide(usingAnimation: useAnimation)
    }
}

// MARK: - 
// MARK: - View Hierarchy

extension LPProgressHUD {
    
    public override func didMoveToSuperview() {
        updateForCurrentOrientation(animated: false)
    }
}

// MARK: - 
// MARK: - UI

extension LPProgressHUD {

    func commonInit() {
        // Transparent background
        isOpaque = false
        backgroundColor = UIColor.clear
        // Make it invisible for now
        alpha = 0.0
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.allowsGroupOpacity = false
        
        setupViews()
        updateIndicators()
        registerForNotifications()
    }
    
    func setupViews() {
        let defaultColor = contentColor
        
        backgroundView.style = .solidColor
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.alpha = 0.0
        addSubview(backgroundView)
        
        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.layer.cornerRadius = 5.0
        bezelView.alpha = 0.0
        addSubview(bezelView)
        
        updateBezelMotionEffects()
        
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = defaultColor
        label.font = UIFont.boldSystemFont(ofSize: LPDefaultLabelFontSize)
        label.isOpaque = false
        label.backgroundColor = UIColor.clear
        
        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = defaultColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.boldSystemFont(ofSize: LPDefaultDetailsLabelFontSize)
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = UIColor.clear
        
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: LPDefaultDetailsLabelFontSize)
        button.setTitleColor(defaultColor, for: .normal)
        
        for view in [label, detailsLabel, button] as [UIView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(998.0, for: .horizontal)
            view.setContentCompressionResistancePriority(998.0, for: .vertical)
            bezelView.addSubview(view)
        }
        
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.isHidden = true
        bezelView.addSubview(topSpacer)
        
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.isHidden = true
        bezelView.addSubview(bottomSpacer)
    }
    
    func updateIndicators() {
        let isActivityIndicator = indicator is UIActivityIndicatorView
        let isRoundIndicator = indicator is LPRoundProgressView
        
        switch mode {
        case .indeterminate:
            
            if !isActivityIndicator {
                // Update to indeterminate indicator
                indicator?.removeFromSuperview()
                let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
                indicatorView.startAnimating()
                bezelView.addSubview(indicatorView)
                indicator = indicatorView
            }
        case .determinateHorizontalBar:
            
            // Update to bar determinate indicator
            indicator?.removeFromSuperview()
            let bar = LPBarProgressView()
            bezelView.addSubview(bar)
            indicator = bar
        case .determinate, .annularDeterminate:
            
            if !isRoundIndicator {
                // Update to determinante indicator
                indicator?.removeFromSuperview()
                let roundView = LPRoundProgressView()
                bezelView.addSubview(roundView)
                indicator = roundView
            }
            
            if mode == .annularDeterminate {
                (indicator as? LPRoundProgressView)?.isAnnular = true
            }
        case .customView:
            
            if let customView = customView, customView != indicator {
                // Update custom view indicator
                indicator?.removeFromSuperview()
                bezelView.addSubview(customView)
                indicator = customView
            }
        case .text:
            
            indicator?.removeFromSuperview()
            indicator = nil
        }
        
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        
        if let indicator = indicator {
            if indicator.responds(to: #selector(setter: progress)) {
                indicator.setValue(progress, forKey: "progress")
            }
            
            indicator.setContentCompressionResistancePriority(998.0, for: .horizontal)
            indicator.setContentCompressionResistancePriority(998.0, for: .vertical)
        }
        
        updateViews(for: contentColor)
        setNeedsUpdateConstraints()
    }
    
    func updateViews(for color: UIColor) {
        label.textColor = color
        detailsLabel.textColor = color
        button.setTitleColor(color, for: .normal)
        
        if indicator is UIActivityIndicatorView {
            
            (indicator as? UIActivityIndicatorView)?.color = color
        } else if indicator is LPRoundProgressView {
            
            (indicator as? LPRoundProgressView)?.progressTintColor = color
            (indicator as? LPRoundProgressView)?.backgroundTintColor = color.withAlphaComponent(0.1)
        } else if indicator is LPBarProgressView {
            
            (indicator as? LPBarProgressView)?.progressColor = color
            (indicator as? LPBarProgressView)?.lineColor = color
        } else {
            if let indicator = indicator, indicator.responds(to: #selector(setter: tintColor)) {
                indicator.tintColor = color
            }
        }
    }
    
    func updateBezelMotionEffects() {
        if !bezelView.responds(to: #selector(addMotionEffect)) {
            return
        }
        
        if isMotionEffectsEnabled {
            let effectOffset = 10.0
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            bezelView.addMotionEffect(group)
        } else {
            for effect in bezelView.motionEffects {
                bezelView.removeMotionEffect(effect)
            }
        }
    }
}

// MARK: -
// MARK: - Layout

extension LPProgressHUD {
    
    public override func updateConstraints() {
        var bezelConstraints: [NSLayoutConstraint] = []
        let metrics = ["margin": margin]
        var subviews = [topSpacer, label, detailsLabel, button, bottomSpacer]
        
        if let indicator = indicator {
            subviews.insert(indicator, at: 1)
        }
        
        // Remove existing constraints
        removeConstraints(constraints)
        topSpacer.removeConstraints(topSpacer.constraints)
        bottomSpacer.removeConstraints(bottomSpacer.constraints)
        if let bezelConstraints = self.bezelConstraints {
            bezelView.removeConstraints(bezelConstraints)
            self.bezelConstraints = nil
        }
        
        // Center bezel in container (self), applying the offset if set
        var centeringConstraints: [NSLayoutConstraint] = []
        centeringConstraints.append(NSLayoutConstraint(item: bezelView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: offset.x))
        centeringConstraints.append(NSLayoutConstraint(item: bezelView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: offset.y))
        apply(priority: 998.0, to: centeringConstraints)
        addConstraints(centeringConstraints)
        
        // Ensure minimum side margin is kept
        var sideConstraints: [NSLayoutConstraint] = []
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezelView]-(>=margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: ["bezelView": bezelView]))
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezelView]-(>=margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: ["bezelView": bezelView]))
        apply(priority: 999.0, to: sideConstraints)
        addConstraints(sideConstraints)
        
        // Minimum bezel size, if set
        if !minSize.equalTo(.zero) {
            var minSizeConstraints: [NSLayoutConstraint] = []
            minSizeConstraints.append(NSLayoutConstraint(item: bezelView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minSize.width))
            minSizeConstraints.append(NSLayoutConstraint(item: bezelView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: minSize.height))
            apply(priority: 997.0, to: minSizeConstraints)
            bezelConstraints.append(contentsOf: minSizeConstraints)
        }
        
        // Square aspect ratio, if set
        if isSquare {
            let square = NSLayoutConstraint(item: bezelView, attribute: .height, relatedBy: .equal, toItem: bezelView, attribute: .width, multiplier: 1.0, constant: 0.0)
            square.priority = 997.0
            bezelConstraints.append(square)
        }
        
        // Top and bottom spacing
        topSpacer.addConstraint(NSLayoutConstraint(item: topSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: margin))
        bottomSpacer.addConstraint(NSLayoutConstraint(item: bottomSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: margin))
        
        // Top and bottom spaces should be equal
        bezelConstraints.append(NSLayoutConstraint(item: topSpacer, attribute: .height, relatedBy: .equal, toItem: bottomSpacer, attribute: .height, multiplier: 1.0, constant: 0.0))
        
        // Layout subviews in bezel
        var paddingConstraints: [NSLayoutConstraint] = []
        for (idx, view) in subviews.enumerated() {
            
            // Center in bezel
            bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: bezelView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            
            // Ensure the minimum edge margin is kept
            bezelConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: ["view": view]))
            
            // Element spacing
            if idx == 0 {
                
                // First, ensure spacing to bezel edge
                bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: bezelView, attribute: .top, multiplier: 1.0, constant: 0.0))
            } else if idx == subviews.count - 1 {
                
                // Last, ensure spacing to bezel edge
                bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: bezelView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
            }
            
            if idx > 0 {
                // Has previous
                let padding = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: subviews[idx - 1], attribute: .bottom, multiplier: 1.0, constant: 0.0)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }
        
        bezelView.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        self.paddingConstraints = paddingConstraints
        
        super.updateConstraints()
    }
    
    public override func layoutSubviews() {
        // There is no need to update constraints if they are going to
        // be recreated in [super layoutSubviews] due to needsUpdateConstraints being set.
        // This also avoids an issue on iOS 8, where updatePaddingConstraints
        // would trigger a zombie object access.
        if !needsUpdateConstraints() {
            updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    func updatePaddingConstraints() {
        // Set padding dynamically, depending on whether the view is visible or not
        guard let paddingConstraints = paddingConstraints else { return }
        
        var hasVisibleAncestors = false
        for padding in paddingConstraints {
            guard let firstView = padding.firstItem as? UIView else { return }
            guard let secondView = padding.secondItem as? UIView else { return }
            
            let firstVisible = !firstView.isHidden && !firstView.intrinsicContentSize.equalTo(.zero)
            let secondVisible = !secondView.isHidden && !secondView.intrinsicContentSize.equalTo(.zero)
            
            // Set if both views are visible or if there's a visible view on top that doesn't have padding
            // added relative to the current view yet
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? LPDefaultPadding : 0.0
            
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }
    
    func apply(priority: UILayoutPriority, to constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.priority = priority
        }
    }
}

// MARK: - 
// MARK: - NSProgress

extension LPProgressHUD {
    
    func setNSProgressDisplayLink(enabled: Bool) {
        // We're using CADisplayLink, because NSProgress can change very quickly and observing it may starve the main thread,
        // so we're refreshing the progress only every frame draw
        if enabled && progressObject != nil {
            // Only create if not already active.
            if progressObjectDisplayLink == nil {
                progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        } else {
            progressObjectDisplayLink = nil
        }
    }
    
    func updateProgressFromProgressObject() {
        if let progressObject = progressObject {
            progress = CGFloat(progressObject.fractionCompleted)
        }
    }
}

// MARK: -
// MARK: - Notifications

extension LPProgressHUD {
    
    func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationDidChange),
                                               name: Notification.Name.UIApplicationDidChangeStatusBarOrientation,
                                               object: nil)
    }
    
    func unregisterFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func statusBarOrientationDidChange(_ notification: Notification) {
        if let _ = superview {
            updateForCurrentOrientation(animated: true)
        }
    }
    
    func updateForCurrentOrientation(animated: Bool) {
        // Stay in sync with the superview in any case
        if let superview = superview {
            frame = superview.bounds
        }
    }
}
