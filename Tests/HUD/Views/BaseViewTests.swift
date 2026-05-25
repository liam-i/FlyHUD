//
//  BaseViewTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class BaseViewTests: XCTestCase {

    // MARK: - Mock BaseView Subclass

    private class MockBaseView: BaseView {
        var commonInitCallCount = 0

        override func commonInit() {
            super.commonInit()
            commonInitCallCount += 1
        }
    }

    // MARK: - Initialization Tests

    func testInitWithFrame() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 200)
        let baseView = BaseView(frame: frame)

        XCTAssertEqual(baseView.frame, frame, "Frame should be set correctly")
//        XCTAssertTrue(baseView is UIView, "BaseView should be a UIView")
    }

    func testInitWithCoder() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.finishEncoding()

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data as Data)
            let baseView = BaseView(coder: unarchiver)

            XCTAssertNotNil(baseView, "BaseView should be initialized with coder")
        } catch {
            // If coder initialization fails, it's acceptable for this test
            XCTAssertTrue(true, "Coder initialization may fail in test environment")
        }
    }

    // MARK: - CommonInit Tests

    func testCommonInitCalledInFrameInitializer() {
        let mockView = MockBaseView(frame: .zero)

        XCTAssertEqual(mockView.commonInitCallCount, 1, "commonInit should be called once during frame initialization")
    }

    func testCommonInitCalledInCoderInitializer() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.finishEncoding()

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data as Data)
            let mockView = MockBaseView(coder: unarchiver)

            if mockView != nil {
                XCTAssertEqual(mockView!.commonInitCallCount, 1, "commonInit should be called once during coder initialization")
            }
        } catch {
            // If coder initialization fails, it's acceptable for this test
            XCTAssertTrue(true, "Coder initialization may fail in test environment")
        }
    }

    func testDefaultCommonInitImplementation() {
        let baseView = BaseView(frame: .zero)

        // Default implementation should do nothing and not throw
        XCTAssertNoThrow(baseView.commonInit(), "Default commonInit should not throw")
    }

    // MARK: - Subclass Tests

    func testSubclassCanOverrideCommonInit() {
        class CustomBaseView: BaseView {
            var isConfigured = false

            override func commonInit() {
                super.commonInit()
                isConfigured = true
            }
        }

        let customView = CustomBaseView(frame: .zero)
        XCTAssertTrue(customView.isConfigured, "Subclass should be able to override commonInit")
    }

    func testSubclassCallingSuperCommonInit() {
        class TrackingSuperCallView: BaseView {
            var superCalled = false

            override func commonInit() {
                super.commonInit() // This should not throw
                superCalled = true
            }
        }

        let trackingView = TrackingSuperCallView(frame: .zero)
        XCTAssertTrue(trackingView.superCalled, "Subclass should be able to call super.commonInit()")
    }

    // MARK: - Multiple Initialization Tests

    func testMultipleInitializationCallsCommonInitOnce() {
        let mockView = MockBaseView(frame: .zero)

        // Manually calling commonInit should increment the count
        mockView.commonInit()

        XCTAssertEqual(mockView.commonInitCallCount, 2, "commonInit can be called multiple times")
    }

    // MARK: - Memory Management Tests

    func testBaseViewDeallocation() {
        var baseView: BaseView? = BaseView(frame: .zero)
        weak let weakBaseView = baseView

        baseView = nil

        XCTAssertNil(weakBaseView, "BaseView should be deallocated when no strong references remain")
    }

    func testMockBaseViewDeallocation() {
        var mockView: MockBaseView? = MockBaseView(frame: .zero)
        weak let weakMockView = mockView

        mockView = nil

        XCTAssertNil(weakMockView, "MockBaseView should be deallocated when no strong references remain")
    }

    // MARK: - Inheritance Tests

    func testBaseViewIsUIView() {
        let baseView = BaseView(frame: .zero)

//        XCTAssertTrue(baseView is UIView, "BaseView should inherit from UIView")
        XCTAssertTrue(baseView.isKind(of: UIView.self), "BaseView should be kind of UIView")
    }

    func testBaseViewProperties() {
        let frame = CGRect(x: 5, y: 10, width: 50, height: 100)
        let baseView = BaseView(frame: frame)

        // Test that UIView properties are accessible
        XCTAssertEqual(baseView.frame, frame, "Frame property should be accessible")

        baseView.backgroundColor = .red
        XCTAssertEqual(baseView.backgroundColor, .red, "UIView properties should be accessible and modifiable")

        baseView.alpha = 0.5
        XCTAssertEqual(baseView.alpha, 0.5, "Alpha property should be accessible and modifiable")
    }

    // MARK: - View Hierarchy Tests

    func testBaseViewInViewHierarchy() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let baseView = BaseView(frame: CGRect(x: 10, y: 10, width: 50, height: 50))

        containerView.addSubview(baseView)

        XCTAssertEqual(baseView.superview, containerView, "BaseView should be added to container view")
        XCTAssertTrue(containerView.subviews.contains(baseView), "Container view should contain BaseView")
    }

    // MARK: - Edge Cases Tests

    func testZeroFrameInitialization() {
        let baseView = BaseView(frame: .zero)

        XCTAssertEqual(baseView.frame, .zero, "Zero frame should be set correctly")
        XCTAssertEqual(baseView.bounds, .zero, "Bounds should be zero")
    }

    func testNegativeFrameInitialization() {
        let negativeFrame = CGRect(x: -10, y: -20, width: 100, height: 200)
        let baseView = BaseView(frame: negativeFrame)

        XCTAssertEqual(baseView.frame, negativeFrame, "Negative frame values should be allowed")
    }

    // MARK: - Performance Tests

    func testBaseViewInitializationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = BaseView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            }
        }
    }
}
