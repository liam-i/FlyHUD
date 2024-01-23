//
//  ActivityIndicatorView.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit
#if canImport(HUD)
import HUD
#endif

/// The visual style of the activity indicator.
public protocol ActivityIndicatorViewStyleable {
    /// Returns a Boolean value that indicates whether the receiver and a given object are equal.
    /// - Parameter object: The object to be compared to the receiver.
    /// - Returns: true if the receiver and object are equal, otherwise false.
    func isEqual(_ object: Any) -> Bool

    /// Creates an animation builder
    func makeAnimation() -> ActivityIndicatorAnimationBuildable

    /// Specifying the default size of the activity indicator view in its superview’s coordinates.
    var defaultSize: CGSize { get }
    /// The default color of the activity indicator.
    var defaultColor: UIColor { get }
    /// The default track color of the activity indicator.
    var defaultTrackColor: UIColor? { get }
    /// The default line width of the activity indicator.
    var defaultLineWidth: CGFloat { get }
}

extension ActivityIndicatorViewStyleable {
    public var defaultSize: CGSize { CGSize(width: 37.0, height: 37.0) }
    public var defaultColor: UIColor { .HUDContent }
    public var defaultTrackColor: UIColor? { defaultColor.withAlphaComponent(0.1) }
    public var defaultLineWidth: CGFloat { 2.0 }
}

extension ActivityIndicatorView {
    /// The visual style of the activity indicator.
    /// - Note: You set the value of the style property with these constants.
    public enum Style: Equatable, CaseIterable, ActivityIndicatorViewStyleable {
        case ringClipRotate
        case ballSpinFade
        case circleStrokeSpin
        case circleArcDotSpin

        public func isEqual(_ object: Any) -> Bool {
            self == object as? ActivityIndicatorView.Style
        }

        public func makeAnimation() -> ActivityIndicatorAnimationBuildable {
            switch self {
            case .ringClipRotate:
                return ActivityIndicatorAnimation.RingClipRotate()
            case .ballSpinFade:
                return ActivityIndicatorAnimation.BallSpinFade()
            case .circleStrokeSpin:
                return ActivityIndicatorAnimation.CircleStrokeSpin()
            case .circleArcDotSpin:
                return ActivityIndicatorAnimation.CircleArcDotSpin()
            }
        }
    }
}

/// A view that shows that a task is in progress.
/// - Note: You control when an activity indicator animates by calling the startAnimating() and stopAnimating() methods. To automatically hide the activity indicator when animation stops, set the hidesWhenStopped property to true. You can set the color of the activity indicator by using the color property.
public class ActivityIndicatorView: BaseView, ActivityIndicatorViewable {
    /// The basic appearance of the activity indicator view. The value of this property is a constant that specifies the style of the activity indicator view.
    /// - Note: After style is changed, it will switch to the default style. E.g: color, line width, etc.
    /// - SeeAlso: For more on these constants, see ActivityIndicatorView.Style.
    public var style: ActivityIndicatorViewStyleable = Style.ringClipRotate {
        didSet {
            guard style.isEqual(oldValue) == false else { return }
            updateProperties()
        }
    }

    /// The color of the activity indicator.
    /// - Note: If you set a color for an activity indicator, it overrides the color provided by the style property.
    public lazy var color: UIColor! = style.defaultColor {
        didSet {
            color.notEqual(oldValue, do: makeAnimationIfNeeded())
        }
    }
    /// The track color of the activity indicator.
    public lazy var trackColor: UIColor? = style.defaultTrackColor {
        didSet {
            trackColor.notEqual(oldValue, do: makeAnimationIfNeeded())
        }
    }
    /// The line width of the activity indicator.
    public lazy var lineWidth: CGFloat = style.defaultLineWidth {
        didSet {
            lineWidth.notEqual(oldValue, do: makeAnimationIfNeeded())
        }
    }
    /// A Boolean value that controls whether the activity indicator is hidden when the animation is stopped.
    /// - Note: If the value of this property is true (the default), the receiver sets its isHidden property (UIView) to true when receiver is not animating. If the hidesWhenStopped property is false, the receiver is not hidden when animation stops. You stop an animating activity indicator with the stopAnimating() method.
    public lazy var hidesWhenStopped: Bool = true

