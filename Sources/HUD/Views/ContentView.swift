//
//  ContentView.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by liam on 2024/1/31.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

// MARK: - Model

extension ContentView {
    public enum Mode: Equatable, HUDExtended {
        /// Shows only labels and a button.
        case text
        /// UIActivityIndicatorView. Style `Defaults to .large`.
        case indicator(UIActivityIndicatorView.Style = .h.large)
        /// UIProgressView. Style `Defaults to .default`.
        case progress(UIProgressView.Style = .default)
        /// Shows a custom view. e.g. a UIImageView. The view should implement intrinsicContentSize
        /// for proper sizing. For best results use approximately 37 by 37 pixels.
        ///
        /// - Important: For VoiceOver accessibility, set `isAccessibilityElement = false` on your
        ///   custom view. ContentView acts as the single accessible element for the entire HUD,
        ///   providing combined label/value/traits. A custom view with its own accessibility
        ///   properties may cause duplicate or confusing VoiceOver announcements.
        case custom(UIView)

        /// Whether to show only labels and button.
        public var isText: Bool {
            self == .text
        }

        /// Whether it is UIActivityIndicatorView, ActivityIndicatorViewable or RotateViewable.
        public var isIndicator: Bool {
            if case .indicator = self { return true }
            if case let .custom(view) = self, (view is ActivityIndicatorViewable || view is RotateViewable) { return true }
            return false
        }

        /// Whether it is UIProgressView or ProgressViewable.
        public var isProgress: Bool {
            if case .progress = self { return true }
            if case let .custom(view) = self, view is ProgressViewable { return true }
            return false
        }

        /// Neither text, indicator, nor progress.
        public var isCustom: Bool {
            isText == false && isIndicator == false && isProgress == false
        }
    }

    public enum IndicatorPosition: Equatable, CaseIterable, HUDExtended {
        /// Inserts the given indicator on top of other views.
        case top
        /// Adds the given indicator to the bottom of other views.
        case bottom
        /// Inserts the given indicator to the leading of other views.
        case leading
        /// Adds the given indicator to the trailing of other views.
        case trailing
    }

    public enum Alignment: Equatable, CaseIterable {
        /// A layout where the stack view aligns the center of its arranged views with its center along its axis.
        case center
        /// A layout for vertical stacks where the stack view aligns the leading edge of its arranged views along its leading edge.
        case leading
        /// A layout for vertical stacks where the stack view aligns the trailing edge of its arranged views along its trailing edge.
        case trailing

        fileprivate var valueOfStackView: UIStackView.Alignment {
            switch self {
            case .center:   return .center
            case .leading:  return .leading
            case .trailing: return .trailing
            }
        }

        @MainActor fileprivate var valueOfText: NSTextAlignment {
            switch self {
            case .center:   return .center
            case .leading:  return UIView.isRTL ? .right : .left
            case .trailing: return UIView.isRTL ? .left : .right
            }
        }
    }

    public struct Layout: Equatable, HUDExtended {
        /// The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). `Defaults to 20.0`.
        public var hMargin: CGFloat
        /// The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). `Defaults to 20.0`.
        public var vMargin: CGFloat

        /// The horizontal space between HUD elements (labels, indicators or custom views). `Defaults to 8.0`.
        public var hSpacing: CGFloat
        /// The vertical space between HUD elements (labels, indicators or custom views). `Defaults to 4.0`.
        public var vSpacing: CGFloat

        /// The alignment of the arranged subviews perpendicular to the stack view’s axis. `Defaults to .center`.
        public var alignment: Alignment

        /// The minimum size of the HUD contentView. `Defaults to .zero (no minimum size)`.
        public var minSize: CGSize
        /// Force the HUD dimensions to be equal if possible. `Defaults to false`.
        public var isSquare: Bool

