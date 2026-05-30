//
//  AccessibilityView.swift
//  Example SwiftUI
//
//  Created by Liam on 2025/5/27.
//  Copyright © 2025 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyHUDSwiftUI
import FlyIndicatorHUD
import FlyProgressHUD

// MARK: - VoiceOver Accessibility Demos

/// Demonstrates all VoiceOver accessibility APIs provided by FlyHUD.
///
/// ## Architecture: Single-Element Pattern
/// `ContentView` is the sole VoiceOver focus element. All child views are hidden from accessibility.
/// This ensures VoiceOver reads one coherent description combining label, details, progress, and actions.
///
/// ## APIs Demonstrated:
/// - `accessibilityLabel` — Combined label + detailsLabel
/// - `accessibilityHint` — Mode-aware contextual hint
/// - `accessibilityValue` — Progress percentage
/// - `accessibilityTraits` — `.updatesFrequently` / `.staticText`
/// - `accessibilityCustomActions` — Button exposure via swipe up/down
/// - `accessibilityViewIsModal` — Prevents focus escape behind HUD
/// - `accessibilityPerformEscape()` — Two-finger Z-scrub dismissal
/// - `isEventDeliveryEnabled` sync — Modal state tracks event delivery
/// - `isDynamicTypeEnabled` — Labels scale with system text size
/// - `.custom(UIView)` pattern — Custom views set `isAccessibilityElement = false`
/// - Progress milestones — Announcements at 25% intervals
/// - Layout/screen changed notifications — Focus management on show/hide/update
struct AccessibilityView: View {
    @State private var hostView: UIView?

