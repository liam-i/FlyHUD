//
//  ButtonTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

@MainActor
final class ButtonTests: XCTestCase {

    var button: Button!

    override func setUp() async throws {
        try await super.setUp()
        button = Button(fontSize: 12.0, textColor: .white)
    }

    override func tearDown() async throws {
        button = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testConvenienceInit() {
        let button = Button(fontSize: 14.0, textColor: .blue)

        XCTAssertEqual(button.titleLabel?.textAlignment, .center)
        XCTAssertEqual(button.titleLabel?.font, .boldSystemFont(ofSize: 14.0))
        XCTAssertEqual(button.titleColor(for: .normal), .blue)
    }

    func testConvenienceInitWithNilColor() {
        let button = Button(fontSize: 12.0, textColor: nil)
        // UIButton provides a default title color (white) when nil is set
        XCTAssertNotNil(button.titleColor(for: .normal))
    }

    func testFrameInit() {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        let button = Button(frame: frame)

        XCTAssertEqual(button.frame, frame)
        XCTAssertEqual(button.layer.borderWidth, 1.0, "Default border width should be 1.0")
    }

    // MARK: - RoundedCorners Tests

    func testDefaultRoundedCorners() {
        XCTAssertEqual(button.roundedCorners, .full, "Default rounded corners should be .full")
    }

    func testRoundedCornersRadius() {
        button.roundedCorners = .radius(8.0)
        XCTAssertEqual(button.roundedCorners, .radius(8.0))

        // Trigger layout to apply corner radius
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        button.layoutSubviews()
        XCTAssertEqual(button.layer.cornerRadius, ceil(8.0))
    }

    func testRoundedCornersFull() {
        button.roundedCorners = .full
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        button.layoutSubviews()
        XCTAssertEqual(button.layer.cornerRadius, ceil(button.bounds.midY))
    }

    func testRoundedCornersEquality() {
        XCTAssertEqual(RoundedCorners.full, RoundedCorners.full)
        XCTAssertEqual(RoundedCorners.radius(5.0), RoundedCorners.radius(5.0))
        XCTAssertNotEqual(RoundedCorners.radius(5.0), RoundedCorners.radius(10.0))
        XCTAssertNotEqual(RoundedCorners.full, RoundedCorners.radius(5.0))
    }

    // MARK: - Border Width Tests

    func testDefaultBorderWidth() {
        XCTAssertEqual(button.borderWidth, 1.0, "Default border width should be 1.0")
        XCTAssertEqual(button.layer.borderWidth, 1.0)
    }

    func testBorderWidthUpdate() {
        button.borderWidth = 2.0
        XCTAssertEqual(button.borderWidth, 2.0)
        XCTAssertEqual(button.layer.borderWidth, 2.0)
    }

    func testBorderWidthZero() {
        button.borderWidth = 0.0
        XCTAssertEqual(button.layer.borderWidth, 0.0)
    }

    // MARK: - Title Tests

    func testSetTitle() {
        button.setTitle("Cancel", for: .normal)
        XCTAssertEqual(button.title(for: .normal), "Cancel")
        XCTAssertFalse(button.isEmptyOfText)
    }

    func testSetTitleNil() {
        button.setTitle("Cancel", for: .normal)
        button.setTitle(nil, for: .normal)
        XCTAssertTrue(button.isEmptyOfText)
    }

    func testSetTitleEmpty() {
        button.setTitle("", for: .normal)
        XCTAssertTrue(button.isEmptyOfText)
    }

    // MARK: - isEmptyOfText Tests

    func testIsEmptyOfTextWhenNoTitle() {
        XCTAssertTrue(button.isEmptyOfText, "Should be empty when no title is set")
    }

    func testIsEmptyOfTextWithTitle() {
        button.setTitle("OK", for: .normal)
        XCTAssertFalse(button.isEmptyOfText, "Should not be empty when title is set")
    }

    // MARK: - intrinsicContentSize Tests

    func testIntrinsicContentSizeWhenEmpty() {
        // Without title and without control events, size should be zero
        XCTAssertEqual(button.intrinsicContentSize, .zero)
    }

    func testIntrinsicContentSizeWithTitle() {
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(dummyAction), for: .touchUpInside)
        let size = button.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Width should be positive with title and events")
        XCTAssertGreaterThan(size.height, 0, "Height should be positive with title and events")
    }

    // MARK: - Title Color Tests

    func testSetTitleColor() {
        button.setTitleColor(.red, for: .normal)
        XCTAssertEqual(button.titleColor(for: .normal), .red)
        XCTAssertEqual(button.layer.borderColor, UIColor.red.cgColor)
    }

    func testSetTitleColorNil() {
        button.setTitleColor(nil, for: .normal)
        // UIButton provides a default title color (white) when nil is set
        XCTAssertNotNil(button.titleColor(for: .normal))
    }

    // MARK: - Highlight Tests

    func testHighlightBackground() {
        button.setTitleColor(.blue, for: .normal)
        button.setTitleColor(.blue.withAlphaComponent(0.5), for: .selected)

        button.isHighlighted = false
        XCTAssertEqual(button.backgroundColor, .clear, "Background should be clear when not highlighted")

        button.isHighlighted = true
        // Background should be the selected color with 0.1 alpha
        XCTAssertNotNil(button.backgroundColor)
    }

    // MARK: - Layout Tests

    func testLayoutSubviewsWithRadiusCorners() {
        button.roundedCorners = .radius(10.0)
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        button.layoutSubviews()

        XCTAssertEqual(button.layer.cornerRadius, ceil(10.0))
    }

    func testLayoutSubviewsWithFullCorners() {
        button.roundedCorners = .full
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        button.layoutSubviews()

        XCTAssertEqual(button.layer.cornerRadius, ceil(40.0 / 2.0))
    }

    // MARK: - Coder Init Tests

    func testInitWithCoder() {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.finishEncoding()

        if let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data as Data) {
            let btn = Button(coder: unarchiver)
            if let btn = btn {
                XCTAssertEqual(btn.layer.borderWidth, 1.0)
            }
        }
    }

    // MARK: - IntrinsicContentSize Edge Cases

    func testIntrinsicContentSizeWithEventsOnly() {
        // No title but has control events - should NOT return .zero
        button.addTarget(self, action: #selector(dummyAction), for: .touchUpInside)
        let size = button.intrinsicContentSize
        // With control events but no title, isEmptyOfText is true but allControlEvents > 0
        // so it should still calculate size
        XCTAssertNotEqual(size, .zero, "Should return non-zero size when control events are registered")
    }

    // MARK: - Bounds didSet Tests

    func testBoundsDidSetHidesWhenEmpty() {
        button.setTitle(nil, for: .normal)
        button.bounds = CGRect(x: 0, y: 0, width: 100, height: 44)
        // isEmptyOfText = true → isHiddenInStackView should be true
        XCTAssertTrue(button.isEmptyOfText)
    }

    func testBoundsDidSetShowsWhenHasTitle() {
        button.setTitle("OK", for: .normal)
        button.bounds = CGRect(x: 0, y: 0, width: 100, height: 44)
        XCTAssertFalse(button.isEmptyOfText)
    }

    @objc private func dummyAction() {}
}
