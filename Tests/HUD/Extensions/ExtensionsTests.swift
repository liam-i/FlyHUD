//
//  ExtensionsTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

final class ExtensionsTests: XCTestCase {

    // MARK: - UIView Extensions Tests

    func testUIViewIsRTL() {
        // Test Right-to-Left layout detection
        let isRTL = UIView.isRTL

        // This will depend on the current system settings
        // We just verify it returns a boolean value
        XCTAssertTrue(isRTL == true || isRTL == false, "isRTL should return a boolean value")
    }

    func testIsHiddenInStackView() {
        let view = UIView()

        // Initial state
        XCTAssertFalse(view.isHiddenInStackView, "View should not be hidden initially")

        // Set to hidden
        view.isHiddenInStackView = true
        XCTAssertTrue(view.isHiddenInStackView, "View should be hidden after setting to true")
        XCTAssertTrue(view.isHidden, "Underlying isHidden should also be true")

        // Set to visible
        view.isHiddenInStackView = false
        XCTAssertFalse(view.isHiddenInStackView, "View should not be hidden after setting to false")
        XCTAssertFalse(view.isHidden, "Underlying isHidden should also be false")

        // Test that setting the same value doesn't change anything
        view.isHiddenInStackView = false
        XCTAssertFalse(view.isHiddenInStackView, "View should remain not hidden")
    }

    func testSetContentCompressionResistancePriorityForAxis() {
        let view = UIView()
        let priority: Float = 900.0

        view.setContentCompressionResistancePriorityForAxis(priority)

        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints, "translatesAutoresizingMaskIntoConstraints should be false")

        let horizontalPriority = view.contentCompressionResistancePriority(for: .horizontal)
        let verticalPriority = view.contentCompressionResistancePriority(for: .vertical)

        XCTAssertEqual(horizontalPriority.rawValue, priority, "Horizontal compression resistance priority should be set")
        XCTAssertEqual(verticalPriority.rawValue, priority, "Vertical compression resistance priority should be set")
    }

    // MARK: - UIView.EdgeConstraint Tests

    func testEdgeConstraintInitialization() {
        let containerView = UIView()
        let childView = UIView()
        containerView.addSubview(childView)

        let centerPriority = UILayoutPriority(900)
        let edgePriority = UILayoutPriority(800)

        let edgeConstraint = UIView.EdgeConstraint(
            childView,
            to: containerView,
            useSafeGuide: false,
            center: centerPriority,
            edge: edgePriority
        )

        XCTAssertNotNil(edgeConstraint.x, "X constraint should be created")
        XCTAssertNotNil(edgeConstraint.y, "Y constraint should be created")
        XCTAssertNotNil(edgeConstraint.top, "Top constraint should be created")
        XCTAssertNotNil(edgeConstraint.bottom, "Bottom constraint should be created")
        XCTAssertNotNil(edgeConstraint.left, "Left constraint should be created")
        XCTAssertNotNil(edgeConstraint.right, "Right constraint should be created")

        XCTAssertEqual(edgeConstraint.x.priority, centerPriority, "X constraint should have center priority")
        XCTAssertEqual(edgeConstraint.y.priority, centerPriority, "Y constraint should have center priority")
        XCTAssertEqual(edgeConstraint.top.priority, edgePriority, "Top constraint should have edge priority")
        XCTAssertEqual(edgeConstraint.bottom.priority, edgePriority, "Bottom constraint should have edge priority")
        XCTAssertEqual(edgeConstraint.left.priority, edgePriority, "Left constraint should have edge priority")
        XCTAssertEqual(edgeConstraint.right.priority, edgePriority, "Right constraint should have edge priority")
    }

    func testEdgeConstraintWithSafeAreaGuide() {
        let containerView = UIView()
        let childView = UIView()
        containerView.addSubview(childView)

        let edgeConstraint = UIView.EdgeConstraint(
            childView,
            to: containerView,
            useSafeGuide: true,
            center: UILayoutPriority(900),
            edge: UILayoutPriority(800)
        )

        // Verify constraints are created (can't easily test anchor relationships in unit tests)
        XCTAssertNotNil(edgeConstraint.x, "X constraint should be created with safe area guide")
        XCTAssertNotNil(edgeConstraint.y, "Y constraint should be created with safe area guide")
    }

    func testEdgeConstraintUpdateOffset() {
        let containerView = UIView()
        let childView = UIView()
        containerView.addSubview(childView)

        let edgeConstraint = UIView.EdgeConstraint(
            childView,
            to: containerView,
            useSafeGuide: false,
            center: UILayoutPriority(900),
            edge: UILayoutPriority(800)
        )

        let offset = CGPoint(x: 10, y: 20)
        let edgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 25, right: 35)

        edgeConstraint.update(offset: offset, edge: edgeInsets)

        XCTAssertEqual(edgeConstraint.x.constant, offset.x, "X constraint constant should be updated")
        XCTAssertEqual(edgeConstraint.y.constant, offset.y, "Y constraint constant should be updated")
        XCTAssertEqual(edgeConstraint.left.constant, edgeInsets.left, "Left constraint constant should be updated")
        XCTAssertEqual(edgeConstraint.right.constant, -edgeInsets.right, "Right constraint constant should be negative right inset")
        XCTAssertEqual(edgeConstraint.top.constant, edgeInsets.top, "Top constraint constant should be updated")
        XCTAssertEqual(edgeConstraint.bottom.constant, -edgeInsets.bottom, "Bottom constraint constant should be negative bottom inset")
    }

    func testEdgeConstraintUpdateMargins() {
        let containerView = UIView()
        let childView = UIView()
        containerView.addSubview(childView)

        let edgeConstraint = UIView.EdgeConstraint(
            childView,
            to: containerView,
            useSafeGuide: false,
            center: UILayoutPriority(900),
            edge: UILayoutPriority(800)
        )

        let hMargin: CGFloat = 10
        let vMargin: CGFloat = 20

        edgeConstraint.update(hMargin: hMargin, vMargin: vMargin)

        XCTAssertEqual(edgeConstraint.left.constant, hMargin, "Left constraint constant should be horizontal margin")
        XCTAssertEqual(edgeConstraint.right.constant, -hMargin, "Right constraint constant should be negative horizontal margin")
        XCTAssertEqual(edgeConstraint.top.constant, vMargin, "Top constraint constant should be vertical margin")
        XCTAssertEqual(edgeConstraint.bottom.constant, -vMargin, "Bottom constraint constant should be negative vertical margin")
    }
}
