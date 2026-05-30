//
//  DeclarativeModifiersView.swift
//  Example SwiftUI
//
//  Created by Liam on 2025/5/26.
//  Copyright © 2025 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyHUDSwiftUI
import FlyProgressHUD

// MARK: - HUD isPresented Modifier

/// Demonstrates `.hud(isPresented:animation:configuration:)` — the primary declarative modifier.
///
/// This is the core SwiftUI API for presenting HUDs declaratively. It bridges
/// FlyHUD's UIKit-based HUD to SwiftUI using a Bool binding for visibility control.
///
/// **Parameters demonstrated:**
/// - `isPresented`: Bool binding — HUD shows when `true`, hides when `false`
/// - `animation`: `HUD.Animation` — controls show/hide transition style, damping, and duration
/// - `configuration`: `(HUD) -> Void` — closure to configure mode, labels, colors, layout, etc.
///
/// **Key behaviors:**
/// - Setting `isPresented = false` triggers hide animation
/// - The `configuration` closure is called on each SwiftUI update (can reconfigure live HUD)
/// - HUD's `completionBlock` automatically resets `isPresented` to `false` on hide
///
/// ```swift
/// .hud(isPresented: $isLoading, animation: .animation(.zoomIn, damping: .default)) { hud in
///     hud.contentView.mode = .indicator()
///     hud.contentView.label.text = "Loading..."
///     hud.contentView.detailsLabel.text = "Please wait"
///     hud.contentView.contentColor = .systemBlue
/// }
/// ```
struct HUDIsPresentedView: View {
    @State private var isLoading = false
    @State private var selectedAnimation: HUD.Animation = .init()
    @State private var animationName = "default"

