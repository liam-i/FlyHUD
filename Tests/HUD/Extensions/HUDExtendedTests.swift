//
//  HUDExtendedTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

extension String: @retroactive HUDExtended {}
extension Int: @retroactive HUDExtended {}

@MainActor
final class HUDExtendedTests: XCTestCase {

    // MARK: - HUDExtension Tests

    func testHUDExtensionInitialization() {
        let value = "test"
        let `extension` = HUDExtension(value)

        // We can't directly access the private `type` property, but we can test the behavior
        XCTAssertNotNil(`extension`, "HUDExtension should be initialized successfully")
    }

    // MARK: - HUDExtended Protocol Tests

    func testHUDExtendedStaticProperty() {
        let staticH = String.h
        XCTAssertNotNil(staticH, "Static h property should be available")
    }

    func testHUDExtendedInstanceProperty() {
        let string = "test"
        let instanceH = string.h
        XCTAssertNotNil(instanceH, "Instance h property should be available")
    }

    // MARK: - Built-in Types HUDExtended Conformance Tests

    func testOptionalHUDExtended() {
        let optionalString: String? = "test"
        let h = optionalString.h
        XCTAssertNotNil(h, "Optional should conform to HUDExtended")
    }

    func testFloatHUDExtended() {
        let float: Float = 3.14
        let h = float.h
        XCTAssertNotNil(h, "Float should conform to HUDExtended")
    }

    func testBoolHUDExtended() {
        let bool = true
        let h = bool.h
        XCTAssertNotNil(h, "Bool should conform to HUDExtended")
    }

    func testCGRectHUDExtended() {
        let rect = CGRect.zero
        let h = rect.h
        XCTAssertNotNil(h, "CGRect should conform to HUDExtended")
    }

    func testCGPointHUDExtended() {
        let point = CGPoint.zero
        let h = point.h
        XCTAssertNotNil(h, "CGPoint should conform to HUDExtended")
    }

    func testCGFloatHUDExtended() {
        let cgFloat: CGFloat = 3.14
        let h = cgFloat.h
        XCTAssertNotNil(h, "CGFloat should conform to HUDExtended")
    }

    func testNSObjectHUDExtended() {
        let object = NSObject()
        let h = object.h
        XCTAssertNotNil(h, "NSObject should conform to HUDExtended")
    }

    // MARK: - UIColor Extension Tests

    func testUIColorContentColor() {
        let contentColor = UIColor.h.content
        XCTAssertNotNil(contentColor, "Content color should be available")

        if #available(iOS 13.0, tvOS 13.0, visionOS 1.0, *) {
            // On iOS 13+, should be label color with alpha
            let expectedColor = UIColor.label.withAlphaComponent(0.7)
            XCTAssertEqual(contentColor, expectedColor, "Content color should be label color with alpha on iOS 13+")
        } else {
            // On older systems, should be black with alpha
            let expectedColor = UIColor(white: 0.0, alpha: 0.7)
            XCTAssertEqual(contentColor, expectedColor, "Content color should be black with alpha on older systems")
        }
    }

    func testUIColorBackgroundColor() {
        let backgroundColor = UIColor.h.background

        if #available(iOS 13.0, visionOS 1.0, *) {
            // On iOS 13+, should be nil
            XCTAssertNil(backgroundColor, "Background color should be nil on iOS 13+")
        } else {
            // On older systems, should have a white tint
            XCTAssertNotNil(backgroundColor, "Background color should not be nil on older systems")
            let expectedColor = UIColor(white: 0.8, alpha: 0.6)
            XCTAssertEqual(backgroundColor, expectedColor, "Background color should be white with alpha on older systems")
        }
    }

    // MARK: - Equatable Extension Tests

    func testNotEqualWithEqualValues() {
        let value1 = 5
        let value2 = 5
        var blockExecuted = false

        value1.h.notEqual(value2, do: blockExecuted = true)

        XCTAssertFalse(blockExecuted, "Block should not be executed when values are equal")
    }

    func testNotEqualWithDifferentValues() {
        let value1 = 5
        let value2 = 10
        var blockExecuted = false

        value1.h.notEqual(value2, do: blockExecuted = true)

        XCTAssertTrue(blockExecuted, "Block should be executed when values are not equal")
    }

    func testNotEqualWithNSObjectProtocol() {
        let object1 = NSString(string: "test")
        let object2 = NSString(string: "test")
        let object3 = NSString(string: "different")
        var blockExecuted = false

        // Test with equal objects
        object1.h.notEqual(object2, do: blockExecuted = true)
        XCTAssertFalse(blockExecuted, "Block should not be executed when NSObjects are equal")

        // Reset and test with different objects
        blockExecuted = false
        object1.h.notEqual(object3, do: blockExecuted = true)
        XCTAssertTrue(blockExecuted, "Block should be executed when NSObjects are not equal")

        // Test with nil
        blockExecuted = false
        object1.h.notEqual(nil, do: blockExecuted = true)
        XCTAssertTrue(blockExecuted, "Block should be executed when comparing with nil")
    }

    // MARK: - AnyObject Extension Tests

    func testThenMethod() {
        let view = UIView()
        let originalFrame = view.frame

        let result = view.h.then { view in
            view.frame = CGRect(x: 10, y: 20, width: 100, height: 200)
            view.backgroundColor = .red
        }

        XCTAssertTrue(result === view, "Then method should return the same object")
        XCTAssertNotEqual(view.frame, originalFrame, "Frame should be modified by then block")
        XCTAssertEqual(view.frame, CGRect(x: 10, y: 20, width: 100, height: 200), "Frame should be set to expected value")
        XCTAssertEqual(view.backgroundColor, .red, "Background color should be set to red")
    }

    func testThenMethodWithThrowingBlock() {
        let view = UIView()

        enum TestError: Error {
            case testError
        }

        do {
            _ = try view.h.then { _ in
                throw TestError.testError
            }
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is TestError, "Should catch the thrown error")
        }
    }

    func testThenMethodChaining() {
        let view = UIView()

        let result = view.h.then { view in
            view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        }.h.then { view in
            view.backgroundColor = .blue
        }

        XCTAssertTrue(result === view, "Chained then methods should return the same object")
        XCTAssertEqual(view.frame, CGRect(x: 0, y: 0, width: 100, height: 100), "Frame should be set by first then")
        XCTAssertEqual(view.backgroundColor, .blue, "Background color should be set by second then")
    }
}
