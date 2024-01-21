//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

// MARK: - Examples

extension ViewController {
    @objc func progressButtonClicked(_ sender: UIButton) {
        let style = progressViews[sender.tag].style
        HUD.show(to: view, mode: .progress(style), label: String(describing: style)).with { hud in
            Task.request {
                hud.progress = $0
            } completion: {
                hud.hide()
            }
        }
    }

    @objc func indicatorButtonClicked(_ sender: UIButton) {
        let style = indicatorViews[sender.tag].style
        HUD.show(to: view, mode: .indicator(style), label: String(describing: style)).with { hud in
            Task.request {
                hud.hide()
            }
        }
    }

//    private var container: UIView {
//        navigationController!.view
//    }
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
//        let hud = HUD.showStatus(to: container, duration: 3.0, using: .slideUpDown, label: "Wrong password")
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
//    @objc func customViewExample() {
//        HUD.showStatus(to: container, duration: 3.0) {
//            $0.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
//            $0.label.text = "Done"
//            $0.layout.with {
//                $0.isSquare = true
//                $0.offset = .zero
//            }
//            $0.animation.style = .fade
//        }
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
//            $0.button.setTitle("Cancel", for: .normal)
//            $0.button.addTarget(self, action: #selector(self.cancelWork), for: .touchUpInside)
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
//    @objc func cancelWork(_ sender: UIButton) {
//        Task.cancelTask()
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
}

// MARK: - Class ViewController

class ViewController: UITableViewController {
    @IBOutlet weak var progressStackView: UIStackView!
    @IBOutlet weak var indicatorStackView: UIStackView!

    var progressViews: [ProgressView] = []
    var indicatorViews: [ActivityIndicatorView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        var idx = 0
        progressStackView.arrangedSubviews.forEach { stack in
            (stack as! UIStackView).arrangedSubviews.forEach { container in
                guard idx < ProgressView.Style.allCases.count else { return }
                let style = ProgressView.Style.allCases[idx]
                let view = ProgressView(style: style)
                for case let button as UIButton in container.subviews {
                    button.addTarget(self, action: #selector(progressButtonClicked(_:)), for: .primaryActionTriggered)
                    button.tag = idx
                }
                container.insertSubview(view, at: 0)
                if style == .buttBar || style == .roundBar {
                    view.lineWidth = 3.0
                    view.edge(to: container, height: 15)
                } else {
                    view.edge(to: container)
                }
                idx += 1
                progressViews.append(view)
            }
        }
        ActivityIndicatorView.Style.allCases.enumerated().forEach { (offset, style) in
            let container = indicatorStackView.arrangedSubviews[offset]
            let view = ActivityIndicatorView(style: style)

            for case let button as UIButton in container.subviews {
                button.addTarget(self, action: #selector(indicatorButtonClicked(_:)), for: .primaryActionTriggered)
                button.tag = offset
            }
            container.insertSubview(view, at: 0)
            view.edge(to: container)
            view.startAnimating()
            indicatorViews.append(view)
        }
        updateProgress()
    }

    private func updateProgress() {
        Task.request { progress in
            self.progressViews.forEach {
                $0.progress = progress
            }
        } completion: {
            Task.request(1) { self.updateProgress() }
        }
    }
}

extension UIView {
    func edge(to view: UIView, height: CGFloat? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = [
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        ]
        if let height = height {
            constraints.append(contentsOf: [
                centerYAnchor.constraint(equalTo: view.centerYAnchor),
                heightAnchor.constraint(equalToConstant: height)])
        } else {
            constraints.append(contentsOf: [
                topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
                bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)])
        }
        NSLayoutConstraint.activate(constraints)
    }
}
