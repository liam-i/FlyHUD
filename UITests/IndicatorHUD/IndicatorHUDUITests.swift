//
//  IndicatorHUDUITests.swift
//  FlyHUD UITests
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest

/// End-to-end UI tests verifying ActivityIndicatorView styles load and display correctly.
final class IndicatorHUDUITests: XCTestCase {
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

    // MARK: - Indicator Styles

    func testIndicatorStyles_loadWithoutCrash() {
        scrollToAndTap("ActivityIndicatorView Styles")

        let exists = app.navigationBars.element.waitForExistence(timeout: 3.0)
        XCTAssertTrue(exists, "Indicator styles view should load")
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
