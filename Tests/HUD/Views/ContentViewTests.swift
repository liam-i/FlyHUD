//
//  ContentViewTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

@MainActor
final class ContentViewTests: XCTestCase {

    var contentView: ContentView!

    override func setUp() async throws {
        contentView = ContentView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    }

    override func tearDown() async throws {
        contentView = nil
    }

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        XCTAssertNotNil(contentView.label, "Label should be initialized")
        XCTAssertNotNil(contentView.detailsLabel, "Details label should be initialized")
        XCTAssertNotNil(contentView.button, "Button should be initialized")
        XCTAssertTrue(contentView.clipsToBounds, "Content view should clip to bounds")
        XCTAssertTrue(contentView.isHidden, "Content view should be hidden initially")
    }

    func testDefaultMode() {
        XCTAssertTrue(contentView.mode.isIndicator, "Default mode should be indicator")
    }

    func testDefaultLayout() {
        let layout = contentView.layout
        XCTAssertEqual(layout.hMargin, 20.0, "Default horizontal margin should be 20")
        XCTAssertEqual(layout.vMargin, 20.0, "Default vertical margin should be 20")
        XCTAssertEqual(layout.hSpacing, 8.0, "Default horizontal spacing should be 8")
        XCTAssertEqual(layout.vSpacing, 4.0, "Default vertical spacing should be 4")
        XCTAssertEqual(layout.alignment, .center, "Default alignment should be center")
        XCTAssertEqual(layout.minSize, .zero, "Default min size should be zero")
        XCTAssertFalse(layout.isSquare, "Default isSquare should be false")
    }

    // MARK: - Mode Tests

    func testModeText() {
        contentView.mode = .text

        XCTAssertTrue(contentView.mode.isText, "Mode should be text")
        XCTAssertFalse(contentView.mode.isIndicator, "Text mode should not be indicator")
        XCTAssertFalse(contentView.mode.isProgress, "Text mode should not be progress")
        XCTAssertFalse(contentView.mode.isCustom, "Text mode should not be custom")
    }

    func testModeIndicator() {
        contentView.mode = .indicator(.large)

        XCTAssertTrue(contentView.mode.isIndicator, "Mode should be indicator")
        XCTAssertFalse(contentView.mode.isText, "Indicator mode should not be text")
        XCTAssertFalse(contentView.mode.isProgress, "Indicator mode should not be progress")
    }

    func testModeProgress() {
        contentView.mode = .progress(.default)

        XCTAssertTrue(contentView.mode.isProgress, "Mode should be progress")
        XCTAssertFalse(contentView.mode.isText, "Progress mode should not be text")
        XCTAssertFalse(contentView.mode.isIndicator, "Progress mode should not be indicator")
    }

    func testModeCustomWithIndicatorViewable() {
        let indicator = ActivityIndicatorView(style: .ballSpinFade)
        contentView.mode = .custom(indicator)

        XCTAssertTrue(contentView.mode.isIndicator, "Custom ActivityIndicatorViewable should be indicator")
        XCTAssertFalse(contentView.mode.isProgress, "Custom ActivityIndicatorViewable should not be progress")
    }

    func testModeCustomWithProgressViewable() {
        let progressView = FlyProgressHUD.ProgressView(style: .round)
        contentView.mode = .custom(progressView)

        XCTAssertTrue(contentView.mode.isProgress, "Custom ProgressViewable should be progress")
        XCTAssertFalse(contentView.mode.isIndicator, "Custom ProgressViewable should not be indicator")
    }

    func testModeCustomWithPlainView() {
        let view = UIImageView(image: UIImage(systemName: "checkmark"))
        contentView.mode = .custom(view)

        XCTAssertTrue(contentView.mode.isCustom, "Custom plain view should be custom")
        XCTAssertFalse(contentView.mode.isIndicator, "Custom plain view should not be indicator")
        XCTAssertFalse(contentView.mode.isProgress, "Custom plain view should not be progress")
        XCTAssertFalse(contentView.mode.isText, "Custom plain view should not be text")
    }

    func testModeSwitching() {
        contentView.mode = .indicator()
        XCTAssertTrue(contentView.mode.isIndicator)

        contentView.mode = .progress()
        XCTAssertTrue(contentView.mode.isProgress)

        contentView.mode = .text
        XCTAssertTrue(contentView.mode.isText)

        let customView = UIView()
        contentView.mode = .custom(customView)
        XCTAssertTrue(contentView.mode.isCustom)
    }

    // MARK: - Mode Equality Tests

    func testModeEquality() {
        XCTAssertEqual(ContentView.Mode.text, ContentView.Mode.text)
        XCTAssertEqual(ContentView.Mode.indicator(.large), ContentView.Mode.indicator(.large))
        XCTAssertNotEqual(ContentView.Mode.indicator(.large), ContentView.Mode.indicator(.medium))
        XCTAssertEqual(ContentView.Mode.progress(.default), ContentView.Mode.progress(.default))
        XCTAssertNotEqual(ContentView.Mode.text, ContentView.Mode.indicator())
    }

    func testModeCustomEquality() {
        let view1 = UIView()
        let view2 = UIView()
        XCTAssertEqual(ContentView.Mode.custom(view1), ContentView.Mode.custom(view1))
        XCTAssertNotEqual(ContentView.Mode.custom(view1), ContentView.Mode.custom(view2))
    }

    // MARK: - IndicatorPosition Tests

    func testIndicatorPositionCases() {
        let allCases = ContentView.IndicatorPosition.allCases
        XCTAssertEqual(allCases.count, 4, "Should have 4 indicator positions")
        XCTAssertTrue(allCases.contains(.top))
        XCTAssertTrue(allCases.contains(.bottom))
        XCTAssertTrue(allCases.contains(.leading))
        XCTAssertTrue(allCases.contains(.trailing))
    }

    func testIndicatorPositionDefault() {
        XCTAssertEqual(contentView.indicatorPosition, .top, "Default indicator position should be top")
    }

    func testIndicatorPositionChange() {
        contentView.indicatorPosition = .bottom
        XCTAssertEqual(contentView.indicatorPosition, .bottom)

        contentView.indicatorPosition = .leading
        XCTAssertEqual(contentView.indicatorPosition, .leading)

        contentView.indicatorPosition = .trailing
        XCTAssertEqual(contentView.indicatorPosition, .trailing)
    }

    // MARK: - Alignment Tests

    func testAlignmentCases() {
        let allCases = ContentView.Alignment.allCases
        XCTAssertEqual(allCases.count, 3, "Should have 3 alignment options")
        XCTAssertTrue(allCases.contains(.center))
        XCTAssertTrue(allCases.contains(.leading))
        XCTAssertTrue(allCases.contains(.trailing))
    }

    // MARK: - Layout Tests

    func testLayoutCustomValues() {
        let layout = ContentView.Layout(
            hMargin: 30.0,
            vMargin: 15.0,
            hSpacing: 12.0,
            vSpacing: 8.0,
            alignment: .leading,
            minSize: CGSize(width: 100, height: 100),
            isSquare: true
        )

        XCTAssertEqual(layout.hMargin, 30.0)
        XCTAssertEqual(layout.vMargin, 15.0)
        XCTAssertEqual(layout.hSpacing, 12.0)
        XCTAssertEqual(layout.vSpacing, 8.0)
        XCTAssertEqual(layout.alignment, .leading)
        XCTAssertEqual(layout.minSize, CGSize(width: 100, height: 100))
        XCTAssertTrue(layout.isSquare)
    }

    func testLayoutEquality() {
        let layout1 = ContentView.Layout()
        let layout2 = ContentView.Layout()
        let layout3 = ContentView.Layout(hMargin: 10)

        XCTAssertEqual(layout1, layout2)
        XCTAssertNotEqual(layout1, layout3)
    }

    func testLayoutUpdate() {
        contentView.layout = ContentView.Layout(hMargin: 50, vMargin: 50)
        XCTAssertEqual(contentView.layout.hMargin, 50.0)
        XCTAssertEqual(contentView.layout.vMargin, 50.0)
    }

    // MARK: - ContentColor Tests

    func testDefaultContentColor() {
        XCTAssertNotNil(contentView.contentColor, "Default content color should not be nil")
    }

    func testContentColorUpdate() {
        contentView.contentColor = .red
        XCTAssertEqual(contentView.contentColor, .red)
    }

    func testContentColorNil() {
        contentView.contentColor = nil
        XCTAssertNil(contentView.contentColor)
    }

    // MARK: - Progress Tests

    func testDefaultProgress() {
        XCTAssertEqual(contentView.progress, 0.0, "Default progress should be 0.0")
    }

    func testProgressUpdate() {
        contentView.mode = .progress()
        contentView.progress = 0.5
        XCTAssertEqual(contentView.progress, 0.5)
    }

    func testProgressBoundaryValues() {
        contentView.mode = .progress()
        contentView.progress = 0.0
        XCTAssertEqual(contentView.progress, 0.0)

        contentView.progress = 1.0
        XCTAssertEqual(contentView.progress, 1.0)
    }

    // MARK: - DynamicType Tests

    func testDefaultDynamicType() {
        XCTAssertFalse(contentView.isDynamicTypeEnabled, "Dynamic type should be disabled by default")
    }

    func testEnableDynamicType() {
        contentView.isDynamicTypeEnabled = true
        XCTAssertTrue(contentView.isDynamicTypeEnabled)
    }

    // MARK: - MotionEffects Tests

    func testDefaultMotionEffects() {
        XCTAssertFalse(contentView.isMotionEffectsEnabled, "Motion effects should be disabled by default")
    }

    func testEnableMotionEffects() {
        contentView.isMotionEffectsEnabled = true
        XCTAssertTrue(contentView.isMotionEffectsEnabled)
    }

    // MARK: - Label Tests

    func testLabelProperties() {
        let label = contentView.label
        XCTAssertEqual(label.numberOfLines, 1, "Label should have 1 line")
        XCTAssertEqual(label.textAlignment, .center, "Label alignment should be center")
    }

    func testDetailsLabelProperties() {
        let detailsLabel = contentView.detailsLabel
        XCTAssertEqual(detailsLabel.numberOfLines, 0, "Details label should have unlimited lines")
        XCTAssertEqual(detailsLabel.textAlignment, .center, "Details label alignment should be center")
    }

    // MARK: - Style Tests

    func testDefaultStyle() {
        // ContentView defaults to blur style
        if case .blur = contentView.style {
            XCTAssertTrue(true)
        } else {
            XCTFail("Default style should be blur")
        }
    }

    func testStyleSolidColor() {
        contentView.style = .solidColor
        if case .solidColor = contentView.style {
            XCTAssertTrue(true)
        } else {
            XCTFail("Style should be solidColor")
        }
    }

    // MARK: - ObservedProgress Tests

    func testObservedProgressDefault() {
        XCTAssertNil(contentView.observedProgress, "Default observed progress should be nil")
    }

    func testObservedProgressSet() {
        contentView.mode = .progress()
        let progress = Progress(totalUnitCount: 100)
        contentView.observedProgress = progress
        XCTAssertNotNil(contentView.observedProgress)
    }

    func testObservedProgressClear() {
        contentView.mode = .progress()
        let progress = Progress(totalUnitCount: 100)
        contentView.observedProgress = progress
        contentView.observedProgress = nil
        XCTAssertNil(contentView.observedProgress)
    }

    // MARK: - Performance Tests

    func testModeSwitchPerformance() {
        measure {
            for _ in 0..<100 {
                contentView.mode = .indicator()
                contentView.mode = .text
                contentView.mode = .progress()
                contentView.mode = .text
            }
        }
    }
}
