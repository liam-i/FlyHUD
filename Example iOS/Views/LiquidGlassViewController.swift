//
//  LiquidGlassViewController.swift
//  Example iOS
//
//  Created by Liam on 2025/7/18.
//  Copyright © 2025 Liam. All rights reserved.
//

import UIKit
import FlyHUD

// MARK: - LiquidGlassViewController

/// Demonstrates FlyHUD with Liquid Glass style (iOS 26+).
#if compiler(>=6.2) && !os(visionOS)
@available(iOS 26.0, *)
final class LiquidGlassViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Glass HUD"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )
        setupUI()
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Gradient background to make glass visible
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemPurple.withAlphaComponent(0.2).cgColor,
            UIColor.systemOrange.withAlphaComponent(0.15).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.frame = view.bounds
        gradientLayer.name = "backgroundGradient"
        view.layer.insertSublayer(gradientLayer, at: 0)

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])

        // Default glass HUD
        let defaultButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Glass HUD") { [weak self] _ in
            guard let self else { return }
            let hud = HUD.show(to: self.view, mode: .indicator(), label: "Loading...") {
                $0.contentView.style = .glass
                $0.contentView.roundedCorners = .radius(20)
            }
            hud.hide(afterDelay: 2.5)
        })
        stackView.addArrangedSubview(defaultButton)

        // Tinted glass HUD
        let tintedButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Tinted Glass HUD") { [weak self] _ in
            guard let self else { return }
            let hud = HUD.show(to: self.view, mode: .indicator(), label: "Syncing...") {
                $0.contentView.style = .glass
                $0.contentView.color = .systemBlue
                $0.contentView.roundedCorners = .radius(20)
            }
            hud.hide(afterDelay: 2.5)
        })
        stackView.addArrangedSubview(tintedButton)

        // Full-rounded glass HUD
        let fullButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Full Rounded Glass") { [weak self] _ in
            guard let self else { return }
            let hud = HUD.show(to: self.view, mode: .indicator(), label: "Done") {
                $0.contentView.style = .glass
                $0.contentView.roundedCorners = .full
            }
            hud.hide(afterDelay: 2.5)
        })
        stackView.addArrangedSubview(fullButton)

        // Text-only glass HUD
        let textButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Text-Only Glass") { [weak self] _ in
            guard let self else { return }
            let hud = HUD.show(to: self.view, mode: .text, label: "Saved!", detailsLabel: "Your changes have been saved") {
                $0.contentView.style = .glass
                $0.contentView.roundedCorners = .radius(16)
            }
            hud.hide(afterDelay: 2.0)
        })
        stackView.addArrangedSubview(textButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layer.sublayers?.first { $0.name == "backgroundGradient" }?.frame = view.bounds
    }

    // MARK: - Actions

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
#endif
