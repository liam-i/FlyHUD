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

/// A HUD observer that tracks the state of the HUD in your application.
public protocol HUDDelegate: AnyObject {
    /// Called after the HUD was fully hidden from the screen.
    func hudWasHidden(_ hud: HUD)
}

// MARK: - HUD

/// Displays a simple HUD window containing a progress indicator and two optional labels for short messages.
///
/// - Note: To still allow touches to pass through the HUD, you can set hud.isEventDeliveryEnabled = true.
/// - Attention: HUD is a UI class and should therefore only be accessed on the main thread.
open class HUD: BaseView, ContentViewDelegate {
    /// The view containing the labels and indicator (or customView). The HUD object places the content in this view in front of any background views.
    public private(set) lazy var contentView = ContentView(frame: .zero)
    /// View covering the entire HUD area, placed behind contentView.
    public private(set) lazy var backgroundView = BackgroundView(frame: bounds)

    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layout: Layout = .init() {
        didSet {
            layout.h.notEqual(oldValue, do: update(constraints: true, keyboardGuide: true))
        }
    }

    /// The animation (style, duration, damping) that should be used when the HUD is shown and hidden.
    public var animation: Animation = .init()
    /// Grace period is the time (in seconds) that the invoked method may be run without showing the HUD.
    ///
    /// If the task finishes before the grace time runs out, the HUD will not be shown at all.
    /// This may be used to prevent HUD display for very short tasks. `Defaults to 0.0 (no grace time)`.
    ///
    /// - Note: The graceTime needs to be set before the hud is shown. You thus can't use `show(to:using:)`,
    ///         but instead need to alloc / init the HUD, configure the grace time and than show it manually.
    public var graceTime: TimeInterval = 0.0
    /// The minimum time (in seconds) that the HUD is shown. This avoids the problem of the HUD being shown and than instantly hidden.
    ///
    /// `Defaults to 0.0 (no minimum show time)`.
    public var minShowTime: TimeInterval = 0.0
    /// Removes the HUD from its parent view when hidden. `Defaults to true`.
    public var removeFromSuperViewOnHide: Bool = true

    /// This is an activity count that records multiple shows and hides of the same HUD object.
    public private(set) var count: Int = 0
    /// A Boolean value indicating whether the HUD is in the enable activity count. `Defaults to false`.
    ///
    /// - Note: If set to true, the activity count is incremented by 1 when showing the HUD.
    ///         The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    public var isCountEnabled: Bool = false

#if !os(tvOS)
    /// A layout guide that tracks the keyboard’s position in your app’s layout. `Default to disable`.
    ///
    /// - Note: Global configuration. Priority less than member property keyboardGuide.
    public static var keyboardGuide: KeyboardGuide = .disable {
        didSet {
            keyboardGuide.h.notEqual(oldValue, do: updateKeyboardObserver())
        }
    }
    /// A layout guide that tracks the keyboard’s position in your app’s layout. `Default to nil`.
    ///
    /// - Note: Priority greater than static property keyboardGuide.
    /// - Note: If set to nil, the static property keyboardGuide is used.
    public var keyboardGuide: KeyboardGuide? {
        didSet {
            keyboardGuide.h.notEqual(oldValue, do: updateKeyboardObserver())
        }
    }
#endif

    /// A Boolean value that controls the delivery of user events. `Defaults to false`.
    ///
    /// If set to true user events (click, touch) will be delivered normally to the HUD's parent view.
    ///
    /// If set to false user events (click, touch) will be delivered normally to the HUD's subviews.
    /// - Note: This property is affected by "isUserInteractionEnabled".
    public var isEventDeliveryEnabled: Bool = false

    /// The HUD delegate object. Receives HUD state notifications.
    public weak var delegate: HUDDelegate?
    /// Called after the HUD was fully hidden from the screen.
    public var completionBlock: ((_ hud: HUD) -> Void)?

    private lazy var keyboardGuideView = UIView(frame: bounds)
    private var constraint: EdgeConstraint?
    private var isFinished: Bool = false
    private var showStarted: Date?

    // MARK: - Lifecycle

    /// A convenience constructor that initializes the HUD with the `view's bounds`.
    /// Calls the designated constructor with `view.bounds` as the parameter.
    ///
    /// - Parameter view: The view instance that will provide the `bounds` for the HUD.
    ///                   Should be the same instance as the HUD's superview (i.e., the view that the HUD will be added to).
    public convenience init(with view: UIView) {
        self.init(frame: view.bounds)
    }

