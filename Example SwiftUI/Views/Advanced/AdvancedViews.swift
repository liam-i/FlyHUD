//
//  AdvancedViews.swift
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
                let hud = HUD(with: view)
                hud.isCountEnabled = true
                hud.contentView.mode = .indicator()
                view.addSubview(hud)

                // Show 3 times (count increments each time)
                for i in 1...3 {
                    hud.show()
                    hud.contentView.label.text = "Count: \(hud.count)"
                    hud.contentView.detailsLabel.text = "Show \(i)/3"
                }
                // Hide 3 times with delay (count decrements each time)
                for i in 1...3 {
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(Double(i)))
                        hud.hide()
                        hud.contentView.label.text = "Count: \(hud.count)"
                    }
                }
            }

            Button("Show Multiple Separate HUDs") {
                guard let view = hostView else { return }
                let hud1 = HUD.show(to: view, mode: .indicator(), label: "HUD 1")
                Task { @MainActor in
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
                Task { @MainActor in
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
                        progress = min(progress + 0.04, 1.0)
                        pv.progress = progress
                    }
                    let checkmark = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
                    checkmark.isAccessibilityElement = false
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

// MARK: - GraceTime

struct GraceTimeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("graceTime delays HUD display.\nIf the task finishes before the grace period, the HUD never appears.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Fast Task (No HUD)") {
                guard let view = hostView else { return }
                let hud = HUD(with: view)
                hud.graceTime = 1.0
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "Won't appear"
                view.addSubview(hud)
                hud.show(animated: false)

                // Task completes in ~0.3s — within graceTime, so HUD never shows
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    hud.hide()
                }
            }

            Button("Slow Task (HUD Appears)") {
                guard let view = hostView else { return }
                let hud = HUD(with: view)
                hud.graceTime = 1.0
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "Slow task"
                hud.contentView.detailsLabel.text = "graceTime = 1s"
                view.addSubview(hud)
                hud.show()

                // Task takes 3s — exceeds graceTime, so HUD appears after 1s
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    hud.contentView.mode = .custom(UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)))
                    hud.contentView.label.text = "Done!"
                    hud.contentView.detailsLabel.text = nil
                    hud.hide(afterDelay: 1.5)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("GraceTime")
        .hudHost($hostView)
    }
}

// MARK: - MinShowTime

struct MinShowTimeView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("minShowTime ensures the HUD stays visible for a minimum duration, even if the task finishes early.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Quick Task (minShowTime = 2s)") {
                guard let view = hostView else { return }
                let hud = HUD(with: view)
                hud.minShowTime = 2.0
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "MinShowTime = 2s"
                hud.contentView.detailsLabel.text = "Task finishes fast, HUD stays"
                view.addSubview(hud)
                hud.show()

                // Task completes in ~0.5s, but HUD stays for 2s
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    hud.contentView.mode = .custom(UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)))
                    hud.contentView.label.text = "Done!"
                    hud.contentView.detailsLabel.text = "Waiting for minShowTime..."
                    hud.hide()
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("MinShowTime")
        .hudHost($hostView)
    }
}

// MARK: - URLSession Download

struct URLSessionDownloadView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Demonstrates progress tracking with a simulated download task.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Start Download") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .progress(.annularRound), label: "Downloading...")

                Task { @MainActor in
                    for i in 1...100 {
                        try? await Task.sleep(for: .milliseconds(30))
                        hud.contentView.progress = Float(i) / 100.0
                    }
                    hud.contentView.mode = .custom(UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate)))
                    hud.contentView.label.text = "Download Complete"
                    hud.hide(afterDelay: 1.5)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Download Progress")
        .hudHost($hostView)
    }
}
