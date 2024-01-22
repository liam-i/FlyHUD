//
//  ProgressView.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit
#if canImport(HUD)
import HUD
#endif

/// The styles permitted for the progress bar.
public protocol ProgressViewStyleable {
    /// Returns a Boolean value that indicates whether the receiver and a given object are equal.
    /// - Parameter object: The object to be compared to the receiver.
    /// - Returns: true if the receiver and object are equal, otherwise false.
    func isEqual(_ object: Any) -> Bool

    /// Creates an animation builder
    func makeAnimation() -> ProgressAnimationBuildable

    /// Specifying the default size of the progress view in its superview’s coordinates.
    var defaultSize: CGSize { get }
    /// The default color shown for the portion of the progress bar that’s filled.
    var defaultProgressTintColor: UIColor { get }
    /// The default color shown for the portion of the progress bar that isn’t filled.
    var defaultTrackTintColor: UIColor? { get }
    /// The default width shown for the portion of the progress bar that’s filled.
    var defaultLineWidth: CGFloat { get }
}

extension ProgressViewStyleable {
    public var defaultSize: CGSize { .zero }
    public var defaultProgressTintColor: UIColor { .contentOfHUD }
    public var defaultTrackTintColor: UIColor? { defaultProgressTintColor.withAlphaComponent(0.1) }
    public var defaultLineWidth: CGFloat { 2.0 }
}

extension ProgressView {
    /// The styles permitted for the progress bar.
    /// - Note: You can retrieve the current style of progress view through the `ProgressView.style` property.
    public enum Style: CaseIterable, ProgressViewStyleable {
        /// A flat bar progress view. Display mode butt.
        case buttBar
        /// A flat bar progress view. Display mode round.
        case roundBar
        /// A round, pie-chart like, progress view.
        case round
        /// Ring-shaped progress view.
        case annularRound
        /// A pie progress view.
        case pie

        public func isEqual(_ object: Any) -> Bool {
            self == object as? ProgressView.Style
        }

        public func makeAnimation() -> ProgressAnimationBuildable {
            switch self {
            case .buttBar, .roundBar:   return ProgressAnimation.Bar(isRound: self == .roundBar)
            case .round, .annularRound: return ProgressAnimation.Round(isAnnular: self == .annularRound)
            case .pie:                  return ProgressAnimation.Pie()
            }
        }

        public var defaultSize: CGSize {
            switch self {
            case .buttBar, .roundBar:   return CGSize(width: 120.0, height: 10.0)
            case .round, .annularRound: return CGSize(width: 37.0, height: 37.0)
            case .pie:                  return CGSize(width: 37.0, height: 37.0)
            }
        }
    }
}

/// A view that depicts the progress of a task over time.
/// - Note: The ProgressView class provides properties for managing the style of the progress bar and for getting and setting values that are pinned to the progress of a task.
/// - Note: For an indeterminate progress indicator — or a “spinner” — use an instance of the ActivityIndicatorView class.
public class ProgressView: BaseView, ProgressViewable {
    /// The current graphical style of the progress view. The value of this property is a constant that specifies the style of the progress view.
    /// - Note: After style is changed, it will switch to the default style. E.g: color, line width, etc.
    /// - SeeAlso: For more on these constants, see ProgressView.Style.
    public var style: ProgressViewStyleable = Style.buttBar {
        didSet {
            guard style.isEqual(oldValue) == false else { return }
            updateProperties()
        }
    }