    /// Common initialization method, allowing overriding
    open override func commonInit() {
        isOpaque = false // Transparent background
        backgroundColor = .clear
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.allowsGroupOpacity = false
        setupViews()
        isHidden = true // Make it invisible for now
#if !os(tvOS)
        updateKeyboardObserver()
        registerForNotifications()
#endif
    }

    deinit {
        cancelHideDelayWorkItem()
        cancelGraceWorkItem()
        cancelMinShowWorkItem()
#if !os(tvOS)
        KeyboardObserver.shared.remove(self)
        unregisterFromNotifications()
#endif
#if DEBUG
        print("👍👍👍 HUD is released.")
#endif
    }

    // MARK: - Show & hide

    /// A Boolean value that determines whether the view is hidden.
    open override var isHidden: Bool {
        didSet {
            contentView.isHidden = isHidden
        }
    }

    /// Find all unfinished HUD subviews and return them.
    ///
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
    ///
    /// - Parameter view: The view that is going to be searched.
    /// - Returns: A reference to the last HUD subview discovered.
    public class func lastHUD(for view: UIView) -> HUD? {
        for case let hud as HUD in view.subviews.reversed() where hud.isFinished == false {
            return hud
        }
        return nil
    }

    /// Creates a new HUD. adds it to provided view and shows it. And auto hides the HUD after a duration.
    ///
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - duration: The total duration of the show, measured in seconds. Duration must be greater than 0.0. `Default to 2.0`.
    ///   - animated: If set to true the HUD will appear using the default animation.
    ///               If set to false the HUD will not use animations while appearing. `Default to true`.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    ///            If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.
    ///   - offset: The contentView offset relative to the center of the view. You can use `.h.maxOffset` to move the HUD
    ///             all the way to the screen edge in each direction. `Default to .zero`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: Default animation `HUD.Animation(style:.fade,duration:0.3,damping:.disable)`
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func showStatus(
        to view: UIView,
        duration: TimeInterval = 2.0,
        animated: Bool = true,
        mode: ContentView.Mode = .text,
        label: String?,
        offset: CGPoint = .zero,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        showStatus(
            to: view,
            duration: duration,
            using: animated ? .init() : .init(style: .none),
            mode: mode,
            label: label,
            offset: offset,
            populator: populator)
    }

