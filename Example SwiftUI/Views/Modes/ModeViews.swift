//
//  ModeViews.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

private typealias HUDProgressView = FlyProgressHUD.ProgressView

/// A UIImageView conforming to RotateViewable for rotation animation.
class RotateImageView: UIImageView, RotateViewable {}

// MARK: - Indicator Mode

/// Demonstrates `ContentView.Mode.indicator(style)` with various system indicator styles.
///
/// ```swift
/// HUD.show(to: view, mode: .indicator(.large), label: "Loading")
/// ```
struct IndicatorModeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("System UIActivityIndicatorView modes")
                .font(.headline)

            Button("Default Indicator") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Loading...")
                hud.hide(afterDelay: 2.0)
            }

            Button("Large Indicator") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(.large), label: "Please wait")
                hud.hide(afterDelay: 2.0)
            }

            Button("Medium Indicator") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(.medium), label: "Processing")
                hud.hide(afterDelay: 2.0)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Indicator Mode")
        .hudHost($hostView)
    }
}

// MARK: - Progress Mode

/// Demonstrates `ContentView.Mode.progress(style)` with system UIProgressView.
///
/// ```swift
/// let hud = HUD.show(to: view, mode: .progress(.default), label: "Downloading")
/// hud.contentView.progress = 0.5
/// ```
struct ProgressModeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("System UIProgressView modes")
                .font(.headline)

            Button("Default Progress Bar") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .progress(.default), label: "Downloading...")
                simulateProgress(hud: hud)
            }

            Button("Bar Progress Style") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .progress(.bar), label: "Uploading...")
                simulateProgress(hud: hud)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Progress Mode")
        .hudHost($hostView)
    }

    private func simulateProgress(hud: HUD) {
        Task { @MainActor in
            var progress: Float = 0.0
            while progress < 1.0 {
                try? await Task.sleep(for: .milliseconds(100))
                progress += 0.05
                hud.contentView.progress = progress
            }
            hud.hide(afterDelay: 0.3)
        }
    }
}

// MARK: - Custom View Mode

/// Demonstrates `ContentView.Mode.custom(UIView)` with custom views.
///
/// ```swift
/// let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
/// HUD.show(to: view, mode: .custom(imageView), label: "Done!")
/// ```
struct CustomModeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Custom UIView as indicator")
                .font(.headline)

            Button("Checkmark Icon") {
                guard let view = hostView else { return }
                let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate))
                let hud = HUD.show(to: view, mode: .custom(iv), label: "Completed!")
                hud.hide(afterDelay: 2.0)
            }

            Button("Custom ProgressView (Round)") {
                guard let view = hostView else { return }
                let pv = HUDProgressView(style: .round)
                pv.progressTintColor = .systemBlue
                pv.trackTintColor = .systemGray4
                pv.isLabelEnabled = true
                let hud = HUD.show(to: view, mode: .custom(pv), label: "Downloading")
                simulateCustomProgress(pv: pv, hud: hud)
            }

            Button("Custom ActivityIndicatorView") {
                guard let view = hostView else { return }
                let indicator = ActivityIndicatorView(style: .ballSpinFade)
                indicator.color = .systemPurple
                indicator.trackColor = .systemGray5
                indicator.lineWidth = 3.0
                let hud = HUD.show(to: view, mode: .custom(indicator), label: "Custom Indicator")
                hud.hide(afterDelay: 3.0)
            }

            Button("RotateViewable Image") {
                guard let view = hostView else { return }
                let iv = RotateImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath")?.withRenderingMode(.alwaysTemplate))
                iv.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
                iv.contentMode = .scaleAspectFit
                iv.startRotating()
                let hud = HUD.show(to: view, mode: .custom(iv), label: "Syncing...")
                hud.hide(afterDelay: 3.0)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Custom Mode")
        .hudHost($hostView)
    }

    private func simulateCustomProgress(pv: HUDProgressView, hud: HUD) {
        Task { @MainActor in
            var progress: Float = 0.0
            while progress < 1.0 {
                try? await Task.sleep(for: .milliseconds(100))
                progress += 0.04
                pv.progress = progress
            }
            hud.hide(afterDelay: 0.3)
        }
    }
}
