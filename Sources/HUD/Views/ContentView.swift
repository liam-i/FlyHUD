//
//  ContentView.swift
//  HUD <https://github.com/liam-i/HUD>
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
        /// Shows only labels and button.
        case text
        /// UIActivityIndicatorView. Style `Defalut to .large`.
        case indicator(UIActivityIndicatorView.Style = .h.large)
        /// UIProgressView.  Style `Defalut to .default`.
        case progress(UIProgressView.Style = .default)
        /// Shows a custom view. e.g. a UIImageView. The view should implement intrinsicContentSize
        /// for proper sizing. For best results use approximately 37 by 37 pixels.
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

        /// Whether UIProgressView or ProgressViewable.
        public var isProgress: Bool {
            if case .progress = self { return true }
            if case let .custom(view) = self, view is ProgressViewable { return true }
            return false
        }

        /// Not text, indicator and progress.
        public var isCustom: Bool {
            isText == false && isIndicator == false && isProgress == false
        }
    }

    public enum IndicatorPosition: Equatable, CaseIterable, HUDExtended {
        /// Inserts the given indicator on top of other views.
        case top
        /// Adds the given indicator to the bottom of other views.
        case bottom
        /// Inserts the given indicator to the left of other views.
        case left
        /// Adds the given indicator to the right of other views.
        case right
    }

    public enum Alignment: Equatable, CaseIterable {
        /// A layout where the stack view aligns the center of its arranged views with its center along its axis.
        case center
        /// A layout for vertical stacks where the stack view aligns the leading edge of its arranged views along its leading edge.
        case left
        /// A layout for vertical stacks where the stack view aligns the trailing edge of its arranged views along its trailing edge.
        case right

        fileprivate var valueOfStackView: UIStackView.Alignment {
            switch self {
            case .center:   return .center
            case .left:     return .leading
            case .right:    return .trailing
            }
        }

        fileprivate var valueOfText: NSTextAlignment {
            switch self {
            case .center:   return .center
            case .left:     return .left
            case .right:    return .right
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

/// The content view of the HUD object. The view containing the labels and indicator (or customView).
public class ContentView: BackgroundView, DisplayLinkDelegate {
    /// A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    public private(set) lazy var label: UILabel = Label(fontSize: 16.0, numberOfLines: 1, textColor: contentColor)
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public private(set) lazy var detailsLabel: UILabel = Label(fontSize: 12.0, numberOfLines: 0, textColor: contentColor)
    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public private(set) lazy var button = Button(fontSize: 12.0, textColor: contentColor)

    /// HUD operation mode. `Default to .indicator(.large)`.
    public var mode: Mode = .indicator() {
        didSet {
            mode.h.notEqual(oldValue, do: updateIndicators(false))
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
    /// Set to nil to manage color individually. `Defaults to semi-translucent white`
    public var contentColor: UIColor? = .h.content {
        didSet {
            contentColor.h.notEqual(oldValue, do: updateViewsContentColor())
        }
    }

    /// The progress of the progress indicator, from 0.0 to 1.0. `Defaults to 0.0`.
    public var progress: Float = 0.0 {
        didSet {
            progress.h.notEqual(oldValue, do: (indicator as? ProgressViewable)?.progress = progress)
        }
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

    public override func commonInit() {
        clipsToBounds = true
        isHidden = true
        color = .h.background
        roundedCorners = .radius(5.0)
        style = .blur()

        setupViews()
        updateIndicators(true)
        updateLayoutConstraints(true)
    }

    deinit {
        observedProgress = nil // 1.observedProgress = nil; 2.DisplayLink.shared.remove(self)
#if DEBUG
        print("👍👍👍 ContentView is released.")
#endif
    }

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
                setIndicator(UIActivityIndicatorView(style: style))
            }
        case let .progress(style): // Update to UIProgressView
            if let indicator = indicator as? iOSUIProgressView {
                indicator.progressViewStyle = style
            } else {
                setIndicator(iOSUIProgressView(progressViewStyle: style))
            }
        case let .custom(view): // Update custom view indicator
            view.h.notEqual(indicator, do: setIndicator(view))
        }

        if let indicator = indicator {
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
        guard let indicator = indicator else {
            return updateIndicators(false)
        }
        setIndicator(indicator)
        delegate?.layoutConstraintsDidChange(from: self)
    }

    private var indicator: UIView?
    private func setIndicator(_ newValue: UIView?) {
        if let oldValue = indicator {
            hStackView.removeArrangedSubview(oldValue)
            vStackView.removeArrangedSubview(oldValue)
            oldValue.removeFromSuperview()
        }
        if let newValue = newValue {
            switch indicatorPosition {
            case .top:      vStackView.insertArrangedSubview(newValue, at: 0)
            case .bottom:   vStackView.addArrangedSubview(newValue)
            case .left:     hStackView.insertArrangedSubview(newValue, at: 0)
            case .right:    hStackView.addArrangedSubview(newValue)
            }
        }
        indicator = newValue
    }

    private func updateViewsContentColor() {
        guard let contentColor = contentColor else { return } // If set to nil to manage color individually.

        label.textColor = contentColor
        detailsLabel.textColor = contentColor
        button.setTitleColor(contentColor, for: .normal)

        guard let indicator = indicator else { return }
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
        guard let progress = observedProgress, progress.fractionCompleted <= 1.0 else { return }
        // They can be customized or use the default text. To suppress one
        // (or both) of the labels, set the descriptions to empty strings.
        label.text = progress.localizedDescription
        detailsLabel.text = progress.localizedAdditionalDescription
    }

    // MARK: Motion effect

    private var motionEffectGroup: UIMotionEffectGroup?
    private func updateMotionEffects() {
        // Only set the motion effect while the contentView is visible to avoid
        // unnecessarily creating the effect if it is disabled after initialization.
        guard isMotionEffectsEnabled && isHidden == false else {
            if let motionEffects = motionEffectGroup {
                motionEffectGroup = nil
                removeMotionEffect(motionEffects)
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
        button.titleLabel?.textAlignment = label.textAlignment
        constraint.update(with: layout)

        guard isInitialized == false else { return }
        delegate?.layoutConstraintsDidChange(from: self)
    }

    private class Constraint {
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

protocol ContentViewDelegate: AnyObject {
    func layoutConstraintsDidChange(from contentView: ContentView)
}
