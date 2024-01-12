//
//  HUD.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2017/6/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

public protocol HUDDelegate: AnyObject {
    /// Called after the HUD was fully hidden from the screen.
    func hudWasHidden(_ hud: HUD)
}

/// Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
///
/// - NOTE: To still allow touches to pass through the HUD, you can set hud.userInteractionEnabled = NO.
/// - ATTENTION: HUD is a UI class and should therefore only be accessed on the main thread.
open class HUD: UIView {
    // MARK: - Properties

    /// The HUD delegate object. Receives HUD state notifications.
    public weak var delegate: HUDDelegate?

    /// Called after the HUD is hidden.
    public var completionBlock: ((_ hud: HUD) -> Void)?

    /// The minimum time (in seconds) that the HUD is shown. This avoids the problem of the HUD being shown and than instantly hidden.
    /// Defaults to 0 (no minimum show time).
    /// - Note: The graceTime needs to be set before the hud is shown. You thus can't use `show(to:animated:)`,
    ///         but instead need to alloc / init the HUD, configure the grace time and than show it manually.
    public var graceTime: TimeInterval = 0.0

    /// The minimum time (in seconds) that the HUD is shown. This avoids the problem of the HUD being shown and than instantly hidden.
    /// Defaults to 0 (no minimum show time).
    public var minShowTime: TimeInterval = 0.0

    /// Removes the HUD from its parent view when hidden. Defaults to true.
    public var removeFromSuperViewOnHide: Bool = true

    /// Handle show `HUD` multiple times in the same `View`.
    public private(set) var count: Int = 0
    /// Enable `count`. Defaults to false.
    public static var isCountEnabled: Bool = false

    // MARK: - Appearance

