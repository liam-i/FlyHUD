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
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func labelExample() {
        let hud = HUD.show(to: container, using: .zoomOutIn)
        hud.label.text = "Loading..."

        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func detailsLabelExample() {
        let hud = HUD.show(to: container, using: .zoomOut)
        hud.label.text = "Loading..."
        hud.detailsLabel.text = "Parsing data\n(1/1)"

        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func determinateExample() {
        let hud = HUD.show(to: container, using: .zoomIn)
        hud.mode = .determinate
        hud.detailsLabel.text = "Loading..."

        Network.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func annularDeterminateExample() {
        let hud = HUD.show(to: container)
        hud.mode = .annularDeterminate
        hud.label.text = "Loading..."

        Network.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func barDeterminateExample() {
        let hud = HUD.show(to: container)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Loading..."

        Network.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func textExample() {
        let hud = HUD.show(to: container)
        hud.mode = .text
        hud.label.text = "Wrong password"
        Network.request(2) {
            // test.
            hud.layoutConfig.with {
                $0.offset = CGPoint(x: HUDLayoutConfiguration.maxOffset, y: HUDLayoutConfiguration.maxOffset)
                $0.hMargin = 100
                $0.vMargin = 50
                $0.spacing = 40
                $0.isSquare = true
            }

            hud.hide(animated: true, afterDelay: 3.0)
        }
    }

    @objc func customViewExample() {
        let hud = HUD.show(to: container)
        hud.mode = .customView(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
        hud.layoutConfig.isSquare = true
        hud.label.text = "Done"
        hud.hide(animated: true, afterDelay: 3.0)
    }

    @objc func cancelationExample() {
        let hud = HUD.show(to: container)
        hud.mode = .determinate
        hud.label.text = "Loading..."
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(self, action: #selector(cancelWork), for: .touchUpInside)

        Network.request {
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func modeSwitchingExample() {
        let hud = HUD.show(to: container)
        hud.label.text = "Preparing..."
        hud.layoutConfig.minSize = CGSize(width: 150.0, height: 100.0)

        Network.requestMultiTask {
            /// Demo `HUD.hud(for:)` method
            HUD.hud(for: self.container)?.progress = $0
        } completion: {
            switch $0 {
            case 3:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .determinate
                hud.label.text = "Loading..."
            case 2:
                /// Demo `HUD.hud(for:)` method
                guard let hud = HUD.hud(for: self.container) else { return assertionFailure() }
                hud.mode = .indeterminate
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
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func networkingExample() {
        let hud = HUD.show(to: container)
        hud.label.text = "Preparing..."
        hud.layoutConfig.minSize = CGSize(width: 150.0, height: 100.0)

        Network.download {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .determinate
            hud.progress = $0
        } completion: {
            guard let hud = HUD.hud(for: self.container) else { return }
            hud.mode = .customView(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
            hud.label.text = "Completed"
            hud.hide(animated: true, afterDelay: 3.0)
        }
    }

    @objc func determinateProgressExample() {
        let hud = HUD.show(to: container)
        hud.mode = .determinate
        hud.label.text = "Loading..."

        let progress = Progress(totalUnitCount: 100)
        hud.progressObject = progress
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

        // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
        // label.text and detailLabel.text takes their info from the progressObject.
        // They can be customized or use the default text.
        // To suppress one (or both) of the labels, set the descriptions to empty strings.
//        progress.localizedDescription = "Download Progress"

        Network.resume(with: progress) {
            hud.hide(animated: true)
        }
    }

    @objc func dimBackgroundExample() {
        let hud = HUD.show(to: container)
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func colorExample() {
        let hud = HUD.show(to: container)
        hud.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
        hud.label.text = "Loading..."
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func cancelWork(_ sender: UIButton) {
        Network.cancelTask()
    }

    @objc func multipleHUDExample() {
        /// Handle show `HUD` multiple times in the same `View`.

        HUD.isCountEnabled = true

        func request1() {
            let hud = HUD.show(to: container)
            Network.request(.random(in: 1...3)) {
                hud.hide(animated: true)

                print("response1 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            print("request1  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request2() {
            let hud = HUD.show(to: container)
            Network.request(.random(in: 1...3)) {
                hud.hide(animated: true)

                print("response2 --> hud(\(hud.hashValue)).count=\(hud.count)")
            }
            print("request2  --> hud(\(hud.hashValue)).count=\(hud.count)")
        }
        func request3() {
            let hud = HUD.show(to: container)
            Network.request(.random(in: 1...3)) {
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
