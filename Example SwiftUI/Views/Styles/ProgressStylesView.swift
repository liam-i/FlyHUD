//
//  ProgressStylesView.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyHUDSwiftUI
import FlyProgressHUD

private typealias HUDProgressView = FlyProgressHUD.ProgressView

// MARK: - ProgressView Styles

/// Demonstrates all `HUDProgressView.Style` cases and configurable properties.
///
/// Properties demonstrated:
/// - `style`: buttBar, roundBar, round, annularRound, pie
/// - `progressTintColor`: Filled portion color
/// - `trackTintColor`: Unfilled portion color
/// - `lineWidth`: Line thickness
/// - `isLabelEnabled`: Show percentage label
/// - `labelFont`: Percentage label font
/// - `progress`: Manual progress value
/// - `observedProgress`: Auto-syncing with Foundation.Progress
struct ProgressStylesView: View {
    @State private var hostView: UIView?

    private let styles: [(HUDProgressView.Style, String)] = [
        (.buttBar, "Butt Bar"),
        (.roundBar, "Round Bar"),
        (.round, "Round"),
        (.annularRound, "Annular Round"),
        (.pie, "Pie"),
    ]

    var body: some View {
        List {
            Section("Tap to show HUD with style") {
                ForEach(styles, id: \.1) { style, name in
                    Button(name) {
                        showProgress(style: style, name: name)
                    }
                }
            }

            Section("Properties Demo") {
                Button("Custom progressTintColor") {
                    showWithProgressTint()
                }
                Button("Custom trackTintColor") {
                    showWithTrackTint()
                }
                Button("Custom lineWidth (6.0)") {
                    showWithLineWidth()
                }
                Button("isLabelEnabled = true") {
                    showWithLabel()
                }
                Button("Custom labelFont (.monospacedDigit)") {
                    showWithLabelFont()
                }
            }
        }
        .navigationTitle("ProgressView Styles")
        .hudHost($hostView)
    }

    private func showProgress(style: HUDProgressView.Style, name: String) {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: style)
        let hud = HUD.show(to: view, mode: .custom(pv), label: name)
        simulateProgress(pv: pv, hud: hud)
    }

    private func showWithProgressTint() {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: .round)
        pv.progressTintColor = .systemOrange
        let hud = HUD.show(to: view, mode: .custom(pv), label: "progressTintColor = .systemOrange")
        simulateProgress(pv: pv, hud: hud)
    }

    private func showWithTrackTint() {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: .annularRound)
        pv.trackTintColor = .systemPink.withAlphaComponent(0.3)
        let hud = HUD.show(to: view, mode: .custom(pv), label: "trackTintColor = .systemPink")
        simulateProgress(pv: pv, hud: hud)
    }

    private func showWithLineWidth() {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: .round)
        pv.lineWidth = 6.0
        let hud = HUD.show(to: view, mode: .custom(pv), label: "lineWidth = 6.0")
        simulateProgress(pv: pv, hud: hud)
    }

    private func showWithLabel() {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: .round)
        pv.isLabelEnabled = true
        let hud = HUD.show(to: view, mode: .custom(pv), label: "isLabelEnabled = true")
        simulateProgress(pv: pv, hud: hud)
    }

    private func showWithLabelFont() {
        guard let view = hostView else { return }
        let pv = HUDProgressView(style: .annularRound)
        pv.isLabelEnabled = true
        pv.labelFont = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        let hud = HUD.show(to: view, mode: .custom(pv), label: "Custom labelFont")
        simulateProgress(pv: pv, hud: hud)
    }

    private func simulateProgress(pv: HUDProgressView, hud: HUD) {
        Task { @MainActor in
            var progress: Float = 0.0
            while progress < 1.0 {
                try? await Task.sleep(for: .milliseconds(80))
                progress = min(progress + 0.03, 1.0)
                pv.progress = progress
            }
            hud.hide(afterDelay: 0.3)
        }
    }
}
