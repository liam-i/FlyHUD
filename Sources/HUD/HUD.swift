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
/// - Note: To still allow touches to pass through the HUD, you can set hud.userInteractionEnabled = NO.
/// - Attention: HUD is a UI class and should therefore only be accessed on the main thread.
open class HUD: BaseView, ProgressViewDelegate, KeyboardObservable {
    /// A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    public private(set) lazy var label = UILabel(frame: .zero)
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public private(set) lazy var detailsLabel = UILabel(frame: .zero)
    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public private(set) lazy var button = RoundedButton(frame: .zero)
    /// The view containing the labels and indicator (or customView). The HUD object places the content in this view in front of any background views.
    public private(set) lazy var bezelView = BackgroundView(frame: .zero)
    /// View covering the entire HUD area, placed behind bezelView.
    public private(set) lazy var backgroundView = BackgroundView(frame: bounds)

    /// HUD operation mode. `Default to .indicator(.large)`.
    public var mode: Mode = .indicator() {
        didSet {
            mode.notEqual(oldValue, do: updateIndicators())
        }
    }
    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layout: Layout = .init() {
        didSet {
            layout.notEqual(oldValue, do: setNeedsUpdateConstraints())
        }
    }

    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views. `Defaults to UIColor.label.withAlphaComponent(0.7)`.
    public var contentColor: UIColor = .HUDContent {
        didSet {
            contentColor.notEqual(oldValue, do: updateViewsContentColor())
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0. `Defaults to 0.0`.
    public var progress: Float = 0.0 {
        didSet {
            progress.notEqual(oldValue, do: (indicator as? ProgressViewable)?.progress = progress)
        }
    }
    /// The Progress object feeding the progress information to the progress indicator.
    /// - Note: When this property is set, the progress view updates its progress value automatically using information it receives from the [Progress](https://developer.apple.com/documentation/foundation/progress) object. Set the property to nil when you want to update the progress manually.  `Defaults to nil`.
    /// - Note: It will auto set localizedDescription and localizedAdditionalDescription to the text of label and detaillabel properties. They can be customized or use the default text. To suppress one (or both) of the labels, set the descriptions to empty strings.
    public var observedProgress: Progress? {
        get { (indicator as? ProgressViewable)?.observedProgress }
        set { (indicator as? ProgressViewable)?.observedProgress = newValue }
    }

    /// The animation (type, duration, damping) that should be used when the HUD is shown and hidden.
    public var animation: Animation = .init()
    /// A boolean value indicating whether the HUD is visible.
    public var isVisible: Bool { isHidden == false }
    /// Grace period is the time (in seconds) that the invoked method may be run without showing the HUD.
    /// If the task finishes before the grace time runs out, the HUD will not be shown at all. This may be used to prevent HUD display for very short tasks. `Defaults to 0.0 (no grace time)`.
    /// - Note: The graceTime needs to be set before the hud is shown. You thus can't use `show(to:using:)`,
    ///         but instead need to alloc / init the HUD, configure the grace time and than show it manually.
    public var graceTime: TimeInterval = 0.0
    /// The minimum time (in seconds) that the HUD is shown. This avoids the problem of the HUD being shown and than instantly hidden. `Defaults to 0.0 (no minimum show time)`.
    public var minShowTime: TimeInterval = 0.0
    /// Removes the HUD from its parent view when hidden. `Defaults to true`.
    public var removeFromSuperViewOnHide: Bool = true

    /// This is an activity count that records multiple shows and hides of the same HUD object.
    public private(set) var count: Int = 0
    /// A Boolean value indicating whether the HUD is in the enable activity count. `Defaults to false`.
    /// - Note: If set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    public var isCountEnabled: Bool = false

    /// A layout guide that tracks the keyboard’s position in your app’s layout. `Default to disable`.
    /// - Note: Global configuration. Priority less than member property keyboardGuide.
    public static var keyboardGuide: KeyboardGuide = .disable {
        didSet {
            keyboardGuide.notEqual(oldValue, do: updateKeyboardObserver())
        }
    }
    /// A layout guide that tracks the keyboard’s position in your app’s layout. `Default to nil`.
    /// - Note: Priority greater than static property keyboardGuide.
    /// - Note: If set to nil, the static property keyboardGuide is used.
    public var keyboardGuide: KeyboardGuide? {
        didSet {
            keyboardGuide.notEqual(oldValue, do: updateKeyboardObserver())
        }
    }

    /// A Boolean value that controls the delivery of user events. `Defaults to false`.
    ///
    /// If set to true user events (click, touch) will be delivered normally to the HUD's parent view.
    ///
    /// If set to false user events (click, touch) will be delivered normally to the HUD's subviews.
    /// - Note: This property is affected by "isUserInteractionEnabled".
    public var isEventDeliveryEnabled: Bool = false

    /// When enabled, the bezel center gets slightly affected by the device accelerometer data. `Defaults to false`.
    public var isMotionEffectsEnabled: Bool = false {
        didSet {
            isMotionEffectsEnabled.notEqual(oldValue, do: updateBezelMotionEffects())
        }
    }

    /// The HUD delegate object. Receives HUD state notifications.
    public weak var delegate: HUDDelegate?
    /// Called after the HUD is hidden.
    public var completionBlock: ((_ hud: HUD) -> Void)?

    private var isFinished: Bool = false
    private var indicator: UIView?
    private var contentView = UIView(frame: .zero)
    private var showStarted: Date?
    private var paddingConstraints: [NSLayoutConstraint]?
    private var bezelConstraints: [NSLayoutConstraint]?
    private var graceWorkItem: DispatchWorkItem?
    private var minShowWorkItem: DispatchWorkItem?
    private var hideDelayWorkItem: DispatchWorkItem?
    private var bezelMotionEffects: UIMotionEffectGroup?

    // MARK: - Lifecycle

    /// Common initialization method, allowing overriding
    open override func commonInit() {
        isOpaque = false // Transparent background
        backgroundColor = .clear
        isHidden = true // Make it invisible for now
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.allowsGroupOpacity = false
        setupViews()
        updateIndicators()
        updateKeyboardObserver()
        registerForNotifications()
    }

    deinit {
        cancelHideDelayWorkItem()
        cancelGraceWorkItem()
        cancelMinShowWorkItem()
        unregisterFromNotifications()
        #if DEBUG
        print("👍👍👍 HUD is released.")
        #endif
    }

    // MARK: - Show & hide

    /// Find all unfinished HUD subviews and return them.
    /// - Parameter view: The view that is going to be searched.
    /// - Returns: A reference to all discovered HUD subviews.
    public class func huds(for view: UIView) -> [HUD] {
        view.subviews.compactMap {
            if let hud = $0 as? HUD, hud.isFinished == false {
                return hud
            }
            return nil
        }
    }

    /// Finds the `top-most` HUD subview that hasn't finished and returns it.
    /// - Parameter view: The view that is going to be searched.
    /// - Returns: A reference to the last HUD subview discovered.
    public class func hud(for view: UIView) -> HUD? {
        for case let hud as HUD in view.subviews.reversed() where hud.isFinished == false {
            return hud
        }
        return nil
    }

    /// Creates a new HUD. adds it to provided view and shows it. And auto hides the HUD after a duration.
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - duration: The total duration of the show, measured in seconds. Duration must be greater than 0.0. `Default to 2.0`.
    ///   - animation: Use HUD.Animation.  `Default to (style:.fade,duration:0.3,damping:.disable)`.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text. If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.  `Default to nil`.
    ///   - detailsLabel: An optional details message displayed below the labelText message. The details text can span multiple lines.  `Default to nil`.
    ///   - offset: The bezel offset relative to the center of the view. You can use `.HUDMaxOffset` to move the HUD all the way to the screen edge in each direction. `Default to .HUDVMaxOffset`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func showStatus(
        to view: UIView,
        duration: TimeInterval = 2.0,
        using animation: Animation = .init(),
        mode: Mode = .text,
        label: String? = nil,
        detailsLabel: String? = nil,
        offset: CGPoint = .HUDVMaxOffset,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        show(to: view, using: animation, mode: mode, label: label, detailsLabel: detailsLabel) {
            $0.layout.offset = offset
            populator?($0)
        }.with {
            $0.removeFromSuperViewOnHide = true
            $0.hide(using: animation, afterDelay: duration)
        }
    }

    /// Creates a new HUD. adds it to provided view and shows it. The counterpart to this method is `hide(for:using:)`.
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - animation: Use HUD.Animation.  `Default to (style:.fade,duration:0.3,damping:.disable)`.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text. If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.  `Default to nil`.
    ///   - detailsLabel: An optional details message displayed below the labelText message. The details text can span multiple lines.  `Default to nil`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func show(
        to view: UIView,
        using animation: Animation = .init(),
        mode: Mode = .indicator(),
        label: String? = nil,
        detailsLabel: String? = nil,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        HUD(frame: view.bounds).with { // Creates a new HUD
            $0.animation = animation
            $0.mode = mode
            $0.label.text = label
            $0.detailsLabel.text = detailsLabel
            populator?($0)
            view.addSubview($0)
            $0.removeFromSuperViewOnHide = true
            $0.show(using: $0.animation)
        }
    }

