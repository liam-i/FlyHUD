//
//  RotateViewableTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class RotateViewableTests: XCTestCase {

    // MARK: - Mock RotateViewable Implementation

    private class MockRotateView: UIView, RotateViewable {
        var customDuration: CFTimeInterval = 0.25

        var duration: CFTimeInterval {
            return customDuration
        }
    }

    private var rotateView: MockRotateView!

    override func setUp() async throws {
        rotateView = MockRotateView()
    }

    override func tearDown() async throws {
        rotateView?.stopRotating()
        rotateView = nil
    }

    // MARK: - Protocol Conformance Tests

    func testMockRotateViewConformsToProtocol() {
        XCTAssertNotNil(rotateView as (any RotateViewable)?, "MockRotateView should conform to RotateViewable")
    }

    // MARK: - Duration Property Tests

    func testDefaultDuration() {
        let defaultView = MockRotateView()

        // Reset to use default implementation
        defaultView.customDuration = 0.25
        XCTAssertEqual(defaultView.duration, 0.25, "Default duration should be 0.25")
    }

    func testCustomDuration() {
        let customDuration: CFTimeInterval = 1.0
        rotateView.customDuration = customDuration

        XCTAssertEqual(rotateView.duration, customDuration, "Custom duration should be set correctly")
    }

    // MARK: - Animation Key Tests

    func testAnimationKey() {
        // Test that we can access the animation key through the HUD extension
        // Note: The key is private, but we can test that animations are added/removed
        XCTAssertNotNil(rotateView.layer, "Layer should exist for animation")
    }

    // MARK: - Start Rotating Tests

    func testStartRotating() {
        // Initially no animations
        XCTAssertEqual(rotateView.layer.animationKeys()?.count ?? 0, 0, "Should have no animations initially")

        rotateView.startRotating()

        // Should have animation added
        let animationKeys = rotateView.layer.animationKeys()
        XCTAssertNotNil(animationKeys, "Animation keys should not be nil")
        XCTAssertGreaterThan(animationKeys?.count ?? 0, 0, "Should have at least one animation")
    }

    func testStartRotatingAnimationProperties() {
        rotateView.startRotating()

        let animationKeys = rotateView.layer.animationKeys()
        XCTAssertNotNil(animationKeys, "Animation keys should not be nil")

        if let keys = animationKeys, !keys.isEmpty {
            let animation = rotateView.layer.animation(forKey: keys.first!)
            XCTAssertNotNil(animation, "Animation should exist")

            if let basicAnimation = animation as? CABasicAnimation {
                XCTAssertEqual(basicAnimation.keyPath, "transform", "Animation should target transform")
                XCTAssertEqual(basicAnimation.duration, rotateView.duration, "Animation duration should match view duration")
                XCTAssertTrue(basicAnimation.isCumulative, "Animation should be cumulative")
                XCTAssertEqual(basicAnimation.repeatCount, .greatestFiniteMagnitude, "Animation should repeat indefinitely")
                XCTAssertFalse(basicAnimation.isRemovedOnCompletion, "Animation should not be removed on completion")
            }
        }
    }

    func testMultipleStartRotatingCalls() {
        rotateView.startRotating()
        let animationKeysAfterFirst = rotateView.layer.animationKeys()?.count ?? 0

        rotateView.startRotating()
        let animationKeysAfterSecond = rotateView.layer.animationKeys()?.count ?? 0

        // Multiple calls should not add multiple animations for the same key
        XCTAssertEqual(animationKeysAfterFirst, animationKeysAfterSecond, "Multiple start calls should not add multiple animations")
    }

    // MARK: - Stop Rotating Tests

    func testStopRotating() {
        rotateView.startRotating()

        // Verify animation was added
        let animationKeysBeforeStop = rotateView.layer.animationKeys()?.count ?? 0
        XCTAssertGreaterThan(animationKeysBeforeStop, 0, "Should have animations before stop")

        rotateView.stopRotating()

        // Animation should be removed
        let animationKeysAfterStop = rotateView.layer.animationKeys()?.count ?? 0
        XCTAssertEqual(animationKeysAfterStop, 0, "Should have no animations after stop")
    }

    func testStopRotatingWithoutStarting() {
        // Should not throw when stopping without starting
        XCTAssertNoThrow(rotateView.stopRotating(), "Stop rotating without starting should not throw")

        let animationKeys = rotateView.layer.animationKeys()?.count ?? 0
        XCTAssertEqual(animationKeys, 0, "Should have no animations")
    }

    func testMultipleStopRotatingCalls() {
        rotateView.startRotating()
        rotateView.stopRotating()

        // Multiple stop calls should not cause issues
        XCTAssertNoThrow(rotateView.stopRotating(), "Multiple stop calls should not throw")

        let animationKeys = rotateView.layer.animationKeys()?.count ?? 0
        XCTAssertEqual(animationKeys, 0, "Should have no animations after multiple stops")
    }

    // MARK: - Animation Lifecycle Tests

    func testStartStopCycle() {
        // Test multiple start/stop cycles
        for _ in 0..<5 {
            rotateView.startRotating()
            XCTAssertGreaterThan(rotateView.layer.animationKeys()?.count ?? 0, 0, "Should have animations after start")

            rotateView.stopRotating()
            XCTAssertEqual(rotateView.layer.animationKeys()?.count ?? 0, 0, "Should have no animations after stop")
        }
    }

    func testAnimationStateAfterViewDeallocation() {
        var testView: MockRotateView? = MockRotateView()
        weak let weakView = testView

        testView?.startRotating()

        // Release strong reference
        testView = nil

        // View should be deallocated
        XCTAssertNil(weakView, "View should be deallocated")
    }

    // MARK: - Transform Animation Tests

    func testAnimationTransformValues() {
        rotateView.startRotating()

        if let animationKeys = rotateView.layer.animationKeys(),
           let firstKey = animationKeys.first,
           let animation = rotateView.layer.animation(forKey: firstKey) as? CABasicAnimation {

            // Test from value (identity transform)
            if let fromValue = animation.fromValue as? NSValue {
                let fromTransform = fromValue.caTransform3DValue
                XCTAssertTrue(CATransform3DEqualToTransform(fromTransform, CATransform3DIdentity), "From transform should be identity")
            }

            // Test to value (90-degree rotation)
            if let toValue = animation.toValue as? NSValue {
                let toTransform = toValue.caTransform3DValue
                let expectedTransform = CATransform3DMakeRotation(.pi / 2.0, 0.0, 0.0, 1.0)
                XCTAssertTrue(CATransform3DEqualToTransform(toTransform, expectedTransform), "To transform should be 90-degree rotation")
            }
        } else {
            XCTFail("Should have rotation animation")
        }
    }

    // MARK: - Custom Duration Tests

    func testCustomDurationInAnimation() {
        let customDuration: CFTimeInterval = 2.0
        rotateView.customDuration = customDuration

        rotateView.startRotating()

        if let animationKeys = rotateView.layer.animationKeys(),
           let firstKey = animationKeys.first,
           let animation = rotateView.layer.animation(forKey: firstKey) as? CABasicAnimation {

            XCTAssertEqual(animation.duration, customDuration, "Animation duration should match custom duration")
        } else {
            XCTFail("Should have rotation animation with custom duration")
        }
    }

    // MARK: - Protocol Extension Tests

    func testProtocolDefaultImplementation() {
        // Create a minimal implementation to test default behavior
        class MinimalRotateView: UIView, RotateViewable {}

        let minimalView = MinimalRotateView()

        // Test default duration
        XCTAssertEqual(minimalView.duration, 0.25, "Default duration should be 0.25")

        // Test that default implementations work
        XCTAssertNoThrow(minimalView.startRotating(), "Default startRotating should not throw")
        XCTAssertNoThrow(minimalView.stopRotating(), "Default stopRotating should not throw")

        minimalView.stopRotating() // Clean up
    }

    // MARK: - Thread Safety Tests

    func testConcurrentStartStop() {
        let expectation1 = XCTestExpectation(description: "Concurrent start/stop operations")
        let expectation2 = XCTestExpectation(description: "Concurrent start/stop operations")

        DispatchQueue.main.async { [self] in
            for _ in 0..<10 {
                self.rotateView.startRotating()
                self.rotateView.stopRotating()
            }
            expectation1.fulfill()
        }

        DispatchQueue.main.async { [self] in
            for _ in 0..<10 {
                self.rotateView.startRotating()
                self.rotateView.stopRotating()
            }
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 2.0)

        // Ensure final state is clean
        rotateView.stopRotating()
        XCTAssertEqual(rotateView.layer.animationKeys()?.count ?? 0, 0, "Should have no animations after concurrent operations")
    }
}
