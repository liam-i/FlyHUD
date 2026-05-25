//
//  DemoViewModel.swift
//  Example iOS
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

// MARK: - DemoViewModel

/// ViewModel that encapsulates all HUD demo logic and configuration state.
/// Each public method demonstrates a specific HUD API usage pattern.
@MainActor final class DemoViewModel {

    // MARK: - State

    var config: Configuration {
        didSet { onConfigChanged?() }
    }

    /// Called when configuration changes to allow the view to update live HUDs.
    var onConfigChanged: (() -> Void)?

    init() {
        var config = Configuration()
        #if os(iOS)
        config.keyboardGuide = HUD.keyboardGuide
        #endif
        self.config = config
    }

    // MARK: - Computed Sections

    /// Configuration items visible based on current state.
    var visibleConfigItems: [ConfigItem] {
        ConfigItem.allCases.filter { item in
            if config.isDefaultModeStyle && item.isCustomOnly { return false }
            if !config.isForceAnimationEnabled && item.isForceAnimOnly { return false }
            return true
        }
    }

    /// Visible config items for a specific section.
    func visibleConfigItems(for section: DemoSection) -> [ConfigItem] {
        visibleConfigItems.filter { $0.section == section }
    }

    // MARK: - HUD Presentation Helpers

    /// Show HUD with full configuration applied.
    /// - Note: When `isDefaultModeStyle` is true, uses the simple API.
    ///         When false, applies all custom configuration.
    func showHUD(on view: UIView, mode: ContentView.Mode, label: String? = nil) -> HUD {
        let hud: HUD
        if config.isDefaultModeStyle {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // 📌 Simple API: one-liner HUD display
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            hud = HUD.show(to: view, mode: mode, label: label)
        } else {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // 📌 Custom API: full configuration with animation
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            if case let .custom(v) = mode, let pv = v as? ProgressView {
                pv.isLabelEnabled = pv.style.isEqual(ProgressView.Style.round) || pv.style.isEqual(ProgressView.Style.annularRound)
            }
            hud = HUD.show(to: view, using: config.currAnimation, mode: mode) { [config] hud in
                Self.applyConfig(config, to: hud, label: label)
            }
        }
        return hud
    }

    /// Hide the HUD respecting current animation settings.
    func hideHUD(_ hud: HUD) {
        if config.isDefaultModeStyle {
            hud.hide()
        } else {
            hud.hide(using: config.currAnimation)
        }
    }

    // MARK: - Demo: Indicator

    /// Demonstrates showing an activity indicator or progress view HUD.
    /// Tapping any indicator in the gallery triggers this.
    func showIndicatorDemo(on view: UIView, mode: ContentView.Mode, completion: @escaping (HUD) -> Void) {
        let hud = showHUD(on: view, mode: mode)
        completion(hud)
    }

    /// Simulates a task with progress updates.
    func simulateTask(for hud: HUD, on view: UIView) {
        Task.request(config.takeTime) { progress in
            if hud.contentView.mode.isProgressView {
                hud.contentView.progress = progress
            }
        } completion: { [weak self] in
            self?.hideHUD(hud)
        }
    }

    // MARK: - Demo: Status / Toast

    /// Shows a status HUD (icon + text) or toast (text only).
    ///
    /// ```swift
    /// // Toast
    /// HUD.show(to: view, mode: .text, label: "Wrong password")
    /// hud.hide(afterDelay: 2.0)
    ///
    /// // Status with icon
    /// HUD.show(to: view, mode: .custom(UIImageView(image: checkmark)), label: "Done")
    /// hud.hide(afterDelay: 2.0)
    /// ```
    func showStatus(on view: UIView, onlyText: Bool) -> HUD {
        let mode: ContentView.Mode = onlyText ? .text : .custom(UIImageView(named: "Checkmark"))
        let hud = showHUD(on: view, mode: mode, label: mode.description)
        if config.isDefaultModeStyle {
            hud.hide(afterDelay: config.hideAfterDelay)
        } else {
            hud.hide(using: config.currAnimation, afterDelay: config.hideAfterDelay)
        }
        return hud
    }

    // MARK: - Demo: Multiple HUDs

    /// Demonstrates the count-based HUD for overlapping requests.
    ///
    /// ```swift
    /// let hud = HUD(with: view)
    /// hud.isCountEnabled = true
    /// view.addSubview(hud)
    /// hud.show()   // count = 1
    /// hud.show()   // count = 2
    /// hud.hide()   // count = 1
    /// hud.hide()   // count = 0 → actually hides
    /// ```
    func showMultipleHUDs(on view: UIView) {
        let counter = Counter()
        let hud = HUD(with: view)
        hud.isCountEnabled = true
        view.addSubview(hud)

        func startRequest() {
            counter.request += 1
            hud.show()
            hud.contentView.label.text = "Count: \(hud.count)"
            hud.contentView.detailsLabel.text = "Request: \(counter.request), Response: \(counter.response)"

            Task.request(.random(in: 1...5)) {
                counter.response += 1
                hud.hide(afterDelay: 1)
                hud.contentView.label.text = "Count: \(hud.count)"
                hud.contentView.detailsLabel.text = "Request: \(counter.request), Response: \(counter.response)"
            }
        }

        startRequest()
        startRequest()
        startRequest()
    }

    // MARK: - Demo: Mode Switching