    /// The color shown for the portion of the progress bar that’s filled.
    public lazy var progressTintColor: UIColor? = style.defaultProgressTintColor {
        didSet {
            progressTintColor.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// The color shown for the portion of the progress bar that isn’t filled.
    public lazy var trackTintColor: UIColor? = style.defaultTrackTintColor {
        didSet {
            trackTintColor.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// The width shown for the portion of the progress bar that’s filled.
    public lazy var lineWidth: CGFloat = style.defaultLineWidth {
        didSet {
            lineWidth.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// The current progress of the progress view.
    /// - Note: 0.0 .. 1.0, default is 0.0. values outside are pinned.
    public var progress: Float = 0.0 {
        didSet {
            progress.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// The Progress object feeding the progress information to the progress indicator.
    /// - Note: When this property is set, the progress view updates its progress value automatically using information it receives from the [Progress](https://developer.apple.com/documentation/foundation/progress) object. Set the property to nil when you want to update the progress manually.  `Defaults to nil`.
    public var observedProgress: Progress? {
        didSet {
            observedProgress.notEqual(oldValue, do: updateProgressDisplayLink())
        }
    }

    /// The object that acts as the delegate of the progress view. The delegate must adopt the ProgressViewDelegate protocol.
    public weak var delegate: ProgressViewDelegate?

    private var animationBuilder: ProgressAnimationBuildable?

    /// Creates a progress view with the specified style.
    /// - Parameters:
    ///   - style: A constant that specifies the style of the object to be created. See ProgressView.Style for descriptions of the style constants.
    ///   - size: Specifying the size of the progress view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ProgressView`, which is passed into the block as an argument.
    /// - Returns: An initialized ProgressView object.
    public convenience init(style: Style, size: CGSize = .zero, populator: ((ProgressView) -> Void)? = nil) {
        self.init(styleable: style, size: size, populator: populator)
    }

    /// Creates a progress view with the specified style.
    /// - Parameters:
    ///   - style: A constant that specifies the style of the object to be created.
    ///   - size: Specifying the size of the progress view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ProgressView`, which is passed into the block as an argument.
    /// - Returns: An initialized ProgressView object.
    public convenience init(styleable: ProgressViewStyleable, size: CGSize = .zero, populator: ((ProgressView) -> Void)? = nil) {
        self.init(frame: CGRect(origin: .zero, size: size))
        self.style = styleable
        populator?(self)
    }

    public override func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }

    deinit {
#if DEBUG
        print("👍👍👍 ProgressView is released.")
#endif
    }

    public override func draw(_ rect: CGRect) {
        var animationBuilder: ProgressAnimationBuildable {
            if let builder = self.animationBuilder {
                return builder
            }

            let builder = style.makeAnimation()
            self.animationBuilder = builder
            return builder
        }

        animationBuilder.draw(
            progress: CGFloat(min(progress, 1.0)),
            in: layer,
            color: progressTintColor,
            trackColor: trackTintColor,
            lineWidth: lineWidth)
    }

    public override var bounds: CGRect {
        didSet {
            bounds.notEqual(oldValue, do: invalidateIntrinsicContentSize())
        }
    }

    private var windowIsNil: Bool = false
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return windowIsNil = true }
        guard windowIsNil else { return }
        windowIsNil = false
        setNeedsDisplay()
    }

    public override var intrinsicContentSize: CGSize {
        bounds.isEmpty ? style.defaultSize : bounds.size
    }

    private func updateProperties() {
        frame.size = style.defaultSize
        progressTintColor = style.defaultProgressTintColor
        trackTintColor = style.defaultTrackTintColor
        lineWidth = style.defaultLineWidth
        invalidateIntrinsicContentSize()
    }

    // MARK: Progress

    private class WeakProxy {
        private weak var target: ProgressView?

        init(_ target: ProgressView) {
            self.target = target
        }

        @objc func onScreenUpdate() {
            target?.updateProgressFromObservedProgress()
        }
    }

    public override var alpha: CGFloat {
        didSet {
            updateProgressDisplayLink()
        }
    }

    public override var isHidden: Bool {
        didSet {
            updateProgressDisplayLink()
        }
    }

    public override func didMoveToSuperview() {
        updateProgressDisplayLink()
    }

    private var observedProgressDisplayLink: CADisplayLink?
    private func updateProgressDisplayLink() {
        // We're using CADisplayLink, because Progress can change very quickly and observing it
        // may starve the main thread, so we're refreshing the progress only every frame draw
        let enabled = isHidden == false && alpha > 0.0 && superview != nil
        if enabled && observedProgress != nil {
            if observedProgressDisplayLink == nil { // Only create if not already active.
                let displayLink = CADisplayLink(target: WeakProxy(self), selector: #selector(WeakProxy.onScreenUpdate))
                displayLink.add(to: .main, forMode: .default)
                observedProgressDisplayLink = displayLink
            }
        } else {
            observedProgressDisplayLink?.invalidate()
            observedProgressDisplayLink = nil
        }
    }

    private func updateProgressFromObservedProgress() {
        guard let observedProgress = observedProgress else { return }
        progress = Float(observedProgress.fractionCompleted)
        delegate?.updateProgress(from: observedProgress)
    }
}
