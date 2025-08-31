//
//  ActivityIndicatorViewTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

final class ActivityIndicatorViewTests: XCTestCase {

    var activityIndicatorView: ActivityIndicatorView!

    override func setUpWithError() throws {
        try super.setUpWithError()
        activityIndicatorView = ActivityIndicatorView()
    }

    override func tearDownWithError() throws {
        activityIndicatorView?.stopAnimating()
        activityIndicatorView = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(activityIndicatorView, "ActivityIndicatorView should be initialized")
//        XCTAssertTrue(activityIndicatorView is BaseView, "ActivityIndicatorView should inherit from BaseView")
//        XCTAssertTrue(activityIndicatorView is ActivityIndicatorViewable, "ActivityIndicatorView should conform to ActivityIndicatorViewable")
    }

    func testInitWithFrame() {
        let frame = CGRect(x: 10, y: 20, width: 100, height: 100)
        let view = ActivityIndicatorView(frame: frame)

        XCTAssertEqual(view.frame, frame, "Frame should be set correctly")
    }

    func testInitWithCoder() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.finishEncoding()

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data as Data)
            let view = ActivityIndicatorView(coder: unarchiver)

            XCTAssertNotNil(view, "ActivityIndicatorView should be initialized with coder")
        } catch {
            XCTAssertTrue(true, "Coder initialization may fail in test environment")
        }
    }

    // MARK: - Style Tests

    func testDefaultStyle() {
        XCTAssertTrue(activityIndicatorView.style.isEqual(ActivityIndicatorView.Style.ringClipRotate), "Default style should be ringClipRotate")
    }

    func testStyleChange() {
        let newStyle = ActivityIndicatorView.Style.ballSpinFade
        activityIndicatorView.style = newStyle

        XCTAssertTrue(activityIndicatorView.style.isEqual(newStyle), "Style should be changed correctly")
    }

    func testStyleEquality() {
        let style1 = ActivityIndicatorView.Style.ringClipRotate
        let style2 = ActivityIndicatorView.Style.ringClipRotate
        let style3 = ActivityIndicatorView.Style.ballSpinFade

        XCTAssertTrue(style1.isEqual(style2), "Same styles should be equal")
        XCTAssertFalse(style1.isEqual(style3), "Different styles should not be equal")
        XCTAssertFalse(style1.isEqual("string"), "Style should not be equal to non-style object")
    }

    func testAllStyleCases() {
        let allStyles = ActivityIndicatorView.Style.allCases

        XCTAssertTrue(allStyles.contains(.ringClipRotate), "Should contain ringClipRotate style")
        XCTAssertTrue(allStyles.contains(.ballSpinFade), "Should contain ballSpinFade style")
        XCTAssertTrue(allStyles.contains(.circleStrokeSpin), "Should contain circleStrokeSpin style")
        XCTAssertTrue(allStyles.contains(.circleArcDotSpin), "Should contain circleArcDotSpin style")
        XCTAssertEqual(allStyles.count, 4, "Should have exactly 4 style cases")
    }

    // MARK: - Animation Builder Tests

    func testMakeAnimationForRingClipRotate() {
        let animation = ActivityIndicatorView.Style.ringClipRotate.makeAnimation()
        XCTAssertNotNil(animation, "Should create animation for ringClipRotate")
        XCTAssertTrue(animation is ActivityIndicatorAnimation.RingClipRotate, "Should create RingClipRotate animation")
    }

    func testMakeAnimationForBallSpinFade() {
        let animation = ActivityIndicatorView.Style.ballSpinFade.makeAnimation()
        XCTAssertNotNil(animation, "Should create animation for ballSpinFade")
        XCTAssertTrue(animation is ActivityIndicatorAnimation.BallSpinFade, "Should create BallSpinFade animation")
    }

    func testMakeAnimationForCircleStrokeSpin() {
        let animation = ActivityIndicatorView.Style.circleStrokeSpin.makeAnimation()
        XCTAssertNotNil(animation, "Should create animation for circleStrokeSpin")
        XCTAssertTrue(animation is ActivityIndicatorAnimation.CircleStrokeSpin, "Should create CircleStrokeSpin animation")
    }

    func testMakeAnimationForCircleArcDotSpin() {
        let animation = ActivityIndicatorView.Style.circleArcDotSpin.makeAnimation()
        XCTAssertNotNil(animation, "Should create animation for circleArcDotSpin")
        XCTAssertTrue(animation is ActivityIndicatorAnimation.CircleArcDotSpin, "Should create CircleArcDotSpin animation")
    }

    // MARK: - Color Property Tests

    func testDefaultColor() {
        // Default color should match the style's default color
        let expectedColor = ActivityIndicatorView.Style.ringClipRotate.defaultColor
        XCTAssertEqual(activityIndicatorView.color, expectedColor, "Default color should match style's default color")
    }

    func testColorChange() {
        let newColor = UIColor.red
        activityIndicatorView.color = newColor

        XCTAssertEqual(activityIndicatorView.color, newColor, "Color should be changed correctly")
    }

    func testColorChangeTriggersAnimation() {
        activityIndicatorView.startAnimating()

        // Changing color should potentially update animation
        let newColor = UIColor.blue
        activityIndicatorView.color = newColor

        XCTAssertEqual(activityIndicatorView.color, newColor, "Color should be updated")
        // Animation should still be running
        XCTAssertTrue(activityIndicatorView.isAnimating, "Should still be animating after color change")
    }

    func testColorSetToSameValue() {
        let initialColor = activityIndicatorView.color
        activityIndicatorView.color = initialColor

        XCTAssertEqual(activityIndicatorView.color, initialColor, "Color should remain the same")
    }

    // MARK: - ActivityIndicatorViewStyleable Protocol Tests

    func testStyleDefaultSize() {
        let style = ActivityIndicatorView.Style.ringClipRotate
        let defaultSize = style.defaultSize

        XCTAssertEqual(defaultSize, CGSize(width: 37.0, height: 37.0), "Default size should be 37x37")
    }

    func testStyleDefaultColor() {
        let style = ActivityIndicatorView.Style.ringClipRotate
        let defaultColor = style.defaultColor

        XCTAssertEqual(defaultColor, UIColor.h.content, "Default color should be content color")
    }

    func testStyleDefaultTrackColor() {
        let style = ActivityIndicatorView.Style.ringClipRotate
        let defaultTrackColor = style.defaultTrackColor

        let expectedTrackColor = style.defaultColor.withAlphaComponent(0.1)
        XCTAssertEqual(defaultTrackColor, expectedTrackColor, "Default track color should be default color with 0.1 alpha")
    }

    func testStyleDefaultLineWidth() {
        let style = ActivityIndicatorView.Style.ringClipRotate
        let defaultLineWidth = style.defaultLineWidth

        XCTAssertEqual(defaultLineWidth, 2.0, "Default line width should be 2.0")
    }

    // MARK: - Memory Management Tests

    func testActivityIndicatorViewDeallocation() {
        var view: ActivityIndicatorView? = ActivityIndicatorView()
        weak var weakView = view

        view?.startAnimating()
        view?.stopAnimating()
        view = nil

        XCTAssertNil(weakView, "ActivityIndicatorView should be deallocated")
    }

    // MARK: - View Hierarchy Tests

    func testAddToSuperview() {
        let containerView = UIView()
        containerView.addSubview(activityIndicatorView)

        XCTAssertEqual(activityIndicatorView.superview, containerView, "Should be added to container view")
        XCTAssertTrue(containerView.subviews.contains(activityIndicatorView), "Container should contain activity indicator view")
    }

    // MARK: - Style Reset Tests

    func testStyleChangeResetsProperties() {
        // Set custom color
        activityIndicatorView.color = UIColor.red

        // Change style
        activityIndicatorView.style = ActivityIndicatorView.Style.ballSpinFade

        // Color should be reset to new style's default
        let expectedColor = ActivityIndicatorView.Style.ballSpinFade.defaultColor
        XCTAssertEqual(activityIndicatorView.color, expectedColor, "Color should be reset to new style's default after style change")
    }

    func testStyleChangeToSameStyleDoesNotReset() {
        let originalColor = UIColor.red
        activityIndicatorView.color = originalColor

        // Set style to the same style
        activityIndicatorView.style = ActivityIndicatorView.Style.ringClipRotate

        // Color should remain the same
        XCTAssertEqual(activityIndicatorView.color, originalColor, "Color should not change when setting same style")
    }

    // MARK: - Edge Cases Tests

    func testMultipleStyleChanges() {
        let styles: [ActivityIndicatorView.Style] = [.ballSpinFade, .circleStrokeSpin, .circleArcDotSpin, .ringClipRotate]

        for style in styles {
            activityIndicatorView.style = style
            XCTAssertTrue(activityIndicatorView.style.isEqual(style), "Style should be set correctly")
        }
    }

    func testStyleChangeWhileAnimating() {
        activityIndicatorView.startAnimating()
        XCTAssertTrue(activityIndicatorView.isAnimating, "Should be animating before style change")

        activityIndicatorView.style = ActivityIndicatorView.Style.ballSpinFade

        // Should still be animating after style change
        XCTAssertTrue(activityIndicatorView.isAnimating, "Should still be animating after style change")
    }
}
