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

    @objc func indeterminateExample() {
        let hud = HUD.show(to: container, using: .zoomInOut)
        Task.request(3) {
            hud.hide(animated: true)
        }
        Task.test(1) {
            if #available(iOS 13.0, *) {
                hud.mode = .indeterminate(.medium) // test.
            }
        }
        Task.test(2) {
            hud.layoutConfig.offset = CGPoint(x: 50, y: 0) // test.
        }
    }

    @objc func labelExample() {
        let hud = HUD.show(to: container, using: .zoomInOut, label: "Loading...")
        Task.request {
            hud.hide(animated: true)
        }
    }

    @objc func detailsLabelExample() {
        let hud = HUD.show(to: container) {
            $0.animationType = .zoomInOut
            $0.label.text = "Loading..."
            $0.detailsLabel.text = "Parsing data\n(1/1)"
        }
        Task.request {
            hud.hide(animated: true)
        }
    }

    @objc func determinateExample() {
        let hud = HUD.show(to: container, using: .zoomInOut, mode: .determinate(), label: "Loading...")
        Task.request(5) {
            HUD.hud(for: self.container)?.progress = $0 // test.
            //hud.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
        Task.test(1) {
            hud.mode = .determinate(isAnnular: false, lineWidth: 4) // test.
        }
        Task.test(2) {
            hud.mode = .determinate(isAnnular: false, lineWidth: 8, lineSize: 60) // test.
        }
        Task.test(3) {
            hud.mode = .determinate(isAnnular: true, lineWidth: 12, lineSize: 80) // test.
            hud.label.font = .boldSystemFont(ofSize: 32)
        }
    }

    @objc func annularDeterminateExample() {
        let hud = HUD.show(to: container, mode: .determinate(isAnnular: true), label: "Loading...")
        Task.request {
            hud.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func barDeterminateExample() {
        let hud = HUD.show(to: container, mode: .determinateHorizontalBar(), label: "Loading...")
        Task.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
        Task.test(1) {
            hud.mode = .determinateHorizontalBar(lineWidth: 20, spacing: 10) // test.
        }
    }

    @objc func textExample() {
        let hud = HUD.showText(to: container, duration: 3.0, label: "Wrong password")
        Task.test(1) {
            hud.layoutConfig.with {
                $0.offset = .zero
                $0.hMargin = 50
                $0.vMargin = 40
                $0.spacing = 40
                $0.isSquare = true
            }
        }
    }

    @objc func customViewExample() {
        HUD.showStatus(to: container, duration: 3.0) {
            $0.mode = .customView(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
            $0.label.text = "Done"
            $0.layoutConfig.with {
                $0.isSquare = true
                $0.offset = .zero
            }
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
            hud.hide(animated: true)
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
            $0.layoutConfig.minSize = CGSize(width: 150.0, height: 100.0)
        }
        Task.requestMultiTask {
            /// Demo `HUD.hud(for:)` method
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            switch $0 {
            case 3:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .determinate()
                hud.label.text = "Loading..."
            case 2:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .indeterminate()
                hud.label.text = "Cleaning up..."
            case 1:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .customView(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
                hud.label.text = "Completed"
            case 0:
                hud.hide(animated: true)
            default:
                assertionFailure()
            }
        }
    }

    @objc func windowExample() {
        let hud = HUD.show(to: view.window!)
        Task.request {
            hud.hide(animated: true)
        }
    }

    @objc func networkingExample() {
        HUD.show(to: container) {
            $0.label.text = "Preparing..."
            $0.layoutConfig.minSize = CGSize(width: 150.0, height: 100.0)
        }
        Task.download {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .determinate()
            hud.progress = $0
        } completion: {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .customView(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
            hud.label.text = "Completed"
            hud.hide(animated: true, afterDelay: 3.0)
        }
    }

    @objc func determinateProgressExample() {
        let hud = HUD.show(to: container, mode: .determinate(), label: "Loading...")

        let progress = Progress(totalUnitCount: 100)
        hud.progressObject = progress
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

        // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
        // label.text and detailLabel.text takes their info from the progressObject.
        // They can be customized or use the default text.
        // To suppress one (or both) of the labels, set the descriptions to empty strings.
//        progress.localizedDescription = "Download Progress"

        Task.resume(with: progress) {
            hud.hide(animated: true)
        }
    }

    @objc func dimBackgroundExample() {
        let hud = HUD.show(to: container) {
            $0.backgroundView.style = .solidColor
            $0.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
        }
        Task.request {
            hud.hide(animated: true)
        }
    }

    @objc func colorExample() {
        let hud = HUD.show(to: container) {
            $0.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
            $0.label.text = "Loading..."
        }
        Task.request {
            hud.hide(animated: true)
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
                hud.hide(animated: true)

                print("response1 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            print("request1  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request2() {
            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
            Task.request(.random(in: 1...3)) {
                hud.hide(animated: true)

                print("response2 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            print("request2  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request3() {
            let hud = HUD.show(to: container) { $0.isCountEnabled = true }
            Task.request(.random(in: 1...3)) {
                hud.hide(animated: true)

                print("response3 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
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