    var body: some View {
        List {
            // MARK: Animation Style Demos
            Section("Animation Styles") {
                Button("Default (fade)") {
                    showWith(animation: .init(), name: "default (fade)")
                }
                Button(".animation(.zoomIn)") {
                    showWith(animation: .animation(.zoomIn), name: "zoomIn")
                }
                Button(".animation(.zoomInOut)") {
                    showWith(animation: .animation(.zoomInOut), name: "zoomInOut")
                }
                Button(".animation(.slideUp)") {
                    showWith(animation: .animation(.slideUp), name: "slideUp")
                }
                Button(".animation(.slideDown)") {
                    showWith(animation: .animation(.slideDown), name: "slideDown")
                }
                Button(".animation(.slideRightLeft)") {
                    showWith(animation: .animation(.slideRightLeft), name: "slideRightLeft")
                }
            }

            // MARK: Damping Demos
            Section("Damping Parameter") {
                Button("damping: .disable (no spring)") {
                    showWith(animation: .animation(.zoomIn, damping: .disable), name: "zoomIn, damping: .disable")
                }
                Button("damping: .default") {
                    showWith(animation: .animation(.zoomIn, damping: .default), name: "zoomIn, damping: .default")
                }
                Button("damping: .ratio(0.4) (bouncy)") {
                    showWith(animation: .animation(.zoomIn, damping: .ratio(0.4)), name: "zoomIn, damping: .ratio(0.4)")
                }
                Button("damping: .ratio(0.8) (subtle)") {
                    showWith(animation: .animation(.zoomIn, damping: .ratio(0.8)), name: "zoomIn, damping: .ratio(0.8)")
                }
            }

            // MARK: Duration Demos
            Section("Duration Parameter") {
                Button("duration: 0.1 (very fast)") {
                    showWith(animation: .animation(.fade, duration: 0.1), name: "fade, duration: 0.1")
                }
                Button("duration: 0.3 (default)") {
                    showWith(animation: .animation(.fade, duration: 0.3), name: "fade, duration: 0.3")
                }
                Button("duration: 1.0 (slow)") {
                    showWith(animation: .animation(.fade, duration: 1.0), name: "fade, duration: 1.0")
                }
                Button("duration: 2.0 (very slow)") {
                    showWith(animation: .animation(.fade, duration: 2.0), name: "fade, duration: 2.0")
                }
            }

            // MARK: Configuration Closure Demos
            Section("Configuration Closure") {
                Button("Mode: .indicator() + label") {
                    selectedAnimation = .animation(.zoomInOut, damping: .default)
                    animationName = "indicator + label"
                    isLoading = true
                    hideAfter(2.0)
                }
                Button("Mode: .text + detailsLabel") {
                    selectedAnimation = .init()
                    animationName = "text + details"
                    isLoading = true
                    hideAfter(2.0)
                }
                Button("Custom contentColor (.systemBlue)") {
                    selectedAnimation = .animation(.zoomIn)
                    animationName = "contentColor: .systemBlue"
                    isLoading = true
                    hideAfter(2.0)
                }
            }

            // MARK: Manual Control
            Section("Manual Control") {
                Button("Hide Immediately (isPresented = false)") {
                    isLoading = false
                }
                .disabled(!isLoading)

                Text("isPresented = \(isLoading ? "true" : "false")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("animation = \(animationName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(".hud(isPresented:)")
        .hud(isPresented: $isLoading, animation: selectedAnimation) { hud in
            // Configuration closure — called on each update
            switch animationName {
            case "text + details":
                hud.contentView.mode = .text
                hud.contentView.label.text = "Message Sent"
                hud.contentView.detailsLabel.text = "Your message has been delivered"
            case "contentColor: .systemBlue":
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "Styled HUD"
                hud.contentView.contentColor = .systemBlue
            default:
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "Loading..."
                hud.contentView.detailsLabel.text = "Animation: \(animationName)"
            }
        }
    }

    private func showWith(animation: HUD.Animation, name: String) {
        selectedAnimation = animation
        animationName = name
        isLoading = true
        hideAfter(2.5)
    }

    private func hideAfter(_ seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            isLoading = false
        }
    }
}

// MARK: - HUD Item Modifier

/// Demonstrates `.hud(item:animation:configuration:)` — item-driven declarative modifier.
///
/// The HUD is shown when `item` is non-nil and hidden when set to `nil`.
/// This pattern is ideal for presenting different HUD configurations based on
/// application state, similar to SwiftUI's `.sheet(item:)` pattern.
///
/// **Parameters demonstrated:**
/// - `item`: `Binding<Item?>` where `Item: Identifiable` — drives show/hide
/// - `animation`: `HUD.Animation` — transition animation (applied to all items)
/// - `configuration`: `(Item, HUD) -> Void` — configures HUD based on current item
///
/// **Key behaviors:**
/// - Each new item value triggers a HUD reconfiguration
/// - Setting item to `nil` hides the HUD
/// - The item's identity is used to detect changes
///
/// ```swift
/// struct LoadState: Identifiable {
///     let id = UUID()
///     let mode: ContentView.Mode
///     let label: String
/// }
///
/// .hud(item: $loadState, animation: .animation(.zoomInOut)) { state, hud in
///     hud.contentView.mode = state.mode
///     hud.contentView.label.text = state.label
/// }
/// ```
struct HUDItemView: View {
    @State private var hudItem: HUDDisplayItem?
    @State private var useAnimation: HUD.Animation = .animation(.zoomInOut)

    var body: some View {
        List {
            // MARK: Different Mode Items
            Section("Different Modes via Item") {
                Button("Indicator Item") {
                    hudItem = HUDDisplayItem(mode: .indicator(), label: "Loading...", details: nil)
                    hideItemAfter(2.0)
                }
                Button("Large Indicator Item") {
                    hudItem = HUDDisplayItem(mode: .indicator(.large), label: "Processing", details: "Please wait...")
                    hideItemAfter(2.5)
                }
                Button("Text Item") {
                    hudItem = HUDDisplayItem(mode: .text, label: "Saved!", details: "Your changes are saved")
                    hideItemAfter(1.5)
                }
                Button("Custom Icon Item (checkmark)") {
                    let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate))
                    iv.isAccessibilityElement = false
                    hudItem = HUDDisplayItem(mode: .custom(iv), label: "Success", details: nil)
                    hideItemAfter(2.0)
                }
                Button("Custom Icon Item (exclamationmark)") {
                    let iv = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill")?.withRenderingMode(.alwaysTemplate))
                    iv.isAccessibilityElement = false
                    hudItem = HUDDisplayItem(mode: .custom(iv), label: "Warning", details: "Check your input")
                    hideItemAfter(2.5)
                }
            }

            // MARK: Animation Parameter
            Section("Animation Parameter") {
                Button("zoomInOut (current)") {
                    useAnimation = .animation(.zoomInOut)
                    hudItem = HUDDisplayItem(mode: .indicator(), label: "zoomInOut", details: nil)
                    hideItemAfter(2.0)
                }
                Button("slideUpDown") {
                    useAnimation = .animation(.slideUpDown)
                    hudItem = HUDDisplayItem(mode: .indicator(), label: "slideUpDown", details: nil)
                    hideItemAfter(2.0)
                }
                Button("fade with damping") {
                    useAnimation = .animation(.fade, damping: .ratio(0.5))
                    hudItem = HUDDisplayItem(mode: .indicator(), label: "fade + damping", details: nil)
                    hideItemAfter(2.0)
                }
            }

            // MARK: Item Switching
            Section("Rapid Item Switching") {
                Button("Switch Items (A → B → C → nil)") {
                    Task { @MainActor in
                        hudItem = HUDDisplayItem(mode: .indicator(), label: "Step A", details: "Starting...")
                        try? await Task.sleep(for: .seconds(1.0))
                        hudItem = HUDDisplayItem(mode: .indicator(.large), label: "Step B", details: "In progress...")
                        try? await Task.sleep(for: .seconds(1.0))
                        let iv = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
                        iv.isAccessibilityElement = false
                        hudItem = HUDDisplayItem(mode: .custom(iv), label: "Step C", details: "Done!")
                        try? await Task.sleep(for: .seconds(1.0))
                        hudItem = nil
                    }
                }
            }

            // MARK: Manual Dismiss
            Section("Control") {
                Button("Dismiss (item = nil)") {
                    hudItem = nil
                }
                .disabled(hudItem == nil)

                Text("item = \(hudItem?.label ?? "nil")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(".hud(item:)")
        .hud(item: $hudItem, animation: useAnimation) { item, hud in
            hud.contentView.mode = item.mode
            hud.contentView.label.text = item.label
            hud.contentView.detailsLabel.text = item.details
        }
    }

    private func hideItemAfter(_ seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            hudItem = nil
        }
    }
}

/// A sample Identifiable item for driving HUD state.
private struct HUDDisplayItem: Identifiable {
    let id = UUID()
    let mode: ContentView.Mode
    let label: String
    let details: String?
}

// MARK: - HUD Status Modifier

/// Demonstrates `.hudStatus(isPresented:duration:animation:configuration:)` — self-dismissing HUD.
///
/// The HUD automatically hides after the specified duration and resets the binding to `false`.
/// This is ideal for toast-like notifications where you want to show a brief message.
///
/// **Parameters demonstrated:**
/// - `isPresented`: `Binding<Bool>` — triggers show on `true`, auto-resets to `false`
/// - `duration`: `TimeInterval` — seconds before auto-hide (default: 2.0)
/// - `animation`: `HUD.Animation` — transition animation for show/hide
/// - `configuration`: `(HUD) -> Void` — full HUD configuration closure
///
/// **Key behaviors:**
/// - Binding resets to `false` after duration expires and hide animation completes
/// - Rising edge detection: only shows on `false → true` transition
/// - Setting `isPresented = false` manually hides early
///
/// ```swift
/// .hudStatus(isPresented: $showStatus, duration: 2.0, animation: .animation(.slideUp)) { hud in
///     hud.contentView.mode = .custom(imageView)
///     hud.contentView.label.text = "Done!"
///     hud.contentView.contentColor = .systemGreen
/// }
/// ```
struct HUDStatusModifierView: View {
    @State private var showSuccess = false
    @State private var showError = false
    @State private var showCustomAnim = false
    @State private var showWithAppearance = false
    @State private var showLongDuration = false

    var body: some View {
        List {
            // MARK: Duration Variations
            Section("Duration Parameter") {
                Button("duration: 1.0 (quick)") {
                    showSuccess = true
                }
                Button("duration: 3.0 (longer)") {
                    showError = true
                }
                Button("duration: 5.0 (long)") {
                    showLongDuration = true
                }
            }

            // MARK: Animation Variations
            Section("Animation Parameter") {
                Button("Default animation (fade)") {
                    showSuccess = true
                }
                Button(".animation(.zoomIn)") {
                    showError = true
                }
                Button(".animation(.slideUp, damping: .default)") {
                    showCustomAnim = true
                }
            }

            // MARK: Configuration Examples
            Section("Configuration Closure") {
                Button("Success with icon + color") {
                    showSuccess = true
                }
                Button("Error with icon + red color") {
                    showError = true
                }
                Button("Custom appearance (blur + white)") {
                    showWithAppearance = true
                }
            }

            // MARK: State Display
            Section("Binding State") {
                Text("showSuccess = \(showSuccess ? "true" : "false")")
                    .font(.caption)
                Text("showError = \(showError ? "true" : "false")")
                    .font(.caption)
                Text("showCustomAnim = \(showCustomAnim ? "true" : "false")")
                    .font(.caption)
                Text("showWithAppearance = \(showWithAppearance ? "true" : "false")")
                    .font(.caption)
                Text("showLongDuration = \(showLongDuration ? "true" : "false")")
                    .font(.caption)
            }
        }
        .navigationTitle(".hudStatus()")
        // duration: 1.0, default animation
        .hudStatus(isPresented: $showSuccess, duration: 1.0) { hud in
            let iv = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
            iv.isAccessibilityElement = false
            hud.contentView.mode = .custom(iv)
            hud.contentView.label.text = "Success!"
            hud.contentView.contentColor = .systemGreen
        }
        // duration: 3.0, zoomIn animation
        .hudStatus(isPresented: $showError, duration: 3.0, animation: .animation(.zoomIn)) { hud in
            let iv = UIImageView(image: UIImage(systemName: "xmark.circle")?.withRenderingMode(.alwaysTemplate))
            iv.isAccessibilityElement = false
            hud.contentView.mode = .custom(iv)
            hud.contentView.label.text = "Failed!"
            hud.contentView.detailsLabel.text = "Please try again"
            hud.contentView.contentColor = .systemRed
        }
        // slideUp + damping animation
        .hudStatus(isPresented: $showCustomAnim, duration: 2.0, animation: .animation(.slideUp, damping: .default)) { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "Syncing..."
            hud.contentView.detailsLabel.text = "slideUp + damping animation"
        }
        // Custom appearance: blur background, white content
        .hudStatus(isPresented: $showWithAppearance, duration: 2.5, animation: .animation(.zoomInOut)) { hud in
            let iv = UIImageView(image: UIImage(systemName: "info.circle.fill")?.withRenderingMode(.alwaysTemplate))
            iv.isAccessibilityElement = false
            hud.contentView.mode = .custom(iv)
            hud.contentView.label.text = "Info"
            hud.contentView.detailsLabel.text = "Custom blur style"
            hud.contentView.style = .blur(.dark)
            hud.contentView.contentColor = .white
        }
        // Long duration: 5.0
        .hudStatus(isPresented: $showLongDuration, duration: 5.0) { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Long Notice"
            hud.contentView.detailsLabel.text = "This will stay visible for 5 seconds"
        }
    }
}

// MARK: - HUD Loading Convenience

/// Demonstrates `.hudLoading(isPresented:label:detailsLabel:)` — convenience loading preset.
///
/// This is a high-level convenience that internally creates a `.hud(isPresented:)` modifier
/// with `mode = .indicator()` pre-configured. It's the simplest way to show a loading state.
///
/// **Parameters demonstrated:**
/// - `isPresented`: `Binding<Bool>` — controls visibility
/// - `label`: `String?` — optional main label below indicator (default: nil)
/// - `detailsLabel`: `String?` — optional details label below main label (default: nil)
///
/// **Comparison with `.hud(isPresented:)`:**
/// - `.hudLoading()` = preset with indicator mode, no animation customization
/// - `.hud(isPresented:)` = full control over mode, animation, appearance
///
/// ```swift
/// // Simplest usage — just an indicator
/// .hudLoading(isPresented: $isLoading)
///
/// // With label
/// .hudLoading(isPresented: $isLoading, label: "Loading...")
///
/// // With label + details
/// .hudLoading(isPresented: $isLoading, label: "Downloading", detailsLabel: "2.3 MB remaining")
/// ```
struct HUDLoadingView: View {
    @State private var isLoadingSimple = false
    @State private var isLoadingLabel = false
    @State private var isLoadingDetails = false

    var body: some View {
        List {
            // MARK: Parameter Combinations
            Section("Parameter Combinations") {
                Button("No parameters (indicator only)") {
                    isLoadingSimple = true
                    hideAfter(2.0, binding: $isLoadingSimple)
                }
                Button("label: \"Loading...\"") {
                    isLoadingLabel = true
                    hideAfter(2.0, binding: $isLoadingLabel)
                }
                Button("label + detailsLabel") {
                    isLoadingDetails = true
                    hideAfter(2.5, binding: $isLoadingDetails)
                }
            }

            // MARK: Simulated Tasks
            Section("Simulated Real-World Usage") {
                Button("Network Request (1.5s)") {
                    isLoadingLabel = true
                    hideAfter(1.5, binding: $isLoadingLabel)
                }
                Button("File Download (3s)") {
                    isLoadingDetails = true
                    hideAfter(3.0, binding: $isLoadingDetails)
                }
                Button("Quick Validation (0.5s)") {
                    isLoadingSimple = true
                    hideAfter(0.5, binding: $isLoadingSimple)
                }
            }

            // MARK: State Display
            Section("Binding State") {
                Text("isLoadingSimple = \(isLoadingSimple ? "true" : "false")")
                    .font(.caption)
                Text("isLoadingLabel = \(isLoadingLabel ? "true" : "false")")
                    .font(.caption)
                Text("isLoadingDetails = \(isLoadingDetails ? "true" : "false")")
                    .font(.caption)
            }
        }
        .navigationTitle(".hudLoading()")
        .hudLoading(isPresented: $isLoadingSimple)
        .hudLoading(isPresented: $isLoadingLabel, label: "Loading...")
        .hudLoading(isPresented: $isLoadingDetails, label: "Downloading", detailsLabel: "This may take a moment")
    }

    private func hideAfter(_ seconds: Double, binding: Binding<Bool>) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            binding.wrappedValue = false
        }
    }
}

// MARK: - HUD Toast Convenience

/// Demonstrates `.hudToast(isPresented:duration:label:detailsLabel:)` — convenience toast preset.
///
/// Internally uses `.hudStatus()` with `mode = .text` pre-configured.
/// Ideal for brief text notifications that don't need an indicator.
///
/// **Parameters demonstrated:**
/// - `isPresented`: `Binding<Bool>` — triggers show on `true`, auto-resets to `false`
/// - `duration`: `TimeInterval` — seconds before auto-hide (default: 1.5)
/// - `label`: `String` — **required** main text to display
/// - `detailsLabel`: `String?` — optional secondary text (default: nil)
///
/// **Comparison with `.hudStatus()`:**
/// - `.hudToast()` = preset text-only toast, simple parameters
/// - `.hudStatus()` = full control over mode, animation, appearance
///
/// ```swift
/// // Simple toast
/// .hudToast(isPresented: $show, label: "Copied!")
///
/// // With duration and details
/// .hudToast(isPresented: $show, duration: 3.0, label: "Saved", detailsLabel: "All changes saved")
/// ```
struct HUDToastView: View {
    @State private var showSimple = false
    @State private var showDetails = false
    @State private var showShort = false
    @State private var showLong = false

