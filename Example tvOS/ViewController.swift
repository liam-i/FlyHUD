//
//  ViewController.swift
//  Example tvOS
//
//  Created by Liam on 2024/1/15.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

class ViewController: UIViewController {
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 30
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private lazy var topRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 40
        sv.alignment = .center
        return sv
    }()

    private lazy var bottomRow: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 40
        sv.alignment = .center
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        let demos: [(String, Selector)] = [
            ("Indicator", #selector(showIndicator)),
            ("Progress Bar", #selector(showProgressBar)),
            ("Circular Progress", #selector(showCircularProgress)),
            ("Toast", #selector(showToast)),
            ("Custom Icon", #selector(showCustomIcon)),
            ("Mode Switching", #selector(showModeSwitching)),
            ("Observed Progress", #selector(showObservedProgress)),
            ("Activity Indicators", #selector(showActivityIndicators))
        ]

        for (index, demo) in demos.enumerated() {
            let button = makeButton(title: demo.0, action: demo.1)
            if index < 4 {
                topRow.addArrangedSubview(button)
            } else {
                bottomRow.addArrangedSubview(button)
            }
        }

        stackView.addArrangedSubview(topRow)
        stackView.addArrangedSubview(bottomRow)
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .primaryActionTriggered)
        button.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40)
        return button
    }

    // MARK: - Demo: System Indicator

    @objc private func showIndicator() {
        let hud = HUD.show(to: view, label: "Loading...") {
            $0.contentView.detailsLabel.text = "Please wait"
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
            $0.contentView.detailsLabel.font = .systemFont(ofSize: 24)
        }
        hud.hide(afterDelay: 3.0)
    }

    // MARK: - Demo: Progress Bar

    @objc private func showProgressBar() {
        let hud = HUD.show(to: view) {
            $0.contentView.mode = .custom(ProgressView(style: .buttBar, size: CGSize(width: 320, height: 40)).h.then {
                $0.lineWidth = 10
            })
            $0.contentView.label.text = NSLocalizedString("Downloading...", comment: "HUD progress title")
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Task {
            await Self.simulateProgress { progress in
                hud.contentView.progress = progress
            }
            hud.contentView.mode = .text
            hud.contentView.label.text = "Done!"
            hud.hide(afterDelay: 1.0)
        }
    }

    // MARK: - Demo: Circular Progress

    @objc private func showCircularProgress() {
        let hud = HUD.show(to: view) {
            $0.contentView.mode = .custom(ProgressView(style: .annularRound, size: CGSize(width: 60, height: 60)).h.then {
                $0.lineWidth = 4
                $0.isLabelEnabled = true
                $0.labelFont = .boldSystemFont(ofSize: 14)
            })
            $0.contentView.label.text = NSLocalizedString("Uploading...", comment: "HUD upload title")
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Task {
            await Self.simulateProgress(duration: 4) { progress in
                hud.contentView.progress = progress
            }
            hud.contentView.mode = .text
            hud.contentView.label.text = "Upload Complete"
            hud.hide(afterDelay: 1.5)
        }
    }

    // MARK: - Demo: Toast

    @objc private func showToast() {
        HUD.showStatus(to: view, duration: 2.5, label: "Settings Saved") {
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
            $0.contentView.detailsLabel.text = "Your preferences have been updated"
            $0.contentView.detailsLabel.font = .systemFont(ofSize: 24)
        }
    }

    // MARK: - Demo: Custom Icon

    @objc private func showCustomIcon() {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60)
        ])

        let hud = HUD.show(to: view, mode: .custom(imageView), label: "Success!") {
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }
        hud.hide(afterDelay: 2.5)
    }

    // MARK: - Demo: Mode Switching

    @objc private func showModeSwitching() {
        let hud = HUD.show(to: view, label: "Preparing...") {
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            // Switch to progress mode
            hud.contentView.mode = .progress()
            hud.contentView.label.text = "Downloading..."

            await Self.simulateProgress(duration: 3) { progress in
                hud.contentView.progress = progress
            }

            // Switch to custom icon mode (success)
            let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
            checkmark.tintColor = .systemGreen
            checkmark.contentMode = .scaleAspectFit
            checkmark.isAccessibilityElement = false
            checkmark.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                checkmark.widthAnchor.constraint(equalToConstant: 60),
                checkmark.heightAnchor.constraint(equalToConstant: 60)
            ])
            hud.contentView.mode = .custom(checkmark)
            hud.contentView.label.text = "Complete!"

            hud.hide(afterDelay: 2.0)
        }
    }

    // MARK: - Demo: Observed Progress

    @objc private func showObservedProgress() {
        let progress = Progress(totalUnitCount: 100)
        let hud = HUD.show(to: view) {
            $0.contentView.mode = .custom(ProgressView(style: .round, size: CGSize(width: 60, height: 60)).h.then {
                $0.lineWidth = 4
                $0.isLabelEnabled = true
                $0.labelFont = .boldSystemFont(ofSize: 14)
            })
            $0.contentView.observedProgress = progress
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Task {
            for i in 1...100 {
                try? await Task.sleep(nanoseconds: 40_000_000)
                progress.completedUnitCount = Int64(i)
            }
            hud.hide(afterDelay: 1.0)
        }
    }

    // MARK: - Demo: Activity Indicators

    @objc private func showActivityIndicators() {
        let styles: [ActivityIndicatorView.Style] = [
            .ringClipRotate, .ballSpinFade, .circleStrokeSpin, .circleArcDotSpin
        ]
        let styleNames = ["Ring Clip", "Ball Spin", "Circle Stroke", "Circle Arc"]

        let hud = HUD.show(to: view) {
            $0.contentView.mode = .indicator(styles[0])
            $0.contentView.label.text = styleNames[0]
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
            $0.contentView.detailsLabel.text = "1/\(styles.count)"
            $0.contentView.detailsLabel.font = .systemFont(ofSize: 24)
        }

        Task {
            for i in 1..<styles.count {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                hud.contentView.mode = .indicator(styles[i])
                hud.contentView.label.text = styleNames[i]
                hud.contentView.detailsLabel.text = "\(i + 1)/\(styles.count)"
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            hud.hide()
        }
    }

    // MARK: - Helpers

    /// Simulates a progress task using structured concurrency.
    static func simulateProgress(
        duration: UInt32 = 3,
        onProgress: @MainActor @Sendable @escaping (Float) -> Void
    ) async {
        let steps = 100
        let intervalNanoseconds = UInt64(duration) * 1_000_000_000 / UInt64(steps)

        for step in 1...steps {
            try? await Task.sleep(nanoseconds: intervalNanoseconds)
            let progress = Float(step) / Float(steps)
            await MainActor.run { onProgress(progress) }
        }
    }
}