        /// Creates a new Layout.
        /// 
        /// - Parameters:
        ///   - hMargin: The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). `Defaults to 20.0`.
        ///   - vMargin: The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). `Defaults to 20.0`.
        ///   - hSpacing: The horizontal space between HUD elements (labels, indicators or custom views). `Defaults to 8.0`.
        ///   - vSpacing: The vertical space between HUD elements (labels, indicators or custom views). `Defaults to 4.0`.
        ///   - alignment: The alignment of the arranged subviews perpendicular to the stack view’s axis. `Defaults to .center`.
        ///   - minSize: The minimum size of the HUD contentView. `Defaults to .zero (no minimum size)`.
        ///   - isSquare: Force the HUD dimensions to be equal if possible. `Defaults to false`.
        public init(hMargin: CGFloat = 20.0,
                    vMargin: CGFloat = 20.0,
                    hSpacing: CGFloat = 8.0,
                    vSpacing: CGFloat = 4.0,
                    alignment: Alignment = .center,
                    minSize: CGSize = .zero,
                    isSquare: Bool = false) {
            self.hMargin = hMargin
            self.vMargin = vMargin
            self.hSpacing = hSpacing
            self.vSpacing = vSpacing
            self.alignment = alignment
            self.minSize = minSize
            self.isSquare = isSquare
        }
    }
}

// MARK: - ContentView

/// The content view of the HUD object. The view containing the labels, button and indicator (or customView).
/// The HUD object places the content in this view in front of any background views.
public class ContentView: BackgroundView, DisplayLinkDelegate {
    /// A label that holds an optional short message to be displayed below the indicator (or custom view). The HUD is automatically resized to fit the entire text.
    public private(set) lazy var label: UILabel = Label(fontSize: 16.0, numberOfLines: 1, textColor: contentColor)
    /// A label that holds an optional details message displayed below the label. The details text can span multiple lines.
    public private(set) lazy var detailsLabel: UILabel = Label(fontSize: 12.0, numberOfLines: 0, textColor: contentColor)
    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public private(set) lazy var button = Button(fontSize: 12.0, textColor: contentColor)

    /// HUD operation mode. `Defaults to .indicator(.large)`.
    public var mode: Mode = .indicator() {
        didSet {
            mode.h.notEqual(oldValue, do: {
                updateIndicators(false)
                // VoiceOver: Reset milestone tracking so a new progress session
                // always starts fresh, even if it begins in the same 25% bucket.
                lastAnnouncedMilestone = -1
                // VoiceOver: Notify that the HUD's content layout changed (e.g. indicator → progress)
                // so VoiceOver re-reads the updated traits and value.
                UIAccessibility.post(notification: .layoutChanged, argument: self)
            }())
        }
    }

    /// The horizontal and vertical position of the indicator relative to other views. `Defaults to .top`.
    public var indicatorPosition: IndicatorPosition = .top {
        didSet {
            indicatorPosition.h.notEqual(oldValue, do: updateIndicatorPosition())
        }
    }

    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layout: Layout = .init() {
        didSet {
            layout.h.notEqual(oldValue, do: updateLayoutConstraints(false))
        }
    }

    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views.
    /// Set to nil to manage color individually. `Defaults to .h.content (semi-translucent label color)`
    public var contentColor: UIColor? = .h.content {
        didSet {
            contentColor.h.notEqual(oldValue, do: updateViewsContentColor())
        }
    }