    /// Demonstrates switching HUD modes dynamically during a multi-step task.
    ///
    /// ```swift
    /// hud.contentView.mode = .progress(.round)
    /// hud.contentView.mode = .indicator()
    /// hud.contentView.mode = .custom(checkmarkView)
    /// ```
    func showModeSwitching(on view: UIView) {
        let hud = showHUD(on: view, mode: .indicator(), label: "Preparing...")

        Task.requestMultiTask { progress in
            hud.contentView.progress = progress
        } completion: { step in
            switch step {
            case 3:
                hud.contentView.layout.minSize = CGSize(width: 200, height: 100)
                hud.layout.offset = .h.vMinOffset
                hud.contentView.mode = .progress(.round)
                hud.contentView.label.text = "Loading..."
            case 2:
                hud.contentView.layout.minSize = CGSize(width: 150, height: 300)
                hud.layout.offset = .h.vMaxOffset
                hud.contentView.mode = .indicator()
                hud.contentView.label.text = "Cleaning up..."
            case 1:
                hud.contentView.layout.minSize = CGSize(width: 180, height: 200)
                hud.layout.offset = CGPoint(x: .h.maxOffset, y: .h.maxOffset)
                hud.contentView.mode = .custom(UIImageView(named: "Checkmark"))
                hud.contentView.label.text = "Completed"
            case 0:
                hud.hide()
            default:
                break
            }
        }
    }

    // MARK: - Demo: URLSession

    /// Demonstrates progress tracking with a real URLSession download.
    ///
    /// ```swift
    /// hud.contentView.mode = .progress(.annularRound)
    /// // In URLSession delegate:
    /// hud.contentView.progress = Float(written) / Float(total)
    /// ```
    func showURLSession(on view: UIView) {
        let hud = showHUD(on: view, mode: .indicator(), label: "Preparing...")
        hud.contentView.layout.minSize = CGSize(width: 150, height: 100)
        hud.contentView.mode = .progress(.annularRound)

        Task.download { progress in
            hud.contentView.progress = progress
        } completion: {
            hud.contentView.mode = .custom(UIImageView(named: "Checkmark"))
            hud.contentView.label.text = "Completed"
            hud.hide(afterDelay: 3.0)
        }
    }

    // MARK: - Demo: Observed Progress

    /// Demonstrates integration with Foundation's `Progress` object.
    ///
    /// ```swift
    /// hud.contentView.observedProgress = progress
    /// // progress.localizedDescription → label
    /// // progress.localizedAdditionalDescription → detailsLabel
    /// ```
    func showObservedProgress(on view: UIView) {
        let hud = showHUD(on: view, mode: .progress(.round))
        Task.resume { progress in
            hud.contentView.observedProgress = progress
            hud.contentView.button.setTitle("Cancel", for: .normal)
            hud.contentView.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)
        } completion: {
            hud.hide()
        }
    }

    // MARK: - Demo: ShowStatus (Convenience)

    /// Demonstrates the `showStatus` convenience method for auto-hiding status HUDs.
    ///
    /// ```swift
    /// HUD.showStatus(to: view, duration: 2.0, mode: .custom(checkmarkView), label: "Saved!")
    /// // Automatically hides after duration — no manual hide() needed.
    /// ```
    func showStatusDemo(on view: UIView) {
        HUD.showStatus(to: view, duration: 2.0, mode: .custom(UIImageView(named: "Checkmark")), label: "Saved!")
    }

    // MARK: - Demo: Dynamic Type

    /// Demonstrates Dynamic Type support for accessibility.
    ///
    /// ```swift
    /// hud.contentView.isDynamicTypeEnabled = true
    /// // Labels now respond to system text size changes
    /// ```
    func showDynamicType(on view: UIView) {
        let hud = showHUD(on: view, mode: .indicator(), label: "Dynamic Type Enabled")
        hud.contentView.isDynamicTypeEnabled = true
        hud.contentView.detailsLabel.text = "Labels scale with system text size"
        hud.hide(afterDelay: 3.0)
    }

    // MARK: - Configuration Apply

    /// Applies the full configuration to a HUD instance.
    static func applyConfig(_ config: Configuration, to hud: HUD, label: String?) {
        hud.contentView.label.text = label ?? (config.isLabelEnabled ? hud.contentView.mode.description : nil)
        if config.isEventDeliveryEnabled {
            hud.contentView.detailsLabel.text = "Events are delivered normally to the HUD's parent view"
            hud.contentView.detailsLabel.textColor = .systemRed
        } else {
            hud.contentView.detailsLabel.text = config.isDetailsLabelEnabled ? "This is the detail label" : nil
        }
        hud.contentView.button.setTitle(config.isButtonEnabled ? "Cancel" : nil, for: .normal)
        hud.contentView.contentColor = config.contentColor.color
        hud.contentView.style = config.contentViewStyle
        hud.contentView.color = config.contentViewColor == .default ? .h.background : config.contentViewColor.color
        hud.contentView.layout = config.contentLayout
        hud.contentView.indicatorPosition = config.position
        hud.contentView.isDynamicTypeEnabled = config.isDynamicTypeEnabled
        hud.contentView.roundedCorners = .radius(config.roundedCorners)
        hud.backgroundView.style = config.backgroundViewStyle
        hud.backgroundView.color = config.backgroundViewColor == .default ? .clear : config.backgroundViewColor.color
        hud.layout = config.layout
        hud.animation = config.animation
        hud.graceTime = config.graceTime
        hud.minShowTime = config.minShowTime
        hud.removeFromSuperViewOnHide = config.removeFromSuperViewOnHide
        hud.isCountEnabled = config.isCountEnabled
        hud.isEventDeliveryEnabled = config.isEventDeliveryEnabled
        hud.contentView.isMotionEffectsEnabled = config.isMotionEffectsEnabled
        #if os(iOS)
        hud.keyboardGuide = config.keyboardGuide
        #endif
    }
}

// MARK: - Helpers

private final class Counter: @unchecked Sendable {
    var request: Int = 0
    var response: Int = 0
}