    /// Creates a new HUD. adds it to provided view and shows it. And auto hides the HUD after a duration.
    ///
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - duration: The total duration of the show, measured in seconds. Duration must be greater than 0.0. `Default to 2.0`.
    ///   - animation: Use HUD.Animation.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    ///            If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.
    ///   - offset: The contentView offset relative to the center of the view. You can use `.maxOffset` to move the HUD all the way to
    ///             the screen edge in each direction. `Default to .vMaxOffset`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func showStatus(
        to view: UIView,
        duration: TimeInterval = 2.0,
        using animation: Animation,
        mode: ContentView.Mode = .text,
        label: String?,
        offset: CGPoint = .h.vMaxOffset,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        show(to: view, using: animation, mode: mode, label: label) {
            $0.layout.offset = offset
            populator?($0)
        }.h.then {
            $0.removeFromSuperViewOnHide = true
            $0.hide(using: animation, afterDelay: duration)
        }
    }

    /// Creates a new HUD. adds it to provided view and shows it. The counterpart to this method is `hide(for:using:)`.
    ///
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - animated: If set to true the HUD will appear using the default animation. If set to false the HUD will not use animations while appearing. `Default to true`.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    ///            If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.  `Default to nil`.
    ///   - detailsLabel: An optional details message displayed below the labelText message. The details text can span multiple lines.  `Default to nil`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: Default animation `HUD.Animation(style:.fade,duration:0.3,damping:.disable)`
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func show(
        to view: UIView,
        animated: Bool = true,
        mode: ContentView.Mode = .indicator(),
        label: String? = nil,
        detailsLabel: String? = nil,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        show(to: view,
             using: animated ? .init() : .init(style: .none),
             mode: mode,
             label: label,
             detailsLabel: detailsLabel,
             populator: populator)
    }

    /// Creates a new HUD. adds it to provided view and shows it. The counterpart to this method is `hide(for:using:)`.
    ///
    /// - Parameters:
    ///   - view: The view that the HUD will be added to
    ///   - animation: Use HUD.Animation.
    ///   - mode: HUD operation mode. `Default to .indicator(.large)`.
    ///   - label: An optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    ///            If the text is too long it will get clipped by displaying "..." at the end. If left unchanged or set to "", then no message is displayed.  `Default to nil`.
    ///   - detailsLabel: An optional details message displayed below the labelText message. The details text can span multiple lines.  `Default to nil`.
    ///   - populator: A block or function that populates the `HUD`, which is passed into the block as an argument. `Default to nil`.
    /// - Returns: A reference to the created HUD.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    @discardableResult
    public class func show(
        to view: UIView,
        using animation: Animation,
        mode: ContentView.Mode = .indicator(),
        label: String? = nil,
        detailsLabel: String? = nil,
        populator: ((HUD) -> Void)? = nil
    ) -> HUD {
        HUD(with: view).h.then { // Creates a new HUD
            $0.animation = animation
            $0.contentView.mode = mode
            $0.contentView.label.text = label
            $0.contentView.detailsLabel.text = detailsLabel
            populator?($0)
            view.addSubview($0)
            $0.removeFromSuperViewOnHide = true
            $0.show(using: $0.animation)
        }
    }

    /// Finds the `top-most` HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:using:...)`.
    ///
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animated: If set to true the HUD will disappear using the current animation. If set to false the HUD will not use animations while disappearing. `Default to true`.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if a HUD was found and removed, false otherwise.
    /// - SeeAlso: HUD.Animation.
    @discardableResult
    public class func hide(for view: UIView, animated: Bool = true, afterDelay delay: TimeInterval = 0.0) -> Bool {
        hide(for: view, using: animated ? nil : .init(style: .none), afterDelay: delay)
    }

    /// Finds the `top-most` HUD subview that hasn't finished and hides it. The counterpart to this method is `show(to:using:...)`.
    ///
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if a HUD was found and removed, false otherwise.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD.
    ///         The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    @discardableResult
    public class func hide(for view: UIView, using animation: Animation?, afterDelay delay: TimeInterval = 0.0) -> Bool {
        guard let hud = lastHUD(for: view) else { return false }
        hud.removeFromSuperViewOnHide = true
        hud.hide(using: animation, afterDelay: delay)
        return true
    }

    /// Find all unfinished HUD subviews and hide them. The counterpart to this method is `show(to:using:...)`.
    ///
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animated: If set to true the HUD will disappear using the current animation. If set to false the HUD will not use animations while disappearing. `Default to true`.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if one or more HUDs were found and removed, false otherwise.
    /// - SeeAlso: HUD.Animation.
    @discardableResult
    public class func hideAll(for view: UIView, animated: Bool = true, afterDelay delay: TimeInterval = 0.0) -> Bool {
        hideAll(for: view, using: animated ? nil : .init(style: .none), afterDelay: delay)
    }

    /// Find all unfinished HUD subviews and hide them. The counterpart to this method is `show(to:using:...)`.
    ///
    /// - Parameters:
    ///   - view: The view that is going to be searched for a HUD subview.
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Returns: true if one or more HUDs were found and removed, false otherwise.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD.
    ///         The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    @discardableResult
    public class func hideAll(for view: UIView, using animation: Animation?, afterDelay delay: TimeInterval = 0.0) -> Bool {
        let huds = huds(for: view)
        huds.forEach {
            $0.removeFromSuperViewOnHide = true
            $0.hide(using: animation, afterDelay: delay)
        }
        return huds.isEmpty == false
    }

    /// Displays the HUD.
    ///
    /// - Parameter animated: If set to true the HUD will appear using the current animation. If set to false the HUD will not use animations while appearing. `Default to true`.
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated.
    ///         Call this method when your task is already set up to be executed in a new thread (e.g., when using something like Operation or making an asynchronous call like URLRequest).
    /// - SeeAlso: HUD.Animation.
    public func show(animated: Bool = true) {
        show(using: animated ? nil : .init(style: .none))
    }

    /// Displays the HUD.
    ///
    /// - Parameter animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    /// - Note: You need to make sure that the main thread completes its run loop soon after this method call so that the user interface can be updated.
    ///         Call this method when your task is already set up to be executed in a new thread (e.g., when using something like Operation or making an asynchronous call like URLRequest).
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD. The activity count is decremented by 1 when hiding the HUD.
    public func show(using animation: Animation?) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")
        show(animation ?? self.animation)
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    ///
    /// - Parameters:
    ///   - animated: If set to true the HUD will disappear using the current animation. If set to false the HUD will not use animations while disappearing. `Default to true`.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - SeeAlso: HUD.Animation.
    public func hide(animated: Bool = true, afterDelay delay: TimeInterval = 0.0) {
        hide(using: animated ? nil : .init(style: .none), afterDelay: delay)
    }

    /// Hides the HUD. This still calls the `hudWasHidden(:)` delegate. This is the counterpart of the show: method. Use it to hide the HUD when your task completes.
    ///
    /// - Parameters:
    ///   - animation: Use HUD.Animation. Priority greater than the current animation. If set to `nil` the HUD uses the animation of its member property.
    ///   - delay: Hides the HUD after a delay. Delay in seconds until the HUD is hidden. `Default to 0.0`.
    /// - Note: If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD.
    ///         The activity count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
    public func hide(using animation: Animation?, afterDelay delay: TimeInterval = 0.0) {
        assert(Thread.isMainThread, "HUD needs to be accessed on the main thread.")
        hide(animation ?? self.animation, afterDelay: delay)
    }

    private func show(_ animation: Animation) {
        // If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD.
        // The activity count is decremented by 1 when hiding the HUD.
        if isCountEnabled {
            count += 1
        }

        isFinished = false
        cancelMinShowWorkItem()
        cancelGraceWorkItem() // Modified grace time to 0 and show again
        cancelHideDelayWorkItem() // Cancel any scheduled hide(using:afterDelay:) calls

        // If the grace time is set, postpone the HUD display
        guard graceTime > 0.0 else {
            return performShow(animation) // ... otherwise show the HUD immediately
        }

        let workItem = DispatchWorkItem { [weak self] in
            // Show the HUD only if the task is still running
            guard let `self` = self, isFinished == false else { return }
            performShow(animation)
        }
        graceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + graceTime, execute: workItem)
    }

    private func performShow(_ animation: Animation) {
        // Cancel any previous animations
        contentView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()

        showStarted = Date()
        isHidden = false

        update(constraints: false, keyboardGuide: true)
        perform(animation, showing: true, completion: nil)
    }

    private func hide(_ animation: Animation, afterDelay delay: TimeInterval) {
        // If `isCountEnabled` is set to true, the activity count is incremented by 1 when showing the HUD.  The activity
        // count is decremented by 1 when hiding the HUD. Hide HUD if count reaches 0. Returns if count has not reached 0.
        if isCountEnabled {
            count -= 1
            if count > 0 { return }
        }

        // Hides the HUD after a delay. Delay in seconds until the HUD is hidden.
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
        // This needs to happen here instead of in done, to avoid races if another
        // hide(using:afterDelay:) call comes in while the HUD is animating out.
        cancelHideDelayWorkItem()
        perform(animation, showing: false) { [self] in
            cancelHideDelayWorkItem() // Cancel any scheduled hide(using:afterDelay:) calls

            if isFinished {
                isHidden = true
                if removeFromSuperViewOnHide {
                    removeFromSuperview()
                }
            } else {
                assertionFailure("why?")
            }

            completionBlock?(self)
            delegate?.hudWasHidden(self)
        }
        showStarted = nil
    }

    private func perform(_ animation: Animation, showing: Bool, completion: (() -> Void)?) {
        let alpha: CGFloat = showing ? 1.0 : 0.0
        let completionBlock: (Bool) -> Void = { [self] _ in
            contentView.alpha = alpha
            backgroundView.alpha = alpha
            contentView.transform = .identity // Reset after the animation is completed
            completion?()
        }

        guard animation.style != .none, showStarted != nil else { return completionBlock(true) }

        let style = animation.style.corrected(showing) // Automatically determine the correct animation style

        // Set starting state
        if showing && contentView.alpha == 0.0 {
            setTransform(to: style.reversed ?? style)
        }

        UIView.animate(withDuration: animation.duration, delay: 0.0,
                       usingSpringWithDamping: animation.damping.value,
                       initialSpringVelocity: 0.0,
                       options: .beginFromCurrentState,
                       animations: { [self] in
            setTransform(to: showing ? .fade : style)
            contentView.alpha = alpha
            backgroundView.alpha = alpha
        }, completion: completionBlock)
    }

    private func setTransform(to style: Animation.Style) {
        switch style {
        case .zoomIn:
            contentView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        case .zoomOut:
            contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        case .slideUp:
            layoutIfNeeded()
            contentView.transform = CGAffineTransform(translationX: 0.0, y: bounds.minY - contentView.frame.maxY)
        case .slideDown:
            layoutIfNeeded()
            contentView.transform = CGAffineTransform(translationX: 0.0, y: bounds.maxY - contentView.frame.minY)
        case .slideRight:
            layoutIfNeeded()
            contentView.transform = CGAffineTransform(translationX: bounds.maxX - contentView.frame.minX, y: 0.0)
        case .slideLeft:
            layoutIfNeeded()
            contentView.transform = CGAffineTransform(translationX: bounds.minX - contentView.frame.maxX, y: 0.0)
        default:
            contentView.transform = .identity
        }
    }

    // MARK: Cancel Dispatch Work Item

    private var graceWorkItem, minShowWorkItem, hideDelayWorkItem: DispatchWorkItem?
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

    // MARK: UI

    private func setupViews() {
        addSubview(backgroundView.h.then {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.alpha = 0.0
        })
        addSubview(keyboardGuideView.h.then {
            $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            $0.backgroundColor = .clear
        })
        keyboardGuideView.addSubview(contentView.h.then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isHidden = true
            $0.alpha = 0.0
            $0.delegate = self
        })
    }

    // MARK: Layout constraint

    func layoutConstraintsDidChange(from contentView: ContentView) {
        update(constraints: false, keyboardGuide: true)
    }

    private func update(constraints: Bool, keyboardGuide: Bool) {
        guard let constraint = constraint else { return }

        if constraints {
            constraint.update(offset: layout.offset, edge: layout.edgeInsets)
        }
#if !os(tvOS)
        if keyboardGuide {
            guard isKeyboardGuideEnabled, let keyboardInfo = KeyboardObserver.shared.keyboardInfo else { return }
            updateKeyboardGuide(with: keyboardInfo, animated: false)
        }
#endif
    }

    // MARK: View Hierarchy

    open override func didMoveToSuperview() {
        guard superview != nil else { return }
        updateForCurrentOrientation()

        guard constraint == nil else { return }
        constraint = EdgeConstraint(contentView, to: self,
                                    useSafeGuide: layout.isSafeAreaLayoutGuideEnabled,
                                    center: .init(995.0), edge: .init(1000.0))
        update(constraints: true, keyboardGuide: false)
    }

    @objc
    private func updateForCurrentOrientation() {
        guard let superview = superview else { return }
        frame = superview.bounds // Stay in sync with the superview in any case
    }

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard isEventDeliveryEnabled else { return hitView }

        let contentViewRect = contentView.convert(contentView.bounds, to: self)
        return contentViewRect.contains(point) ? hitView : nil
    }
}