    /// HUD operation mode. The default is indeterminate.
    public var mode: HUDMode = .indeterminate {
        didSet {
            guard mode != oldValue else { return }
            updateIndicators()
        }
    }

    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views.
    /// Defaults to semi-translucent black.
    public var contentColor: UIColor = {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return UIColor.label.withAlphaComponent(0.7)
        } else {
            return UIColor(white: 0.0, alpha: 0.7)
        }
    }() {
        didSet {
            guard contentColor != oldValue, !contentColor.isEqual(oldValue) else { return }
            updateViews(for: contentColor)
        }
    }

    /// The animation type that should be used when the HUD is shown and hidden.
    public var animationType: HUDAnimation = .fade

    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layoutConfig: HUDLayoutConfiguration = .init() {
        didSet {
            guard layoutConfig != oldValue else { return }
            setNeedsUpdateConstraints()
        }
    }

    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. Defaults to false.
    public var isMotionEffectsEnabled: Bool = false {
        didSet {
            guard isMotionEffectsEnabled != oldValue else { return }
            updateBezelMotionEffects()
        }
    }

    // MARK: - Progress

    /// The progress of the progress indicator, from 0.0 to 1.0. Defaults to 0.0.
    public var progress: CGFloat = 0.0 {
        didSet {
            guard progress != oldValue, let indicator = indicator as? Progressive else { return }
            indicator.progress = progress
        }
    }

    /// The NSProgress object feeding the progress information to the progress indicator.
    public var progressObject: Progress? {
        didSet {
            guard progressObject != oldValue else { return }
            setNSProgressDisplayLink(enabled: true)
        }
    }

    // MARK: - Views

    /// The view containing the labels and indicator (or customView).
    public lazy var bezelView = BackgroundView(frame: .zero)

    /// View covering the entire HUD area, placed behind bezelView.
    public lazy var backgroundView = BackgroundView(frame: bounds)

    /// The UIView (e.g., a UIImageView) to be shown when the HUD is in HUDModeCustomView.
    /// The view should implement intrinsicContentSize for proper sizing. For best results use approximately 37 by 37 pixels.
    public var customView: UIView? {
        didSet {
            guard customView != oldValue, mode == .customView else { return }
            updateIndicators()
        }
    }

    /// A label that holds an optional short message to be displayed below the activity indicator.
    /// The HUD is automatically resized to fit the entire text.
    public lazy var label = UILabel(frame: .zero)

    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public lazy var detailsLabel = UILabel(frame: .zero)

    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public lazy var button = RoundedButton(frame: .zero)

    private static let defaultLabelFontSize: CGFloat = 16.0
    private static let defaultDetailsLabelFontSize: CGFloat = 12.0

    private var useAnimation: Bool = false
    private var isFinished: Bool = false
    private var indicator: UIView?
    private var showStarted: Date?
    private var paddingConstraints: [NSLayoutConstraint]?
    private var bezelConstraints: [NSLayoutConstraint]?
    private var graceTimer: Timer?
    private var minShowTimer: Timer?
    private var hideDelayTimer: Timer?
    private var bezelMotionEffects: UIMotionEffectGroup?
    private var progressObjectDisplayLink: CADisplayLink? {
        didSet {
            guard progressObjectDisplayLink != oldValue else { return }
            oldValue?.invalidate()
            progressObjectDisplayLink?.add(to: .main, forMode: .default)
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

    /// Common initialization method, allowing overriding
    open func commonInit() {
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

    deinit {
        unregisterFromNotifications()
        #if DEBUG
        print("👍👍👍 HUD is released.")
        #endif
    }

    // MARK: - Show & hide

    /// Creates a new HUD, adds it to provided view and shows it. The counterpart to this method is `hide(for:animated:)`.
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - animated: If set to true the HUD will appear using the current animationType. If set to false the HUD will not use animations while appearing. `Default to true.`
    /// - Returns: A reference to the created HUD.
    /// - Note: This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
    /// - SeeAlso: animationType.
    @discardableResult
    public class func show(to view: UIView, animated: Bool = true) -> HUD {
        if HUD.isCountEnabled, let hud = hud(for: view) {
            hud.count += 1
            return hud
        }

        let hud = HUD(with: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }

    /// Finds the top-most HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:animated:)`.
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animated: If set to true the HUD will disappear using the current animationType. If set to false the HUD will not use animations while disappearing. `Default to true.`
    /// - Returns: true if a HUD was found and removed, false otherwise.
    /// - Note: This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
    /// - SeeAlso: animationType.
    @discardableResult
    public class func hide(for view: UIView, animated: Bool = true) -> Bool {
        guard let hud = hud(for: view) else { return false }
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: animated)
        return true
    }

    /// Finds the top-most HUD subview that hasn't finished and returns it.
    /// - Parameter view: The view that is going to be searched.
    /// - Returns: A reference to the last HUD subview discovered.
    public class func hud(for view: UIView) -> HUD? {
        for case let hud as HUD in view.subviews.reversed() where hud.isFinished == false {
            return hud
        }
        return nil
    }

    /// Displays the HUD.
    /// - Parameter animated: If set to true the HUD will appear using the current animationType. If set to false the HUD will not use animations while appearing. `Default to true.`
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated. Call this method when your task is already set up to be executed in a new thread (e.g., when using something like NSOperation or making an asynchronous call like NSURLRequest).
    /// - SeeAlso: animationType.
    public func show(animated: Bool = true) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")

        if HUD.isCountEnabled {
            count += 1
        }

        minShowTimer?.invalidate()
        useAnimation = animated
        isFinished = false

        // fix #605: https://github.com/jdg/MBProgressHUD/issues/605
        // Modified grace time to 0 and show again
        graceTimer?.invalidate()
        // Cancel any scheduled hide(animated:afterDelay:) calls
        hideDelayTimer?.invalidate()

        // If the grace time is set, postpone the HUD display
        if graceTime > 0.0 {
            let timer = Timer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .common)
            graceTimer = timer
            return
        }

        // ... otherwise show the HUD immediately
        show(usingAnimation: useAnimation)
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    /// - Parameter animated: If set to true the HUD will disappear using the current animationType. If set to false the HUD will not use animations while disappearing. `Default to true.`
    /// - SeeAlso: animationType.
    public func hide(animated: Bool = true) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")

        if HUD.isCountEnabled {
            count -= 1
            if count > 0 {
                return
            }
        }

        graceTimer?.invalidate()
        useAnimation = animated
        isFinished = true

        // If the minShow time is set, calculate how long the HUD was shown, and postpone the hiding operation if necessary
        if let showStarted = showStarted, minShowTime > 0.0 {
            let interv = Date().timeIntervalSince(showStarted)
            if interv < minShowTime {
                let timer = Timer(timeInterval: minShowTime - interv, target: self,
                                  selector: #selector(handleMinShowTimer), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: .common)
                minShowTimer = timer
                return
            }
        }

        // ... otherwise hide the HUD immediately
        hide(usingAnimation: useAnimation)
    }

    /// Hides the HUD after a delay. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    /// - Parameters:
    ///   - animated: If set to true the HUD will disappear using the current animationType. If set to false the HUD will not use animations while disappearing. `Default to true.`
    ///   - delay: Delay in seconds until the HUD is hidden.
    /// - SeeAlso: animationType.
    public func hide(animated: Bool = true, afterDelay delay: TimeInterval) {
        // Cancel any scheduled hideAnimated:afterDelay: calls
        hideDelayTimer?.invalidate()

        let timer = Timer(timeInterval: delay, target: self, selector: #selector(handleHideTimer), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: .common)
        hideDelayTimer = timer
    }

    // MARK: - Internal show & hide operations

    private func show(usingAnimation animated: Bool) {
        // Cancel any previous animations
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()

        // fix #605: https://github.com/jdg/MBProgressHUD/issues/605
//        // Cancel any scheduled hide(animated:afterDelay:) calls
//        hideDelayTimer?.invalidate()

        showStarted = Date()
        alpha = 1.0

        // Needed in case we hide and re-show with the same NSProgress object attached.
        setNSProgressDisplayLink(enabled: true)

        // Set up motion effects only at this point to avoid needlessly creating the effect if it was disabled after initialization.
        updateBezelMotionEffects()

        if animated {
            animate(in: true, type: animationType, completion: nil)
        } else {
            bezelView.transform = .identity
            bezelView.alpha = 1.0
            backgroundView.alpha = 1.0
        }
    }

    private func hide(usingAnimation animated: Bool) {
        // Cancel any scheduled hide(animated:afterDelay:) calls.
        // This needs to happen here instead of in done, to avoid races if another hide(animated:afterDelay:)
        // call comes in while the HUD is animating out.
        hideDelayTimer?.invalidate()

        if animated && showStarted != nil {
            showStarted = nil
            animate(in: false, type: animationType, completion: { _ in
                self.done()
            })
        } else {
            showStarted = nil
            bezelView.alpha = 0.0
            backgroundView.alpha = 0.0
            done()
        }
    }

    private func animate(in animating: Bool, type: HUDAnimation, completion: ((Bool) -> Void)?) {
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

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: {
            if animating {
                self.bezelView.transform = CGAffineTransform.identity
            } else if !animating && type == .zoomIn {
                self.bezelView.transform = large
            } else if !animating && type == .zoomOut {
                self.bezelView.transform = small
            }

            let alpha: CGFloat = animating ? 1.0 : 0.0
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
        }, completion: completion)
    }

    private func done() {
        // Cancel any scheduled hideDelayed: calls
        hideDelayTimer?.invalidate()
        setNSProgressDisplayLink(enabled: false)

        if isFinished {
            alpha = 0.0
            if removeFromSuperViewOnHide {
                removeFromSuperview()
            }
        }

        completionBlock?(self)
        delegate?.hudWasHidden(self)
    }

    // MARK: - Timer callbacks

    @objc
    private func handleHideTimer(_ timer: Timer) {
        let animated = timer.userInfo as? Bool ?? true
        hide(animated: animated)
    }

    @objc
    private func handleGraceTimer(_ timer: Timer) {
        // Show the HUD only if the task is still running
        if !isFinished {
            show(usingAnimation: useAnimation)
        }
    }

    @objc
    private func handleMinShowTimer(_ timer: Timer) {
        hide(usingAnimation: useAnimation)
    }

    // MARK: - View Hierarchy

    open override func didMoveToSuperview() {
        updateForCurrentOrientation(animated: false)
    }

    // MARK: - UI

    private func setupViews() {
        let defaultColor = contentColor

        backgroundView.style = .solidColor
        backgroundView.backgroundColor = UIColor.clear
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.alpha = 0.0
        addSubview(backgroundView)

        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.alpha = 0.0
        addSubview(bezelView)

        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = defaultColor
        label.font = UIFont.boldSystemFont(ofSize: HUD.defaultLabelFontSize)
        label.isOpaque = false
        label.backgroundColor = UIColor.clear

        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = defaultColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.boldSystemFont(ofSize: HUD.defaultDetailsLabelFontSize)
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = UIColor.clear

        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: HUD.defaultDetailsLabelFontSize)
        button.setTitleColor(defaultColor, for: .normal)

        for view in [label, detailsLabel, button] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .horizontal)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .vertical)
            bezelView.addSubview(view)
        }
    }

    // swiftlint:disable function_body_length
    private func updateIndicators() {
        switch mode {
        case .indeterminate:
            if !(indicator is UIActivityIndicatorView) {
                indicator?.removeFromSuperview()
                let indicatorView: UIActivityIndicatorView // Update to indeterminate indicator
                if #available(iOS 13.0, tvOS 13.0, *) {
                    indicatorView = UIActivityIndicatorView(style: .large)
                    indicatorView.color = UIColor.white
                } else {
                    indicatorView = UIActivityIndicatorView(style: .whiteLarge)
                }
                indicatorView.startAnimating()
                bezelView.addSubview(indicatorView)
                indicator = indicatorView
            }
        case .determinateHorizontalBar:
            // Update to bar determinate indicator
            indicator?.removeFromSuperview()
            let bar = BarProgressView()
            bezelView.addSubview(bar)
            indicator = bar
        case .determinate, .annularDeterminate:
            if !(indicator is RoundProgressView) {
                // Update to determinante indicator
                indicator?.removeFromSuperview()
                let roundView = RoundProgressView()
                bezelView.addSubview(roundView)
                indicator = roundView
            }

            if mode == .annularDeterminate {
                (indicator as? RoundProgressView)?.isAnnular = true
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

        if let indicator = indicator {
            let priority = UILayoutPriority(rawValue: 998.0)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.setContentCompressionResistancePriority(priority, for: .horizontal)
            indicator.setContentCompressionResistancePriority(priority, for: .vertical)

            if let indicator = indicator as? Progressive {
                indicator.progress = progress
            }
        }

        updateViews(for: contentColor)
        setNeedsUpdateConstraints()
    }
    // swiftlint:enable function_body_length

    private func updateViews(for color: UIColor) {
        label.textColor = color
        detailsLabel.textColor = color
        button.setTitleColor(color, for: .normal)

        // UIAppearance settings are prioritized. If they are preset the set color is ignored.
        guard let indicator = indicator else { return }
        if let indicator = indicator as? UIActivityIndicatorView {
            indicator.color = color
        } else if let indicator = indicator as? RoundProgressView {
            indicator.progressTintColor = color
            indicator.trackTintColor = color.withAlphaComponent(0.1)
        } else if let indicator = indicator as? BarProgressView {
            indicator.progressTintColor = color
            indicator.lineColor = color
        } else {
            indicator.tintColor = color
        }
    }

    private func updateBezelMotionEffects() {
        if isMotionEffectsEnabled && bezelMotionEffects == nil {
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

            bezelMotionEffects = group
        } else if let motionEffects = bezelMotionEffects {
            bezelMotionEffects = nil
            bezelView.removeMotionEffect(motionEffects)
        }
    }

    // MARK: - Layout

    // swiftlint:disable function_body_length
    open override func updateConstraints() {
        var bezelConstraints: [NSLayoutConstraint] = []
        var subviews = [label, detailsLabel, button]

        if let indicator = indicator {
            subviews.insert(indicator, at: 0)
        }

        // Remove existing constraints
        removeConstraints(constraints)
        if let bezelConstraints = self.bezelConstraints {
            bezelView.removeConstraints(bezelConstraints)
            self.bezelConstraints = nil
        }

        // Center bezel in container (self), applying the offset if set
        let centeringConstraints: [NSLayoutConstraint] = [
            bezelView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: layoutConfig.offset.x),
            bezelView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: layoutConfig.offset.y)
        ]
        apply(priority: UILayoutPriority(rawValue: 998.0), to: centeringConstraints)
        addConstraints(centeringConstraints)

        // Ensure minimum side margin is kept
        let sideConstraints: [NSLayoutConstraint] = [
            bezelView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: layoutConfig.edgeInsets.left),
            bezelView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -layoutConfig.edgeInsets.right),
            bezelView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: layoutConfig.edgeInsets.top),
            bezelView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -layoutConfig.edgeInsets.bottom),
        ]
        apply(priority: UILayoutPriority(rawValue: 999.0), to: sideConstraints)
        addConstraints(sideConstraints)

        // Minimum bezel size, if set
        if !layoutConfig.minSize.equalTo(.zero) {
            let minSizeConstraints: [NSLayoutConstraint] = [
                bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: layoutConfig.minSize.width),
                bezelView.heightAnchor.constraint(greaterThanOrEqualToConstant: layoutConfig.minSize.height)
            ]
            apply(priority: UILayoutPriority(rawValue: 997.0), to: minSizeConstraints)
            bezelConstraints.append(contentsOf: minSizeConstraints)
        }

        // Square aspect ratio, if set
        if layoutConfig.isSquare {
            let square = bezelView.heightAnchor.constraint(equalTo: bezelView.widthAnchor)
            square.priority = UILayoutPriority(rawValue: 997.0)
            bezelConstraints.append(square)
        }

        // Layout subviews in bezel
        var paddingConstraints: [NSLayoutConstraint] = []
        let lastSubviewIDX = subviews.count - 1
        for (idx, view) in subviews.enumerated() {
            // Center in bezel
            bezelConstraints.append(view.centerXAnchor.constraint(equalTo: bezelView.centerXAnchor))

            // Ensure the minimum edge margin is kept
            bezelConstraints.append(contentsOf: [
                view.leadingAnchor.constraint(greaterThanOrEqualTo: bezelView.leadingAnchor, constant: layoutConfig.hMargin),
                view.trailingAnchor.constraint(lessThanOrEqualTo: bezelView.trailingAnchor, constant: -layoutConfig.hMargin)
            ])

            // Element spacing
            if idx == 0 {
                // First, ensure spacing to bezel edge
                bezelConstraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: bezelView.topAnchor, constant: layoutConfig.vMargin))
            } else if idx == lastSubviewIDX {
                // Last, ensure spacing to bezel edge
                bezelConstraints.append(view.bottomAnchor.constraint(lessThanOrEqualTo: bezelView.bottomAnchor, constant: -layoutConfig.vMargin))
            }

            if idx > 0 {
                // Has previous
                let padding = view.topAnchor.constraint(equalTo: subviews[idx - 1].bottomAnchor)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }

        bezelView.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        self.paddingConstraints = paddingConstraints
        self.updatePaddingConstraints()

        super.updateConstraints()
    }
    // swiftlint:enable function_body_length

    open override func layoutSubviews() {
        // There is no need to update constraints if they are going to
        // be recreated in [super layoutSubviews] due to needsUpdateConstraints being set.
        // This also avoids an issue on iOS 8, where updatePaddingConstraints
        // would trigger a zombie object access.
        if !needsUpdateConstraints() {
            updatePaddingConstraints()
        }
        super.layoutSubviews()
    }

    private func updatePaddingConstraints() {
        // Set padding dynamically, depending on whether the view is visible or not
        guard let paddingConstraints = paddingConstraints else { return }

        var hasVisibleAncestors = false
        for paddingConstraint in paddingConstraints {
            var firstVisible = false
            var secondVisible = false
            if let firstView = paddingConstraint.firstItem as? UIView {
                firstVisible = !firstView.isHidden && !firstView.intrinsicContentSize.equalTo(.zero)
            }
            if let secondView = paddingConstraint.secondItem as? UIView {
                secondVisible = !secondView.isHidden && !secondView.intrinsicContentSize.equalTo(.zero)
            }

            // Set if both views are visible or if there's a visible view on top that doesn't have padding added relative to the current view yet
            paddingConstraint.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? layoutConfig.padding : 0.0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }

    private func apply(priority: UILayoutPriority, to constraints: [NSLayoutConstraint]) {
        constraints.forEach { $0.priority = priority }
    }

    // MARK: - NSProgress

    private func setNSProgressDisplayLink(enabled: Bool) {
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

    @objc
    private func updateProgressFromProgressObject() {
        guard let progressObject = progressObject else { return }
        progress = CGFloat(progressObject.fractionCompleted)
        // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
        // They can be customized or use the default text. To suppress one (or both) of the labels, set the descriptions to empty strings.
        label.text = progressObject.localizedDescription
        detailsLabel.text = progressObject.localizedAdditionalDescription
    }

    // MARK: - Notifications

    private func registerForNotifications() {
#if !os(tvOS)
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
#endif
    }

    private func unregisterFromNotifications() {
#if !os(tvOS)
        NotificationCenter.default.removeObserver(self)
#endif
    }

#if !os(tvOS)
    @objc
    private func statusBarOrientationDidChange(_ notification: Notification) {
        guard superview != nil else { return }
        updateForCurrentOrientation(animated: true)
    }
#endif

    private func updateForCurrentOrientation(animated: Bool) {
        guard let superview = superview else { return }
        frame = superview.bounds // Stay in sync with the superview in any case
    }
}
