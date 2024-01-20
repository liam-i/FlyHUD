//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

// MARK: UITableViewDelegate, UITableViewDataSource

class ViewController: UITableViewController {
    // MARK: Getters and Setters
    private lazy var examples: [[Model]] = Model.examples

    override func numberOfSections(in tableView: UITableView) -> Int {
        return examples.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = examples[indexPath.section][indexPath.row].title
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        perform(examples[indexPath.section][indexPath.row].selector)
    }
}

// MARK: Examples

extension ViewController {
    private var container: UIView {
        navigationController!.view
    }

    @objc func activityIndicatorExample() {
        let hud = HUD.show(to: container, using: .zoomInOut)

//        let indicator = ActivityIndicatorView(style: .circleArcDotSpin)
//        let hud = HUD.show(to: container, using: .zoomInOut, mode: .custom(indicator))

        Task.request(3) {
            hud.hide()
        }
//        Task.test(1) {
//            if #available(iOS 13.0, *) {
//                hud.mode = .indicator(.medium) // test.
//            }
//        }
//        Task.test(2) {
//            hud.layout.offset = CGPoint(x: 50, y: 0) // test.
//        }
        


    }

    @objc func labelExample() {
        let hud = HUD.show(to: container, using: .zoomOutIn, label: "Loading...")
        Task.request {
            hud.hide()
        }
    }

    @objc func detailsLabelExample() {
        let hud = HUD.show(to: container) {
            $0.animation.style = .zoomIn
            $0.label.text = "Loading..."
            $0.detailsLabel.text = "Parsing data\n(1/1)"
        }
        Task.request {
            hud.hide()
        }
    }

    @objc func customActivityIndicatorExample() {
        let hud = HUD.show(to: container) {
            $0.label.text = "Loading..."
            $0.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
            $0.animation.style = .zoomOut
        }
        Task.request {
            hud.hide()
        }
    }

    @objc func determinateExample() {
        let hud = HUD.show(to: container, using: .slideUpDown, mode: .custom(ProgressView(style: .round())), label: "Loading...")
        Task.request(5) {
            HUD.hud(for: self.container)?.progress = $0 // test.
            //hud.progress = $0
        } completion: {
            hud.hide()
        }
//        Task.test(1) {
//            hud.mode = .custom(ProgressView(style: .round(), populator: { $0.lineWidth = 4 })) // test.
//        }
//        Task.test(2) {
//            hud.mode = .custom(ProgressView(style: .round(), populator: {
//                $0.lineWidth = 4
//                $0.frame.size = CGSize(width: 80, height: 80)
//            })) // test.
//        }
//        Task.test(3) {
//            hud.mode = .custom(ProgressView(style: .round(true), populator: {
//                $0.lineWidth = 12
//                $0.frame.size = CGSize(width: 80, height: 80)
//            })) // test.
//            hud.label.font = .boldSystemFont(ofSize: 32)
//        }
    }

    @objc func annularDeterminateExample() {
        let hud = HUD.show(to: container, using: .slideDownUp, mode: .custom(ProgressView(style: .round(true))), label: "Loading...")
        Task.request {
            hud.progress = $0
        } completion: {
            hud.hide()
        }
    }