    /// Enables Dynamic Type support for all labels. When set to true, label fonts scale with the user's preferred content size.
    ///
    /// - Note: This is opt-in. Set to true to support accessibility text sizing.
    public var isDynamicTypeEnabled: Bool = false {
        didSet {
            (label as? Label)?.isDynamicTypeEnabled = isDynamicTypeEnabled
            (detailsLabel as? Label)?.isDynamicTypeEnabled = isDynamicTypeEnabled
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0. `Defaults to 0.0`.
    public var progress: Float = 0.0 {
        didSet {
            progress.h.notEqual(oldValue, do: {
                (indicator as? ProgressViewable)?.progress = progress
                // VoiceOver: Announce progress milestone from ContentView (the accessible element).
                // Covers both system UIProgressView and custom ProgressView modes.
                if mode.isProgress {
                    announceProgressMilestoneIfNeeded()
                }
            }())
        }
    }

    /// Tracks the last milestone that was announced via VoiceOver to prevent repeated announcements.
    /// Reset to -1 on initialization; milestones are integers 0–4 representing 0%, 25%, 50%, 75%, 100%.
    private var lastAnnouncedMilestone: Int = -1

    /// Posts a VoiceOver announcement when progress crosses a 25% threshold.
    ///
    /// This method is called from two paths:
    /// 1. Manual progress: `ContentView.progress` didSet (when user sets progress directly)
    /// 2. Observed progress: `updateScreenInDisplayLink()` (when using `observedProgress`)
    ///
    /// It reads from `observedProgress.fractionCompleted` when available (which tracks the real
    /// progress of a `Progress` object), falling back to the `progress` property for manual mode.
    /// This ensures correct percentage reporting regardless of the progress update mechanism.
    ///
    /// Announcements are throttled to 25% intervals (0%, 25%, 50%, 75%, 100%) to avoid
    /// overwhelming VoiceOver users with continuous updates during smooth progress animations.
    private func announceProgressMilestoneIfNeeded() {
        let value: Float
        if let observed = observedProgress {
            value = Float(observed.fractionCompleted)
        } else {
            value = progress
        }
        let clamped = max(0.0, min(value, 1.0))
        guard !clamped.isNaN, !clamped.isInfinite else { return }
        let milestone = Int(clamped * 4) // 0→0%, 1→25%, 2→50%, 3→75%, 4→100%
        guard milestone != lastAnnouncedMilestone else { return }
        lastAnnouncedMilestone = milestone
        UIAccessibility.post(notification: .announcement, argument: "\(Int(clamped * 100))%")
    }

    /// The Progress object feeding the progress information to the progress indicator.
    ///
    /// When this property is set, the progress view updates its progress value automatically using information it receives from the [Progress](https://developer.apple.com/documentation/foundation/progress) object.
    /// Set the property to nil when you want to update the progress manually. `Defaults to nil`.
    ///
    /// - Note: It will auto set localizedDescription and localizedAdditionalDescription to the text of label and detaillabel properties.
    ///         They can be customized or use the default text. To suppress one (or both) of the labels, set the descriptions to empty strings.
    public var observedProgress: Progress? {
        get { (indicator as? ProgressViewable)?.observedProgress }
        set {
            (indicator as? ProgressViewable)?.observedProgress = newValue
            updateObservedProgressDisplayLink()
        }
    }

    /// When enabled, the contentView center gets slightly affected by the device accelerometer data. `Defaults to false`.
    public var isMotionEffectsEnabled: Bool = false {
        didSet {
            isMotionEffectsEnabled.h.notEqual(oldValue, do: updateMotionEffects())
        }
    }

    weak var delegate: ContentViewDelegate?
    private lazy var hStackView = UIStackView(views: [vStackView], axis: .horizontal)
    private lazy var vStackView = UIStackView(views: [label, detailsLabel, button], axis: .vertical)
    private lazy var constraint = Constraint(hStackView, to: self)

    // MARK: - Lifecycle

    /// Common initialization method.
    public override func commonInit() {
        clipsToBounds = true
        isHidden = true
        color = .h.background
        roundedCorners = .radius(5.0)
        style = .blur()

        // VoiceOver: ContentView is the single accessibility element for the entire HUD.
        // All child views (Label, Button, ProgressView, ActivityIndicatorView) set
        // isAccessibilityElement = false to avoid duplicate announcements. This design
        // ensures VoiceOver reads one coherent description combining label, details,
        // progress value, and exposes button actions via accessibilityCustomActions.
        isAccessibilityElement = true

        setupViews()
        updateIndicators(true)
        updateLayoutConstraints(true)
    }

    /// Stored accessibility label override. When non-nil, takes priority over the
    /// computed label derived from `label.text` and `detailsLabel.text`.
    /// Use this to provide a custom VoiceOver description for custom indicator views
    /// that have no associated text labels (e.g., a checkmark image).
    private var storedAccessibilityLabel: String?

    /// VoiceOver: Combines `label` and `detailsLabel` into a single spoken description.
    /// For example: "Loading, Please wait..." — read as one element.
    /// If a custom label was explicitly set via the setter, it takes priority.
    /// Falls back to the custom indicator view's own accessibilityLabel when labels are empty.
    public override var accessibilityLabel: String? {
        get {
            // Priority 1: Explicitly set override
            if let stored = storedAccessibilityLabel {
                return stored
            }
            // Priority 2: Combined visible label text
            let text = [label.text, detailsLabel.text]
                .compactMap { $0?.isEmpty == false ? $0 : nil }
                .joined(separator: ", ")
            if !text.isEmpty {
                return text
            }
            // Priority 3: Custom view's own accessibilityLabel (useful for image-only HUDs)
            if case .custom(let view) = mode {
                return view.accessibilityLabel
            }
            return nil
        }
        set { storedAccessibilityLabel = newValue }
    }

    /// Stored accessibility hint override. When non-nil, takes priority over the computed hint.
    private var storedAccessibilityHint: String?

    /// VoiceOver: Provides contextual hint based on the current mode.
    /// Tells VoiceOver users what's happening (loading, progress) and how to dismiss.
    public override var accessibilityHint: String? {
        get {
            // Allow explicit override
            if let stored = storedAccessibilityHint {
                return stored
            }
            if mode.isIndicator {
                return NSLocalizedString("Loading in progress", comment: "VoiceOver hint for activity indicator HUD")
            }
            if mode.isProgress {
                return NSLocalizedString("Task in progress", comment: "VoiceOver hint for progress HUD")
            }
            return nil
        }
        set { storedAccessibilityHint = newValue }
    }

    /// Stored accessibility value override. When non-nil, takes priority over the computed value.
    private var storedAccessibilityValue: String?

    /// VoiceOver: Reports current progress percentage (e.g. "45%") when in progress mode.
    /// Returns nil for non-progress modes so VoiceOver does not read a stale value.
    /// Uses observedProgress when available, falls back to the manual `progress` property.
    public override var accessibilityValue: String? {
        get {
            if let stored = storedAccessibilityValue {
                return stored
            }
            if mode.isProgress {
                let value: Float
                if let observed = observedProgress {
                    value = Float(observed.fractionCompleted)
                } else {
                    value = progress
                }
                return "\(Int(max(0.0, min(value, 1.0)) * 100))%"
            }
            return nil
        }
        set { storedAccessibilityValue = newValue }
    }

    /// Stored accessibility traits override.
    private var storedAccessibilityTraits: UIAccessibilityTraits?

    /// VoiceOver: Uses `.updatesFrequently` for progress/indicator modes so VoiceOver
    /// knows the element's value may change (progress percentage updates).
    /// Falls back to `.staticText` for text-only modes (toasts, status messages).
    public override var accessibilityTraits: UIAccessibilityTraits {
        get {
            if let stored = storedAccessibilityTraits {
                return stored
            }
            if mode.isProgress { return .updatesFrequently }
            if mode.isIndicator { return .updatesFrequently }
            return .staticText
        }
        set { storedAccessibilityTraits = newValue }
    }

    /// VoiceOver: Exposes the HUD's action button as a custom action.
    /// Users can swipe up/down to discover and activate it (e.g. "Cancel" or "Retry").
    /// Only provided when the button has visible text and registered control events.
    public override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            guard !button.isEmptyOfText, button.allControlEvents.rawValue > 0 else { return nil }
            let title = button.title(for: .normal) ?? button.title(for: .selected) ?? ""
            guard !title.isEmpty else { return nil }
            return [UIAccessibilityCustomAction(name: title) { [weak self] _ in
                self?.button.sendActions(for: .touchUpInside)
                return true
            }]
        }
        set { super.accessibilityCustomActions = newValue }
    }

#if compiler(>=6.2)
    isolated deinit {
        observedProgress = nil // Clears observed progress and removes self from DisplayLink
#if DEBUG
        print("👍👍👍 ContentView is released.")
#endif
    }
#else
    deinit {
        MainActor.assumeIsolated {
            observedProgress = nil // Clears observed progress and removes self from DisplayLink
        }
#if DEBUG
        print("👍👍👍 ContentView is released.")
#endif
    }
#endif