    /// A Boolean value indicating whether the activity indicator is currently running its animation.
    public private(set) var isAnimating: Bool = false

    /// Creates an activity indicator view with the specified style.
    /// - Parameters:
    ///   - style: A constant that specifies the style of the object to be created. See ActivityIndicatorView.Style for descriptions of the style constants.
    ///   - size: Specifying the size of the activity indicator view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ActivityIndicatorView`, which is passed into the block as an argument.
    /// - Returns: An initialized ActivityIndicatorView object.
    public convenience init(style: Style, size: CGSize = .zero, populator: ((ActivityIndicatorView) -> Void)? = nil) {
        self.init(styleable: style, size: size, populator: populator)
    }

    /// Creates an activity indicator view with the specified style.
    /// - Parameters:
    ///   - styleable: A constant that specifies the style of the object to be created.
    ///   - size: Specifying the size of the activity indicator view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ActivityIndicatorView`, which is passed into the block as an argument.
    /// - Returns: An initialized ActivityIndicatorView object.
    public convenience init(styleable: ActivityIndicatorViewStyleable, size: CGSize = .zero, populator: ((ActivityIndicatorView) -> Void)? = nil) {
        self.init(frame: CGRect(origin: .zero, size: size))
        self.style = styleable
        populator?(self)
    }

    public override func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        isHidden = true
        registerForTraitChanges()
    }

    deinit {
#if DEBUG
        print("👍👍👍 ActivityIndicatorView is released.")
#endif
    }

    /// Starts the animation of the activity indicator.
    /// - Note: When the activity indicator is animated, the gear spins to indicate indeterminate progress. The indicator is animated until stopAnimating() is called.
    public func startAnimating() {
        guard isAnimating == false else { return }
        isHidden = false
        isAnimating = true
        layer.speed = 1
        makeAnimation()
    }

    /// Stops the animation of the activity indicator.
    /// - Note: Call this method to stop the animation of the activity indicator started with a call to startAnimating(). When animating is stopped, the indicator is hidden, unless hidesWhenStopped is false.
    public func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false
        if hidesWhenStopped {
            isHidden = true
            layer.sublayers?.removeAll()
        } else {
            layer.sublayers?.forEach {
                $0.removeAnimation(forKey: ActivityIndicatorAnimation.key)
            }
        }
    }

    public override var intrinsicContentSize: CGSize {
        bounds.isEmpty ? style.defaultSize : bounds.size
    }

    public override var bounds: CGRect {
        didSet {
            guard oldValue != bounds && isAnimating else { return }
            invalidateIntrinsicContentSize()
            makeAnimation() // setup the animation again for the new bounds
        }
    }

    private var windowIsNil: Bool = false
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return windowIsNil = true }
        guard windowIsNil else { return }
        windowIsNil = false
        makeAnimation()
    }

    private func updateProperties() {
        frame.size = style.defaultSize
        color = style.defaultColor
        trackColor = style.defaultColor
        lineWidth = style.defaultLineWidth
        invalidateIntrinsicContentSize()
    }

    private func makeAnimation() {
        layer.sublayers = nil
        let animation = style.makeAnimation()
        animation.make(in: layer, color: color, trackColor: trackColor, lineWidth: lineWidth)
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 17.0, *) {
            // Use the trait change registration APIs
        } else {
            makeAnimationIfNeeded()
        }
    }

    private func registerForTraitChanges() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self], action: #selector(makeAnimationIfNeeded))
        }
    }

    @objc private func makeAnimationIfNeeded() {
        guard isAnimating else { return }
        makeAnimation() // setup the animation again for the new bounds
    }
}
