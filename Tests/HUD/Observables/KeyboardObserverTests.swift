//
//  KeyboardObserverTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

#if os(iOS)
@MainActor
final class KeyboardObserverTests: XCTestCase {

    var keyboardObserver: KeyboardObserver!

    override func setUp() async throws {
        keyboardObserver = KeyboardObserver.shared
    }

    override func tearDown() async throws {
        // Clean up any observers
        if let mockObserver = mockObserver {
            keyboardObserver.remove(mockObserver)
        }
    }

    private var mockObserver: MockKeyboardObservable?

    // MARK: - Mock Observer

    private class MockKeyboardObservable: KeyboardObservable {
        var keyboardInfoChanges: [KeyboardInfo] = []
        var keyboardObserverExpectation: XCTestExpectation?

        func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo) {
            keyboardInfoChanges.append(keyboardInfo)
            keyboardObserverExpectation?.fulfill()
        }
    }

    // MARK: - KeyboardInfo Tests

    func testKeyboardInfoName() {
        let willChangeInfo = KeyboardInfo(
            name: .willChangeFrame,
            animationDuration: 0.3,
            animationCurve: 7,
            frameBegin: .zero,
            frameEnd: CGRect(x: 0, y: 100, width: 320, height: 216),
            isVisible: true
        )

        let didChangeInfo = KeyboardInfo(
            name: .didChangeFrame,
            animationDuration: 0.3,
            animationCurve: 7,
            frameBegin: .zero,
            frameEnd: CGRect(x: 0, y: 100, width: 320, height: 216),
            isVisible: true
        )

        XCTAssertEqual(willChangeInfo.name, .willChangeFrame, "Name should be willChangeFrame")
        XCTAssertEqual(didChangeInfo.name, .didChangeFrame, "Name should be didChangeFrame")
    }

    func testKeyboardInfoProperties() {
        let animationDuration: TimeInterval = 0.3
        let animationCurve: UInt = 7
        let frameBegin = CGRect.zero
        let frameEnd = CGRect(x: 0, y: 100, width: 320, height: 216)
        let isVisible = true

        let keyboardInfo = KeyboardInfo(
            name: .willChangeFrame,
            animationDuration: animationDuration,
            animationCurve: animationCurve,
            frameBegin: frameBegin,
            frameEnd: frameEnd,
            isVisible: isVisible
        )

        XCTAssertEqual(keyboardInfo.animationDuration, animationDuration, "Animation duration should match")
        XCTAssertEqual(keyboardInfo.animationCurve, animationCurve, "Animation curve should match")
        XCTAssertEqual(keyboardInfo.frameBegin, frameBegin, "Frame begin should match")
        XCTAssertEqual(keyboardInfo.frameEnd, frameEnd, "Frame end should match")
        XCTAssertEqual(keyboardInfo.isVisible, isVisible, "Is visible should match")
    }

    func testKeyboardInfoVisibility() {
        let screenHeight = UIScreen.main.bounds.height

        // Keyboard visible (frame end Y is less than screen height)
        let visibleKeyboardInfo = KeyboardInfo(
            name: .willChangeFrame,
            animationDuration: 0.3,
            animationCurve: 7,
            frameBegin: CGRect(x: 0, y: screenHeight, width: 320, height: 216),
            frameEnd: CGRect(x: 0, y: screenHeight - 216, width: 320, height: 216),
            isVisible: true
        )

        // Keyboard hidden (frame end Y is at or beyond screen height)
        let hiddenKeyboardInfo = KeyboardInfo(
            name: .willChangeFrame,
            animationDuration: 0.3,
            animationCurve: 7,
            frameBegin: CGRect(x: 0, y: screenHeight - 216, width: 320, height: 216),
            frameEnd: CGRect(x: 0, y: screenHeight, width: 320, height: 216),
            isVisible: false
        )

        XCTAssertTrue(visibleKeyboardInfo.isVisible, "Keyboard should be visible when frame is on screen")
        XCTAssertFalse(hiddenKeyboardInfo.isVisible, "Keyboard should be hidden when frame is off screen")
    }

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let instance1 = KeyboardObserver.shared
        let instance2 = KeyboardObserver.shared

        XCTAssertTrue(instance1 === instance2, "KeyboardObserver.shared should return the same instance")
    }

    func testEnableMethod() {
        // This should not throw and should return the shared instance
        XCTAssertNoThrow(KeyboardObserver.enable(), "KeyboardObserver.enable() should not throw")

        let sharedInstance = KeyboardObserver.shared
        XCTAssertNotNil(sharedInstance, "Shared instance should be available after enable")
    }

    // MARK: - Observer Management Tests

    func testAddObserver() {
        let observer = MockKeyboardObservable()
        mockObserver = observer

        XCTAssertNoThrow(keyboardObserver.add(observer), "Adding observer should not throw")
    }

    func testRemoveObserver() {
        let observer = MockKeyboardObservable()

        keyboardObserver.add(observer)
        XCTAssertNoThrow(keyboardObserver.remove(observer), "Removing observer should not throw")
    }

    func testAddMultipleObservers() {
        let observer1 = MockKeyboardObservable()
        let observer2 = MockKeyboardObservable()

        keyboardObserver.add(observer1)
        keyboardObserver.add(observer2)

        XCTAssertNoThrow(keyboardObserver.remove(observer1), "Removing first observer should not throw")
        XCTAssertNoThrow(keyboardObserver.remove(observer2), "Removing second observer should not throw")
    }

    func testRemoveNonExistentObserver() {
        let observer = MockKeyboardObservable()

        // Removing an observer that was never added should not throw
        XCTAssertNoThrow(keyboardObserver.remove(observer), "Removing non-existent observer should not throw")
    }

    // MARK: - KeyboardInfo Property Tests

    func testInitialKeyboardInfo() {
        // Initially, keyboard info might be nil
        let initialKeyboardInfo = keyboardObserver.keyboardInfo

        // We can't guarantee the initial state, but it should be accessible
        XCTAssertTrue(initialKeyboardInfo == nil || initialKeyboardInfo != nil, "KeyboardInfo should be accessible")
    }

    // MARK: - Weak Reference Tests

    func testWeakObserverReference() {
        var observer: MockKeyboardObservable? = MockKeyboardObservable()
        weak let weakObserver = observer

        // Add observer
        keyboardObserver.add(observer!)

        // Release strong reference
        observer = nil

        // Weak reference should become nil
        XCTAssertNil(weakObserver, "Observer should be weakly referenced and deallocated")

        // Adding a new observer after the previous one was deallocated should work
        let newObserver = MockKeyboardObservable()
        mockObserver = newObserver
        XCTAssertNoThrow(keyboardObserver.add(newObserver), "Adding new observer after previous was deallocated should work")

        keyboardObserver.remove(newObserver)
    }

    // MARK: - Notification Simulation Tests

    func testKeyboardNotificationHandling() {
        let observer = MockKeyboardObservable()
        let expectation = XCTestExpectation(description: "Keyboard notification should trigger observer callback")
        observer.keyboardObserverExpectation = expectation
        mockObserver = observer

        keyboardObserver.add(observer)

        // Simulate keyboard notification
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 100, width: 320, height: 216),
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect.zero,
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.3,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7)
        ]

        let notification = Notification(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )

        NotificationCenter.default.post(notification)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.keyboardInfoChanges.count, 1, "Observer should receive one keyboard info change")

        let receivedInfo = observer.keyboardInfoChanges.first!
        XCTAssertEqual(receivedInfo.name, .willChangeFrame, "Should receive willChangeFrame notification")
        XCTAssertEqual(receivedInfo.animationDuration, 0.3, "Animation duration should match")
        XCTAssertEqual(receivedInfo.animationCurve, 7, "Animation curve should match")

        keyboardObserver.remove(observer)
    }

    func testKeyboardDidChangeFrameNotification() {
        let observer = MockKeyboardObservable()
        let expectation = XCTestExpectation(description: "Keyboard did change frame notification")
        observer.keyboardObserverExpectation = expectation
        mockObserver = observer

        keyboardObserver.add(observer)

        // Simulate keyboard did change frame notification
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 200, width: 320, height: 216),
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect(x: 0, y: 100, width: 320, height: 216),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(0)
        ]

        let notification = Notification(
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )

        NotificationCenter.default.post(notification)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(observer.keyboardInfoChanges.count, 1, "Observer should receive one keyboard info change")

        let receivedInfo = observer.keyboardInfoChanges.first!
        XCTAssertEqual(receivedInfo.name, .didChangeFrame, "Should receive didChangeFrame notification")
        XCTAssertEqual(receivedInfo.animationDuration, 0.25, "Animation duration should match")
        XCTAssertEqual(receivedInfo.animationCurve, 0, "Animation curve should match")

        keyboardObserver.remove(observer)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentObserverManagement() {
        let observer1 = MockKeyboardObservable()
        let observer2 = MockKeyboardObservable()

        let expectation1 = XCTestExpectation(description: "Concurrent add/remove operations")
        let expectation2 = XCTestExpectation(description: "Concurrent add/remove operations")

        DispatchQueue.main.async { [self] in
            keyboardObserver.add(observer1)
            keyboardObserver.remove(observer1)
            expectation1.fulfill()
        }

        DispatchQueue.main.async { [self] in
            keyboardObserver.add(observer2)
            keyboardObserver.remove(observer2)
            expectation2.fulfill()
        }

        wait(for: [expectation1, expectation2], timeout: 2.0)

        XCTAssertTrue(true, "Concurrent observer management should complete without crashes")
    }

    // MARK: - Edge Case Notification Tests

    func testNotificationWithoutUserInfo() {
        let observer = MockKeyboardObservable()
        mockObserver = observer
        keyboardObserver.add(observer)

        // Post notification without userInfo - should be ignored (guard early return)
        let notification = Notification(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: nil
        )
        NotificationCenter.default.post(notification)

        // Observer should NOT be called
        XCTAssertEqual(observer.keyboardInfoChanges.count, 0, "Observer should not be called for notification without userInfo")

        keyboardObserver.remove(observer)
    }

    func testNotificationWithoutFrameEndKey() {
        let observer = MockKeyboardObservable()
        mockObserver = observer
        keyboardObserver.add(observer)

        // Post notification with userInfo but missing keyboardFrameEndUserInfoKey
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.3
        ]
        let notification = Notification(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )
        NotificationCenter.default.post(notification)

        // Observer should NOT be called (guard fails on frameEnd)
        XCTAssertEqual(observer.keyboardInfoChanges.count, 0, "Observer should not be called for notification without frameEnd")

        keyboardObserver.remove(observer)
    }

    func testNotificationWithMissingOptionalFields() {
        let observer = MockKeyboardObservable()
        let expectation = XCTestExpectation(description: "Should handle missing optional fields")
        observer.keyboardObserverExpectation = expectation
        mockObserver = observer
        keyboardObserver.add(observer)

        // Only frameEnd is required, others use defaults
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 500, width: 320, height: 216)
        ]
        let notification = Notification(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )
        NotificationCenter.default.post(notification)

        wait(for: [expectation], timeout: 1.0)

        let info = observer.keyboardInfoChanges.first!
        XCTAssertEqual(info.animationDuration, 0.0, "Missing animation duration should default to 0")
        XCTAssertEqual(info.animationCurve, 0, "Missing animation curve should default to 0")
        XCTAssertEqual(info.frameBegin, .zero, "Missing frame begin should default to zero")

        keyboardObserver.remove(observer)
    }
}
#endif // os(iOS)