    private func setupViews() {
        label.setContentCompressionResistancePriorityForAxis(997.0)
        detailsLabel.setContentCompressionResistancePriorityForAxis(996.0)
        button.setContentCompressionResistancePriorityForAxis(997.0)
        addSubview(hStackView)
    }

    private func updateIndicators(_ isInitialized: Bool) {
        switch mode {
        case .text:
            setIndicator(nil)
        case let .indicator(style): // Update to UIActivityIndicatorView
            if let indicator = indicator as? UIActivityIndicatorView {
                indicator.style = style
            } else {
                let activityIndicator = UIActivityIndicatorView(style: style)
                // VoiceOver: System UIActivityIndicatorView has isAccessibilityElement = true
                // by default with "In progress" label. Hide it to prevent duplicate announcements.
                activityIndicator.isAccessibilityElement = false
                setIndicator(activityIndicator)
            }
        case let .progress(style): // Update to UIProgressView
            if let indicator = indicator as? iOSUIProgressView {
                indicator.progressViewStyle = style
            } else {
                let progressIndicator = iOSUIProgressView(progressViewStyle: style)
                // VoiceOver: System UIProgressView has its own accessibility properties.
                // Hide it — ContentView reports progress via accessibilityValue.
                progressIndicator.isAccessibilityElement = false
                setIndicator(progressIndicator)
            }
        case let .custom(view): // Update custom view indicator
            // VoiceOver: Enforce hidden from accessibility on custom views to prevent
            // duplicate announcements. ContentView is the single accessible element.
            view.isAccessibilityElement = false
            view.h.notEqual(indicator, do: setIndicator(view))
        }

        // Re-evaluate DisplayLink subscription after indicator change.
        // If the new indicator is not ProgressViewable, observedProgress (computed) returns nil,
        // which removes self from DisplayLink — preventing a subscription leak.
        updateObservedProgressDisplayLink()

        if let indicator {
            indicator.setContentCompressionResistancePriorityForAxis(998.0)
            switch indicator {
            case let indicator as ActivityIndicatorViewable: indicator.startAnimating()
            case let indicator as ProgressViewable:          indicator.progress = progress
            case let indicator as RotateViewable:            indicator.startRotating()
            default: break
            }
        }

        updateViewsContentColor()

        guard isInitialized == false else { return }
        delegate?.layoutConstraintsDidChange(from: self)
    }

