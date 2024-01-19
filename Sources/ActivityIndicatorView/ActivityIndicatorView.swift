//
//  ActivityIndicatorView.swift
//  HUD
//
//  Created by liam on 2024/1/16.
//

import UIKit

public protocol ActivityIndicatorViewStyleable {
    func makeAnimation() -> ActivityIndicatorAnimationBuildable

    var defaultSize: CGSize { get }
    var defaultColor: UIColor { get }
    var defaultTrackColor: UIColor? { get }
    var defaultLineWidth: CGFloat { get }
}

extension ActivityIndicatorViewStyleable {
    public var defaultSize: CGSize { CGSize(width: 37.0, height: 37.0) }
    public var defaultColor: UIColor { .contentOfHUD }
    public var defaultTrackColor: UIColor? { defaultColor.withAlphaComponent(0.1) }
    public var defaultLineWidth: CGFloat { 2.0 }
}

extension ActivityIndicatorView {
    public enum Style: Equatable, ActivityIndicatorViewStyleable {
        case ringClipRotate
        case ballSpinFade
        case circleStrokeSpin
        case circleArcDotSpin

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

public class ActivityIndicatorView: UIView, ActivityIndicatorViewable {
    /// The basic appearance of the activity indicator.
    /// - Note: See UIActivityIndicatorView.Style for the available styles. The default value is UIActivityIndicatorView.Style.medium.
    public let style: ActivityIndicatorViewStyleable
    public lazy var color: UIColor! = style.defaultColor
    /// The color shown for the portion of the track that isn’t filled.
    public lazy var trackColor: UIColor? = style.defaultTrackColor
    public lazy var lineWidth: CGFloat = style.defaultLineWidth
    public lazy var hidesWhenStopped: Bool = true

    public private(set) var isAnimating: Bool = false

    public convenience init(style: Style = .ringClipRotate, size: CGSize = .zero, populator: ((ActivityIndicatorView) -> Void)? = nil) {
        self.init(styleable: style, size: size, populator: populator)
    }

    public init(styleable: ActivityIndicatorViewStyleable, size: CGSize = .zero, populator: ((ActivityIndicatorView) -> Void)? = nil) {
        self.style = styleable
        super.init(frame: CGRect(origin: .zero, size: size))
        populator?(self)
        backgroundColor = .clear
        isOpaque = false
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
#if DEBUG
        print("👍👍👍 ActivityIndicatorView is released.")
#endif
    }

    public func startAnimating() {
        guard isAnimating == false else { return }
        isHidden = false
        isAnimating = true
        layer.speed = 1
        makeAnimation()
    }

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

    private func makeAnimation() {
        layer.sublayers = nil
        let animation = style.makeAnimation()
        animation.make(in: layer, color: color, trackColor: trackColor, lineWidth: lineWidth)
    }
}