#if !os(tvOS)
extension HUD: KeyboardObservable {
    // MARK: - Notifications
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateForCurrentOrientation),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil)
    }

    private func unregisterFromNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Keyboard Guide

    private static func updateKeyboardObserver() {
        guard keyboardGuide != .disable else { return }
        KeyboardObserver.enable() // Enable keyboard observation
    }

    private func updateKeyboardObserver() {
        guard isKeyboardGuideEnabled else {
            return KeyboardObserver.shared.remove(self)
        }
        KeyboardObserver.shared.add(self)
    }

    private var isKeyboardGuideEnabled: Bool {
        (keyboardGuide == .disable || (keyboardGuide == nil && HUD.keyboardGuide == .disable)) == false
    }

    public func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo) {
        guard isKeyboardGuideEnabled else {
            return KeyboardObserver.shared.remove(self)
        }
        updateKeyboardGuide(with: keyboardInfo, animated: true)
    }

    private func updateKeyboardGuide(with keyboard: KeyboardInfo, animated: Bool) {
        guard isHidden == false else { return }

        let animations: () -> Void = { [self] in
            let keyboardGuide = keyboardGuide ?? HUD.keyboardGuide

            guard keyboard.isVisible && keyboardGuide != .disable else {
                return keyboardGuideView.transform = .identity
            }

            layoutIfNeeded()

            let topSafeArea = safeAreaInsets.top
            var frameToWindow = bounds
            if let window = UIApplication.shared.delegate?.window {
                frameToWindow = convert(frameToWindow, to: window)
            }

            if case let .center(offsetY) = keyboardGuide {
                var y = (keyboard.frameEnd.minY - topSafeArea - frameToWindow.minY) / 2.0 + topSafeArea + offsetY
                if (y - contentView.bounds.midY) < 0.0 {
                    y = contentView.bounds.midY
                }
                keyboardGuideView.transform = CGAffineTransform(translationX: 0.0, y: -max(contentView.frame.midY - y, 0.0))
            } else if case let .bottom(spacing) = keyboardGuide {
                let y = max(keyboard.frameEnd.minY - contentView.bounds.height - frameToWindow.minY - spacing, 0.0)
                keyboardGuideView.transform = CGAffineTransform(translationX: 0.0, y: -max(contentView.frame.minY - y, 0.0))
            }
        }

        guard animated else {
            return animations()
        }
        let options = AnimationOptions.beginFromCurrentState.union(.init(rawValue: keyboard.animationCurve << 16))
        UIView.animate(withDuration: keyboard.animationDuration, delay: 0.0, options: options, animations: animations)
    }
}
#endif
