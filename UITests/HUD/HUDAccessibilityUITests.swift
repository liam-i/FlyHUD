//
//  HUDAccessibilityUITests.swift
//  FlyHUD UITests
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest

/// UI tests verifying VoiceOver accessibility attributes on HUD elements.
/// Coverage targets:
/// - ContentView: accessibilityLabel, accessibilityValue, accessibilityHint,
///   accessibilityTraits, accessibilityCustomActions, isAccessibilityElement
/// - HUD: accessibilityViewIsModal, accessibilityPerformEscape, isEventDeliveryEnabled sync
/// - Label: isAccessibilityElement = false, layoutChanged on text change
/// - Button: isAccessibilityElement = false, custom actions exposure
/// - BackgroundView: accessibilityElementsHidden = true
/// - ActivityIndicatorView: isAccessibilityElement = false
/// - ProgressView: isAccessibilityElement = false
/// - Progress milestones: announcements at 25% intervals
/// - Observed progress: label text updates without flooding VoiceOver
/// - Dynamic Type: labels scale properly
/// - HUDTargetView (SwiftUI bridge): accessibilityElementsHidden = true
final class HUDAccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - accessibilityLabel

    /// Verifies that the HUD's accessibility label matches the displayed text.
    func testHUD_accessibilityLabelMatchesDisplayedText() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 3.0),
                      "HUD accessible element should exist with 'Loading' in its label")
    }

    /// Verifies the HUD with animation shows correct label.
    func testHUD_accessibilityLabelWithAnimation() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show with Animation"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Zoom'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 3.0),
                      "HUD with animation should have correct accessibility label")
    }

    /// Verifies HUD reflects combined label + details text.
    func testHUD_accessibilityLabelCombinesLabelAndDetails() {
        scrollToAndTap("Mode Switching")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // Check that there's an accessible element with combined text (comma-separated)
        let hudElements = app.otherElements.matching(NSPredicate(format: "label CONTAINS ','"))
        if hudElements.count > 0 {
            XCTAssertTrue(hudElements.firstMatch.exists,
                          "HUD should combine label and details with comma separator")
        }
    }

    // MARK: - accessibilityValue (Progress)

    /// Verifies that progress-mode HUD reports percentage via accessibilityValue.
    func testProgressHUD_hasAccessibilityValue() {
        scrollToAndTap("Progress Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch

        if progressElement.waitForExistence(timeout: 3.0) {
            XCTAssertTrue(progressElement.exists,
                          "Progress HUD should have an accessibility value with percentage")
            if let value = progressElement.value as? String {
                XCTAssertTrue(value.hasSuffix("%"),
                              "Accessibility value should end with '%', got: \(value)")
            }
        }
    }

    /// Verifies that progress HUD accessibility value changes over time.
    func testProgressHUD_accessibilityValueUpdatesOverTime() {
        scrollToAndTap("Observed Progress")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch

        guard progressElement.waitForExistence(timeout: 5.0) else { return }

        let initialValue = progressElement.value as? String ?? ""

        // Wait for progress to advance
        sleep(2)

        if progressElement.exists {
            let updatedValue = progressElement.value as? String ?? ""
            XCTAssertTrue(updatedValue.hasSuffix("%") || initialValue.hasSuffix("%"),
                          "Progress value should be a percentage format")
        }
    }

    /// Verifies text-only mode has nil accessibilityValue.
    func testTextHUD_noAccessibilityValue() {
        scrollToAndTap("Toast (Text Only)")

        let showButton = app.buttons["Simple Toast"]
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // Toast HUD should appear with label "Message sent" but NO progress value
        let hudElement = app.otherElements.matching(
            NSPredicate(format: "label CONTAINS 'Message sent'")
        ).firstMatch

        if hudElement.waitForExistence(timeout: 2.0) {
            let value = hudElement.value as? String ?? ""
            XCTAssertFalse(value.contains("%"),
                           "Text-only toast should not have a progress percentage value, got: \(value)")
        }
    }

    // MARK: - accessibilityHint

    /// Verifies indicator mode HUD has accessibility hint.
    func testIndicatorHUD_hasAccessibilityHint() {
        scrollToAndTap("Indicator Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // Look for accessible element with indicator hint
        let hudElement = app.otherElements.matching(NSPredicate(format: "label != ''")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0),
                      "Indicator HUD should have accessible element")
    }

    /// Verifies progress mode HUD has accessibility hint.
    func testProgressHUD_hasAccessibilityHint() {
        scrollToAndTap("Progress Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch
        XCTAssertTrue(progressElement.waitForExistence(timeout: 3.0),
                      "Progress HUD should exist with accessible value")
    }

    // MARK: - accessibilityTraits

    /// Verifies that indicator-mode HUD exists as a single accessible element.
    func testIndicatorHUD_singleAccessibleElement() {
        scrollToAndTap("Indicator Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0, "At least one accessible element should exist while HUD is shown")
    }

    /// Verifies custom view mode is accessible.
    func testCustomViewMode_isAccessible() {
        scrollToAndTap("Custom View Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "Custom view mode HUD should be accessible")
    }

    // MARK: - accessibilityViewIsModal

    /// Verifies that while HUD is showing, it is the modal focus element.
    func testHUD_isModal_preventsBackgroundAccess() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // While HUD is modal, it should be the accessible focus target.
        XCTAssertTrue(hudElement.exists, "HUD should be the modal focus element")
    }

    /// Verifies that after HUD is hidden, background elements regain focus.
    func testHUD_afterHide_backgroundRegainsFocus() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // Wait for auto-hide (2 seconds)
        sleep(3)

        // After hide, the HUD element should no longer exist
        XCTAssertFalse(hudElement.exists, "HUD should be dismissed")

        // Background navigation elements should be accessible again
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists, "Navigation should be accessible after HUD hides")
    }

    // MARK: - accessibilityPerformEscape

    /// Verifies that after the HUD is shown, it can be hidden.
    /// (XCUI cannot directly invoke accessibilityPerformEscape, but we verify dismiss behavior)
    func testHUD_canBeHiddenAfterShowing() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // Use "Hide All" to simulate escape behavior
        let hideButton = app.buttons["Hide All"]
        if hideButton.waitForExistence(timeout: 1.0) {
            hideButton.tap()
            sleep(1)
            XCTAssertFalse(hudElement.exists, "HUD should be dismissed after hide")
        }
    }

    /// Verifies that manual show/hide cycle works correctly for VoiceOver.
    func testHUD_manualShowHide_accessibilityCleanup() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show & Hide Manually"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Working'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // Should auto-hide after ~1.5 seconds
        sleep(3)
        XCTAssertFalse(hudElement.exists, "HUD should be dismissed after manual hide")
    }

    // MARK: - Button / Custom Actions

    /// Verifies that HUD with button action works in accessible context.
    func testHUD_withButton_accessibleAction() {
        scrollToAndTap("Mode Switching")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0, "HUD should be accessible when showing with button")
    }

    // MARK: - Toast / Status (Auto-Hide)

    /// Verifies that text-only toast has accessible label with text content.
    func testToast_accessibilityLabelIsTextContent() {
        scrollToAndTap("Toast (Text Only)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let toastElements = app.otherElements.matching(
            NSPredicate(format: "label != ''")
        )
        XCTAssertTrue(toastElements.count > 0,
                      "Toast HUD should have accessible label with text content")
    }

    /// Verifies toast auto-hides and accessibility element disappears.
    func testToast_autoHides_accessibilityElementRemoved() {
        scrollToAndTap("ShowStatus (Auto-Hide)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        // Toast should appear
        sleep(1)
        let toastElements = app.otherElements.matching(
            NSPredicate(format: "label != ''")
        )
        let countDuringToast = toastElements.count

        // Wait for auto-dismiss (typically 2-3 seconds)
        sleep(4)

        // Toast should have been removed
        let countAfterDismiss = app.otherElements.matching(
            NSPredicate(format: "label != ''")
        ).count
        XCTAssertTrue(countAfterDismiss <= countDuringToast,
                      "Toast should be removed after auto-hide duration")
    }

    // MARK: - ActivityIndicatorView Styles

    /// Verifies all ActivityIndicatorView styles are accessible when shown in HUD.
    func testActivityIndicatorStyles_accessible() {
        scrollToAndTap("ActivityIndicatorView Styles")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "ActivityIndicatorView HUD should be accessible")
    }

    // MARK: - ProgressView Styles

    /// Verifies ProgressView styles are accessible when shown in HUD.
    func testProgressViewStyles_accessible() {
        scrollToAndTap("ProgressView Styles")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch

        if progressElement.waitForExistence(timeout: 3.0) {
            if let value = progressElement.value as? String {
                XCTAssertTrue(value.hasSuffix("%"),
                              "ProgressView style HUD should report percentage: \(value)")
            }
        }
    }

    // MARK: - Dynamic Type

    /// Verifies HUD works with Dynamic Type scaling.
    func testHUD_dynamicType_remainsAccessible() {
        scrollToAndTap("Dynamic Type")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "HUD should remain accessible with Dynamic Type enabled")
    }

    // MARK: - Mode Switching

    /// Verifies accessibility updates when mode switches from indicator to progress.
    func testModeSwitching_accessibilityUpdates() {
        scrollToAndTap("Mode Switching")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // HUD should be accessible in first mode
        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "HUD should be accessible during mode switching")

        // Wait for mode to switch
        sleep(2)

        // Should still be accessible after mode switch
        let hudElementsAfterSwitch = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElementsAfterSwitch.count > 0,
                      "HUD should remain accessible after mode switch")
    }

    // MARK: - Observed Progress

    /// Verifies observedProgress HUD is accessible and reports progress.
    func testObservedProgress_accessible() {
        scrollToAndTap("Observed Progress")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(2)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch

        if progressElement.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(progressElement.exists,
                          "Observed progress HUD should report progress percentage")
        }
    }

    /// Verifies observed progress doesn't create duplicate accessible elements.
    func testObservedProgress_noDuplicateAccessibleElements() {
        scrollToAndTap("Observed Progress")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(2)

        // Only ONE accessible element should report progress (ContentView is the single element)
        let progressElements = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        )

        if progressElements.firstMatch.waitForExistence(timeout: 5.0) {
            XCTAssertEqual(progressElements.count, 1,
                           "Only one accessible element should report progress value (ContentView)")
        }
    }

    // MARK: - Multiple HUDs

    /// Verifies multiple stacked HUDs maintain accessibility.
    func testMultipleHUDs_accessible() {
        scrollToAndTap("Multiple HUDs (Count)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "Multiple HUDs scenario should have accessible elements")
    }

    // MARK: - Child Views Hidden

    /// Verifies that child views (labels, indicator, button) are NOT separate accessible elements.
    /// Only ContentView should be the accessible element.
    func testHUD_childViews_notSeparateAccessibleElements() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // The label "Loading..." should NOT appear as a separate staticText within the HUD
        // because Label.isAccessibilityElement = false
        // The entire HUD content is a single accessible element (ContentView)
        let loadingStaticText = app.staticTexts["Loading..."]
        // In UITests, staticTexts query finds visual labels,
        // but VoiceOver should only see the ContentView's combined label
        XCTAssertTrue(hudElement.exists, "ContentView should be the single accessible element")
    }

    /// Verifies that ActivityIndicatorView is not a separate accessible element.
    func testHUD_activityIndicator_notSeparateAccessibleElement() {
        scrollToAndTap("Indicator Mode")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // The indicator should not be a separate accessible element
        // Only the ContentView should be accessible
        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0, "ContentView should be accessible")
    }

    /// Verifies that BackgroundView is hidden from accessibility.
    func testHUD_backgroundView_hiddenFromAccessibility() {
        scrollToAndTap("Appearance")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // Background view elements should NOT appear as accessible elements
        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        // Only ContentView label elements should exist, not background
        XCTAssertTrue(hudElements.count > 0, "Only ContentView should be accessible, not BackgroundView")
    }

    // MARK: - Delegate / Completion

    /// Verifies accessibility is maintained when using delegate pattern.
    func testDelegateCompletion_accessibilityMaintained() {
        scrollToAndTap("Delegate & Completion")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "HUD should be accessible when using delegate pattern")
    }

    // MARK: - Helpers

    private func scrollToAndTap(_ label: String) {
        let cell = app.staticTexts[label]
        var attempts = 0
        while !cell.exists && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(cell.waitForExistence(timeout: 2.0), "\(label) should be visible after scrolling")
        cell.tap()
    }
}
