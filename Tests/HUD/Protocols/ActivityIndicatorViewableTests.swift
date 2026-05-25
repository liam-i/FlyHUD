//
//  ActivityIndicatorViewableTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class ActivityIndicatorViewableTests: XCTestCase {

    var activityIndicator: UIActivityIndicatorView!

    override func setUp() async throws {
        activityIndicator = UIActivityIndicatorView()
    }

    override func tearDown() async throws {
        activityIndicator = nil
    }

    // MARK: - Protocol Conformance Tests

    func testUIActivityIndicatorViewConformsToProtocol() {
        XCTAssertNotNil(activityIndicator as (any ActivityIndicatorViewable)?, "UIActivityIndicatorView should conform to ActivityIndicatorViewable")
    }

    // MARK: - Color Property Tests

    func testColorProperty() {
        let testColor = UIColor.red
        activityIndicator.color = testColor

        XCTAssertEqual(activityIndicator.color, testColor, "Color should be set correctly")
    }

    // MARK: - Track Color Property Tests

    func testTrackColorProperty() {
        let testColor = UIColor.blue

        // UIActivityIndicatorView doesn't support track color, should always return nil
        activityIndicator.trackColor = testColor
        XCTAssertNil(activityIndicator.trackColor, "Track color should always be nil for UIActivityIndicatorView")
    }

    func testTrackColorGetterAlwaysReturnsNil() {
        XCTAssertNil(activityIndicator.trackColor, "Track color getter should always return nil")
    }

    // MARK: - Hides When Stopped Property Tests

    func testHidesWhenStoppedProperty() {
        // Default value should be true
        XCTAssertTrue(activityIndicator.hidesWhenStopped, "Default hidesWhenStopped should be true")

        activityIndicator.hidesWhenStopped = false
        XCTAssertFalse(activityIndicator.hidesWhenStopped, "hidesWhenStopped should be set to false")

        activityIndicator.hidesWhenStopped = true
        XCTAssertTrue(activityIndicator.hidesWhenStopped, "hidesWhenStopped should be set to true")
    }

    // MARK: - Animation State Tests

    func testIsAnimatingProperty() {
        // Initially should not be animating
        XCTAssertFalse(activityIndicator.isAnimating, "Should not be animating initially")

        activityIndicator.startAnimating()
        XCTAssertTrue(activityIndicator.isAnimating, "Should be animating after startAnimating")

        activityIndicator.stopAnimating()
        XCTAssertFalse(activityIndicator.isAnimating, "Should not be animating after stopAnimating")
    }

    // MARK: - Animation Methods Tests

    func testStartAnimating() {
        activityIndicator.startAnimating()

        XCTAssertTrue(activityIndicator.isAnimating, "Should be animating after startAnimating")

        // If hidesWhenStopped is true, view should be visible when animating
        if activityIndicator.hidesWhenStopped {
            XCTAssertFalse(activityIndicator.isHidden, "Should be visible when animating and hidesWhenStopped is true")
        }
    }

    func testStopAnimating() {
        activityIndicator.startAnimating()
        XCTAssertTrue(activityIndicator.isAnimating, "Should be animating before stopping")

        activityIndicator.stopAnimating()
        XCTAssertFalse(activityIndicator.isAnimating, "Should not be animating after stopAnimating")

        // If hidesWhenStopped is true, view should be hidden when not animating
        if activityIndicator.hidesWhenStopped {
            XCTAssertTrue(activityIndicator.isHidden, "Should be hidden when not animating and hidesWhenStopped is true")
        }
    }

    func testMultipleStartAnimatingCalls() {
        activityIndicator.startAnimating()
        XCTAssertTrue(activityIndicator.isAnimating, "Should be animating after first call")

        activityIndicator.startAnimating()
        XCTAssertTrue(activityIndicator.isAnimating, "Should still be animating after second call")
    }

    func testMultipleStopAnimatingCalls() {
        activityIndicator.startAnimating()
        activityIndicator.stopAnimating()
        XCTAssertFalse(activityIndicator.isAnimating, "Should not be animating after first stop")

        activityIndicator.stopAnimating()
        XCTAssertFalse(activityIndicator.isAnimating, "Should still not be animating after second stop")
    }

    // MARK: - Visibility Tests

    func testVisibilityWithHidesWhenStopped() {
        activityIndicator.hidesWhenStopped = true

        // Initially should be hidden (not animating)
        XCTAssertTrue(activityIndicator.isHidden, "Should be hidden initially when hidesWhenStopped is true")

        activityIndicator.startAnimating()
        XCTAssertFalse(activityIndicator.isHidden, "Should be visible when animating")

        activityIndicator.stopAnimating()
        XCTAssertTrue(activityIndicator.isHidden, "Should be hidden when stopped and hidesWhenStopped is true")
    }

    func testVisibilityWithoutHidesWhenStopped() {
        activityIndicator.hidesWhenStopped = false
        activityIndicator.isHidden = false // Explicitly set to visible

        activityIndicator.startAnimating()
        XCTAssertFalse(activityIndicator.isHidden, "Should remain visible when animating")

        activityIndicator.stopAnimating()
        XCTAssertFalse(activityIndicator.isHidden, "Should remain visible when stopped and hidesWhenStopped is false")
    }

    // MARK: - UIActivityIndicatorView.Style Extension Tests

    func testUIActivityIndicatorViewStyleHUDExtended() {
        let style = UIActivityIndicatorView.Style.large
        let h = style.h
        XCTAssertNotNil(h, "UIActivityIndicatorView.Style should conform to HUDExtended")
    }

    func testLargeStyleExtension() {
        let largeStyle = UIActivityIndicatorView.Style.h.large

        #if os(visionOS)
        XCTAssertEqual(largeStyle, .large, "Should return .large on visionOS")
        #else
        if #available(iOS 13.0, tvOS 13.0, visionOS 1.0, *) {
            XCTAssertEqual(largeStyle, .large, "Should return .large on iOS 13+")
        } else {
            XCTAssertEqual(largeStyle, .whiteLarge, "Should return .whiteLarge on older systems")
        }
        #endif
    }

    // MARK: - Integration Tests

    func testActivityIndicatorViewableProtocolUsage() {
        let activityIndicatorViewable: ActivityIndicatorViewable = activityIndicator

        // Test that we can use the protocol methods
        XCTAssertFalse(activityIndicatorViewable.isAnimating, "Should not be animating initially")

        activityIndicatorViewable.color = .green
        XCTAssertEqual(activityIndicatorViewable.color, .green, "Color should be set through protocol")

        activityIndicatorViewable.hidesWhenStopped = false
        XCTAssertFalse(activityIndicatorViewable.hidesWhenStopped, "hidesWhenStopped should be set through protocol")

        activityIndicatorViewable.startAnimating()
        XCTAssertTrue(activityIndicatorViewable.isAnimating, "Should be animating after protocol method call")

        activityIndicatorViewable.stopAnimating()
        XCTAssertFalse(activityIndicatorViewable.isAnimating, "Should not be animating after protocol method call")
    }
}