    @objc func barDeterminateExample() {
        let prog = ProgressView(style: .pie, size: CGSize(width: 320, height: 50))
//        {
//            $0.lineWidth = 10
//            $0.progressTintColor = .red
//            $0.trackTintColor = .blue
//        }
        let hud = HUD.show(to: container, using: .slideUp, mode: .custom(prog), label: "Loading...")
        Task.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(afterDelay: 0)
        }

//        Task.test(1) {
//            hud.mode = .custom(ProgressView(style: .bar(), populator: {
//                $0.lineWidth = 20
//                $0.frame.size = CGSize(width: 320, height: 80)
//            })) // test.
//        }
    }

    @objc func textExample() {
        let hud = HUD.showStatus(to: container, duration: 3.0, using: .slideUpDown, label: "Wrong password")
//        Task.test(1) {
//            hud.layout.with {
//                $0.offset = .zero
//                $0.hMargin = 50
//                $0.vMargin = 40
//                $0.spacing = 40
//            }
//        }
    }

    @objc func customViewExample() {
        HUD.showStatus(to: container, duration: 3.0) {
            $0.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
            $0.label.text = "Done"
            $0.layout.with {
                $0.isSquare = true
                $0.offset = .zero
            }
            $0.animation.style = .fade
        }
    }

    @objc func customProgressViewExample() {
        class CustomProgressive: BaseView, ProgressViewable {
            var progressTintColor: UIColor? = nil
            var trackTintColor: UIColor? = nil

            var progress: Float = 0.0 {
                didSet {
                    progressView.progress = Float(progress)
                    progressView.progressTintColor = progressTintColor
                    progressView.trackTintColor = trackTintColor

                    label.text = "Progress(\(String(format: "%.2f", progress)))"
                    label.textColor = progressTintColor
                }
            }
            let progressView: UIProgressView = .init(progressViewStyle: .default)
            let label: UILabel = .init()
            override func commonInit() {
                label.textAlignment = .center
                addSubview(progressView)
                addSubview(label)
                progressView.progress = 0.0
                progressView.translatesAutoresizingMaskIntoConstraints = false
                label.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    widthAnchor.constraint(equalToConstant: 150),
                    progressView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    progressView.trailingAnchor.constraint(equalTo: trailingAnchor),
                    progressView.topAnchor.constraint(equalTo: topAnchor),
//                    progressView.heightAnchor.constraint(equalToConstant: 20),
                    label.leadingAnchor.constraint(equalTo: leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: trailingAnchor),
                    label.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 10),
                    label.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }
        }
        let hud = HUD.show(to: container, using: .zoomInOut, mode: .custom(CustomProgressive()))
        Task.request {
            hud.progress = $0
        } completion: {
            hud.hide(afterDelay: 0.5)
        }
    }

    @objc func cancelationExample() {
        let hud = HUD.show(to: container) {
            $0.label.text = "Loading..."
            $0.button.setTitle("Cancel", for: .normal)
            $0.button.addTarget(self, action: #selector(self.cancelWork), for: .touchUpInside)
        }
        Task.request(3) {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide()
        }
        Task.test(1) {
            hud.label.font = .boldSystemFont(ofSize: 20)
            hud.button.titleLabel?.font = .boldSystemFont(ofSize: 17)
            hud.button.borderWidth = 2
            hud.button.roundedCorners = .radius(4)
        }
    }

    @objc func modeSwitchingExample() {
        let hud = HUD.show(to: container) {
            $0.label.text = "Preparing..."
            $0.layout.minSize = CGSize(width: 150.0, height: 100.0)
        }
        Task.requestMultiTask {
            /// Demo `HUD.hud(for:)` method
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            switch $0 {
            case 3:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .custom(ProgressView(style: .round()))
                hud.label.text = "Loading..."
            case 2:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .indicator()
                hud.label.text = "Cleaning up..."
            case 1:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
                hud.label.text = "Completed"
            case 0:
                hud.hide()
            default:
                assertionFailure()
            }
        }
    }

    @objc func windowExample() {
        let hud = HUD.show(to: view.window!)
        Task.request {
            hud.hide()
        }
    }

    @objc func networkingExample() {
        HUD.show(to: container, mode: .progress(.bar()))

        HUD.show(to: container) {
            $0.label.text = "Preparing..."
            $0.layout.minSize = CGSize(width: 150.0, height: 100.0)
        }
        Task.download {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .custom(ProgressView(style: .round()))
            hud.progress = $0
        } completion: {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
            hud.label.text = "Completed"
            hud.hide(afterDelay: 3.0)
        }
    }

    @objc func determinateProgressExample() {
        let hud = HUD.show(to: container, mode: .custom(ProgressView(style: .round())), label: "Loading...")

        let progress = Progress(totalUnitCount: 100)
        hud.observedProgress = progress
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

        // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
        // label.text and detailLabel.text takes their info from the progressObject.
        // They can be customized or use the default text.
        // To suppress one (or both) of the labels, set the descriptions to empty strings.
//        progress.localizedDescription = "Download Progress"

        Task.resume(with: progress) {
            hud.hide()
        }
    }

    @objc func dimBackgroundExample() {
        let hud = HUD.show(to: container) {
            $0.backgroundView.style = .solidColor
            $0.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
        }
        Task.request {
            hud.hide()
        }
    }

    @objc func colorExample() {
        let hud = HUD.show(to: container) {
            $0.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
            $0.label.text = "Loading..."
        }
        Task.request {
            hud.hide()
        }
    }

    @objc func cancelWork(_ sender: UIButton) {
        Task.cancelTask()
    }

    @objc func multipleHUDExample() {
        /// Handle show `HUD` multiple times in the same `View`.
        func request1() {
            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
            Task.request(.random(in: 1...3)) {
                hud.hide()
                hud.label.text = "Count: \(hud.count)"
                print("response1 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            hud.label.text = "Count: \(hud.count)"
            print("request1  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request2() {
            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
            Task.request(.random(in: 1...3)) {
                hud.hide()
                hud.label.text = "Count: \(hud.count)"
                print("response2 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            hud.label.text = "Count: \(hud.count)"
            print("request2  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request3() {
            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
            Task.request(.random(in: 1...3)) {
                hud.hide()
                hud.label.text = "Count: \(hud.count)"
                print("response3 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            hud.label.text = "Count: \(hud.count)"
            print("request3  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }

        request1()
        request2()
        request3()

        let hud = HUD.hud(for: container)
        hud?.completionBlock = { hud in
            print("结束 --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
    }
}
