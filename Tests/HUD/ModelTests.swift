//
//  ModelTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class ModelTests: XCTestCase {

    // MARK: - HUD.Layout Tests

    func testLayoutDefaultInitialization() {
        let layout = HUD.Layout()

        XCTAssertEqual(layout.offset, .zero, "Default offset should be zero")
        XCTAssertEqual(layout.edgeInsets, UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0), "Default edge insets should be 20.0 for all sides")
        XCTAssertTrue(layout.isSafeAreaLayoutGuideEnabled, "Safe area layout guide should be enabled by default")
    }

    func testLayoutCustomInitialization() {
        let customOffset = CGPoint(x: 10.0, y: 20.0)
        let customEdgeInsets = UIEdgeInsets(top: 15.0, left: 10.0, bottom: 25.0, right: 30.0)
        let layout = HUD.Layout(offset: customOffset, edgeInsets: customEdgeInsets, isSafeAreaLayoutGuideEnabled: false)

        XCTAssertEqual(layout.offset, customOffset, "Custom offset should be set correctly")
        XCTAssertEqual(layout.edgeInsets, customEdgeInsets, "Custom edge insets should be set correctly")
        XCTAssertFalse(layout.isSafeAreaLayoutGuideEnabled, "Safe area layout guide should be disabled when set to false")
    }

    func testLayoutEquality() {
        let layout1 = HUD.Layout()
        let layout2 = HUD.Layout()
        let layout3 = HUD.Layout(offset: CGPoint(x: 10.0, y: 10.0))

        XCTAssertEqual(layout1, layout2, "Two default layouts should be equal")
        XCTAssertNotEqual(layout1, layout3, "Layouts with different offsets should not be equal")
    }

    func testLayoutMaxOffset() {
        let maxOffset = CGFloat.h.maxOffset
        let vMinOffset = CGPoint.h.vMinOffset
        let vMaxOffset = CGPoint.h.vMaxOffset

        XCTAssertEqual(maxOffset, 1000000.0, "Max offset should be 1000000.0")
        XCTAssertEqual(vMinOffset, CGPoint(x: 0.0, y: -maxOffset), "Vertical min offset should have negative max offset for y")
        XCTAssertEqual(vMaxOffset, CGPoint(x: 0.0, y: maxOffset), "Vertical max offset should have positive max offset for y")
    }

    // MARK: - HUD.Animation Tests

    func testAnimationDefaultInitialization() {
        let animation = HUD.Animation()

        // 验证默认值（需要查看Animation的默认实现）
        XCTAssertNotNil(animation, "Animation should be initialized successfully")
    }

    func testAnimationStyleCases() {
        let allStyles = HUD.Animation.Style.allCases

        XCTAssertTrue(allStyles.contains(.none), "Should contain none style")
        XCTAssertTrue(allStyles.contains(.fade), "Should contain fade style")
        XCTAssertTrue(allStyles.contains(.zoomInOut), "Should contain zoomInOut style")
        XCTAssertTrue(allStyles.contains(.zoomOutIn), "Should contain zoomOutIn style")
        XCTAssertTrue(allStyles.contains(.zoomIn), "Should contain zoomIn style")
        XCTAssertTrue(allStyles.contains(.zoomOut), "Should contain zoomOut style")
        XCTAssertTrue(allStyles.contains(.slideUpDown), "Should contain slideUpDown style")
        XCTAssertTrue(allStyles.contains(.slideDownUp), "Should contain slideDownUp style")
        XCTAssertTrue(allStyles.contains(.slideUp), "Should contain slideUp style")
        XCTAssertTrue(allStyles.contains(.slideDown), "Should contain slideDown style")
        XCTAssertTrue(allStyles.contains(.slideRightLeft), "Should contain slideRightLeft style")
        XCTAssertTrue(allStyles.contains(.slideLeftRight), "Should contain slideLeftRight style")
        XCTAssertTrue(allStyles.contains(.slideRight), "Should contain slideRight style")
        XCTAssertTrue(allStyles.contains(.slideLeft), "Should contain slideLeft style")
    }

    func testAnimationStyleCorrection() {
        // Test showing animations
        XCTAssertEqual(HUD.Animation.Style.zoomInOut.corrected(true), .zoomIn, "ZoomInOut should be corrected to zoomIn when showing")
        XCTAssertEqual(HUD.Animation.Style.zoomOutIn.corrected(true), .zoomOut, "ZoomOutIn should be corrected to zoomOut when showing")
        XCTAssertEqual(HUD.Animation.Style.slideUpDown.corrected(true), .slideUp, "SlideUpDown should be corrected to slideUp when showing")
        XCTAssertEqual(HUD.Animation.Style.slideDownUp.corrected(true), .slideDown, "SlideDownUp should be corrected to slideDown when showing")
        XCTAssertEqual(HUD.Animation.Style.slideRightLeft.corrected(true), .slideRight, "SlideRightLeft should be corrected to slideRight when showing")
        XCTAssertEqual(HUD.Animation.Style.slideLeftRight.corrected(true), .slideLeft, "SlideLeftRight should be corrected to slideLeft when showing")

        // Test hiding animations
        XCTAssertEqual(HUD.Animation.Style.zoomInOut.corrected(false), .zoomOut, "ZoomInOut should be corrected to zoomOut when hiding")
        XCTAssertEqual(HUD.Animation.Style.zoomOutIn.corrected(false), .zoomIn, "ZoomOutIn should be corrected to zoomIn when hiding")
        XCTAssertEqual(HUD.Animation.Style.slideUpDown.corrected(false), .slideDown, "SlideUpDown should be corrected to slideDown when hiding")
        XCTAssertEqual(HUD.Animation.Style.slideDownUp.corrected(false), .slideUp, "SlideDownUp should be corrected to slideUp when hiding")
        XCTAssertEqual(HUD.Animation.Style.slideRightLeft.corrected(false), .slideLeft, "SlideRightLeft should be corrected to slideLeft when hiding")
        XCTAssertEqual(HUD.Animation.Style.slideLeftRight.corrected(false), .slideRight, "SlideLeftRight should be corrected to slideRight when hiding")

        // Test non-correctable styles
        XCTAssertEqual(HUD.Animation.Style.none.corrected(true), .none, "None style should not be corrected")
        XCTAssertEqual(HUD.Animation.Style.fade.corrected(true), .fade, "Fade style should not be corrected")
        XCTAssertEqual(HUD.Animation.Style.zoomIn.corrected(true), .zoomIn, "ZoomIn style should not be corrected")
    }

    func testAnimationStyleReversed() {
        XCTAssertEqual(HUD.Animation.Style.zoomIn.reversed, .zoomOut, "ZoomIn reverse should be zoomOut")
        XCTAssertEqual(HUD.Animation.Style.zoomOut.reversed, .zoomIn, "ZoomOut reverse should be zoomIn")
        XCTAssertEqual(HUD.Animation.Style.slideUp.reversed, .slideDown, "SlideUp reverse should be slideDown")
        XCTAssertEqual(HUD.Animation.Style.slideDown.reversed, .slideUp, "SlideDown reverse should be slideUp")
        XCTAssertEqual(HUD.Animation.Style.slideRight.reversed, .slideLeft, "SlideRight reverse should be slideLeft")
        XCTAssertEqual(HUD.Animation.Style.slideLeft.reversed, .slideRight, "SlideLeft reverse should be slideRight")
        XCTAssertNil(HUD.Animation.Style.fade.reversed, "Fade should not have a reverse")
        XCTAssertNil(HUD.Animation.Style.none.reversed, "None should not have a reverse")
        XCTAssertNil(HUD.Animation.Style.zoomInOut.reversed, "Combined styles should not have a reverse")
        XCTAssertNil(HUD.Animation.Style.slideUpDown.reversed, "Combined styles should not have a reverse")
    }

    func testAnimationEquality() {
        let animation1 = HUD.Animation()
        let animation2 = HUD.Animation()

        XCTAssertEqual(animation1, animation2, "Two default animations should be equal")
    }

    func testAnimationCustomInitialization() {
        let animation = HUD.Animation(style: .zoomIn, damping: .ratio(0.8), duration: 0.5)

        XCTAssertEqual(animation.style, .zoomIn)
        XCTAssertEqual(animation.damping, .ratio(0.8))
        XCTAssertEqual(animation.duration, 0.5)
    }

    func testAnimationFactoryMethod() {
        let animation = HUD.Animation.animation(.slideUp, damping: .default, duration: 0.4)

        XCTAssertEqual(animation.style, .slideUp)
        XCTAssertEqual(animation.damping, .default)
        XCTAssertEqual(animation.duration, 0.4)
    }

    func testAnimationDefaultValues() {
        let animation = HUD.Animation()

        XCTAssertEqual(animation.style, .fade, "Default style should be fade")
        XCTAssertEqual(animation.damping, .disable, "Default damping should be disable")
        XCTAssertEqual(animation.duration, 0.3, "Default duration should be 0.3")
    }

    // MARK: - Animation.Damping Tests

    func testDampingDisable() {
        let damping = HUD.Animation.Damping.disable
        XCTAssertEqual(damping.value, 1.0, "Disable damping should have value 1.0")
    }

    func testDampingDefault() {
        let damping = HUD.Animation.Damping.default
        XCTAssertEqual(damping.value, 0.65, "Default damping should have value 0.65")
    }

    func testDampingCustomRatio() {
        let damping = HUD.Animation.Damping.ratio(0.8)
        XCTAssertEqual(damping.value, 0.8, "Custom ratio damping should return provided value")
    }

    func testDampingEquality() {
        XCTAssertEqual(HUD.Animation.Damping.disable, HUD.Animation.Damping.disable)
        XCTAssertEqual(HUD.Animation.Damping.default, HUD.Animation.Damping.default)
        XCTAssertEqual(HUD.Animation.Damping.ratio(0.5), HUD.Animation.Damping.ratio(0.5))
        XCTAssertNotEqual(HUD.Animation.Damping.disable, HUD.Animation.Damping.default)
        XCTAssertNotEqual(HUD.Animation.Damping.ratio(0.5), HUD.Animation.Damping.ratio(0.8))
    }

    // MARK: - Animation.Style AllCases Tests

    func testAnimationStyleAllCasesCount() {
        XCTAssertEqual(HUD.Animation.Style.allCases.count, 14, "Should have 14 animation styles")
    }

    #if os(iOS)
    // MARK: - KeyboardGuide Tests

    func testKeyboardGuideDisable() {
        let guide = HUD.KeyboardGuide.disable
        XCTAssertEqual(guide, .disable)
    }

    func testKeyboardGuideCenterDefault() {
        let guide = HUD.KeyboardGuide.center()
        XCTAssertEqual(guide, .center(0.0), "Default center offset should be 0.0")
    }

    func testKeyboardGuideCenterWithOffset() {
        let guide = HUD.KeyboardGuide.center(10.0)
        XCTAssertEqual(guide, .center(10.0))
        XCTAssertNotEqual(guide, .center(0.0))
    }

    func testKeyboardGuideBottomDefault() {
        let guide = HUD.KeyboardGuide.bottom()
        XCTAssertEqual(guide, .bottom(8.0), "Default bottom spacing should be 8.0")
    }

    func testKeyboardGuideBottomWithSpacing() {
        let guide = HUD.KeyboardGuide.bottom(16.0)
        XCTAssertEqual(guide, .bottom(16.0))
        XCTAssertNotEqual(guide, .bottom(8.0))
    }

    func testKeyboardGuideEquality() {
        XCTAssertEqual(HUD.KeyboardGuide.disable, HUD.KeyboardGuide.disable)
        XCTAssertEqual(HUD.KeyboardGuide.center(5.0), HUD.KeyboardGuide.center(5.0))
        XCTAssertEqual(HUD.KeyboardGuide.bottom(10.0), HUD.KeyboardGuide.bottom(10.0))
        XCTAssertNotEqual(HUD.KeyboardGuide.disable, HUD.KeyboardGuide.center())
        XCTAssertNotEqual(HUD.KeyboardGuide.center(), HUD.KeyboardGuide.bottom())
    }
    #endif
}
