//
//  AdvancedViews.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyProgressHUD

private typealias HUDProgressView = FlyProgressHUD.ProgressView

// MARK: - Multiple HUDs (Count)

/// Demonstrates `isCountEnabled` for stacking multiple show/hide calls.
///
/// ```swift
/// hud.isCountEnabled = true
/// HUD.show(to: view) // count = 1
/// HUD.show(to: view) // count = 2
/// HUD.hide(for: view) // count = 1, still showing
/// HUD.hide(for: view) // count = 0, hides
/// ```
struct MultipleHUDsView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("isCountEnabled tracks show/hide balance")
                .font(.headline)

            Button("Show Counted HUD (x3)") {
                guard let view = hostView else { return }
                // Show 3 times
                for i in 1...3 {
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Task \(i)")
                    hud.isCountEnabled = true
                }
                // Hide 3 times with delay
                for i in 1...3 {
                    Task {
                        try? await Task.sleep(for: .seconds(Double(i)))
                        HUD.hide(for: view)
                    }
                }
            }

            Button("Show Multiple Separate HUDs") {
                guard let view = hostView else { return }
                let hud1 = HUD.show(to: view, mode: .indicator(), label: "HUD 1")
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    hud1.contentView.mode = .text
                    hud1.contentView.label.text = "Done 1"
                    try? await Task.sleep(for: .seconds(1.0))
                    hud1.hide()
                }
            }

            Button("HUD.huds(for: view)") {
                guard let view = hostView else { return }
                let count = HUD.huds(for: view).count
                let hud = HUD.show(to: view, mode: .text, label: "Active HUDs: \(count)")
                hud.hide(afterDelay: 1.5)
            }

            Button("HUD.lastHUD(for: view)") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "First HUD")
                Task {
                    try? await Task.sleep(for: .seconds(1.0))
                    if let last = HUD.lastHUD(for: view) {
                        last.contentView.label.text = "Found via lastHUD!"
                    }
                }
                hud.hide(afterDelay: 2.5)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Multiple HUDs")
        .hudHost($hostView)
    }
}

// MARK: - Mode Switching

/// Demonstrates dynamically switching `contentView.mode` on a live HUD.
///
/// ```swift
/// hud.contentView.mode = .indicator()
/// // later...
/// hud.contentView.mode = .custom(checkmark)
/// hud.contentView.label.text = "Done!"
/// ```
struct ModeSwitchingView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Switch mode on a live HUD")
                .font(.headline)

            Button("Indicator → Progress → Done") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Preparing...")

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    let pv = HUDProgressView(style: .round)
                    pv.isLabelEnabled = true
                    hud.contentView.mode = .custom(pv)
                    hud.contentView.label.text = "Downloading..."

                    var progress: Float = 0.0
                    while progress < 1.0 {
                        try? await Task.sleep(for: .milliseconds(80))
                        progress += 0.04
                        pv.progress = progress
                    }
                    let checkmark = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
                    hud.contentView.mode = .custom(checkmark)
                    hud.contentView.label.text = "Complete!"
                    hud.hide(afterDelay: 1.5)
                }
            }

            Button("Text → Indicator → Text") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .text, label: "Starting...")

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.0))
                    hud.contentView.mode = .indicator()
                    hud.contentView.label.text = "Working..."
                    try? await Task.sleep(for: .seconds(2.0))
                    hud.contentView.mode = .text
                    hud.contentView.label.text = "All done!"
                    hud.hide(afterDelay: 1.0)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Mode Switching")
        .hudHost($hostView)
    }
}

// MARK: - Observed Progress

