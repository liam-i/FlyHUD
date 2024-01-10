//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

class ViewController: UITableViewController {
    // MARK: Getters and Setters
    private lazy var examples: [[Model]] = Model.examples
}

// MARK: Examples

extension ViewController {
    @objc func indeterminateExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func labelExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "Loading..."

        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func detailsLabelExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "Loading..."
        hud.detailsLabel.text = "Parsing data\n(1/1)"

        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func determinateExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.detailsLabel.text = "Loading..."

        Network.request {
            HUD.hud(for: self.navigationController!.view)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func annularDeterminateExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .annularDeterminate
        hud.label.text = "Loading..."

        Network.request {
            HUD.hud(for: self.navigationController!.view)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func barDeterminateExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "Loading..."

        Network.request {
            HUD.hud(for: self.navigationController!.view)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func textExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .text
        hud.label.text = "Wrong password"
        hud.offset = CGPoint(x: 0.0, y: HUD.maxOffset) // 移动到底部居中
        hud.hide(animated: true, afterDelay: 3.0)
    }

    @objc func customViewExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
        hud.isSquare = true
        hud.label.text = "Done"
        hud.hide(animated: true, afterDelay: 3.0)
    }

    @objc func cancelationExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.label.text = "Loading..."
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(self, action: #selector(cancelWork), for: .touchUpInside)

        Network.request {
            HUD.hud(for: self.navigationController!.view)?.progress = $0
        } completion: {
            hud.hide(animated: true)
        }
    }

    @objc func modeSwitchingExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "Preparing..."
        hud.minSize = CGSize(width: 150.0, height: 100.0)

        Network.requestMultiTask {
            HUD.hud(for: self.navigationController!.view)?.progress = $0
        } completion: {
            switch $0 {
            case 3:
                guard let hud = HUD.hud(for: self.navigationController!.view) else { return assertionFailure() }
                hud.mode = .determinate
                hud.label.text = "Loading..."
            case 2:
                guard let hud = HUD.hud(for: self.navigationController!.view) else { return assertionFailure() }
                hud.mode = .indeterminate
                hud.label.text = "Cleaning up..."
            case 1:
                guard let hud = HUD.hud(for: self.navigationController!.view) else { return assertionFailure() }
                hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
                hud.mode = .customView
                hud.label.text = "Completed"
            case 0:
                hud.hide(animated: true)
            default:
                assertionFailure()
            }
        }
    }

    @objc func windowExample() {
        let hud = HUD.show(to: view.window!, animated: true)
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func networkingExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "Preparing..."
        hud.minSize = CGSize(width: 150.0, height: 100.0)

        Network.download {
            guard let hud = HUD.hud(for: self.navigationController!.view) else { return }
            hud.mode = .determinate
            hud.progress = $0
        } completion: {
            guard let hud = HUD.hud(for: self.navigationController!.view) else { return }
            hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
            hud.mode = .customView
            hud.label.text = "Completed"
            hud.hide(animated: true, afterDelay: 3.0)
        }
    }

    @objc func determinateProgressExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.label.text = "Loading..."
        let progress = Progress(totalUnitCount: 100)
        hud.progressObject = progress
        hud.button.setTitle("Cancel", for: .normal)
        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

        Network.resume(with: progress) {
            hud.hide(animated: true)
        }
    }

    @objc func dimBackgroundExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func colorExample() {
        let hud = HUD.show(to: navigationController!.view, animated: true)
        hud.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
        hud.label.text = "Loading..."
        Network.request {
            hud.hide(animated: true)
        }
    }

    @objc func cancelWork(_ sender: UIButton) {
        Network.cancelTask()
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension ViewController {
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
