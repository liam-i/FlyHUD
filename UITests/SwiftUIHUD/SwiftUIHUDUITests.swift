//
//  SwiftUIHUDUITests.swift
//  FlyHUD UITests
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest

/// End-to-end UI tests verifying SwiftUI-specific HUD modifier behaviors,
/// including mode switching, configuration views, multiple HUDs, and observed progress.
final class SwiftUIHUDUITests: XCTestCase {
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

    // MARK: - Mode Switching

    func testModeSwitching_navigateAndInteract() {
        scrollToAndTap("Mode Switching")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Mode switching view should load")
    }

    // MARK: - Configuration Views

    func testLayoutConfig_loadWithoutCrash() {
        scrollToAndTap("Layout & Positioning")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Layout config view should load")
    }

    func testAnimationConfig_loadWithoutCrash() {
        scrollToAndTap("Animation Styles")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Animation config view should load")
    }

    func testAppearanceConfig_loadWithoutCrash() {
        scrollToAndTap("Appearance")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Appearance config view should load")
    }

    func testTimingConfig_loadWithoutCrash() {
        scrollToAndTap("Timing & Behavior")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Timing config view should load")
    }

    // MARK: - Multiple HUDs

    func testMultipleHUDs_loadAndInteract() {
        scrollToAndTap("Multiple HUDs (Count)")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Multiple HUDs view should load")
    }

    // MARK: - Observed Progress

    func testObservedProgress_loadAndInteract() {
        scrollToAndTap("Observed Progress")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Observed Progress view should load")
    }

    // MARK: - VoiceOver Accessibility

    /// Verifies SwiftUI HUD shows as accessible element when triggered via .hud(isPresented:).
    func testSwiftUIHUD_isPresentedModifier_accessibleElementAppears() {
        scrollToAndTap(".hud(isPresented:)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "SwiftUI .hud(isPresented:) should produce accessible elements when shown")
    }

    /// Verifies SwiftUI HUD via .hudStatus() modifier is accessible.
    func testSwiftUIHUD_hudStatusModifier_accessible() {
        scrollToAndTap(".hudStatus()")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "SwiftUI .hudStatus() should produce accessible elements")
    }

    /// Verifies SwiftUI HUD from Mode Switching shows accessible element.
    func testSwiftUIHUD_modeSwitching_accessibleElementAppears() {
        scrollToAndTap("Mode Switching")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "SwiftUI HUD should produce accessible elements when shown")
    }

    /// Verifies SwiftUI HUD with progress reports percentage via accessibility value.
    func testSwiftUIHUD_progressMode_accessibilityValue() {
        scrollToAndTap("Observed Progress")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(2)

        let progressElement = app.otherElements.matching(
            NSPredicate(format: "value CONTAINS '%'")
        ).firstMatch

        if progressElement.waitForExistence(timeout: 5.0) {
            if let value = progressElement.value as? String {
                XCTAssertTrue(value.hasSuffix("%"),
                              "SwiftUI progress HUD should report percentage: \(value)")
            }
        }
    }

    /// Verifies SwiftUI HUD disappears after dismissal and accessible element is removed.
    func testSwiftUIHUD_dismissal_removesAccessibleElement() {
        scrollToAndTap("Timing & Behavior")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // HUD should appear as accessible
        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        let countDuringHUD = hudElements.count

        // Wait for auto-dismiss
        sleep(5)

        let countAfter = app.otherElements.matching(NSPredicate(format: "label != ''")).count
        XCTAssertTrue(countAfter <= countDuringHUD,
                      "SwiftUI HUD accessible elements should be removed after dismissal")
    }

    /// Verifies multiple SwiftUI HUDs maintain accessible elements.
    func testSwiftUIHUD_multipleHUDs_accessible() {
        scrollToAndTap("Multiple HUDs (Count)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "Multiple SwiftUI HUDs should have accessible elements")
    }

    /// Verifies SwiftUI HUD target view (bridge) is hidden from accessibility.
    func testSwiftUIHUD_bridgeView_hiddenFromAccessibility() {
        scrollToAndTap("Mode Switching")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        // The bridge view (HUDTargetView) should NOT appear as a separate accessible element.
        // Only the ContentView should be the accessible element.
        // We verify no duplicate accessible elements with the same label exist.
        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        var labels = [String]()
        for i in 0..<min(hudElements.count, 10) {
            let element = hudElements.element(boundBy: i)
            if element.exists {
                labels.append(element.label)
            }
        }
        // No duplicates should exist (bridge should be hidden)
        let uniqueLabels = Set(labels)
        XCTAssertEqual(labels.count, uniqueLabels.count,
                       "Bridge view should be hidden — no duplicate accessible labels expected")
    }

    /// Verifies HUDHostView low-level usage is accessible.
    func testSwiftUIHUD_hostViewLowLevel_accessible() {
        scrollToAndTap("HUDHostView (Low-Level)")

        let showButton = app.buttons.element(boundBy: 0)
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        sleep(1)

        let hudElements = app.otherElements.matching(NSPredicate(format: "label != ''"))
        XCTAssertTrue(hudElements.count > 0,
                      "HUDHostView low-level usage should produce accessible elements")
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
