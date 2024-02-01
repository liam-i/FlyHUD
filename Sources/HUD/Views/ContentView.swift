//
//  ContentView.swift
//  LPHUD
//
//  Created by liam on 2024/1/31.
//

import UIKit

extension ContentView {
    public enum Mode: Equatable {
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

    public struct Layout: Equatable {
        /// The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        public var hMargin: CGFloat
        /// The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        public var vMargin: CGFloat

        /// The space between HUD elements (labels, indicators or custom views). Defaults to 4.0.
        public var spacing: CGFloat

        /// The minimum size of the HUD contentView. Defaults to CGSize.zero (no minimum size).
        public var minSize: CGSize

        /// Force the HUD dimensions to be equal if possible.
        public var isSquare: Bool

        /// Creates a new Layout.
        /// - Parameters:
        ///   - offset: The contentView offset relative to the center of the view. You can use `.maxOffset` and `-.maxOffset` to move
        ///             the HUD all the way to the screen edge in each direction. `Default to .zero`
        ///   - edgeInsets: This also represents the minimum contentView distance to the edge of the HUD.
        ///                 Defaults to UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0).
        ///   - hMargin: The horizontal amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        ///   - vMargin: The vertical amount of space between the HUD edge and the HUD elements (labels, indicators or custom views). Defaults to 20.0.
        ///   - spacing: The space between HUD elements (labels, indicators or custom views). Defaults to 4.0.
        ///   - minSize: The minimum size of the HUD contentView. Defaults to CGSize.zero (no minimum size).
        ///   - isSquare: Force the HUD dimensions to be equal if possible.
        ///   - isSafeAreaLayoutGuideEnabled: The layout guide representing the portion of your view that is unobscured by bars and other content.
        public init(hMargin: CGFloat = 20.0,
                    vMargin: CGFloat = 20.0,
                    spacing: CGFloat = 4.0,
                    minSize: CGSize = .zero,
                    isSquare: Bool = false) {
            self.hMargin = hMargin
            self.vMargin = vMargin
            self.spacing = spacing
            self.minSize = minSize
            self.isSquare = isSquare
        }
    }
}
extension ContentView.Mode: HUDExtended {}
extension ContentView.Layout: HUDExtended {}

public class ContentView: BackgroundView, DisplayLinkDelegate {
    /// A label that holds an optional short message to be displayed below the activity indicator. The HUD is automatically resized to fit the entire text.
    public private(set) lazy var label: UILabel = Label(fontSize: 16.0, numberOfLines: 1, textColor: contentColor)
    /// A label that holds an optional details message displayed below the labelText message. The details text can span multiple lines.
    public private(set) lazy var detailsLabel: UILabel = Label(fontSize: 12.0, numberOfLines: 0, textColor: contentColor)
    /// A button that is placed below the labels. Visible only if a target / action is added and a title is assigned.
    public private(set) lazy var button = RoundedButton(fontSize: 12.0, textColor: contentColor)

    /// HUD operation mode. `Default to .indicator(.large)`.
    public lazy var mode: Mode = .indicator() {
        didSet {
            mode.h.notEqual(oldValue, do: updateIndicators())
        }
    }

    /// A color that gets forwarded to all labels and supported indicators. Also sets the tintColor for custom views.
    /// Set to nil to manage color individually. `Defaults to semi-translucent white`
    public var contentColor: UIColor? = .h.content {
        didSet {
            contentColor.h.notEqual(oldValue, do: updateViewsContentColor())
        }
    }

