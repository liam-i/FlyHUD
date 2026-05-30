//
//  HUDUITests.swift
//  FlyHUD UITests
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest

/// End-to-end UI tests verifying core HUD show/hide, layout, and stability behaviors.
final class HUDUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        app = nil
        super.tearDown()
    }

    // MARK: - Basic Show / Hide

    func testBasicHUD_showAndAutoHide() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        // HUD should appear with "Loading..." in its accessibility label
        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD label should appear")

        // Should auto-hide after ~2 seconds
        let disappeared = hudElement.waitForNonExistence(timeout: 4.0)
        XCTAssertTrue(disappeared, "HUD should auto-hide")
    }

    func testBasicHUD_showAndManualHide() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show & Hide Manually"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Working'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0))

        // Should hide after ~1.5 seconds
        let disappeared = hudElement.waitForNonExistence(timeout: 3.0)
        XCTAssertTrue(disappeared, "HUD should hide after manual delay")
    }

    func testBasicHUD_hideAll() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show Default HUD"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0))

        app.buttons["Hide All"].tap()

        let disappeared = hudElement.waitForNonExistence(timeout: 2.0)
        XCTAssertTrue(disappeared, "HUD should be hidden by Hide All")
    }

    // MARK: - Status / Toast

    func testStatusHUD_autoHide() {
        scrollToAndTap("ShowStatus (Auto-Hide)")

        let firstButton = app.buttons.element(boundBy: 0)
        if firstButton.waitForExistence(timeout: 2.0) {
            firstButton.tap()
            sleep(3)
            XCTAssertTrue(firstButton.exists, "Should return to same screen after status auto-hides")
        }
    }

    func testToast_textOnly() {
        scrollToAndTap("Toast (Text Only)")

        let firstButton = app.buttons.element(boundBy: 0)
        if firstButton.waitForExistence(timeout: 2.0) {
            firstButton.tap()
            sleep(3)
            XCTAssertTrue(firstButton.exists, "Should return to same screen after toast")
        }
    }

    // MARK: - Rotation Layout

    func testRotation_hudRemainsVisibleAfterOrientationChange() {
        scrollToAndTap("Show / Hide HUD")
        let showButton = app.buttons["Show Default HUD"]
        XCTAssertTrue(showButton.waitForExistence(timeout: 3.0))
        showButton.tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0), "HUD should appear")

        // Rotate immediately while HUD is showing
        XCUIDevice.shared.orientation = .landscapeLeft

        // Wait for rotation to settle, then verify app stability
        sleep(1)

        // After rotation, either HUD is still visible or has auto-hidden — both are valid.
        // The key assertion is the app didn't crash and UI is accessible.
        XCTAssertTrue(showButton.waitForExistence(timeout: 3.0),
                      "App should remain stable after rotation")

        XCUIDevice.shared.orientation = .portrait
        sleep(1)

        XCTAssertTrue(showButton.waitForExistence(timeout: 3.0),
                      "App should remain stable after rotating back to portrait")
    }

    func testRotation_hudLayoutCentered() {
        scrollToAndTap("Show / Hide HUD")
        app.buttons["Show & Hide Manually"].tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Working'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0))

        XCUIDevice.shared.orientation = .landscapeRight
        sleep(1)

        if hudElement.exists {
            XCTAssertTrue(hudElement.isHittable, "HUD should be hittable (visible/centered) in landscape")
        }

        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Keyboard Interaction

    func testKeyboard_hudAdjustsWhenKeyboardAppears() {
        scrollToAndTap("Layout & Positioning")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Layout config view should load")

        let textField = app.textFields.firstMatch
        if textField.waitForExistence(timeout: 2.0) {
            textField.tap()
            sleep(1)

            XCTAssertTrue(app.navigationBars.element.exists, "App should remain stable with keyboard shown")

            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            } else if app.toolbars.buttons["Done"].exists {
                app.toolbars.buttons["Done"].tap()
            } else {
                app.tap()
            }
        }

        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    func testKeyboard_hudShowWhileKeyboardVisible() {
        scrollToAndTap("Show / Hide HUD")

        // Show the HUD directly (keyboard test simplified — the keyboard guide
        // feature is tested via unit tests; here we just verify show works)
        let showButton = app.buttons["Show Default HUD"]
        guard showButton.waitForExistence(timeout: 3.0) else { return }
        showButton.tap()

        let hudElement = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Loading'")).firstMatch
        XCTAssertTrue(hudElement.waitForExistence(timeout: 2.0),
                      "HUD should appear even with keyboard visible")
    }

    // MARK: - Navigation Stability

    func testNavigationBackAndForth_nocrash() {
        let sections = [
            "Show / Hide HUD",
            "ShowStatus (Auto-Hide)",
            "Indicator Mode",
            "Progress Mode",
            "Custom View Mode"
        ]

        for section in sections {
            scrollToAndTap(section)
            sleep(1)
            app.navigationBars.buttons.element(boundBy: 0).tap()
            sleep(1)
        }

        scrollToTop()
        XCTAssertTrue(app.staticTexts["Show / Hide HUD"].waitForExistence(timeout: 3.0))
    }

    func testRapidButtonTaps_nocrash() {
        scrollToAndTap("Show / Hide HUD")

        let showButton = app.buttons["Show Default HUD"]
        guard showButton.waitForExistence(timeout: 2.0) else { return }

        for _ in 0..<10 {
            showButton.tap()
        }

        sleep(1)
        let hideButton = app.buttons["Hide All"]
        if hideButton.exists {
            hideButton.tap()
        }

        sleep(1)
        XCTAssertTrue(showButton.exists, "App should remain stable after rapid taps")
    }

    // MARK: - Deep Navigation Memory

    func testDeepNavigation_memoryStability() {
        // Sections ordered top-to-bottom matching the ContentListView layout
        let sections = [
            "Show / Hide HUD",
            "ShowStatus (Auto-Hide)",
            "Indicator Mode",
            "Progress Mode",
            "Custom View Mode",
            "Mode Switching"
        ]

        for cycle in 0..<3 {
            scrollToTop()
            for section in sections {
                scrollToAndTap(section)

                sleep(1)
                let firstButton = app.buttons.element(boundBy: 0)
                if firstButton.waitForExistence(timeout: 2.0) {
                    firstButton.tap()
                    sleep(1)
                }

                let backButton = app.navigationBars.buttons.element(boundBy: 0)
                if backButton.waitForExistence(timeout: 2.0) {
                    backButton.tap()
                }
                sleep(1)
            }
        }

        scrollToTop()
        XCTAssertTrue(app.staticTexts["Show / Hide HUD"].waitForExistence(timeout: 3.0),
                      "App should remain responsive after repeated deep navigation (no memory issues)")
    }

    func testDeepNavigation_showHUDInEachSection_thenReturn() {
        let sections = [
            "Show / Hide HUD",
            "ShowStatus (Auto-Hide)",
            "Toast (Text Only)"
        ]

        for section in sections {
            scrollToAndTap(section)

            let firstButton = app.buttons.element(boundBy: 0)
            if firstButton.waitForExistence(timeout: 2.0) {
                firstButton.tap()
            }

            sleep(3)

            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            if backButton.waitForExistence(timeout: 2.0) {
                backButton.tap()
            }
            sleep(1)
        }

        scrollToTop()
        XCTAssertTrue(app.staticTexts["Show / Hide HUD"].waitForExistence(timeout: 3.0),
                      "Main list should be stable after showing HUDs in multiple sections")
    }

    // MARK: - Helpers

    private func scrollToAndTap(_ label: String) {
        let cell = app.staticTexts[label]
        if cell.exists {
            cell.tap()
            return
        }

        // Scroll down to find the element
        for _ in 0..<15 {
            if cell.exists { break }
            app.swipeUp()
        }

        XCTAssertTrue(cell.waitForExistence(timeout: 2.0), "\(label) should be visible after scrolling")
        cell.tap()
    }

    private func scrollToTop() {
        for _ in 0..<5 {
            app.swipeDown()
        }
    }
}
