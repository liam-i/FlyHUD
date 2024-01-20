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
    public enum Style: Equatable, ProgressViewStyleable {
        /// A flat bar progress view.
        /// - Parameter isRound: Display mode - false = square or true = round. Defaults to square.
        case bar(_ isRound: Bool = false)
        /// A progress view for showing definite progress by filling up a circle (pie chart)..
        /// - Parameter isRound: Display mode - false = round or true = annular. Defaults to round.
        case round(_ isAnnular: Bool = false)
        /// A pie progress view.
        case pie

        /// Creates an animation builder
        public func makeAnimation() -> ProgressAnimationBuildable {
            switch self {
            case .bar(let isRound):     return ProgressAnimation.Bar(isRound: isRound)
            case .round(let isAnnular): return ProgressAnimation.Round(isAnnular: isAnnular)
            case .pie:                  return ProgressAnimation.Pie()
            }
        }

        public var defaultSize: CGSize {
            switch self {
            case .bar:      return CGSize(width: 120.0, height: 10.0)
            case .round:    return CGSize(width: 37.0, height: 37.0)
            case .pie:      return CGSize(width: 37.0, height: 37.0)
            }
        }
    }
}

/// A view that depicts the progress of a task over time.
/// - Note: The ProgressView class provides properties for managing the style of the progress bar and for getting and setting values that are pinned to the progress of a task.
/// - Note: For an indeterminate progress indicator — or a “spinner” — use an instance of the ActivityIndicatorView class.
public class ProgressView: UIView, ProgressViewable {
    /// The current graphical style of the progress view.
    /// - Note: The value of this property is a constant that specifies the style of the progress view.
    /// - SeeAlso: For more on these constants, see ProgressView.Style.
    public let style: ProgressViewStyleable

    /// The current progress of the progress view.
    /// - Note: 0.0 .. 1.0, default is 0.0. values outside are pinned.
    public var progress: Float = 0.0 {
        didSet {
            progress.notEqual(oldValue, do: setNeedsDisplay())
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

    private var animationBuilder: ProgressAnimationBuildable?
    
    /// Creates a progress view with the specified style.
    /// - Parameters:
    ///   - style: A constant that specifies the style of the object to be created. See ProgressView.Style for descriptions of the style constants.
    ///   - size: Specifying the size of the progress view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ProgressView`, which is passed into the block as an argument.
    /// - Returns: An initialized ProgressView object.
    public convenience init(style: Style = .bar(), size: CGSize = .zero, populator: ((ProgressView) -> Void)? = nil) {
        self.init(styleable: style, size: size, populator: populator)
    }

    /// Creates a progress view with the specified style.
    /// - Parameters:
    ///   - style: A constant that specifies the style of the object to be created.
    ///   - size: Specifying the size of the progress view in its superview’s coordinates.
    ///   - populator: A block or function that populates the `ProgressView`, which is passed into the block as an argument.
    /// - Returns: An initialized ProgressView object.
    public init(styleable: ProgressViewStyleable, size: CGSize = .zero, populator: ((ProgressView) -> Void)? = nil) {
        self.style = styleable
        super.init(frame: CGRect(origin: .zero, size: size))
        populator?(self)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
#if DEBUG
        print("👍👍👍 ProgressView is released.")
#endif
    }

    public override var bounds: CGRect {
        didSet {
            bounds.notEqual(oldValue, do: invalidateIntrinsicContentSize())
        }
    }

    public override var intrinsicContentSize: CGSize {
        bounds.isEmpty ? style.defaultSize : bounds.size
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

        animationBuilder.draw(progress: progress, in: layer, color: progressTintColor, trackColor: trackTintColor, lineWidth: lineWidth)
    }
}
