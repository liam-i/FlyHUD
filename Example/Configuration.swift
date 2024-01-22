//
//  Configuration.swift
//  HUD_Example
//
//  Created by liam on 2021/7/9.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import LPHUD

struct Configuration {
    var isDefaultModeStyle: Bool = true
    var isEventDeliveryEnabled: Bool = false

    var isLabelEnabled: Bool = false
    var isDetailsLabelEnabled: Bool = false
    var isButtonEnabled: Bool = false

//    var mode: HUD.Mode = .indicator()
    var layout: HUD.Layout = .init()
    var contentColor: UIColor = .contentOfHUD
//    var progress: Float = 0.0
//    var observedProgress: Progress?
    var animation: HUD.Animation = .init()
    mutating func animationStyle(_ idx: Int) {
        switch idx {
        case 0: animation.style = .none
        case 1: animation.style = .fade
        case 2: animation.style = .zoomInOut
        case 3: animation.style = .zoomOutIn
        case 4: animation.style = .zoomIn
        case 5: animation.style = .zoomOut
        case 6: animation.style = .slideUpDown
        case 7: animation.style = .slideDownUp
        case 8: animation.style = .slideUp
        case 9: animation.style = .slideDown
        default:
            print(idx)
        }
    }
    var forceAnimation: HUD.Animation?
    mutating func forceAnimationDuration(_ value: CGFloat) {
        if forceAnimation == nil { forceAnimation = .init() }
        forceAnimation?.duration = value
    }
    mutating func forceAnimationDamping(_ isOn: Bool) {
        if forceAnimation == nil { forceAnimation = .init() }
        forceAnimation?.damping = isOn ? .default : .disable
    }
    mutating func forceAnimationStyle(_ idx: Int) {
        if forceAnimation == nil { forceAnimation = .init() }
        switch idx {
        case 0: forceAnimation = nil
        case 1: forceAnimation?.style = .none
        case 2: forceAnimation?.style = .fade
        case 3: forceAnimation?.style = .zoomInOut
        case 4: forceAnimation?.style = .zoomOutIn
        case 5: forceAnimation?.style = .zoomIn
        case 6: forceAnimation?.style = .zoomOut
        case 7: forceAnimation?.style = .slideUpDown
        case 8: forceAnimation?.style = .slideDownUp
        case 9: forceAnimation?.style = .slideUp
        case 10: forceAnimation?.style = .slideDown
        default:
            print(idx)
        }
    }
    mutating func updateContentColor(_ idx: Int) {
        switch idx {
        case 0: contentColor = .systemRed
        case 1: contentColor = .systemYellow
        case 2: contentColor = .systemOrange
        case 3: contentColor = .systemPurple
        default:
            contentColor = .contentOfHUD
        }
    }


//    var isVisible: Bool
    var graceTime: TimeInterval = 0.0
    var minShowTime: TimeInterval = 0.0
//    var removeFromSuperViewOnHide: Bool = true
    var isCountEnabled: Bool = false

    var isMotionEffectsEnabled: Bool = false
    weak var delegate: (ViewController & HUDDelegate)?
    var completionBlock: ((_ hud: HUD) -> Void)?

    var hideAfterDelay: TimeInterval = 2.0

    init(delegate: (ViewController & HUDDelegate)?, completionBlock: @escaping(_ hud: HUD) -> Void) {
        self.delegate = delegate
        self.completionBlock = completionBlock
    }

    var takesTime: UInt32 = 3
    var imageView: UIImageView {
        UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
    }
}

extension Configuration {
    func request(_ hud: HUD) {
        Task.request(takesTime) { progress in
            if hud.mode.isProgressView {
                hud.progress = progress
            }
        } completion: {
            if isDefaultModeStyle {
                hud.hide() // Default
            } else {
                hud.hide(using: forceAnimation ?? animation)
            }
        }
    }

    func hide(for view: UIView) {
        HUD.hide(for: view, using: forceAnimation ?? animation)
    }

    @discardableResult
    func showStatusHUD(to view: UIView, onlyText: Bool) -> HUD {
        let mode: HUD.Mode = onlyText ? .text : .custom(imageView)
        return showHUD(to: view, mode: mode, label: mode.description).with {
            if isDefaultModeStyle {
                $0.hide(afterDelay: hideAfterDelay)
            } else {
                $0.hide(using: forceAnimation ?? animation, afterDelay: hideAfterDelay)
            }
        }
    }

    func showHUD(to view: UIView, mode: HUD.Mode) -> HUD {
        showHUD(to: view, mode: mode, label: nil)
    }