    var body: some View {
        List {
            // MARK: Duration Variations
            Section("Duration Variations") {
                Button("duration: 0.8 (quick flash)") {
                    showShort = true
                }
                Button("duration: 1.5 (default)") {
                    showSimple = true
                }
                Button("duration: 2.0") {
                    showDetails = true
                }
                Button("duration: 4.0 (long)") {
                    showLong = true
                }
            }

            // MARK: Label Variations
            Section("Label & Details Combinations") {
                Button("Label only: \"Copied\"") {
                    showShort = true
                }
                Button("Label only: \"Message sent\"") {
                    showSimple = true
                }
                Button("Label + detailsLabel") {
                    showDetails = true
                }
                Button("Long text label + details") {
                    showLong = true
                }
            }

            // MARK: Real-World Scenarios
            Section("Real-World Usage") {
                Button("Copy to clipboard") {
                    showShort = true
                }
                Button("Send message") {
                    showSimple = true
                }
                Button("Save document") {
                    showDetails = true
                }
                Button("Batch operation complete") {
                    showLong = true
                }
            }

            // MARK: State Display
            Section("Binding State (auto-resets to false)") {
                Text("showSimple = \(showSimple ? "true" : "false")")
                    .font(.caption)
                Text("showDetails = \(showDetails ? "true" : "false")")
                    .font(.caption)
                Text("showShort = \(showShort ? "true" : "false")")
                    .font(.caption)
                Text("showLong = \(showLong ? "true" : "false")")
                    .font(.caption)
            }
        }
        .navigationTitle(".hudToast()")
        .hudToast(isPresented: $showSimple, label: "Message sent")
        .hudToast(isPresented: $showDetails, duration: 2.0, label: "Saved!", detailsLabel: "Your changes have been applied")
        .hudToast(isPresented: $showShort, duration: 0.8, label: "Copied")
        .hudToast(isPresented: $showLong, duration: 4.0, label: "Processing complete", detailsLabel: "All 42 items have been uploaded successfully")
    }
}

// MARK: - HUD Progress Convenience

/// Demonstrates `.hudProgress(isPresented:progress:label:)` — convenience progress preset.
///
/// This modifier presents a progress HUD with a system `UIProgressView` that's bound
/// to a `Float` value. The progress updates in real-time as the binding changes.
///
/// **Parameters demonstrated:**
/// - `isPresented`: `Binding<Bool>` — controls visibility
/// - `progress`: `Binding<Float>` — progress value (0.0 to 1.0), updates HUD in real-time
/// - `label`: `String?` — optional label below the progress indicator (default: nil)
///
/// **Key behaviors:**
/// - Progress value updates are reflected immediately on the HUD
/// - Setting `isPresented = false` hides the HUD regardless of progress value
/// - The HUD uses system `UIProgressView` (not custom ProgressView from FlyProgressHUD)
///
/// **Comparison with manual approach:**
/// ```swift
/// // Convenience (this modifier)
/// .hudProgress(isPresented: $isUploading, progress: $progress, label: "Uploading")
///
/// // Equivalent manual approach
/// .hud(isPresented: $isUploading) { hud in
///     hud.contentView.mode = .progress()
///     hud.contentView.progress = progress
///     hud.contentView.label.text = "Uploading"
/// }
/// ```
struct HUDProgressModifierView: View {
    @State private var isUploading = false
    @State private var progress: Float = 0.0
    @State private var isDownloading = false
    @State private var downloadProgress: Float = 0.0
    @State private var isSyncing = false
    @State private var syncProgress: Float = 0.0