    var body: some View {
        List {
            // MARK: - accessibilityLabel
            Section {
                Button("Label only → \"Loading\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading")
                    // VoiceOver reads: "Loading"
                    hud.hide(afterDelay: 3.0)
                }
                Button("Label + Details → \"Loading, Please wait\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading") { hud in
                        hud.contentView.detailsLabel.text = "Please wait"
                    }
                    // VoiceOver reads: "Loading, Please wait"
                    hud.hide(afterDelay: 3.0)
                }
                Button("Empty label → nil (no announcement)") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator())
                    // accessibilityLabel returns nil
                    hud.hide(afterDelay: 2.0)
                }
            } header: {
                Text("accessibilityLabel")
            } footer: {
                Text("ContentView.accessibilityLabel combines label.text + \", \" + detailsLabel.text into a single spoken description.")
            }

            // MARK: - accessibilityHint
            Section {
                Button("Indicator → \"Loading in progress\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Syncing")
                    // accessibilityHint = "Loading in progress"
                    hud.hide(afterDelay: 3.0)
                }
                Button("Progress → \"Task in progress\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Downloading") { hud in
                        hud.contentView.progress = 0.35
                    }
                    // accessibilityHint = "Task in progress"
                    hud.hide(afterDelay: 3.0)
                }
                Button("Text → nil (no hint)") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .text, label: "Saved!")
                    // accessibilityHint = nil
                    hud.hide(afterDelay: 2.0)
                }
                Button("Custom indicator → \"Loading in progress\"") {
                    guard let view = hostView else { return }
                    let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
                    indicator.isAccessibilityElement = false
                    let hud = HUD.show(to: view, animated: false, mode: .custom(indicator), label: "Custom Indicator")
                    // accessibilityHint = "Loading in progress" (ActivityIndicatorViewable conformance)
                    hud.hide(afterDelay: 3.0)
                }
                Button("Custom progress → \"Task in progress\"") {
                    guard let view = hostView else { return }
                    let progress = FlyProgressHUD.ProgressView(style: .annularRound)
                    progress.isAccessibilityElement = false
                    let hud = HUD.show(to: view, animated: false, mode: .custom(progress), label: "Custom Progress")
                    // accessibilityHint = "Task in progress" (ProgressViewable conformance)
                    hud.hide(afterDelay: 3.0)
                }
            } header: {
                Text("accessibilityHint")
            } footer: {
                Text("Provides context: \"Loading in progress\" for indicators, \"Task in progress\" for progress, nil for text-only modes.")
            }

            // MARK: - accessibilityValue
            Section {
                Button("Progress 45% → \"45%\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Uploading") { hud in
                        hud.contentView.progress = 0.45
                    }
                    // accessibilityValue = "45%"
                    hud.hide(afterDelay: 3.0)
                }
                Button("Progress 100% → \"100%\"") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Complete") { hud in
                        hud.contentView.progress = 1.0
                    }
                    // accessibilityValue = "100%"
                    hud.hide(afterDelay: 2.0)
                }
                Button("Indicator → nil (no value)") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading")
                    // accessibilityValue = nil (not progress mode)
                    hud.hide(afterDelay: 2.0)
                }
            } header: {
                Text("accessibilityValue")
            } footer: {
                Text("Reports percentage (e.g. \"45%\") in progress mode. Returns nil for non-progress modes.")
            }

            // MARK: - accessibilityTraits
            Section {
                Button("Indicator → .updatesFrequently") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Traits: .updatesFrequently")
                    hud.hide(afterDelay: 2.5)
                }
                Button("Progress → .updatesFrequently") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Traits: .updatesFrequently") { hud in
                        hud.contentView.progress = 0.5
                    }
                    hud.hide(afterDelay: 2.5)
                }
                Button("Text → .staticText") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .text, label: "Traits: .staticText")
                    hud.hide(afterDelay: 2.5)
                }
            } header: {
                Text("accessibilityTraits")
            } footer: {
                Text("`.updatesFrequently` tells VoiceOver the element's value may change. `.staticText` for text-only modes.")
            }

            // MARK: - accessibilityCustomActions (Button)
            Section {
                Button("Button: \"Cancel\" → custom action") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Uploading...") { hud in
                        hud.contentView.button.setTitle("Cancel", for: .normal)
                        hud.contentView.button.addTarget(hud, action: #selector(NSObject.description), for: .touchUpInside)
                    }
                    // VoiceOver: swipe up/down to discover "Cancel" action
                    hud.hide(afterDelay: 4.0)
                }
                Button("No button → no custom actions") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "No Button")
                    // accessibilityCustomActions = nil
                    hud.hide(afterDelay: 2.0)
                }
            } header: {
                Text("accessibilityCustomActions")
            } footer: {
                Text("When a button has a title and control events, it's exposed as a custom action. Users swipe up/down to discover it.")
            }

            // MARK: - accessibilityViewIsModal
            Section {
                Button("Modal (default) — focus trapped in HUD") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Modal Focus")
                    // hud.accessibilityViewIsModal == true (default)
                    // VoiceOver cannot navigate to elements behind the HUD
                    hud.hide(afterDelay: 3.0)
                }
                Button("isEventDeliveryEnabled → modal disabled") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Non-Modal") { hud in
                        hud.isEventDeliveryEnabled = true
                    }
                    // hud.accessibilityViewIsModal == false (synced with event delivery)
                    // VoiceOver CAN navigate to elements behind the HUD
                    hud.hide(afterDelay: 3.0)
                }
            } header: {
                Text("accessibilityViewIsModal")
            } footer: {
                Text("Prevents VoiceOver from navigating behind the HUD. Automatically synced: when isEventDeliveryEnabled = true, modal is false.")
            }

            // MARK: - accessibilityPerformEscape
            Section {
                Button("Show dismissable HUD (Z-scrub to dismiss)") {
                    guard let view = hostView else { return }
                    let _ = HUD.show(to: view, animated: false, mode: .indicator(), label: "Z-scrub to dismiss") { hud in
                        hud.contentView.detailsLabel.text = "Two-finger Z gesture hides this HUD"
                    }
                    // VoiceOver: Two-finger Z-scrub calls accessibilityPerformEscape()
                    // which calls hud.hide(animated: true)
                }
            } header: {
                Text("accessibilityPerformEscape()")
            } footer: {
                Text("Two-finger Z-scrub (escape gesture) dismisses the HUD. This is the standard iOS modal dismissal mechanism for VoiceOver.")
            }

            // MARK: - Progress Milestones
            Section {
                Button("Simulate progress → milestones at 25%") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Downloading")
                    // Milestone announcements: 25%, 50%, 75%, 100%
                    Task { @MainActor in
                        for i in 1...20 {
                            try? await Task.sleep(for: .milliseconds(200))
                            hud.contentView.progress = Float(i) / 20.0
                        }
                        try? await Task.sleep(for: .seconds(0.5))
                        hud.hide(animated: false)
                    }
                }
            } header: {
                Text("Progress Milestone Announcements")
            } footer: {
                Text("VoiceOver announces percentage at 25% intervals (25%, 50%, 75%, 100%) to avoid overwhelming users with continuous updates.")
            }

            // MARK: - Custom View Pattern
            Section {
                Button("Custom view (isAccessibilityElement = false)") {
                    guard let view = hostView else { return }
                    let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate))
                    checkmark.isAccessibilityElement = false // ← Recommended
                    let hud = HUD.show(to: view, animated: false, mode: .custom(checkmark), label: "Done")
                    // VoiceOver reads "Done" from ContentView, not the image's default label
                    hud.hide(afterDelay: 3.0)
                }
                Button("Custom view WITHOUT fix (shows issue)") {
                    guard let view = hostView else { return }
                    let img = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
                    // NOT setting isAccessibilityElement = false → potential duplicate announcement
                    let hud = HUD.show(to: view, animated: false, mode: .custom(img), label: "Warning")
                    hud.hide(afterDelay: 3.0)
                }
            } header: {
                Text("Custom View & Accessibility")
            } footer: {
                Text("Set isAccessibilityElement = false on custom views to maintain the single-element pattern. ContentView handles all VoiceOver output.")
            }

            // MARK: - Dynamic Updates (layoutChanged)
            Section {
                Button("Update label while visible → re-reads") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Step 1")
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1.5))
                        hud.contentView.label.text = "Step 2"
                        // Posts .layoutChanged → VoiceOver re-reads
                        try? await Task.sleep(for: .seconds(1.5))
                        hud.contentView.label.text = "Step 3 — Complete"
                        try? await Task.sleep(for: .seconds(1.5))
                        hud.hide(animated: false)
                    }
                }
                Button("Switch mode while visible → re-reads") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading")
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2.0))
                        hud.contentView.mode = .progress(.round)
                        hud.contentView.label.text = "Downloading"
                        hud.contentView.progress = 0.5
                        // Posts .layoutChanged → VoiceOver re-reads with new traits
                        try? await Task.sleep(for: .seconds(2.0))
                        hud.hide(animated: false)
                    }
                }
            } header: {
                Text("Dynamic Updates (.layoutChanged)")
            } footer: {
                Text("Text/mode changes while HUD is visible post .layoutChanged so VoiceOver re-reads the updated content.")
            }

            // MARK: - Focus Management (screenChanged)
            Section {
                Button("Show → focus moves to HUD") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Focus is here")
                    // Posts .screenChanged with contentView → VoiceOver focuses HUD
                    hud.hide(afterDelay: 3.0)
                }
                Button("Hide → focus returns to content") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Will hide soon")
                    hud.hide(afterDelay: 1.0)
                    // On hide: posts .screenChanged with nil → VoiceOver returns to content
                }
            } header: {
                Text("Focus Management (.screenChanged)")
            } footer: {
                Text("Show posts .screenChanged → focus to HUD. Hide posts .screenChanged(nil) → focus returns to underlying content.")
            }

            // MARK: - isDynamicTypeEnabled
            Section {
                Button("isDynamicTypeEnabled = true") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Dynamic Type") { hud in
                        hud.contentView.isDynamicTypeEnabled = true
                        hud.contentView.detailsLabel.text = "Labels scale with system text size"
                    }
                    hud.hide(afterDelay: 3.0)
                }
                Button("isDynamicTypeEnabled = false (default)") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Fixed Size") { hud in
                        hud.contentView.isDynamicTypeEnabled = false
                        hud.contentView.detailsLabel.text = "Labels do not scale"
                    }
                    hud.hide(afterDelay: 3.0)
                }
            } header: {
                Text("isDynamicTypeEnabled")
            } footer: {
                Text("Opt-in support for accessibility text sizing. When true, labels use preferred fonts that respond to system size changes.")
            }
        }
        .navigationTitle("VoiceOver")
        .hudHost($hostView)
    }
}
