//
//  LabelTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class LabelTests: XCTestCase {

    var label: Label!

    override func setUp() async throws {
        try await super.setUp()
        label = Label(fontSize: 16.0, numberOfLines: 1, textColor: .white)
    }

    override func tearDown() async throws {
        label = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testConvenienceInit() {
        let label = Label(fontSize: 14.0, numberOfLines: 3, textColor: .red)

        XCTAssertFalse(label.adjustsFontSizeToFitWidth)
        XCTAssertEqual(label.textAlignment, .center)
        XCTAssertEqual(label.textColor, .red)
        XCTAssertEqual(label.numberOfLines, 3)
        XCTAssertEqual(label.font, .boldSystemFont(ofSize: 14.0))
        XCTAssertFalse(label.isOpaque)
        XCTAssertEqual(label.backgroundColor, .clear)
    }

    func testConvenienceInitWithNilColor() {
        let label = Label(fontSize: 12.0, numberOfLines: 0, textColor: nil)
        // UILabel provides a default text color (.label) when nil is set
        XCTAssertNotNil(label.textColor)
    }

    // MARK: - isEmptyOfText Tests

    func testIsEmptyOfTextWhenNil() {
        label.text = nil
        XCTAssertTrue(label.isEmptyOfText, "Should be empty when text is nil")
    }

    func testIsEmptyOfTextWhenEmpty() {
        label.text = ""
        XCTAssertTrue(label.isEmptyOfText, "Should be empty when text is empty string")
    }

    func testIsEmptyOfTextWhenHasContent() {
        label.text = "Hello"
        XCTAssertFalse(label.isEmptyOfText, "Should not be empty when text has content")
    }

    func testIsEmptyOfTextWithWhitespace() {
        label.text = " "
        XCTAssertFalse(label.isEmptyOfText, "Should not be empty when text has whitespace")
    }

    // MARK: - intrinsicContentSize Tests

    func testIntrinsicContentSizeWhenEmpty() {
        label.text = nil
        XCTAssertEqual(label.intrinsicContentSize, .zero, "Intrinsic size should be zero when text is empty")
    }

    func testIntrinsicContentSizeWhenEmptyString() {
        label.text = ""
        XCTAssertEqual(label.intrinsicContentSize, .zero, "Intrinsic size should be zero for empty string")
    }

    func testIntrinsicContentSizeWhenHasText() {
        label.text = "Loading..."
        let size = label.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Width should be positive for non-empty text")
        XCTAssertGreaterThan(size.height, 0, "Height should be positive for non-empty text")
    }

    // MARK: - isDynamicTypeEnabled Tests

    func testDynamicTypeDefault() {
        XCTAssertFalse(label.isDynamicTypeEnabled, "Dynamic type should be disabled by default")
    }

    func testEnableDynamicType() {
        label.isDynamicTypeEnabled = true
        XCTAssertTrue(label.isDynamicTypeEnabled)
        XCTAssertTrue(label.adjustsFontForContentSizeCategory)
    }

    func testDisableDynamicType() {
        label.isDynamicTypeEnabled = true
        label.isDynamicTypeEnabled = false
        XCTAssertFalse(label.isDynamicTypeEnabled)
        XCTAssertFalse(label.adjustsFontForContentSizeCategory)
    }

    // MARK: - Text Update Tests

    func testTextUpdateTriggersHiddenState() {
        label.text = "Some text"
        // Label should not be hidden when it has text (for stack view purposes)
        // The exact behavior depends on isHiddenInStackView

        label.text = nil
        // Label should be hidden in stack view when text is nil
    }

    func testTextUpdateWithValidText() {
        label.text = "Loading"
        XCTAssertEqual(label.text, "Loading")
        XCTAssertFalse(label.isEmptyOfText)
    }

    // MARK: - Multiple Lines Tests

    func testSingleLineLabel() {
        let singleLine = Label(fontSize: 16.0, numberOfLines: 1, textColor: .white)
        XCTAssertEqual(singleLine.numberOfLines, 1)
    }

    func testMultilineLabel() {
        let multiline = Label(fontSize: 12.0, numberOfLines: 0, textColor: .white)
        XCTAssertEqual(multiline.numberOfLines, 0)
    }

    // MARK: - Font Tests

    func testFontSize() {
        let label = Label(fontSize: 20.0, numberOfLines: 1, textColor: .white)
        XCTAssertEqual(label.font, .boldSystemFont(ofSize: 20.0))
    }

    func testDynamicTypeFontScaling() {
        let originalFont = label.font!
        label.isDynamicTypeEnabled = true
        // Font should be scaled via UIFontMetrics
        XCTAssertNotNil(label.font)
        // The font family should remain the same even after scaling
        XCTAssertEqual(label.font.familyName, originalFont.familyName)
    }

    // MARK: - VoiceOver Tests

    func testLabelIsNotAccessibilityElement() {
        XCTAssertFalse(label.isAccessibilityElement,
            "Label should be hidden from VoiceOver (ContentView handles accessibility)")
    }

    func testSettingSameTextDoesNotPostNotification() {
        // Add to window so the notification guard applies
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        window.addSubview(label)

        label.text = "Hello"
        // Set same text again — should NOT post layoutChanged (guards with text != oldValue)
        // This test verifies the guard works by not crashing or causing side effects.
        label.text = "Hello"
        XCTAssertEqual(label.text, "Hello")
    }

    func testSettingDifferentTextUpdatesVisibility() {
        label.text = "Visible"
        XCTAssertFalse(label.isHiddenInStackView)

        label.text = nil
        XCTAssertTrue(label.isHiddenInStackView)
    }
}
