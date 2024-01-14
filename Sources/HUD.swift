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
/// - NOTE: To still allow touches to pass through the HUD, you can set hud.userInteractionEnabled = NO.
/// - ATTENTION: HUD is a UI class and should therefore only be accessed on the main thread.
open class HUD: BaseView {
    // MARK: - Properties

    /// The HUD delegate object. Receives HUD state notifications.
    public weak var delegate: HUDDelegate?
    /// Called after the HUD is hidden.
    public var completionBlock: ((_ hud: HUD) -> Void)?

    /// Grace period is the time (in seconds) that the invoked method may be run without showing the HUD. 
    /// If the task finishes before the grace time runs out, the HUD will not be shown at all. This may be used to prevent HUD display for very short tasks. `Defaults to 0.0 (no grace time)`.
    /// - Note: The graceTime needs to be set before the hud is shown. You thus can't use `show(to:animated:)`,
    ///         but instead need to alloc / init the HUD, configure the grace time and than show it manually.
    public var graceTime: TimeInterval = 0.0
    /// The minimum time (in seconds) that the HUD is shown. This avoids the problem of the HUD being shown and than instantly hidden. `Defaults to 0.0 (no minimum show time)`.
    public var minShowTime: TimeInterval = 0.0

    /// Removes the HUD from its parent view when hidden. `Defaults to true`.
    public var removeFromSuperViewOnHide: Bool = true
    /// The animation type that should be used when the HUD is shown and hidden. `Defaults to .fade`.
    public var animationType: HUDAnimation = .fade

    /// Handle show `HUD` multiple times in the same `View` page.
    public private(set) var count: Int = 0
    /// Enable `count`. `Defaults to false`.
    public var isCountEnabled: Bool = false

    // MARK: - Appearance