    /// HUD layout configuration. eg: offset, margin, padding, etc.
    public var layout: Layout = .init() {
        didSet {
            layout.h.notEqual(oldValue, do: updateConstraintsWithLayout())
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
    private lazy var vStackView = UIStackView(arrangedSubviews: [label, detailsLabel, button])
    private lazy var constraint = Constraint(vStackView, to: self)
    private var indicator: UIView?

    public override func commonInit() {
        clipsToBounds = true
        isHidden = true
        color = .h.background
        roundedCorners = .radius(5.0)
        style = .blur()

        setupViews()
        updateIndicators()
    }

    deinit {
        observedProgress = nil // 1. observedProgress = nil; 2. DisplayLink.shared.remove(self)
#if DEBUG
        print("👍👍👍 ContentView is released.")
#endif
    }

    private func setupViews() {
        addSubview(vStackView.h.then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .vertical
            $0.distribution = .fill
            $0.alignment = .center
            $0.spacing = layout.spacing
            $0.arrangedSubviews.forEach {
                $0.setContentCompressionResistancePriorityForAxis(998.0)
            }
        })
    }

    private func updateIndicators() {
        func setupIndicator(_ newValue: UIView?) {
            if let indicator = indicator {
                vStackView.removeArrangedSubview(indicator)
                indicator.removeFromSuperview()
            }
            if let newValue = newValue {
                vStackView.insertArrangedSubview(newValue, at: 0)
            }
            indicator = newValue
        }

        switch mode {
        case .text:
            setupIndicator(nil)
        case let .indicator(style): // Update to UIActivityIndicatorView
            if let indicator = indicator as? UIActivityIndicatorView {
                indicator.style = style
            } else {
                setupIndicator(UIActivityIndicatorView(style: style))
            }
        case let .progress(style): // Update to UIProgressView
            if let indicator = indicator as? iOSUIProgressView {
                indicator.progressViewStyle = style
            } else {
                setupIndicator(iOSUIProgressView(progressViewStyle: style))
            }
        case let .custom(view): // Update custom view indicator
            view.h.notEqual(indicator, do: setupIndicator(view))
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
        updateConstraintsWithLayout()
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

    private func updateConstraintsWithLayout() {
        vStackView.spacing = layout.spacing
        constraint.update(with: layout)
        delegate?.layoutConstraintsDidChange(from: self)
    }

    private class Constraint {
        let width, height, square: NSLayoutConstraint
        let top, left, bottom, right, x, y: NSLayoutConstraint

        init(_ stackView: UIView, to: UIView) {
            let work: (NSLayoutConstraint) -> Void = { $0.priority = .init(997.0) }
            (width, height, square, top, bottom, left, right, x, y) = (
                to.widthAnchor.constraint(greaterThanOrEqualToConstant: 0.0).h.then(work),
                to.heightAnchor.constraint(greaterThanOrEqualToConstant: 0.0).h.then(work),
                to.heightAnchor.constraint(equalTo: to.widthAnchor).h.then(work),

                stackView.topAnchor.constraint(greaterThanOrEqualTo: to.topAnchor),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: to.bottomAnchor),
                stackView.leadingAnchor.constraint(greaterThanOrEqualTo: to.leadingAnchor),
                stackView.trailingAnchor.constraint(lessThanOrEqualTo: to.trailingAnchor),
                stackView.centerXAnchor.constraint(equalTo: to.centerXAnchor),
                stackView.centerYAnchor.constraint(equalTo: to.centerYAnchor))
            NSLayoutConstraint.activate([top, bottom, left, right, x, y])
        }

        func update(with layout: Layout) {
            (width.constant, height.constant, top.constant, bottom.constant, left.constant, right.constant) = (
                layout.minSize.width, layout.minSize.height,
                layout.vMargin, -layout.vMargin, layout.hMargin, -layout.hMargin)

            width.isActive = layout.minSize != .zero
            height.isActive = width.isActive
            square.isActive = layout.isSquare // Square aspect ratio, if set
        }
    }
}

// MARK: - Internal extension

extension RoundedButton {
    fileprivate convenience init(fontSize: CGFloat, textColor: UIColor?) {
        self.init(type: .custom)
        self.titleLabel?.textAlignment = .center
        self.titleLabel?.font = .boldSystemFont(ofSize: fontSize)
        self.setTitleColor(textColor, for: .normal)
    }
}

// MARK: - Internal protocol

protocol ContentViewDelegate: AnyObject {
    func layoutConstraintsDidChange(from contentView: ContentView)
}
