//
//  AccessibilityViewController.swift
//  Example iOS
//
//  Created by Liam on 2025/5/27.
//  Copyright © 2025 Liam. All rights reserved.
//

import UIKit
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

// MARK: - AccessibilityViewController

/// Demonstrates all VoiceOver accessibility APIs provided by FlyHUD.
///
/// ## Architecture: Single-Element Pattern
/// `ContentView` is the sole VoiceOver focus element. All child views are hidden from accessibility.
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
/// - Progress milestones — Announcements at 25% intervals
/// - Dynamic updates — `.layoutChanged` on text/mode change
/// - Focus management — `.screenChanged` on show/hide
final class AccessibilityViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "VoiceOver"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )
        setupTableView()
    }

    // MARK: - Data

    private enum Section: Int, CaseIterable {
        case label, hint, value, traits, customActions, modal, escape, milestones, customView, dynamicUpdates, focus, dynamicType

        var title: String {
            switch self {
            case .label:          return "accessibilityLabel"
            case .hint:           return "accessibilityHint"
            case .value:          return "accessibilityValue"
            case .traits:         return "accessibilityTraits"
            case .customActions:  return "accessibilityCustomActions"
            case .modal:          return "accessibilityViewIsModal"
            case .escape:         return "accessibilityPerformEscape()"
            case .milestones:     return "Progress Milestone Announcements"
            case .customView:     return "Custom View & Accessibility"
            case .dynamicUpdates: return "Dynamic Updates (.layoutChanged)"
            case .focus:          return "Focus Management (.screenChanged)"
            case .dynamicType:    return "isDynamicTypeEnabled"
            }
        }

        var footer: String? {
            switch self {
            case .label:          return "ContentView.accessibilityLabel combines label.text + \", \" + detailsLabel.text."
            case .hint:           return "\"Loading in progress\" for indicators, \"Task in progress\" for progress, nil for text."
            case .value:          return "Reports percentage in progress mode. Returns nil otherwise."
            case .traits:         return ".updatesFrequently for progress/indicator, .staticText for text-only."
            case .customActions:  return "Button with title + events is exposed as custom action (swipe up/down)."
            case .modal:          return "Synced with isEventDeliveryEnabled: pass-through → non-modal."
            case .escape:         return "Two-finger Z-scrub (escape gesture) calls hud.hide(animated: true)."
            case .milestones:     return "VoiceOver announces at 25% intervals to avoid flooding."
            case .customView:     return "Set isAccessibilityElement = false on custom views."
            case .dynamicUpdates: return "Text/mode changes post .layoutChanged → VoiceOver re-reads."
            case .focus:          return "Show posts .screenChanged(contentView). Hide posts .screenChanged(nil)."
            case .dynamicType:    return "Labels respond to system text size when enabled."
            }
        }
    }

    private struct DemoRow {
        let title: String
        let action: () -> Void
    }

    private lazy var rows: [[DemoRow]] = buildRows()

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()

    private func setupTableView() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Row Builders

    private func buildRows() -> [[DemoRow]] {
        Section.allCases.map { section in
            switch section {
            case .label:
                return [
                    DemoRow(title: "Label only → \"Loading\"") { [weak self] in
                        self?.showLabelOnly()
                    },
                    DemoRow(title: "Label + Details → \"Loading, Please wait\"") { [weak self] in
                        self?.showLabelWithDetails()
                    },
                    DemoRow(title: "Empty → nil") { [weak self] in
                        self?.showEmptyLabel()
                    }
                ]
            case .hint:
                return [
                    DemoRow(title: "Indicator → \"Loading in progress\"") { [weak self] in
                        self?.showHintIndicator()
                    },
                    DemoRow(title: "Progress → \"Task in progress\"") { [weak self] in
                        self?.showHintProgress()
                    },
                    DemoRow(title: "Text → nil") { [weak self] in
                        self?.showHintText()
                    },
                    DemoRow(title: "Custom indicator → \"Loading in progress\"") { [weak self] in
                        self?.showHintCustomIndicator()
                    },
                    DemoRow(title: "Custom progress → \"Task in progress\"") { [weak self] in
                        self?.showHintCustomProgress()
                    }
                ]
            case .value:
                return [
                    DemoRow(title: "Progress 45% → \"45%\"") { [weak self] in
                        self?.showValue45()
                    },
                    DemoRow(title: "Progress 100% → \"100%\"") { [weak self] in
                        self?.showValue100()
                    },
                    DemoRow(title: "Indicator → nil") { [weak self] in
                        self?.showValueNil()
                    }
                ]
            case .traits:
                return [
                    DemoRow(title: "Indicator → .updatesFrequently") { [weak self] in
                        self?.showTraitsIndicator()
                    },
                    DemoRow(title: "Progress → .updatesFrequently") { [weak self] in
                        self?.showTraitsProgress()
                    },
                    DemoRow(title: "Text → .staticText") { [weak self] in
                        self?.showTraitsText()
                    }
                ]
            case .customActions:
                return [
                    DemoRow(title: "Button \"Cancel\" → custom action") { [weak self] in
                        self?.showCustomAction()
                    },
                    DemoRow(title: "No button → no custom actions") { [weak self] in
                        self?.showNoCustomAction()
                    }
                ]
            case .modal:
                return [
                    DemoRow(title: "Modal (default) — focus trapped") { [weak self] in
                        self?.showModal()
                    },
                    DemoRow(title: "isEventDeliveryEnabled → non-modal") { [weak self] in
                        self?.showNonModal()
                    }
                ]
            case .escape:
                return [
                    DemoRow(title: "Show HUD (Z-scrub to dismiss)") { [weak self] in
                        self?.showEscapeDemo()
                    }
                ]
            case .milestones:
                return [
                    DemoRow(title: "Simulate progress → milestones at 25%") { [weak self] in
                        self?.showMilestones()
                    }
                ]
            case .customView:
                return [
                    DemoRow(title: "Custom view (isAccessibilityElement = false)") { [weak self] in
                        self?.showCustomViewCorrect()
                    },
                    DemoRow(title: "Custom view WITHOUT fix (shows issue)") { [weak self] in
                        self?.showCustomViewIncorrect()
                    }
                ]
            case .dynamicUpdates:
                return [
                    DemoRow(title: "Update label while visible → re-reads") { [weak self] in
                        self?.showDynamicLabel()
                    },
                    DemoRow(title: "Switch mode while visible → re-reads") { [weak self] in
                        self?.showDynamicMode()
                    }
                ]
            case .focus:
                return [
                    DemoRow(title: "Show → focus moves to HUD") { [weak self] in
                        self?.showFocusOnShow()
                    },
                    DemoRow(title: "Hide → focus returns to content") { [weak self] in
                        self?.showFocusOnHide()
                    }
                ]
            case .dynamicType:
                return [
                    DemoRow(title: "isDynamicTypeEnabled = true") { [weak self] in
                        self?.showDynamicTypeEnabled()
                    },
                    DemoRow(title: "isDynamicTypeEnabled = false (default)") { [weak self] in
                        self?.showDynamicTypeDisabled()
                    }
                ]
            }
        }
    }

    // MARK: - Demo Actions

    // accessibilityLabel
    private func showLabelOnly() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading")
        hud.hide(afterDelay: 3.0)
    }

    private func showLabelWithDetails() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading") { hud in
            hud.contentView.detailsLabel.text = "Please wait"
        }
        hud.hide(afterDelay: 3.0)
    }

    private func showEmptyLabel() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator())
        hud.hide(afterDelay: 2.0)
    }

    // accessibilityHint
    private func showHintIndicator() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Syncing")
        hud.hide(afterDelay: 3.0)
    }

    private func showHintProgress() {
        let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Downloading") { hud in
            hud.contentView.progress = 0.35
        }
        hud.hide(afterDelay: 3.0)
    }

    private func showHintText() {
        let hud = HUD.show(to: view, animated: false, mode: .text, label: "Saved!")
        hud.hide(afterDelay: 2.0)
    }

    private func showHintCustomIndicator() {
        let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
        indicator.isAccessibilityElement = false
        let hud = HUD.show(to: view, animated: false, mode: .custom(indicator), label: "Custom Indicator")
        hud.hide(afterDelay: 3.0)
    }

    private func showHintCustomProgress() {
        let progress = FlyProgressHUD.ProgressView(style: .annularRound)
        progress.isAccessibilityElement = false
        let hud = HUD.show(to: view, animated: false, mode: .custom(progress), label: "Custom Progress")
        hud.hide(afterDelay: 3.0)
    }

    // accessibilityValue
    private func showValue45() {
        let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Uploading") { hud in
            hud.contentView.progress = 0.45
        }
        hud.hide(afterDelay: 3.0)
    }

    private func showValue100() {
        let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Complete") { hud in
            hud.contentView.progress = 1.0
        }
        hud.hide(afterDelay: 2.0)
    }

    private func showValueNil() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "No Value")
        hud.hide(afterDelay: 2.0)
    }

    // accessibilityTraits
    private func showTraitsIndicator() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Traits: .updatesFrequently")
        hud.hide(afterDelay: 2.5)
    }

    private func showTraitsProgress() {
        let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Traits: .updatesFrequently") { hud in
            hud.contentView.progress = 0.5
        }
        hud.hide(afterDelay: 2.5)
    }

    private func showTraitsText() {
        let hud = HUD.show(to: view, animated: false, mode: .text, label: "Traits: .staticText")
        hud.hide(afterDelay: 2.5)
    }

    // accessibilityCustomActions
    private func showCustomAction() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Uploading...") { hud in
            hud.contentView.button.setTitle("Cancel", for: .normal)
            hud.contentView.button.addTarget(self, action: #selector(NSObject.description), for: .touchUpInside)
        }
        hud.hide(afterDelay: 4.0)
    }

    private func showNoCustomAction() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "No Button")
        hud.hide(afterDelay: 2.0)
    }

    // accessibilityViewIsModal
    private func showModal() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Modal Focus")
        hud.hide(afterDelay: 3.0)
    }

    private func showNonModal() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Non-Modal") { hud in
            hud.isEventDeliveryEnabled = true
        }
        hud.hide(afterDelay: 3.0)
    }

    // accessibilityPerformEscape
    private func showEscapeDemo() {
        let _ = HUD.show(to: view, animated: false, mode: .indicator(), label: "Z-scrub to dismiss") { hud in
            hud.contentView.detailsLabel.text = "Two-finger Z gesture hides this HUD"
        }
    }

    // Progress milestones
    private func showMilestones() {
        let hud = HUD.show(to: view, animated: false, mode: .progress(.round), label: "Downloading")
        Swift.Task { @MainActor in
            for i in 1...20 {
                try? await Swift.Task.sleep(nanoseconds: 200_000_000)
                hud.contentView.progress = Float(i) / 20.0
            }
            try? await Swift.Task.sleep(nanoseconds: 500_000_000)
            hud.hide(animated: false)
        }
    }

    // Custom view pattern
    private func showCustomViewCorrect() {
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill")?.withRenderingMode(.alwaysTemplate))
        checkmark.isAccessibilityElement = false
        let hud = HUD.show(to: view, animated: false, mode: .custom(checkmark), label: "Done")
        hud.hide(afterDelay: 3.0)
    }

    private func showCustomViewIncorrect() {
        let img = UIImageView(image: UIImage(systemName: "exclamationmark.triangle"))
        let hud = HUD.show(to: view, animated: false, mode: .custom(img), label: "Warning")
        hud.hide(afterDelay: 3.0)
    }

    // Dynamic updates (.layoutChanged)
    private func showDynamicLabel() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Step 1")
        Swift.Task { @MainActor in
            try? await Swift.Task.sleep(nanoseconds: 1_500_000_000)
            hud.contentView.label.text = "Step 2"
            try? await Swift.Task.sleep(nanoseconds: 1_500_000_000)
            hud.contentView.label.text = "Step 3 — Complete"
            try? await Swift.Task.sleep(nanoseconds: 1_500_000_000)
            hud.hide(animated: false)
        }
    }

    private func showDynamicMode() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Loading")
        Swift.Task { @MainActor in
            try? await Swift.Task.sleep(nanoseconds: 2_000_000_000)
            hud.contentView.mode = .progress(.round)
            hud.contentView.label.text = "Downloading"
            hud.contentView.progress = 0.5
            try? await Swift.Task.sleep(nanoseconds: 2_000_000_000)
            hud.hide(animated: false)
        }
    }

    // Focus management (.screenChanged)
    private func showFocusOnShow() {
        let hud = HUD.show(to: view, mode: .indicator(), label: "Focus is here")
        hud.hide(afterDelay: 3.0)
    }

    private func showFocusOnHide() {
        let hud = HUD.show(to: view, mode: .indicator(), label: "Will hide soon")
        hud.hide(afterDelay: 1.0)
    }

    // isDynamicTypeEnabled
    private func showDynamicTypeEnabled() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Dynamic Type") { hud in
            hud.contentView.isDynamicTypeEnabled = true
            hud.contentView.detailsLabel.text = "Labels scale with system text size"
        }
        hud.hide(afterDelay: 3.0)
    }

    private func showDynamicTypeDisabled() {
        let hud = HUD.show(to: view, animated: false, mode: .indicator(), label: "Fixed Size") { hud in
            hud.contentView.isDynamicTypeEnabled = false
            hud.contentView.detailsLabel.text = "Labels do not scale"
        }
        hud.hide(afterDelay: 3.0)
    }

    // MARK: - Actions

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension AccessibilityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows[section].count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section.allCases[section].title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section.allCases[section].footer
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = rows[indexPath.section][indexPath.row].title
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccessibilityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        rows[indexPath.section][indexPath.row].action()
    }
}
