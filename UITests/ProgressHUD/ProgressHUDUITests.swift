//
//  ProgressHUDUITests.swift
//  FlyHUD UITests
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest

/// End-to-end UI tests verifying ProgressView modes and styles load and display correctly.
final class ProgressHUDUITests: XCTestCase {
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

    // MARK: - Progress Mode

    func testProgressMode_loadAndShow() {
        scrollToAndTap("Progress Mode")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Progress mode view should load")

        let firstButton = app.buttons.element(boundBy: 0)
        if firstButton.waitForExistence(timeout: 2.0) {
            firstButton.tap()
            sleep(2)
        }
    }

    // MARK: - Progress Styles

    func testProgressStyles_loadWithoutCrash() {
        scrollToAndTap("ProgressView Styles")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Progress styles view should load")
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