    /// Finds the `top-most` HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:using:...)`.
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if a HUD was found and removed, false otherwise.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    @discardableResult
    public class func hide(for view: UIView, using animation: Animation? = nil, afterDelay delay: TimeInterval = 0.0) -> Bool {
        guard let hud = hud(for: view) else { return false }
        hud.removeFromSuperViewOnHide = true
        hud.hide(using: animation, afterDelay: delay)
        return true
    }

    /// Find all unfinished HUD subviews and hide them. The counterpart to this method is `show(to:using:...)`.
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if one or more HUDs were found and removed, false otherwise.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    @discardableResult
    public class func hideAll(for view: UIView, using animation: Animation? = nil, afterDelay delay: TimeInterval = 0.0) -> Bool {
        let huds = huds(for: view)
        huds.forEach {
            $0.removeFromSuperViewOnHide = true
            $0.hide(using: animation, afterDelay: delay)
        }
        return huds.isEmpty == false
    }

    /// Displays the HUD.
    /// - Parameter animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated. Call this method when your task is already set up to be executed in a new thread (e.g., when using something like Operation or making an asynchronous call like URLRequest).
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    public func show(using animation: Animation? = nil) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")
        show(animation ?? self.animation)
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    /// - Parameters:
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    public func hide(using animation: Animation? = nil, afterDelay delay: TimeInterval = 0.0) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")
        hide(animation ?? self.animation, afterDelay: delay)
    }

    private func show(_ animation: Animation) {
        // If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
        if isCountEnabled {
            count += 1
        }

        isFinished = false
        cancelMinShowWorkItem()
        cancelGraceWorkItem() // Modified grace time to 0 and show again
        cancelHideDelayWorkItem() // Cancel any scheduled hide(using:afterDelay:) calls

        // If the grace time is set, postpone the HUD display
        if graceTime > 0.0 {
            let workItem = DispatchWorkItem { [weak self] in
                // Show the HUD only if the task is still running
                guard let `self` = self, !self.isFinished else { return }
                self.performShow(animation)
            }
            graceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + graceTime, execute: workItem)
            return
        }

        performShow(animation) // ... otherwise show the HUD immediately
    }

    private func performShow(_ animation: Animation) {
        // Cancel any previous animations
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()

        showStarted = Date()
        isHidden = false
        indicator?.isHidden = false

        updateBezelMotionEffects() // Set up motion effects only at this point to avoid needlessly creating the effect if it was disabled after initialization.
        updateKeyboardGuide()
        perform(animation, showing: true, completion: nil)
    }

    private func hide(_ animation: Animation, afterDelay delay: TimeInterval) {
        guard delay > 0.0 else {
            return hide(animation)
        }

        cancelHideDelayWorkItem() // Cancel any scheduled hide(using:afterDelay:) calls
        let workItem = DispatchWorkItem { [weak self] in
            self?.hide(animation)
        }
        hideDelayWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func hide(_ animation: Animation) {
        // If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
        // Hide HUD if count reaches 0. Returns if count has not reached 0.
        if isCountEnabled {
            count -= 1
            if count > 0 { return }
        }

        cancelGraceWorkItem()
        isFinished = true

        // If the minShow time is set, calculate how long the HUD was shown, and postpone the hiding operation if necessary
        if let showStarted = showStarted, minShowTime > 0.0 {
            let interv = Date().timeIntervalSince(showStarted)
            if interv < minShowTime {
                cancelMinShowWorkItem()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.performHide(animation)
                }
                minShowWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + (minShowTime - interv), execute: workItem)
                return
            }
        }

        performHide(animation) // ... otherwise hide the HUD immediately
    }

    private func performHide(_ animation: Animation) {
        // Cancel any scheduled hide(using:afterDelay:) calls.
        // This needs to happen here instead of in done, to avoid races if another hide(using:afterDelay:)
        // call comes in while the HUD is animating out.
        cancelHideDelayWorkItem()
        perform(animation, showing: false) {
            // Cancel any scheduled hide(using:afterDelay:) calls
            self.cancelHideDelayWorkItem()
            self.indicator?.isHidden = true

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

    private func perform(_ animation: Animation, showing: Bool, completion: (() -> Void)?) {
        let alpha: CGFloat = showing ? 1.0 : 0.0
        let completionBlock: (Bool) -> Void = { _ in
            self.bezelView.transform = .identity // Reset, after the animation is completed
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
            completion?()
        }

        var style = animation.style
        guard style != .none, showStarted != nil else {
            return completionBlock(true)
        }

        // Automatically determine the correct zoom animation type
        switch style {
        case .zoomInOut:    style = showing ? .zoomIn : .zoomOut
        case .zoomOutIn:    style = showing ? .zoomOut : .zoomIn
        case .slideUpDown:  style = showing ? .slideUp : .slideDown
        case .slideDownUp:  style = showing ? .slideDown : .slideUp
        default: break
        }

        // Set starting state
        if showing && bezelView.alpha == 0.0 {
            transform(to: style, isInvert: true)
        }

        UIView.animate(withDuration: animation.duration, delay: 0.0, usingSpringWithDamping: animation.damping.value,
                       initialSpringVelocity: 0.0, options: .beginFromCurrentState, animations: {
            if showing {
                self.transform(to: .fade)
            } else {
                self.transform(to: style, isInvert: false)
            }
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
        }, completion: completionBlock)
    }

    private func transform(to style: Animation.Style, isInvert: Bool) {
        switch style {
        case .zoomIn:       transform(to: isInvert ? .zoomOut : .zoomIn)
        case .zoomOut:      transform(to: isInvert ? .zoomIn : .zoomOut)
        case .slideUp:      transform(to: isInvert ? .slideDown : .slideUp)
        case .slideDown:    transform(to: isInvert ? .slideUp : .slideDown)
        default:            transform(to: .fade)
        }
    }

    private func transform(to style: Animation.Style) {
        switch style {
        case .zoomIn:
            bezelView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        case .zoomOut:
            bezelView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        case .slideUp:
            layoutIfNeeded()
            bezelView.transform = CGAffineTransform(translationX: 0.0, y: bounds.minY - bezelView.frame.maxY)
        case .slideDown:
            layoutIfNeeded()
            bezelView.transform = CGAffineTransform(translationX: 0.0, y: bounds.maxY - bezelView.frame.minY)
        default:
            bezelView.transform = .identity
        }
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
        addSubview(backgroundView.with {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.alpha = 0.0
        })
        addSubview(contentView.with {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.backgroundColor = .clear
        })
        contentView.addSubview(bezelView.with {
            $0.color = .HUDBackground
            $0.roundedCorners = .radius(5.0)
            $0.style = .blur()
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alpha = 0.0
        })
        bezelView.addSubview(label.with {
            $0.adjustsFontSizeToFitWidth = false
            $0.textAlignment = .center
            $0.textColor = defaultColor
            $0.font = .boldSystemFont(ofSize: 16.0) // Default to 16.0
            $0.isOpaque = false
            $0.backgroundColor = .clear
        })
        bezelView.addSubview(detailsLabel.with {
            $0.adjustsFontSizeToFitWidth = false
            $0.textAlignment = .center
            $0.textColor = defaultColor
            $0.numberOfLines = 0
            $0.font = .boldSystemFont(ofSize: 12.0) // Default to 12.0.0
            $0.isOpaque = false
            $0.backgroundColor = .clear
        })
        bezelView.addSubview(button.with {
            $0.titleLabel?.textAlignment = .center
            $0.titleLabel?.font = .boldSystemFont(ofSize: 12.0) // Default to 12.0.0
            $0.setTitleColor(defaultColor, for: .normal)
        })

        for view in [label, detailsLabel, button] {
            view.setContentCompressionResistancePriorityForAxis(UILayoutPriority(998.0))
        }
    }

    private func updateIndicators() {
        func setIndicator(_ newValue: UIView?) {
            indicator?.removeFromSuperview()
            if let newValue = newValue { bezelView.addSubview(newValue) }
            indicator = newValue
        }

        switch mode {
        case .text:
            setIndicator(nil)
        case let .indicator(style): // Update to UIActivityIndicatorView
            if let indicator = indicator as? UIActivityIndicatorView {
                indicator.style = style
            } else {
                setIndicator(UIActivityIndicatorView(style: style))
            }
        case let .progress(style): // Update to UIProgressView
            if let indicator = indicator as? iOSUIProgressView {
                indicator.progressViewStyle = style
            } else {
                setIndicator(iOSUIProgressView(progressViewStyle: style))
            }
        case let .custom(view): // Update custom view indicator
            view.notEqual(indicator, do: setIndicator(view))
        }

        if let indicator = indicator {
            indicator.setContentCompressionResistancePriorityForAxis(UILayoutPriority(998.0))

            if let activityIndicator = indicator as? ActivityIndicatorViewable, activityIndicator.isAnimating == false {
                activityIndicator.startAnimating()
            }
            if let progressView = indicator as? ProgressViewable {
                progressView.delegate = self
                progressView.progress = progress
            }
            if let rotateView = indicator as? RotateViewable {
                rotateView.startRotation()
            }
        }

        updateViewsContentColor()
        setNeedsUpdateConstraints()
    }

    private func updateViewsContentColor() {
        let contentColor = contentColor

        label.textColor = contentColor
        detailsLabel.textColor = contentColor
        button.setTitleColor(contentColor, for: .normal)

        // UIAppearance settings are prioritized. If they are preset the set color is ignored.
        guard let indicator = indicator else { return }
        switch indicator {
        case let indicator as ActivityIndicatorViewable:
            indicator.color = contentColor
        case let indicator as ProgressViewable:
            indicator.progressTintColor = contentColor
        default:
            indicator.tintColor = contentColor
        }
    }

    private func updateBezelMotionEffects() {
        if isMotionEffectsEnabled && bezelMotionEffects == nil {
            let effectOffset = 10.0
            bezelMotionEffects = UIMotionEffectGroup().with {
                $0.motionEffects = [
                    UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis).with {
                        $0.maximumRelativeValue = effectOffset
                        $0.minimumRelativeValue = -effectOffset
                    },
                    UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis).with {
                        $0.maximumRelativeValue = effectOffset
                        $0.minimumRelativeValue = -effectOffset
                    }
                ]
                bezelView.addMotionEffect($0)
            }
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
            bezelView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: layout.offset.x),
            bezelView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: layout.offset.y)
        ]
        addConstraints(centeringConstraints.apply(UILayoutPriority(998.0)))

        // Ensure minimum side margin is kept
        let anchor: (leading: NSLayoutXAxisAnchor, trailing: NSLayoutXAxisAnchor, top: NSLayoutYAxisAnchor, bottom: NSLayoutYAxisAnchor)
        if layout.isSafeAreaLayoutGuideEnabled {
            anchor = (safeAreaLayoutGuide.leadingAnchor, safeAreaLayoutGuide.trailingAnchor,
                      safeAreaLayoutGuide.topAnchor, safeAreaLayoutGuide.bottomAnchor)
        } else {
            anchor = (leadingAnchor, trailingAnchor, topAnchor, bottomAnchor)
        }
        let sideConstraints: [NSLayoutConstraint] = [
            bezelView.leadingAnchor.constraint(greaterThanOrEqualTo: anchor.leading, constant: layout.edgeInsets.left),
            bezelView.trailingAnchor.constraint(lessThanOrEqualTo: anchor.trailing, constant: -layout.edgeInsets.right),
            bezelView.topAnchor.constraint(greaterThanOrEqualTo: anchor.top, constant: layout.edgeInsets.top),
            bezelView.bottomAnchor.constraint(lessThanOrEqualTo: anchor.bottom, constant: -layout.edgeInsets.bottom),
        ]
        addConstraints(sideConstraints.apply(UILayoutPriority(999.0)))

        // Minimum bezel size, if set
        if !layout.minSize.equalTo(.zero) {
            let minSizeConstraints: [NSLayoutConstraint] = [
                bezelView.widthAnchor.constraint(greaterThanOrEqualToConstant: layout.minSize.width),
                bezelView.heightAnchor.constraint(greaterThanOrEqualToConstant: layout.minSize.height)
            ]
            bezelConstraints.append(contentsOf: minSizeConstraints.apply(UILayoutPriority(997.0)))
        }

        // Square aspect ratio, if set
        if layout.isSquare {
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
                view.leadingAnchor.constraint(greaterThanOrEqualTo: bezelView.leadingAnchor, constant: layout.hMargin),
                view.trailingAnchor.constraint(lessThanOrEqualTo: bezelView.trailingAnchor, constant: -layout.hMargin)
            ])

            // Element spacing
            if idx == 0 {
                // First, ensure spacing to bezel edge
                bezelConstraints.append(view.topAnchor.constraint(greaterThanOrEqualTo: bezelView.topAnchor, constant: layout.vMargin))
            } else if idx == lastSubviewIDX {
                // Last, ensure spacing to bezel edge
                bezelConstraints.append(view.bottomAnchor.constraint(lessThanOrEqualTo: bezelView.bottomAnchor, constant: -layout.vMargin))
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
            paddingConstraint.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? layout.spacing : 0.0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }

    // MARK: - Progress

    public func updateProgress(from observedProgress: Progress) {
        // They can be customized or use the default text. To suppress one (or both) of the labels, set the descriptions to empty strings.
        label.text = observedProgress.localizedDescription
        detailsLabel.text = observedProgress.localizedAdditionalDescription
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

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard isEventDeliveryEnabled else { return hitView }
        let bezelRect = bezelView.convert(bezelView.bounds, to: self)
        return bezelRect.contains(point) ? hitView : nil
    }

    private static func updateKeyboardObserver() {
        guard keyboardGuide != .disable else { return }
        _ = KeyboardObserver.shared // Enable keyboard observer
    }

    private func updateKeyboardObserver() {
        if (keyboardGuide == .disable) || (keyboardGuide == nil && HUD.keyboardGuide == .disable) {
            return KeyboardObserver.shared.remove(self)
        }
        KeyboardObserver.shared.add(self)
    }

    public func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo) {
        if (keyboardGuide == .disable) || (keyboardGuide == nil && HUD.keyboardGuide == .disable) {
            return KeyboardObserver.shared.remove(self)
        }
        updateKeyboardGuide(with: keyboardInfo, animated: true)
    }

    private func updateKeyboardGuide() {
        if (keyboardGuide == .disable) || (keyboardGuide == nil && HUD.keyboardGuide == .disable) { return }
        guard let keyboardInfo = KeyboardObserver.shared.keyboardInfo else { return }

        updateKeyboardGuide(with: keyboardInfo, animated: false)
    }

    private func updateKeyboardGuide(with keyboard: KeyboardInfo, animated: Bool) {
        let animations: () -> Void = { [self] in
            guard keyboard.frameEnd.minY < UIScreen.main.bounds.height else {
                return contentView.transform = .identity
            }

            //var safeAreaInsets = safeAreaInsets
            //if safeAreaInsets == .zero, bounds == UIScreen.main.bounds,
            //    let appWindow = UIApplication.shared.delegate?.window, let windowValue = appWindow {
            //    safeAreaInsets = windowValue.safeAreaInsets
            //}
            let keyboardGuide = keyboardGuide ?? HUD.keyboardGuide

            if case let .center(offsetY) = keyboardGuide {
                var y = (keyboard.frameEnd.minY - safeAreaInsets.top) / 2.0 + safeAreaInsets.top + offsetY
                if (y - bezelView.bounds.midY) < 0.0 {
                    y = bezelView.bounds.midY
                }
                contentView.transform = CGAffineTransform(translationX: 0.0, y: -max(bezelView.frame.midY - y, 0.0))
            } else if case let .bottom(spacing) = keyboardGuide {
                let y = max(keyboard.frameEnd.minY - bezelView.bounds.height - spacing, 0.0)
                contentView.transform = CGAffineTransform(translationX: 0.0, y: -max(bezelView.frame.minY - y, 0.0))
            }
        }

        layoutIfNeeded()
        guard animated else {
            return animations()
        }
        let options = AnimationOptions.beginFromCurrentState.union(.init(rawValue: keyboard.animationCurve << 16))
        UIView.animate(withDuration: keyboard.animationDuration, delay: 0.0, options: options, animations: animations)
    }
}
