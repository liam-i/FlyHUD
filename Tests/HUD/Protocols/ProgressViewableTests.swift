//
//  ProgressViewableTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class ProgressViewableTests: XCTestCase {

    var progressView: UIProgressView!

    override func setUp() async throws {
        progressView = UIProgressView()
    }

    override func tearDown() async throws {
        progressView = nil
    }

    // MARK: - Protocol Conformance Tests

    func testUIProgressViewConformsToProtocol() {
        XCTAssertNotNil(progressView as (any ProgressViewable)?, "UIProgressView should conform to ProgressViewable")
    }

    // MARK: - Progress Property Tests

    func testProgressProperty() {
        // Default progress should be 0.0
        XCTAssertEqual(progressView.progress, 0.0, "Default progress should be 0.0")

        // Test setting valid progress values
        progressView.progress = 0.5
        XCTAssertEqual(progressView.progress, 0.5, "Progress should be set to 0.5")

        progressView.progress = 1.0
        XCTAssertEqual(progressView.progress, 1.0, "Progress should be set to 1.0")

        progressView.progress = 0.0
        XCTAssertEqual(progressView.progress, 0.0, "Progress should be set to 0.0")
    }

    func testProgressPropertyBounds() {
        // Test values outside 0.0 - 1.0 range (should be pinned)
        progressView.progress = -0.5
        XCTAssertEqual(progressView.progress, 0.0, "Negative progress should be pinned to 0.0")

        progressView.progress = 1.5
        XCTAssertEqual(progressView.progress, 1.0, "Progress greater than 1.0 should be pinned to 1.0")

        progressView.progress = -10.0
        XCTAssertEqual(progressView.progress, 0.0, "Large negative progress should be pinned to 0.0")

        progressView.progress = 100.0
        XCTAssertEqual(progressView.progress, 1.0, "Large progress should be pinned to 1.0")
    }

    // MARK: - Color Property Tests

    func testProgressTintColorProperty() {
        let testColor = UIColor.red
        progressView.progressTintColor = testColor

        XCTAssertEqual(progressView.progressTintColor, testColor, "Progress tint color should be set correctly")
    }

    func testProgressTintColorNil() {
        progressView.progressTintColor = UIColor.blue
        XCTAssertNotNil(progressView.progressTintColor, "Progress tint color should be set")

        progressView.progressTintColor = nil
        XCTAssertNil(progressView.progressTintColor, "Progress tint color should be nil when set to nil")
    }

    func testTrackTintColorProperty() {
        let testColor = UIColor.gray
        progressView.trackTintColor = testColor

        XCTAssertEqual(progressView.trackTintColor, testColor, "Track tint color should be set correctly")
    }

    func testTrackTintColorNil() {
        progressView.trackTintColor = UIColor.lightGray
        XCTAssertNotNil(progressView.trackTintColor, "Track tint color should be set")

        progressView.trackTintColor = nil
        XCTAssertNil(progressView.trackTintColor, "Track tint color should be nil when set to nil")
    }

    // MARK: - Observed Progress Tests

    func testObservedProgressProperty() {
        // Default should be nil
        XCTAssertNil(progressView.observedProgress, "Default observed progress should be nil")

        let progress = Progress()
        progressView.observedProgress = progress

        XCTAssertEqual(progressView.observedProgress, progress, "Observed progress should be set correctly")
    }

    func testObservedProgressNil() {
        let progress = Progress()
        progressView.observedProgress = progress
        XCTAssertNotNil(progressView.observedProgress, "Observed progress should be set")

        progressView.observedProgress = nil
        XCTAssertNil(progressView.observedProgress, "Observed progress should be nil when set to nil")
    }

    func testObservedProgressAutomaticUpdate() {
        let progress = Progress(totalUnitCount: 100)
        progressView.observedProgress = progress

        // Initial progress should be 0.0
        XCTAssertEqual(progressView.progress, 0.0, "Initial progress should be 0.0")

        // Update the Progress object
        progress.completedUnitCount = 50

        // Give some time for the automatic update (run loop cycle)
        let expectation = XCTestExpectation(description: "Progress should update automatically")
        DispatchQueue.main.async {
            // Progress view should automatically update from the Progress object
            XCTAssertEqual(self.progressView.progress, 0.5, accuracy: 0.01, "Progress should automatically update to 0.5")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - iOSUIProgressView Tests

    func testIOSUIProgressViewIntrinsicContentSize() {
        let customProgressView = iOSUIProgressView()
        let intrinsicSize = customProgressView.intrinsicContentSize

        XCTAssertEqual(intrinsicSize.width, 120.0, "Intrinsic content size width should be 120.0")
        XCTAssertEqual(intrinsicSize.height, 4.0, "Intrinsic content size height should be 4.0")
    }

    func testIOSUIProgressViewConformsToProtocol() {
        let customProgressView: any ProgressViewable = iOSUIProgressView()
        XCTAssertNotNil(customProgressView, "iOSUIProgressView should conform to ProgressViewable")
    }

    func testIOSUIProgressViewDeallocation() {
        var customProgressView: iOSUIProgressView? = iOSUIProgressView()
        weak let weakProgressView = customProgressView

        customProgressView = nil

        // Give some time for deallocation
        XCTAssertNil(weakProgressView, "iOSUIProgressView should be deallocated")
    }

    // MARK: - Protocol Usage Tests

    func testProgressViewableProtocolUsage() {
        let progressViewable: ProgressViewable = progressView

        // Test progress property through protocol
        progressViewable.progress = 0.75
        XCTAssertEqual(progressViewable.progress, 0.75, "Progress should be set through protocol")

        // Test color properties through protocol
        progressViewable.progressTintColor = .blue
        XCTAssertEqual(progressViewable.progressTintColor, .blue, "Progress tint color should be set through protocol")

        progressViewable.trackTintColor = .gray
        XCTAssertEqual(progressViewable.trackTintColor, .gray, "Track tint color should be set through protocol")

        // Test observed progress through protocol
        let progress = Progress()
        progressViewable.observedProgress = progress
        XCTAssertEqual(progressViewable.observedProgress, progress, "Observed progress should be set through protocol")
    }

    // MARK: - Edge Cases Tests

    func testProgressChangeAnimation() {
        // Test that progress changes work correctly
        progressView.progress = 0.0
        XCTAssertEqual(progressView.progress, 0.0, "Initial progress should be 0.0")

        // Simulate animated progress change
        progressView.setProgress(0.8, animated: true)
        XCTAssertEqual(progressView.progress, 0.8, "Progress should be updated to 0.8")

        progressView.setProgress(0.2, animated: false)
        XCTAssertEqual(progressView.progress, 0.2, "Progress should be updated to 0.2 without animation")
    }

    func testProgressViewReset() {
        // Set some values
        progressView.progress = 0.7
        progressView.progressTintColor = .red
        progressView.trackTintColor = .blue
        progressView.observedProgress = Progress()

        // Reset values
        progressView.progress = 0.0
        progressView.progressTintColor = nil
        progressView.trackTintColor = nil
        progressView.observedProgress = nil

        XCTAssertEqual(progressView.progress, 0.0, "Progress should be reset to 0.0")
        XCTAssertNil(progressView.progressTintColor, "Progress tint color should be reset to nil")
        XCTAssertNil(progressView.trackTintColor, "Track tint color should be reset to nil")
        XCTAssertNil(progressView.observedProgress, "Observed progress should be reset to nil")
    }

    // MARK: - Performance Tests

    func testProgressUpdatePerformance() {
        measure {
            for i in 0...1000 {
                progressView.progress = Float(i) / 1000.0
            }
        }
    }
}
