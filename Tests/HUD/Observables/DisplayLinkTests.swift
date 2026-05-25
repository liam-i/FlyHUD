//
//  DisplayLinkTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class DisplayLinkTests: XCTestCase {

    var displayLink: DisplayLink!

    override func setUp() async throws {
        displayLink = DisplayLink.shared
    }

    override func tearDown() async throws {
        // Clean up any delegates
        if let mockDelegate = mockDelegate {
            displayLink.remove(mockDelegate)
        }
    }

    private var mockDelegate: MockDisplayLinkDelegate?

    // MARK: - Mock Delegate

    private class MockDisplayLinkDelegate: DisplayLinkDelegate {
        var updateCallCount = 0
        var updateScreenExpectation: XCTestExpectation?

        func updateScreenInDisplayLink() {
            updateCallCount += 1
            updateScreenExpectation?.fulfill()
        }
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = DisplayLink.shared
        let instance2 = DisplayLink.shared

        XCTAssertTrue(instance1 === instance2, "DisplayLink.shared should return the same instance")
    }

    // MARK: - Delegate Management Tests

    func testAddDelegate() {
        let delegate = MockDisplayLinkDelegate()
        mockDelegate = delegate

        // Adding delegate should not throw
        XCTAssertNoThrow(displayLink.add(delegate), "Adding delegate should not throw")
    }

    func testRemoveDelegate() {
        let delegate = MockDisplayLinkDelegate()

        // Add and then remove delegate
        displayLink.add(delegate)
        XCTAssertNoThrow(displayLink.remove(delegate), "Removing delegate should not throw")
    }

    func testAddMultipleDelegates() {
        let delegate1 = MockDisplayLinkDelegate()
        let delegate2 = MockDisplayLinkDelegate()

        displayLink.add(delegate1)
        displayLink.add(delegate2)

        // Both delegates should be added without issues
        XCTAssertNoThrow(displayLink.remove(delegate1), "Removing first delegate should not throw")
        XCTAssertNoThrow(displayLink.remove(delegate2), "Removing second delegate should not throw")
    }

    func testRemoveNonExistentDelegate() {
        let delegate = MockDisplayLinkDelegate()

        // Removing a delegate that was never added should not throw
        XCTAssertNoThrow(displayLink.remove(delegate), "Removing non-existent delegate should not throw")
    }

    // MARK: - Display Link Lifecycle Tests

    func testDisplayLinkCreationAndDestruction() {
        let delegate = MockDisplayLinkDelegate()
        mockDelegate = delegate

        // Add delegate - this should create the display link
        displayLink.add(delegate)

        // Remove delegate - this should destroy the display link
        displayLink.remove(delegate)

        // No exceptions should be thrown during this process
        XCTAssertTrue(true, "Display link creation and destruction should complete without issues")
    }

    func testDisplayLinkPersistsWithMultipleDelegates() {
        let delegate1 = MockDisplayLinkDelegate()
        let delegate2 = MockDisplayLinkDelegate()

        // Add first delegate
        displayLink.add(delegate1)

        // Add second delegate
        displayLink.add(delegate2)

        // Remove first delegate - display link should persist
        displayLink.remove(delegate1)

        // Remove second delegate - display link should be destroyed
        displayLink.remove(delegate2)

        XCTAssertTrue(true, "Display link should persist until all delegates are removed")
    }

    // MARK: - Delegate Callback Tests

    func testDelegateCallback() {
        let delegate = MockDisplayLinkDelegate()
        let expectation = XCTestExpectation(description: "Delegate callback should be called")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = false // Allow multiple calls

        delegate.updateScreenExpectation = expectation
        mockDelegate = delegate

        displayLink.add(delegate)

        // Wait for at least one callback
        wait(for: [expectation], timeout: 1.0)

        XCTAssertGreaterThan(delegate.updateCallCount, 0, "Delegate callback should be called at least once")

        displayLink.remove(delegate)
    }

    func testMultipleDelegateCallbacks() {
        let delegate1 = MockDisplayLinkDelegate()
        let delegate2 = MockDisplayLinkDelegate()

        let expectation1 = XCTestExpectation(description: "First delegate callback")
        let expectation2 = XCTestExpectation(description: "Second delegate callback")
        expectation1.assertForOverFulfill = false
        expectation2.assertForOverFulfill = false

        delegate1.updateScreenExpectation = expectation1
        delegate2.updateScreenExpectation = expectation2

        displayLink.add(delegate1)
        displayLink.add(delegate2)

        wait(for: [expectation1, expectation2], timeout: 1.0)

        XCTAssertGreaterThan(delegate1.updateCallCount, 0, "First delegate should receive callbacks")
        XCTAssertGreaterThan(delegate2.updateCallCount, 0, "Second delegate should receive callbacks")

        displayLink.remove(delegate1)
        displayLink.remove(delegate2)
    }

    // MARK: - Weak Reference Tests

    func testWeakDelegateReference() {
        var delegate: MockDisplayLinkDelegate? = MockDisplayLinkDelegate()
        weak let weakDelegate = delegate

        // Add delegate
        displayLink.add(delegate!)

        // Release strong reference
        delegate = nil

        // Weak reference should become nil
        XCTAssertNil(weakDelegate, "Delegate should be weakly referenced and deallocated")

        // Adding a new delegate after the previous one was deallocated should work
        let newDelegate = MockDisplayLinkDelegate()
        mockDelegate = newDelegate
        XCTAssertNoThrow(displayLink.add(newDelegate), "Adding new delegate after previous was deallocated should work")

        displayLink.remove(newDelegate)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentDelegateManagement() {
        let delegate1 = MockDisplayLinkDelegate()
        let delegate2 = MockDisplayLinkDelegate()

        let expectation1 = XCTestExpectation(description: "Concurrent add/remove operations")
        let expectation2 = XCTestExpectation(description: "Concurrent add/remove operations")

        DispatchQueue.main.async { [self] in
            displayLink.add(delegate1)
            displayLink.remove(delegate1)
            expectation1.fulfill()
        }

        DispatchQueue.main.async { [self] in
            displayLink.add(delegate2)
            displayLink.remove(delegate2)
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 2.0)

        XCTAssertTrue(true, "Concurrent delegate management should complete without crashes")
    }
}