    var body: some View {
        List {
            // MARK: With / Without Label
            Section("Label Parameter") {
                Button("With label: \"Uploading...\"") {
                    progress = 0.0
                    isUploading = true
                    simulateProgress(binding: $progress, speed: 0.03) {
                        isUploading = false
                    }
                }
                .disabled(isUploading)

                Button("No label (progress only)") {
                    downloadProgress = 0.0
                    isDownloading = true
                    simulateProgress(binding: $downloadProgress, speed: 0.04) {
                        isDownloading = false
                    }
                }
                .disabled(isDownloading)

                Button("With label: \"Syncing files...\"") {
                    syncProgress = 0.0
                    isSyncing = true
                    simulateProgress(binding: $syncProgress, speed: 0.02) {
                        isSyncing = false
                    }
                }
                .disabled(isSyncing)
            }

            // MARK: Progress Speed Demos
            Section("Progress Speed Variations") {
                Button("Fast progress (complete in ~2s)") {
                    progress = 0.0
                    isUploading = true
                    simulateProgress(binding: $progress, speed: 0.05) {
                        isUploading = false
                    }
                }
                .disabled(isUploading)

                Button("Slow progress (complete in ~8s)") {
                    downloadProgress = 0.0
                    isDownloading = true
                    simulateProgress(binding: $downloadProgress, speed: 0.01) {
                        isDownloading = false
                    }
                }
                .disabled(isDownloading)
            }

            // MARK: Cancel Demo
            Section("Manual Cancellation") {
                Button("Start & Cancel Midway") {
                    progress = 0.0
                    isUploading = true
                    Task { @MainActor in
                        // Progress to 50%, then cancel
                        while progress < 0.5 {
                            try? await Task.sleep(for: .milliseconds(80))
                            progress = min(progress + 0.03, 1.0)
                        }
                        // Cancel by setting isPresented = false
                        isUploading = false
                    }
                }
                .disabled(isUploading)

                if isUploading || isDownloading || isSyncing {
                    Button("Cancel All") {
                        isUploading = false
                        isDownloading = false
                        isSyncing = false
                    }
                    .foregroundColor(.red)
                }
            }

            // MARK: State Display
            Section("Binding State") {
                Text("isUploading = \(isUploading ? "true" : "false"), progress = \(String(format: "%.0f%%", progress * 100))")
                    .font(.caption)
                Text("isDownloading = \(isDownloading ? "true" : "false"), progress = \(String(format: "%.0f%%", downloadProgress * 100))")
                    .font(.caption)
                Text("isSyncing = \(isSyncing ? "true" : "false"), progress = \(String(format: "%.0f%%", syncProgress * 100))")
                    .font(.caption)
            }
        }
        .navigationTitle(".hudProgress()")
        .hudProgress(isPresented: $isUploading, progress: $progress, label: "Uploading...")
        .hudProgress(isPresented: $isDownloading, progress: $downloadProgress)
        .hudProgress(isPresented: $isSyncing, progress: $syncProgress, label: "Syncing files...")
    }

