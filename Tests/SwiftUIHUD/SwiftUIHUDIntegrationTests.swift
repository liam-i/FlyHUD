//
//  SwiftUIHUDIntegrationTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
import SwiftUI
@testable import FlyHUD
@testable import FlyHUDSwiftUI
import FlyIndicatorHUD
import FlyProgressHUD

/// Integration tests verifying FlyIndicatorHUD and FlyProgressHUD work correctly
/// through the SwiftUI HUD modifiers.
@MainActor
final class SwiftUIHUDIntegrationTests: XCTestCase {

    var window: UIWindow!

    override func setUp() async throws {
        try await super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.makeKeyAndVisible()
    }

    override func tearDown() async throws {
        HUD.hideAll(for: window, animated: false)
        window = nil
        try await super.tearDown()
    }

    // MARK: - J1: ActivityIndicatorView via .custom()

    func testIndicator_customStyle_showsViaCoordinator() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator(.ballSpinFade)
            hud.contentView.label.text = "Loading"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Loading")
        // Verify it's an ActivityIndicatorView
        if case .custom(let view) = hud?.contentView.mode {
            XCTAssertTrue(view is ActivityIndicatorView)
        } else {
            XCTFail("Expected custom mode with ActivityIndicatorView")
        }
        coordinator.cleanup()
    }

    func testIndicator_builtInStyles_allWork() {
        let styles: [ActivityIndicatorView.Style] = [
            .ringClipRotate, .ballSpinFade,
            .circleStrokeSpin, .circleArcDotSpin
        ]

        for style in styles {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .indicator(style)
            }
            coordinator.updatePresentation()

            let hud = window.subviews.compactMap { $0 as? HUD }.first
            XCTAssertNotNil(hud, "HUD should exist for style: \(style)")
            coordinator.cleanup()
        }
    }

    func testIndicator_switchStyleWhileShowing() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator(.ringClipRotate)
        }
        coordinator.updatePresentation()

        // Switch style via configuration update
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator(.ballSpinFade)
            hud.contentView.label.text = "Changed"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Changed")
        if case .custom(let view) = hud?.contentView.mode {
            XCTAssertTrue(view is ActivityIndicatorView)
        }
        coordinator.cleanup()
    }

    // MARK: - J2: ProgressView via .custom()

    func testProgress_barStyle_showsViaCoordinator() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.3
        coordinator.label = "Uploading"
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.3, accuracy: 0.001)
        coordinator.cleanup()
    }

    func testProgress_customStyle_ring() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .progress(.annularRound)
            hud.contentView.label.text = "Ring Progress"
            hud.contentView.progress = 0.6
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.6, accuracy: 0.001)
        XCTAssertEqual(hud?.contentView.label.text, "Ring Progress")
        if case .custom(let view) = hud?.contentView.mode {
            XCTAssertTrue(view is FlyProgressHUD.ProgressView)
        } else {
            XCTFail("Expected custom mode with ProgressView")
        }
        coordinator.cleanup()
    }

    func testProgress_pieStyle() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .progress(.pie)
            hud.contentView.progress = 0.75
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.75, accuracy: 0.001)
        coordinator.cleanup()
    }

    func testProgress_updatesViaProgressCoordinator() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.label = "0%"
        coordinator.updatePresentation()

        // Simulate progress updates
        for i in stride(from: 0, through: 10, by: 1) {
            coordinator.progress = Float(i) / 10.0
            coordinator.label = "\(i * 10)%"
            coordinator.updatePresentation()
        }

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 1.0, accuracy: 0.001)
        XCTAssertEqual(hud?.contentView.label.text, "100%")
        coordinator.cleanup()
    }

    // MARK: - J3: Mixed Indicator + Progress workflow

    func testMixedWorkflow_indicatorThenProgress() {
        // Start with indicator
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator(.ringClipRotate)
            hud.contentView.label.text = "Connecting..."
        }
        coordinator.updatePresentation()

        // Switch to progress
        coordinator.configuration = { hud in
            hud.contentView.mode = .progress(.roundBar)
            hud.contentView.label.text = "Downloading..."
            hud.contentView.progress = 0.5
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Downloading...")
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.5, accuracy: 0.001)
        coordinator.cleanup()
    }

    // MARK: - J4: Item coordinator with different modes

    func testItemCoordinator_indicatorAndProgressItems() {
        struct HUDItem: Identifiable {
            let id: String
            let mode: ContentView.Mode
            let label: String
        }

        let coordinator = HUDItemCoordinator<HUDItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = item.mode
            hud.contentView.label.text = item.label
        }

        // Show indicator item
        coordinator.currentItem = HUDItem(id: "1", mode: .indicator(.ballSpinFade), label: "Loading")
        coordinator.updatePresentation()

        var hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Loading")

        // Switch to progress item
        coordinator.currentItem = HUDItem(id: "2", mode: .progress(.annularRound), label: "Downloading")
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Downloading")
        coordinator.cleanup()
    }

    // MARK: - J5: Custom UIView via .custom() mode

    func testCustomUIView_imageView() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
            hud.contentView.mode = .custom(imageView)
            hud.contentView.label.text = "Done"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Done")
        if case .custom(let view) = hud?.contentView.mode {
            XCTAssertTrue(view is UIImageView)
        } else {
            XCTFail("Expected custom mode with UIImageView")
        }
        coordinator.cleanup()
    }
}