    private func showHUD(to view: UIView, mode: HUD.Mode, label: String?) -> HUD {
        let hud: HUD
        if isDefaultModeStyle {
            hud = HUD.show(to: view, mode: mode, label: label) // Default Mode Style
        } else {
            hud = custom(to: view, mode: mode, label: label) // Custom Mode Style
        }
        if isEventDeliveryEnabled {
            hud.detailsLabel.text = "Events are delivered normally to the HUD's parent view"
            hud.detailsLabel.textColor = .systemRed
        }
        hud.delegate = delegate
        hud.completionBlock = completionBlock
        return hud
    }

    private func custom(to view: UIView, mode: HUD.Mode, label: String?) -> HUD {
        HUD.show(to: view, using: forceAnimation ?? animation, mode: mode) {
            $0.label.text = label ?? (isLabelEnabled ? mode.description : nil)
            $0.detailsLabel.text = isDetailsLabelEnabled ? "This is the detail label" : nil
            $0.button.setTitle(isButtonEnabled ? "Cancel" : nil, for: .normal)
            if isButtonEnabled {
                $0.button.addTarget(delegate, action: #selector(ViewController.cancelTask), for: .primaryActionTriggered)
            }
            $0.layout = layout
            $0.contentColor = contentColor
            $0.graceTime = graceTime
            $0.minShowTime = minShowTime
            $0.isCountEnabled = isCountEnabled
            $0.isEventDeliveryEnabled = isEventDeliveryEnabled
            $0.isMotionEffectsEnabled = isMotionEffectsEnabled
            $0.delegate = delegate
            $0.completionBlock = completionBlock
        }
    }
}

//extension Model {
//    static var examples: [[Model]] {[
//        [Model(title: "UIActivityIndicator mode", selector: #selector(ViewController.activityIndicatorExample)),
//         Model(title: "With label", selector: #selector(ViewController.labelExample)),
//         Model(title: "With details label", selector: #selector(ViewController.detailsLabelExample)),
//         Model(title: "Ring Clip Rotate", selector: #selector(ViewController.customActivityIndicatorExample))
//        ],
//        [Model(title: "Determinate mode", selector: #selector(ViewController.determinateExample)),
//         Model(title: "Annular determinate mode", selector: #selector(ViewController.annularDeterminateExample)),
//         Model(title: "Bar determinate mode", selector: #selector(ViewController.barDeterminateExample))
//        ],
//        [Model(title: "With action button", selector: #selector(ViewController.cancelationExample)),
//         Model(title: "Mode switching", selector: #selector(ViewController.modeSwitchingExample))
//        ],
//        [Model(title: "On window", selector: #selector(ViewController.windowExample)),
//         Model(title: "URLSession", selector: #selector(ViewController.networkingExample)),
//         Model(title: "Determinate with Progress", selector: #selector(ViewController.determinateProgressExample)),
//         Model(title: "Dim background", selector: #selector(ViewController.dimBackgroundExample)),
//         Model(title: "Colored", selector: #selector(ViewController.colorExample))
//        ],
//        [Model(title: "Multiple HUD", selector: #selector(ViewController.multipleHUDExample))]
//    ]}
//}
//
//    @objc func activityIndicatorExample() {
//        let hud = HUD.show(to: container, using: .zoomInOut)
//
////        let indicator = ActivityIndicatorView(style: .circleArcDotSpin)
////        let hud = HUD.show(to: container, using: .zoomInOut, mode: .custom(indicator))
//
//        Task.request(3) {
//            hud.hide()
//        }
////        Task.test(1) {
////            if #available(iOS 13.0, *) {
////                hud.mode = .indicator(.medium) // test.
////            }
////        }
////        Task.test(2) {
////            hud.layout.offset = CGPoint(x: 50, y: 0) // test.
////        }
//    }
//
//    @objc func labelExample() {
//        let hud = HUD.show(to: container, using: .zoomOutIn, label: "Loading...")
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func detailsLabelExample() {
//        let hud = HUD.show(to: container) {
//            $0.animation.style = .zoomIn
//            $0.label.text = "Loading..."
//            $0.detailsLabel.text = "Parsing data\n(1/1)"
//        }
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func customActivityIndicatorExample() {
//        let hud = HUD.show(to: container) {
//            $0.label.text = "Loading..."
//            $0.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
//            $0.animation.style = .zoomOut
//        }
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func determinateExample() {
//        let hud = HUD.show(to: container, using: .slideUpDown, mode: .custom(ProgressView(style: .round)), label: "Loading...")
//        Task.request(5) {
//            HUD.hud(for: self.container)?.progress = $0 // test.
//            //hud.progress = $0
//        } completion: {
//            hud.hide()
//        }
////        Task.test(1) {
////            hud.mode = .custom(ProgressView(style: .round(), populator: { $0.lineWidth = 4 })) // test.
////        }
////        Task.test(2) {
////            hud.mode = .custom(ProgressView(style: .round(), populator: {
////                $0.lineWidth = 4
////                $0.frame.size = CGSize(width: 80, height: 80)
////            })) // test.
////        }
////        Task.test(3) {
////            hud.mode = .custom(ProgressView(style: .round(true), populator: {
////                $0.lineWidth = 12
////                $0.frame.size = CGSize(width: 80, height: 80)
////            })) // test.
////            hud.label.font = .boldSystemFont(ofSize: 32)
////        }
//    }
//
//    @objc func annularDeterminateExample() {
//        let hud = HUD.show(to: container, using: .slideDownUp, mode: .custom(ProgressView(style: .round)), label: "Loading...")
//        Task.request {
//            hud.progress = $0
//        } completion: {
//            hud.hide()
//        }
//    }
//
//    @objc func barDeterminateExample() {
//        let prog = ProgressView(style: .pie, size: CGSize(width: 320, height: 50))
////        {
////            $0.lineWidth = 10
////            $0.progressTintColor = .red
////            $0.trackTintColor = .blue
////        }
//        let hud = HUD.show(to: container, using: .slideUp, mode: .custom(prog), label: "Loading...") {
//            $0.removeFromSuperViewOnHide = true
//        }
//        Task.request {
//            HUD.hud(for: self.container)?.progress = $0
//        } completion: {
//            hud.hide()
//
//            Task.request {
//                hud.show()
//
//                Task.request {
//                    hud.progress = $0
//                } completion: {
//                    hud.hide()
//                }
//            }
//        }
//
////        Task.test(1) {
////            hud.mode = .custom(ProgressView(style: .bar(), populator: {
////                $0.lineWidth = 20
////                $0.frame.size = CGSize(width: 320, height: 80)
////            })) // test.
////        }
//    }
//
//    @objc func textExample() {
////        Task.test(1) {
////            hud.layout.with {
////                $0.offset = .zero
////                $0.hMargin = 50
////                $0.vMargin = 40
////                $0.spacing = 40
////            }
////        }
//    }
//
//    @objc func customProgressViewExample() {
//        class CustomProgressive: BaseView, ProgressViewable {
//            var delegate: ProgressViewDelegate?
//            var observedProgress: Progress?
//            var progressTintColor: UIColor?
//            var trackTintColor: UIColor?
//
//            var progress: Float = 0.0 {
//                didSet {
//                    progressView.progress = Float(progress)
//                    progressView.progressTintColor = progressTintColor
//                    progressView.trackTintColor = trackTintColor
//
//                    label.text = "Progress(\(String(format: "%.2f", progress)))"
//                    label.textColor = progressTintColor
//                }
//            }
//            let progressView: UIProgressView = .init(progressViewStyle: .default)
//            let label: UILabel = .init()
//            override func commonInit() {
//                label.textAlignment = .center
//                addSubview(progressView)
//                addSubview(label)
//                progressView.progress = 0.0
//                progressView.translatesAutoresizingMaskIntoConstraints = false
//                label.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    widthAnchor.constraint(equalToConstant: 150),
//                    progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
//                    progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
//                    progressView.topAnchor.constraint(equalTo: topAnchor),
////                    progressView.heightAnchor.constraint(equalToConstant: 20),
//                    label.leadingAnchor.constraint(equalTo: leadingAnchor),
//                    label.trailingAnchor.constraint(equalTo: trailingAnchor),
//                    label.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
//                    label.bottomAnchor.constraint(equalTo: bottomAnchor)
//                ])
//            }
//        }
//        let hud = HUD.show(to: container, using: .zoomInOut, mode: .custom(CustomProgressive()))
//        Task.request {
//            hud.progress = $0
//        } completion: {
//            hud.hide(afterDelay: 0.5)
//        }
//    }
//
//    @objc func cancelationExample() {
//        let hud = HUD.show(to: container) {
//            $0.label.text = "Loading..."

//        }
//        Task.request(10) {
//            HUD.hud(for: self.container)?.progress = $0
//        } completion: {
//            hud.hide()
//        }
////        Task.test(1) {
////            hud.label.font = .boldSystemFont(ofSize: 20)
////            hud.button.titleLabel?.font = .boldSystemFont(ofSize: 17)
////            hud.button.borderWidth = 2
////            hud.button.roundedCorners = .radius(4)
////        }
//    }
//
//    @objc func modeSwitchingExample() {
//        let hud = HUD.show(to: container) {
//            $0.label.text = "Preparing..."
//            $0.layout.minSize = CGSize(width: 150.0, height: 100.0)
//        }
//        Task.requestMultiTask {
//            /// Demo `HUD.hud(for:)` method
//            HUD.hud(for: self.container)?.progress = $0
//        } completion: {
//            switch $0 {
//            case 3:
//                /// Demo `HUD.hud(for:)` method
//                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
//                hud.mode = .custom(ProgressView(style: .round))
//                hud.label.text = "Loading..."
//            case 2:
//                /// Demo `HUD.hud(for:)` method
//                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
//                hud.mode = .indicator()
//                hud.label.text = "Cleaning up..."
//            case 1:
//                /// Demo `HUD.hud(for:)` method
//                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
//                hud.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
//                hud.label.text = "Completed"
//            case 0:
//                hud.hide()
//            default:
//                assertionFailure()
//            }
//        }
//    }
//
//    @objc func windowExample() {
//        let hud = HUD.show(to: view.window!)
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func networkingExample() {
//        HUD.show(to: container, mode: .progress(.buttBar))
//
//        HUD.show(to: container) {
//            $0.label.text = "Preparing..."
//            $0.layout.minSize = CGSize(width: 150.0, height: 100.0)
//        }
//        Task.download {
//            guard let hud = HUD.hud(for: self.container) else { return }
//            hud.mode = .custom(ProgressView(style: .round))
//            hud.progress = $0
//        } completion: {
//            guard let hud = HUD.hud(for: self.container) else { return }
//            hud.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
//            hud.label.text = "Completed"
//            hud.hide(afterDelay: 3.0)
//        }
//    }
//
//    @objc func determinateProgressExample() {
//        let hud = HUD.show(to: container, mode: .custom(ProgressView(style: .round)), label: "Loading...")
//
//        let progress = Progress(totalUnitCount: 100)
//        hud.observedProgress = progress
//        hud.button.setTitle("Cancel", for: .normal)
//        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)
//
//        // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
//        // label.text and detailLabel.text takes their info from the progressObject.
//        // They can be customized or use the default text.
//        // To suppress one (or both) of the labels, set the descriptions to empty strings.
////        progress.localizedDescription = "Download Progress"
//
//        Task.resume(with: progress) {
//            hud.hide()
//            progress.cancel()
//            Task.request {
//                self.container.addSubview(hud)
//                progress.resume()
//
//                hud.show()
//
//                Task.request {
//                    hud.hide()
//                }
//            }
//        }
//    }
//
//    @objc func dimBackgroundExample() {
//        let hud = HUD.show(to: container) {
//            $0.backgroundView.style = .solidColor
//            $0.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
//        }
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func colorExample() {
//        let hud = HUD.show(to: container) {
//            $0.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
//            $0.label.text = "Loading..."
//        }
//        Task.request {
//            hud.hide()
//        }
//    }
//
//    @objc func multipleHUDExample() {
//        /// Handle show `HUD` multiple times in the same `View`.
//        func request1() {
//            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
//            Task.request(.random(in: 1...3)) {
//                hud.hide()
//                hud.label.text = "Count: \(hud.count)"
//                print("response1 --> hud(\(hud.hashValue)).count=\(hud.count)")
//            }
//            hud.label.text = "Count: \(hud.count)"
//            print("request1  --> hud(\(hud.hashValue)).count=\(hud.count)")
//        }
//        func request2() {
//            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
//            Task.request(.random(in: 1...3)) {
//                hud.hide()
//                hud.label.text = "Count: \(hud.count)"
//                print("response2 --> hud(\(hud.hashValue)).count=\(hud.count)")
//            }
//            hud.label.text = "Count: \(hud.count)"
//            print("request2  --> hud(\(hud.hashValue)).count=\(hud.count)")
//        }
//        func request3() {
//            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
//            Task.request(.random(in: 1...3)) {
//                hud.hide()
//                hud.label.text = "Count: \(hud.count)"
//                print("response3 --> hud(\(hud.hashValue)).count=\(hud.count)")
//            }
//            hud.label.text = "Count: \(hud.count)"
//            print("request3  --> hud(\(hud.hashValue)).count=\(hud.count)")
//        }
//
//        request1()
//        request2()
//        request3()
//
//        let hud = HUD.hud(for: container)
//        hud?.completionBlock = { hud in
//            print("结束 --> hud(\(hud.hashValue)).count=\(hud.count)")
//        }
//    }

extension HUD.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .text:                                 return "Wrong password"
        case .indicator:                            return "UIActivityIndicatorView"
        case .progress:                             return "UIProgressView"
        case .custom(let view):
            switch view {
            case let view as ProgressView:          return "ProgressView(\(view.style))"
            case let view as ActivityIndicatorView: return "ActivityIndicatorView(\(view.style))"
            default:                                return "Done"
            }
        }
    }

    var isProgressView: Bool {
        switch self {
        case .progress:         return true
        case .custom(let view): return view is ProgressViewable
        default:                return false
        }
    }
}