    private func simulateProgress(binding: Binding<Float>, speed: Float, completion: @escaping () -> Void) {
        Task { @MainActor in
            while binding.wrappedValue < 1.0 {
                try? await Task.sleep(for: .milliseconds(80))
                binding.wrappedValue = min(binding.wrappedValue + speed, 1.0)
            }
            try? await Task.sleep(for: .seconds(0.3))
            completion()
        }
    }
}

// MARK: - HUDHostView Low-Level

/// Demonstrates `HUDHostView(onViewReady:)` — the low-level UIViewRepresentable bridge.
///
/// `HUDHostView` is the foundation that all other modifiers build upon. It provides
/// direct access to a UIView (the window) that can be used for imperative HUD operations.
///
/// **Two ways to use the bridge:**
///
/// 1. **`.hudHost($hostView)`** — higher-level modifier that stores the view in a binding
///    ```swift
///    @State private var hostView: UIView?
///    MyView().hudHost($hostView)
///    // Then: HUD.show(to: hostView!, ...)
///    ```
///
/// 2. **`HUDHostView(onViewReady:)`** — lower-level view with callback
///    ```swift
///    .background(
///        HUDHostView { view in
///            // view is the window — store it for later use
///        }
///        .frame(width: 0, height: 0)
///    )
///    ```
///
/// **When to use:**
/// - Need full imperative control (multiple HUDs, HUD.huds(), HUD.lastHUD(), etc.)
/// - Need access to advanced HUD features not available in declarative modifiers
/// - Migrating from UIKit codebase that already uses FlyHUD imperative API
struct HUDHostViewDemoView: View {
    @State private var targetView: UIView?