/// Demonstrates `contentView.observedProgress` with Foundation.Progress.
///
/// ```swift
/// let progress = Progress(totalUnitCount: 100)
/// hud.contentView.observedProgress = progress
/// progress.completedUnitCount += 10
/// ```
struct ObservedProgressView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("observedProgress auto-updates HUD")
                .font(.headline)

            Button("Simulate with Foundation.Progress") {
                guard let view = hostView else { return }
                let pv = HUDProgressView(style: .round)
                pv.isLabelEnabled = true
                let hud = HUD.show(to: view, mode: .custom(pv), label: "Downloading...")

                let progress = Progress(totalUnitCount: 100)
                hud.contentView.observedProgress = progress

                Task { @MainActor in
                    while !progress.isFinished {
                        try? await Task.sleep(for: .milliseconds(50))
                        progress.completedUnitCount += 1
                    }
                    hud.hide(afterDelay: 0.3)
                }
            }

            Button("With Cancel Button") {
                guard let view = hostView else { return }
                let pv = HUDProgressView(style: .annularRound)
                pv.isLabelEnabled = true
                let hud = HUD.show(to: view, mode: .custom(pv), label: "Processing...")

                let progress = Progress(totalUnitCount: 200)
                hud.contentView.observedProgress = progress
                hud.contentView.button.setTitle("Cancel", for: .normal)
                hud.contentView.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

                Task { @MainActor in
                    while !progress.isCancelled && !progress.isFinished {
                        try? await Task.sleep(for: .milliseconds(50))
                        progress.completedUnitCount += 1
                    }
                    if progress.isCancelled {
                        hud.contentView.label.text = "Cancelled"
                        hud.hide(afterDelay: 1.0)
                    } else {
                        hud.hide(afterDelay: 0.3)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Observed Progress")
        .hudHost($hostView)
    }
}

// MARK: - Keyboard Guide

/// Demonstrates `HUD.KeyboardGuide` for keyboard-aware positioning.
///
/// ```swift
/// hud.keyboardGuide = .center()       // Center between top and keyboard
/// hud.keyboardGuide = .bottom(8)      // Above keyboard with 8pt spacing
/// HUD.keyboardGuide = .center()       // Global default
/// ```
#if os(iOS)
struct KeyboardGuideView: View {
    @State private var hostView: UIView?
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Shows HUD relative to keyboard")
                .font(.headline)

            TextField("Tap to show keyboard", text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()

            Button("keyboardGuide = .center()") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Centered") { hud in
                    hud.keyboardGuide = .center()
                }
                hud.hide(afterDelay: 2.0)
            }

            Button("keyboardGuide = .bottom(8)") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Above keyboard") { hud in
                    hud.keyboardGuide = .bottom(8)
                }
                hud.hide(afterDelay: 2.0)
            }

            Button("keyboardGuide = .disable") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "No keyboard adjust") { hud in
                    hud.keyboardGuide = .disable
                }
                hud.hide(afterDelay: 2.0)
            }

            Button("Set Global: HUD.keyboardGuide = .center()") {
                HUD.keyboardGuide = .center()
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .text, label: "Global keyboardGuide set!")
                hud.hide(afterDelay: 1.5)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Keyboard Guide")
        .hudHost($hostView)
    }
}
#endif

// MARK: - Dynamic Type

/// Demonstrates `isDynamicTypeEnabled` for accessibility text scaling.
///
/// ```swift
/// hud.contentView.isDynamicTypeEnabled = true
/// ```
struct DynamicTypeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Labels respond to system text size")
                .font(.headline)

            Button("isDynamicTypeEnabled = true") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Dynamic Type") { hud in
                    hud.contentView.isDynamicTypeEnabled = true
                    hud.contentView.detailsLabel.text = "Scales with system text size"
                }
                hud.hide(afterDelay: 3.0)
            }

            Button("isDynamicTypeEnabled = false (default)") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Fixed Size") { hud in
                    hud.contentView.isDynamicTypeEnabled = false
                    hud.contentView.detailsLabel.text = "Does not scale"
                }
                hud.hide(afterDelay: 3.0)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Dynamic Type")
        .hudHost($hostView)
    }
}

// MARK: - Delegate & Completion

/// Demonstrates `HUDDelegate` and `completionBlock`.
///
/// ```swift
/// hud.delegate = self  // hudWasHidden(_:) called
/// hud.completionBlock = { hud in print("Hidden!") }
/// ```
struct DelegateCompletionView: View {
    @State private var hostView: UIView?
    @State private var log: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Delegate & completion callbacks")
                .font(.headline)

            Button("Show with completionBlock") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Will call completion")
                hud.completionBlock = { _ in
                    log.append("[\(formattedTime())] completionBlock fired")
                }
                hud.hide(afterDelay: 1.5)
            }

            Button("Clear Log") {
                log.removeAll()
            }

            if !log.isEmpty {
                List(log, id: \.self) { entry in
                    Text(entry)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: 200)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Delegate & Completion")
        .hudHost($hostView)
    }

    private func formattedTime() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: Date())
    }
}
