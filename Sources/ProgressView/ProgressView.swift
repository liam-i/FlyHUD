//
//  ProgressView.swift
//  LPHUD
//
//  Created by liam on 2024/1/16.
//

import UIKit

public protocol ProgressViewStyleable {
    func makeAnimation() -> ProgressAnimationBuildable
    var defaultSize: CGSize { get }
    var defaultProgressTintColor: UIColor { get }
    var defaultTrackTintColor: UIColor? { get }
    var defaultLineWidth: CGFloat { get }
}

extension ProgressViewStyleable {
    public var defaultSize: CGSize { .zero }
    public var defaultProgressTintColor: UIColor { .contentOfHUD }
    public var defaultTrackTintColor: UIColor? { defaultProgressTintColor.withAlphaComponent(0.1) }
    public var defaultLineWidth: CGFloat { 2.0 }
}

extension ProgressView {
    public enum Style: Equatable, ProgressViewStyleable {
        case bar(_ isRound: Bool = false)
        case round(_ isAnnular: Bool = false)
        case pie

        public func makeAnimation() -> ProgressAnimationBuildable {
            switch self {
            case let .bar(isRound):     return ProgressAnimation.Bar(isRound: isRound)
            case let .round(isAnnular): return ProgressAnimation.Round(isAnnular: isAnnular)
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

public class ProgressView: UIView, ProgressViewable {
    public let style: ProgressViewStyleable

    /// Progress (0.0 to 1.0)
    public var progress: Float = 0.0 {
        didSet {
            progress.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// Progress color. Defaults to UIColor.label.withAlphaComponent(0.7)
    public lazy var progressTintColor: UIColor? = style.defaultProgressTintColor {
        didSet {
            progressTintColor.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    /// background (non-progress) color. Defaults to clear.
    public lazy var trackTintColor: UIColor? = style.defaultTrackTintColor {
        didSet {
            trackTintColor.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    public lazy var lineWidth: CGFloat = style.defaultLineWidth {
        didSet {
            lineWidth.notEqual(oldValue, do: setNeedsDisplay())
        }
    }

    private var animationBuilder: ProgressAnimationBuildable?

    public convenience init(style: Style = .bar(), size: CGSize = .zero, populator: ((ProgressView) -> Void)? = nil) {
        self.init(styleable: style, size: size, populator: populator)
    }

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