    var body: some View {
        List {
            // MARK: Basic Usage
            Section("HUDHostView (via .background)") {
                Button("Show via onViewReady callback") {
                    guard let view = targetView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Via HUDHostView")
                    hud.hide(afterDelay: 2.0)
                }

                Button("Show with custom animation") {
                    guard let view = targetView else { return }
                    let hud = HUD.show(to: view, using: .animation(.zoomInOut, damping: .default), mode: .indicator(.large), label: "Full Config") { hud in
                        hud.contentView.detailsLabel.text = "Using HUDHostView onViewReady"
                        hud.contentView.contentColor = .systemBlue
                    }
                    hud.hide(using: .animation(.zoomInOut, damping: .default), afterDelay: 2.5)
                }

                Button("Show text toast") {
                    guard let view = targetView else { return }
                    HUD.showStatus(to: view, duration: 1.5, mode: .text, label: "Quick Toast")
                }
            }

            // MARK: Advanced Imperative APIs
            Section("Advanced (imperative only)") {
                Button("HUD.huds(for:) — count active HUDs") {
                    guard let view = targetView else { return }
                    let count = HUD.huds(for: view).count
                    let hud = HUD.show(to: view, mode: .text, label: "Active HUDs: \(count)")
                    hud.hide(afterDelay: 1.5)
                }

                Button("HUD.hideAll(for:) — dismiss all") {
                    guard let view = targetView else { return }
                    HUD.hideAll(for: view)
                }

                Button("Multiple HUDs + hideAll") {
                    guard let view = targetView else { return }
                    let _ = HUD.show(to: view, mode: .indicator(), label: "HUD 1")
                    let _ = HUD.show(to: view, mode: .indicator(), label: "HUD 2")
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2.0))
                        HUD.hideAll(for: view)
                    }
                }
            }