    /// HUD operation mode. `Default to .indeterminate`.
    public var mode: HUDMode = .indeterminate {
        didSet {
            guard mode != oldValue else { return }
            updateIndicators()
        }
    }
    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layoutConfig: HUDLayoutConfiguration = .init() {
        didSet {
            guard layoutConfig != oldValue else { return }
            setNeedsUpdateConstraints()
        }
    }
    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views. `Defaults to semi-translucent black`.
    public lazy var contentColor: UIColor = {
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
    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. `Defaults to false`.
    public var isMotionEffectsEnabled: Bool = false {
        didSet {
            guard isMotionEffectsEnabled != oldValue else { return }
            updateBezelMotionEffects()
        }
    }

    // MARK: - Progress

    /// The progress of the progress indicator, from 0.0 to 1.0. `Defaults to 0.0`.
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
    public private(set) lazy var bezelView = BackgroundView(frame: .zero)
    /// View covering the entire HUD area, placed behind bezelView.
    public private(set) lazy var backgroundView = BackgroundView(frame: bounds)
    /// A label that holds an optional short message to be displayed below the activity indicator.
    /// The HUD is automatically resized to fit the entire text.
    public private(set) lazy var label = UILabel(frame: .zero)
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public private(set) lazy var detailsLabel = UILabel(frame: .zero)
    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public private(set) lazy var button = RoundedButton(frame: .zero)

    private var isFinished: Bool = false
    private var indicator: UIView?
    private var showStarted: Date?
    private var paddingConstraints: [NSLayoutConstraint]?
    private var bezelConstraints: [NSLayoutConstraint]?
    private var graceWorkItem: DispatchWorkItem?
    private var minShowWorkItem: DispatchWorkItem?
    private var hideDelayWorkItem: DispatchWorkItem?
    private var bezelMotionEffects: UIMotionEffectGroup?
    private var progressObjectDisplayLink: CADisplayLink? {
        didSet {
            guard progressObjectDisplayLink != oldValue else { return }
            oldValue?.invalidate()
            progressObjectDisplayLink?.add(to: .main, forMode: .default)
        }
    }

    // MARK: - Lifecycle

    /// A convenience constructor that initializes the HUD with the `view's bounds`. Calls the designated constructor with `view.bounds` as the parameter.
    /// - Parameter view: The view instance that will provide the `bounds` for the HUD. Should be the same instance as the HUD's superview (i.e., the view that the HUD will be added to).
    public convenience init(with view: UIView) {
        self.init(frame: view.bounds)
    }

    /// Common initialization method, allowing overriding
    open override func commonInit() {
        // Transparent background
        isOpaque = false
        backgroundColor = .clear
        // Make it invisible for now
        isHidden = true
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

    /// Finds the top-most HUD subview that hasn't finished and returns it.
    /// - Parameter view: The view that is going to be searched.
    /// - Returns: A reference to the last HUD subview discovered.
    public class func hud(for view: UIView) -> HUD? {
        for case let hud as HUD in view.subviews.reversed() where hud.isFinished == false {
            return hud
        }
        return nil
    }

    /// Creates a new HUD. adds it to provided view and shows it. The counterpart to this method is `hide(for:animated:)`.
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - animated: If set to true the HUD will appear using the current animationType. If set to false the HUD will not use animations while appearing. `Default to true`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
    /// - SeeAlso: animationType.
    @discardableResult
    public class func show(to view: UIView, animated: Bool = true, populator: ((HUD) -> Void)? = nil) -> HUD {
        if let hud = hud(for: view), hud.isCountEnabled {
            hud.count += 1
            return hud
        }

        let hud = HUD(with: view) // Creates a new HUD
        populator?(hud)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }

    /// Finds the top-most HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:animated:)`.
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animated: If set to true the HUD will disappear using the current animationType. If set to false the HUD will not use animations while disappearing. `Default to true`.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if a HUD was found and removed, false otherwise.
    /// - Note: This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
    /// - SeeAlso: animationType.
    @discardableResult
    public class func hide(for view: UIView, animated: Bool = true, afterDelay delay: TimeInterval = 0.0) -> Bool {
        hide(for: view, options: animated ? nil : HUDAnimationOptions.none, afterDelay: delay) // nil, Use default animation
    }

    /// Finds the top-most HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:using:)`.
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animation: Use HUDAnimation, Priority greater than the current animationType.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: This method sets removeFromSuperViewOnHide. The HUD will automatically be removed from the view hierarchy when hidden.
    @discardableResult
    public class func hide(for view: UIView, using animation: HUDAnimation, afterDelay delay: TimeInterval = 0.0) -> Bool {
        hide(for: view, options: .animation(animation), afterDelay: delay)
    }

    /// Displays the HUD.
    /// - Parameter animated: If set to true the HUD will appear using the current animationType. If set to false the HUD will not use animations while appearing. `Default to true`.
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated. Call this method when your task is already set up to be executed in a new thread (e.g., when using something like NSOperation or making an asynchronous call like NSURLRequest).
    /// - SeeAlso: animationType.
    public func show(animated: Bool = true) {
        show(with: .init(animated: animated, animation: animationType))
    }

    /// Displays the HUD.
    /// - Parameter animation: Use HUDAnimation, Priority greater than the current animationType.
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated. Call this method when your task is already set up to be executed in a new thread (e.g., when using something like NSOperation or making an asynchronous call like NSURLRequest).
    public func show(using animation: HUDAnimation) {
        show(with: .animation(animation))
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    /// - Parameters:
    ///   - animated: If set to true the HUD will disappear using the current animationType. If set to false the HUD will not use animations while disappearing. `Default to true`.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - SeeAlso: animationType.
    public func hide(animated: Bool = true, afterDelay delay: TimeInterval = 0.0) {
        hide(with: .init(animated: animated, animation: animationType), afterDelay: delay)
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    /// - Parameters:
    ///   - animation: Use HUDAnimation, Priority greater than the current animationType.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    public func hide(using animation: HUDAnimation, afterDelay delay: TimeInterval = 0.0) {
        hide(with: .animation(animation), afterDelay: delay)
    }

    private class func hide(for view: UIView, options: HUDAnimationOptions?, afterDelay delay: TimeInterval) -> Bool {
        guard let hud = hud(for: view) else { return false }
        hud.removeFromSuperViewOnHide = true
        hud.hide(with: options ?? .animation(hud.animationType), afterDelay: delay) // Use default animation, if unknown
        return true
    }

    private func show(with options: HUDAnimationOptions) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")

        if isCountEnabled {
            count += 1
        }

        isFinished = false
        cancelMinShowWorkItem()
        // Modified grace time to 0 and show again
        cancelGraceWorkItem()
        // Cancel any scheduled hide(animated:afterDelay:) calls
        cancelHideDelayWorkItem()

        // If the grace time is set, postpone the HUD display
        if graceTime > 0.0 {
            let workItem = DispatchWorkItem { [weak self] in
                // Show the HUD only if the task is still running
                guard let `self` = self, !self.isFinished else { return }
                self.performShow(with: options)
            }
            graceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + graceTime, execute: workItem)
            return
        }

        performShow(with: options) // ... otherwise show the HUD immediately
    }

    private func performShow(with options: HUDAnimationOptions) {
        // Cancel any previous animations
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()

        showStarted = Date()
        isHidden = false

        // Needed in case we hide and re-show with the same NSProgress object attached.
        setNSProgressDisplayLink(enabled: true)
        // Set up motion effects only at this point to avoid needlessly creating the effect if it was disabled after initialization.
        updateBezelMotionEffects()

        perform(with: options, showing: true, completion: nil)
    }

    private func hide(with options: HUDAnimationOptions, afterDelay delay: TimeInterval) {
        guard delay > 0.0 else {
            return hide(with: options)
        }

        cancelHideDelayWorkItem() // Cancel any scheduled hide(animated:afterDelay:) calls
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide(with: options)
        }
        hideDelayWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func hide(with options: HUDAnimationOptions) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")

        if isCountEnabled {
            count -= 1
            if count > 0 {
                return
            }
        }

        cancelGraceWorkItem()
        isFinished = true

        // If the minShow time is set, calculate how long the HUD was shown, and postpone the hiding operation if necessary
        if let showStarted = showStarted, minShowTime > 0.0 {
            let interv = Date().timeIntervalSince(showStarted)
            if interv < minShowTime {
                cancelMinShowWorkItem()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.performHide(with: options)
                }
                minShowWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + (minShowTime - interv), execute: workItem)
                return
            }
        }

        performHide(with: options) // ... otherwise hide the HUD immediately
    }

    private func performHide(with options: HUDAnimationOptions) {
        // Cancel any scheduled hide(animated:afterDelay:) calls.
        // This needs to happen here instead of in done, to avoid races if another hide(animated:afterDelay:)
        // call comes in while the HUD is animating out.
        cancelHideDelayWorkItem()
        perform(with: options, showing: false) {
            // Cancel any scheduled hide(animated:afterDelay:) calls
            self.cancelHideDelayWorkItem()
            self.setNSProgressDisplayLink(enabled: false)

            if self.isFinished {
                self.isHidden = true
                if self.removeFromSuperViewOnHide {
                    self.removeFromSuperview()
                }
            }

            self.completionBlock?(self)
            self.delegate?.hudWasHidden(self)
        }
        showStarted = nil
    }

    private func perform(with options: HUDAnimationOptions, showing: Bool, completion: (() -> Void)?) {
        let alpha: CGFloat = showing ? 1.0 : 0.0
        let completionBlock: (Bool) -> Void = { _ in
            self.bezelView.transform = .identity // Reset, after the animation is completed
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
            completion?()
        }

        guard case .animation(var type) = options, showStarted != nil else {
            return completionBlock(true)
        }

        // Automatically determine the correct zoom animation type
        if type == .zoomInOut {
            type = showing ? .zoomIn : .zoomOut
        } else if type == .zoomOutIn {
            type = showing ? .zoomOut : .zoomIn
        }

        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)

        // Set starting state
        if showing && bezelView.alpha == 0.0 && type == .zoomIn {
            bezelView.transform = small
        } else if showing && bezelView.alpha == 0.0 && type == .zoomOut {
            bezelView.transform = large
        }

        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: {
            if showing {
                self.bezelView.transform = .identity
            } else if !showing && type == .zoomIn {
                self.bezelView.transform = large
            } else if !showing && type == .zoomOut {
                self.bezelView.transform = small
            }
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
        }, completion: completionBlock)
    }

    // MARK: - Cancel Dispatch Work Item

    private func cancelHideDelayWorkItem() {
        hideDelayWorkItem?.cancel()
        hideDelayWorkItem = nil
    }

    private func cancelGraceWorkItem() {
        graceWorkItem?.cancel()
        graceWorkItem = nil
    }

    private func cancelMinShowWorkItem() {
        minShowWorkItem?.cancel()
        minShowWorkItem = nil
    }

    // MARK: - UI

    private func setupViews() {
        let defaultColor = contentColor

        backgroundView.style = .solidColor
        backgroundView.color = .clear
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.alpha = 0.0
        addSubview(backgroundView)

        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.alpha = 0.0
        addSubview(bezelView)

        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = defaultColor
        label.font = .boldSystemFont(ofSize: 16.0) // Default to 16.0
        label.isOpaque = false
        label.backgroundColor = .clear

        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = defaultColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = .boldSystemFont(ofSize: 12.0) // Default to 12.0.0
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = .clear

        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .boldSystemFont(ofSize: 12.0) // Default to 12.0.0
        button.setTitleColor(defaultColor, for: .normal)

        for view in [label, detailsLabel, button] {
            view.setContentCompressionResistancePriorityForAxis(UILayoutPriority(998.0))
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
                    indicatorView.color = .white
                } else {
                    indicatorView = UIActivityIndicatorView(style: .whiteLarge)
                }
                indicatorView.startAnimating()
                bezelView.addSubview(indicatorView)
                indicator = indicatorView
            }
        case .determinateHorizontalBar: // Update to bar determinate indicator
            indicator?.removeFromSuperview()
            let bar = BarProgressView()
            bezelView.addSubview(bar)
            indicator = bar
        case .determinate, .annularDeterminate:
            if !(indicator is RoundProgressView) { // Update to determinante indicator
                indicator?.removeFromSuperview()
                let roundView = RoundProgressView()
                bezelView.addSubview(roundView)
                indicator = roundView
            }

            if mode == .annularDeterminate {
                (indicator as? RoundProgressView)?.isAnnular = true
            }
        case .customView( let customView):
            if customView != indicator { // Update custom view indicator
                indicator?.removeFromSuperview()
                bezelView.addSubview(customView)
                indicator = customView
            }
        case .text:
            indicator?.removeFromSuperview()
            indicator = nil
        }

        if let indicator = indicator {
            indicator.setContentCompressionResistancePriorityForAxis(UILayoutPriority(998.0))
            (indicator as? Progressive)?.progress = progress
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
        addConstraints(centeringConstraints.apply(UILayoutPriority(998.0)))

        // Ensure minimum side margin is kept
        let sideConstraints: [NSLayoutConstraint] = [
            bezelView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: layoutConfig.edgeInsets.left),
            bezelView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -layoutConfig.edgeInsets.right),
            bezelView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: layoutConfig.edgeInsets.top),
            bezelView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -layoutConfig.edgeInsets.bottom),
        ]
        addConstraints(sideConstraints.apply(UILayoutPriority(999.0)))

        // Minimum bezel size, if set
        if !layoutConfig.minSize.equalTo(.zero) {
            let minSizeConstraints: [NSLayoutConstraint] = [
                bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: layoutConfig.minSize.width),
                bezelView.heightAnchor.constraint(greaterThanOrEqualToConstant: layoutConfig.minSize.height)
            ]
            bezelConstraints.append(contentsOf: minSizeConstraints.apply(UILayoutPriority(997.0)))
        }

        // Square aspect ratio, if set
        if layoutConfig.isSquare {
            let square = bezelView.heightAnchor.constraint(equalTo: bezelView.widthAnchor)
            bezelConstraints.append(square.apply(UILayoutPriority(997.0)))
        }

        // Layout subviews in bezel
        var paddingConstraints: [NSLayoutConstraint] = []
        let lastSubviewIDX = subviews.count - 1
        for (idx, view) in subviews.enumerated() {
            bezelConstraints.append(contentsOf: [
                // Center in bezel
                view.centerXAnchor.constraint(equalTo: bezelView.centerXAnchor),
                // Ensure the minimum edge margin is kept
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
        // There is no need to update constraints if they are going to be recreated in super.layoutSubviews() due to needsUpdateConstraints
        // being set. This also avoids an issue on iOS 8, where updatePaddingConstraints would trigger a zombie object access.
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
            paddingConstraint.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? layoutConfig.spacing : 0.0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }

    // MARK: - NSProgress

    private class WeakProxy {
        private weak var target: HUD?

        init(_ target: HUD) {
            self.target = target
        }

        @objc func onScreenUpdate() {
            target?.updateProgressFromProgressObject()
        }
    }

    private func setNSProgressDisplayLink(enabled: Bool) {
        // We're using CADisplayLink, because NSProgress can change very quickly and observing it may starve the main thread,
        // so we're refreshing the progress only every frame draw
        if enabled && progressObject != nil {
            if progressObjectDisplayLink == nil { // Only create if not already active.
                progressObjectDisplayLink = CADisplayLink(target: WeakProxy(self), selector: #selector(WeakProxy.onScreenUpdate))
            }
        } else {
            progressObjectDisplayLink?.invalidate()
            progressObjectDisplayLink = nil
        }
    }

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

    // MARK: - View Hierarchy

    open override func didMoveToSuperview() {
        updateForCurrentOrientation(animated: false)
    }

    private func updateForCurrentOrientation(animated: Bool) {
        guard let superview = superview else { return }
        frame = superview.bounds // Stay in sync with the superview in any case
    }
}