    private func updateIndicatorPosition() {
        guard let indicator else {
            return updateIndicators(false)
        }
        setIndicator(indicator)
        // Restart animation after repositioning (setIndicator stops it during removal)
        switch indicator {
        case let v as ActivityIndicatorViewable: v.startAnimating()
        case let v as RotateViewable:           v.startRotating()
        default: break
        }
        delegate?.layoutConstraintsDidChange(from: self)
    }

    private var indicator: UIView?
    private func setIndicator(_ newValue: UIView?) {
        if let oldValue = indicator {
            switch oldValue {
            case let v as ActivityIndicatorViewable: v.stopAnimating()
            case let v as RotateViewable:           v.stopRotating()
            default: break
            }
            hStackView.removeArrangedSubview(oldValue)
            vStackView.removeArrangedSubview(oldValue)
            oldValue.removeFromSuperview()
        }
        if let newValue {
            switch indicatorPosition {
            case .top:      vStackView.insertArrangedSubview(newValue, at: 0)
            case .bottom:   vStackView.addArrangedSubview(newValue)
            case .leading:  hStackView.insertArrangedSubview(newValue, at: 0)
            case .trailing: hStackView.addArrangedSubview(newValue)
            }
        }
        indicator = newValue
    }

    private func updateViewsContentColor() {
        guard let contentColor else { return } // If set to nil to manage color individually.

        label.textColor = contentColor
        detailsLabel.textColor = contentColor
        button.setTitleColor(contentColor, for: .normal)

        guard let indicator else { return }
        switch indicator {
        case let indicator as ActivityIndicatorViewable: indicator.color = contentColor
        case let indicator as ProgressViewable:          indicator.progressTintColor = contentColor
        default:                                         indicator.tintColor = contentColor // Sets the tintColor for custom views.
        }
    }

    // MARK: Observed progress

    public override var isHidden: Bool {
        didSet {
            indicator?.isHidden = isHidden
            updateMotionEffects()
            updateObservedProgressDisplayLink()
        }
    }