            // MARK: State
            Section("State") {
                Text("targetView = \(targetView == nil ? "nil (waiting...)" : "ready ✓")")
                    .font(.caption)
                    .foregroundStyle(targetView == nil ? .red : .green)
            }
        }
        .navigationTitle("HUDHostView")
        .background(
            HUDHostView { view in
                Task { @MainActor in
                    targetView = view
                }
            }
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - HUD Glass Modifier (iOS 26+)

/// Demonstrates `.hudGlass(isPresented:label:detailsLabel:)` — iOS 26+ Liquid Glass convenience.
///
/// This modifier applies Liquid Glass visual effect to the HUD content view,
/// only available on iOS 26.0+ and tvOS 26.0+. On older OS versions, use
/// `.hud(isPresented:)` with manual glass style configuration instead.
///
/// **Parameters demonstrated:**
/// - `isPresented`: `Binding<Bool>` — controls visibility
/// - `label`: `String?` — optional main label (default: nil)
/// - `detailsLabel`: `String?` — optional details label (default: nil)
///
/// **Internal implementation:**
/// ```swift
/// // What .hudGlass() does internally:
/// .hud(isPresented: isPresented) { hud in
///     hud.contentView.mode = .indicator()
///     hud.contentView.style = .glass       // ← Liquid Glass material
///     hud.contentView.label.text = label
///     hud.contentView.detailsLabel.text = detailsLabel
/// }
/// ```
///
/// **Requirements:**
/// - Xcode 26+ SDK (`#if compiler(>=6.2)`)
/// - iOS 26.0+ / tvOS 26.0+ runtime
/// - Not available on visionOS
struct HUDGlassModifierView: View {
    #if compiler(>=6.2) && !os(visionOS)
    @State private var showGlass = false
    @State private var showGlassLabel = false
    @State private var showGlassDetails = false
    #endif

    var body: some View {
        List {
            #if compiler(>=6.2) && !os(visionOS)
            if #available(iOS 26.0, tvOS 26.0, *) {
                // MARK: Parameter Combinations
                Section("Parameter Combinations") {
                    Button("No parameters (indicator only)") {
                        showGlass = true
                        hideAfter(2.0, binding: $showGlass)
                    }
                    Button("label: \"Loading...\"") {
                        showGlassLabel = true
                        hideAfter(2.0, binding: $showGlassLabel)
                    }
                    Button("label + detailsLabel") {
                        showGlassDetails = true
                        hideAfter(2.5, binding: $showGlassDetails)
                    }
                }

                // MARK: Comparison
                Section("Comparison with Manual Glass") {
                    Text("• .hudGlass() = convenience (indicator + glass)")
                        .font(.caption)
                    Text("• .hud() + style = .glass = full control")
                        .font(.caption)
                    Text("• Both produce same visual result")
                        .font(.caption)
                }

                // MARK: State
                Section("Binding State") {
                    Text("showGlass = \(showGlass ? "true" : "false")")
                        .font(.caption)
                    Text("showGlassLabel = \(showGlassLabel ? "true" : "false")")
                        .font(.caption)
                    Text("showGlassDetails = \(showGlassDetails ? "true" : "false")")
                        .font(.caption)
                }
            } else {
                Section {
                    unavailableHint
                }
            }
            #else
            Section {
                unavailableHint
            }
            #endif
        }
        .navigationTitle(".hudGlass()")
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        #if compiler(>=6.2) && !os(visionOS)
        .modifier(GlassModifiers(showGlass: $showGlass, showGlassLabel: $showGlassLabel, showGlassDetails: $showGlassDetails))
        #endif
    }

    private var unavailableHint: some View {
        Text("Requires iOS 26+ (compile with Xcode 26 SDK)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    #if compiler(>=6.2) && !os(visionOS)
    private func hideAfter(_ seconds: Double, binding: Binding<Bool>) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            binding.wrappedValue = false
        }
    }
    #endif
}

#if compiler(>=6.2) && !os(visionOS)
@available(iOS 26.0, tvOS 26.0, *)
private struct GlassModifiersContent: ViewModifier {
    @Binding var showGlass: Bool
    @Binding var showGlassLabel: Bool
    @Binding var showGlassDetails: Bool

    func body(content: Content) -> some View {
        content
            .hudGlass(isPresented: $showGlass)
            .hudGlass(isPresented: $showGlassLabel, label: "Loading...")
            .hudGlass(isPresented: $showGlassDetails, label: "Syncing", detailsLabel: "Please wait a moment")
    }
}

private struct GlassModifiers: ViewModifier {
    @Binding var showGlass: Bool
    @Binding var showGlassLabel: Bool
    @Binding var showGlassDetails: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, tvOS 26.0, *) {
            content.modifier(GlassModifiersContent(showGlass: $showGlass, showGlassLabel: $showGlassLabel, showGlassDetails: $showGlassDetails))
        } else {
            content
        }
    }
}
#endif