    private func updateObservedProgressDisplayLink() {
        // Only set the delegate while the contentView is visible to avoid
        // unnecessary creation of the object if it is disabled after initialization.
        guard observedProgress != nil && isHidden == false else {
            return DisplayLink.shared.remove(self)
        }
        DisplayLink.shared.add(self)
    }

    /// Refreshing the progress only every frame draw.
    public func updateScreenInDisplayLink() {
        guard let observedProgress else { return }
        // Update labels regardless of fractionCompleted bounds — the description
        // may contain useful text (e.g. "Complete") even when fraction > 1.0.
        label.text = observedProgress.localizedDescription
        detailsLabel.text = observedProgress.localizedAdditionalDescription
        // VoiceOver: Check if a milestone threshold was crossed during observed progress update.
        // Milestones only make sense within the valid [0, 1] range.
        if mode.isProgress,
           observedProgress.fractionCompleted >= 0.0,
           observedProgress.fractionCompleted <= 1.0 {
            announceProgressMilestoneIfNeeded()
        }
    }

    // MARK: Motion effect

    private var motionEffectGroup: UIMotionEffectGroup?
    private func updateMotionEffects() {
        // Only set the motion effect while the contentView is visible to avoid
        // unnecessarily creating the effect if it is disabled after initialization.
        guard isMotionEffectsEnabled && isHidden == false else {
            if let motionEffectGroup {
                self.motionEffectGroup = nil
                removeMotionEffect(motionEffectGroup)
            }
            return
        }
        guard motionEffectGroup == nil else { return }

        let effectOffset = 100.0
        addMotionEffect(UIMotionEffectGroup().h.then {
            $0.motionEffects = [
                UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis).h.then {
                    $0.maximumRelativeValue = effectOffset
                    $0.minimumRelativeValue = -effectOffset
                },
                UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis).h.then {
                    $0.maximumRelativeValue = effectOffset
                    $0.minimumRelativeValue = -effectOffset
                }
            ]
            motionEffectGroup = $0
        })
    }

    // MARK: - Layout constraint

    private func updateLayoutConstraints(_ isInitialized: Bool) {
        hStackView.spacing = layout.hSpacing
        vStackView.spacing = layout.vSpacing
        vStackView.alignment = layout.alignment.valueOfStackView
        label.textAlignment = layout.alignment.valueOfText
        detailsLabel.textAlignment = label.textAlignment
        constraint.update(with: layout)

        guard isInitialized == false else { return }
        delegate?.layoutConstraintsDidChange(from: self)
    }

    @MainActor private class Constraint {
        let width, height, square: NSLayoutConstraint
        let edge: EdgeConstraint

        init(_ stackView: UIView, to: UIView) {
            let toWork: (NSLayoutConstraint) -> Void = { $0.priority = .init(992.0) }
            (width, height, square) = (
                to.widthAnchor.constraint(greaterThanOrEqualToConstant: 0.0).h.then(toWork),
                to.heightAnchor.constraint(greaterThanOrEqualToConstant: 0.0).h.then(toWork),
                to.heightAnchor.constraint(equalTo: to.widthAnchor).h.then(toWork))
            edge = .init(stackView, to: to, useSafeGuide: false, center: .init(994.0), edge: .init(999.0))
        }

        func update(with layout: Layout) {
            (width.constant, height.constant) = (layout.minSize.width, layout.minSize.height)

            edge.update(hMargin: layout.hMargin, vMargin: layout.vMargin)

            width.isActive = layout.minSize != .zero
            height.isActive = width.isActive
            square.isActive = layout.isSquare // Square aspect ratio, if set
        }
    }
}

// MARK: - Internal extension

extension UIStackView {
    fileprivate convenience init(views: [UIView], axis: NSLayoutConstraint.Axis) {
        self.init(arrangedSubviews: views)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.axis = axis
        self.distribution = .fill
        self.alignment = .center
    }
}

// MARK: - Internal protocol

@MainActor protocol ContentViewDelegate: AnyObject {
    func layoutConstraintsDidChange(from contentView: ContentView)
}
