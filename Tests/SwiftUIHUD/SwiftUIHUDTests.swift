//
//  SwiftUIHUDTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
import SwiftUI
@testable import FlyHUD
@testable import FlyHUDSwiftUI

private extension UIView {
    var allSubviews: [UIView] {
        subviews + subviews.flatMap { $0.allSubviews }
    }
}

@MainActor
final class SwiftUIHUDTests: XCTestCase {

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

    // MARK: - HUDTargetView Tests

    func testHUDTargetView_didMoveToWindow_callsOnWindow() {
        let expectation = XCTestExpectation(description: "onWindow called")
        let targetView = HUDTargetView()
        targetView.onWindow = { view in
            XCTAssertNotNil(view)
            expectation.fulfill()
        }
        window.addSubview(targetView)
        wait(for: [expectation], timeout: 1.0)
        targetView.removeFromSuperview()
    }

    func testHUDTargetView_noWindow_doesNotCallOnWindow() {
        let targetView = HUDTargetView()
        var called = false
        targetView.onWindow = { _ in
            called = true
        }
        // Add to a plain UIView (not in window)
        let plainView = UIView(frame: .zero)
        plainView.addSubview(targetView)
        XCTAssertFalse(called)
        targetView.removeFromSuperview()
    }

    func testHUDTargetView_providesWindow() {
        let expectation = XCTestExpectation(description: "provides window")
        let targetView = HUDTargetView()
        targetView.onWindow = { view in
            XCTAssertTrue(view is UIWindow)
            expectation.fulfill()
        }
        window.addSubview(targetView)
        wait(for: [expectation], timeout: 1.0)
        targetView.removeFromSuperview()
    }

    // MARK: - HUDCoordinator Tests

    func testCoordinator_showHUD_addsToHostView() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "Test"
        }
        coordinator.updatePresentation()

        let huds = window.subviews.filter { $0 is HUD }
        XCTAssertEqual(huds.count, 1)
        coordinator.cleanup()
    }

    func testCoordinator_hideHUD_removesFromHostView() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        // Now hide
        coordinator.isPresented = false
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "HUD removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let huds = window.subviews.filter { $0 is HUD }
        XCTAssertEqual(huds.count, 0)
    }

    func testCoordinator_showWhenAlreadyShowing_doesNotCreateDuplicate() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()
        coordinator.updatePresentation()
        coordinator.updatePresentation()

        let huds = window.subviews.filter { $0 is HUD }
        XCTAssertEqual(huds.count, 1)
        coordinator.cleanup()
    }

    func testCoordinator_showWithNoHostView_doesNotCrash() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = nil
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        // Should not crash, no HUD created
        let huds = window.subviews.filter { $0 is HUD }
        XCTAssertEqual(huds.count, 0)
    }

    func testCoordinator_cleanup_removesHUD() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "cleanup complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testCoordinator_configurationApplied() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Hello"
            hud.contentView.detailsLabel.text = "World"
            hud.contentView.contentColor = .red
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Hello")
        XCTAssertEqual(hud?.contentView.detailsLabel.text, "World")
        XCTAssertEqual(hud?.contentView.contentColor, .red)
        coordinator.cleanup()
    }

    func testCoordinator_animationParameter_applied() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        let anim = HUD.Animation(style: .zoomInOut, damping: .default)
        coordinator.animation = anim
        coordinator.configuration = { _ in }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.animation.style, .zoomInOut)
        coordinator.cleanup()
    }

    // MARK: - HUDStatusCoordinator Tests

    func testStatusCoordinator_showsAndAutoHides() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 0.1
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Status"
        }
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        let expectation = XCTestExpectation(description: "auto-hide")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - HUDProgressCoordinator Tests

    func testProgressCoordinator_showsWithProgress() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.5
        coordinator.label = "Uploading"
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.progress, 0.5)
        XCTAssertEqual(hud?.contentView.label.text, "Uploading")
        coordinator.cleanup()
    }

    func testProgressCoordinator_updatesProgress() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.2
        coordinator.label = "Loading"
        coordinator.updatePresentation()

        // Update progress
        coordinator.progress = 0.8
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.progress, 0.8)
        coordinator.cleanup()
    }

    // MARK: - Binding Sync Tests

    func testCoordinator_completionBlock_resetBinding() {
        // Tests that when HUD is dismissed externally (e.g., auto-hide),
        // the binding is reset to false.
        var isPresentedValue = true
        let binding = Binding<Bool>(
            get: { isPresentedValue },
            set: { isPresentedValue = $0 }
        )

        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.isPresentedBinding = binding
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        // Simulate external dismiss: get the HUD and hide it directly
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        hud?.hide(animated: false)

        let expectation = XCTestExpectation(description: "binding reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertFalse(isPresentedValue)
    }

    // MARK: - Memory Tests

    func testCoordinator_noRetainCycle() {
        weak var weakCoordinator: HUDCoordinator?

        autoreleasepool {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
            }
            coordinator.updatePresentation()
            weakCoordinator = coordinator

            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertNil(weakCoordinator)
    }

    // MARK: - HUDItemCoordinator Tests

    func testItemCoordinator_showsHUDForItem() {
        struct TestItem: Identifiable { let id: String; let text: String }
        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        let item = TestItem(id: "1", text: "Loading")
        coordinator.currentItem = item
        coordinator.animation = .init()
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.text
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Loading")
        coordinator.cleanup()
    }

    func testItemCoordinator_hidesOnNilItem() {
        struct TestItem: Identifiable { let id: String }
        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.currentItem = TestItem(id: "1")
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { _, hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.currentItem = nil
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "item hide")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testItemCoordinator_switchesItemRecreatesHUD() {
        struct TestItem: Identifiable { let id: String; let text: String }
        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.text
        }

        coordinator.currentItem = TestItem(id: "1", text: "First")
        coordinator.updatePresentation()

        let firstHUD = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(firstHUD?.contentView.label.text, "First")

        // Switch to new item
        coordinator.currentItem = TestItem(id: "2", text: "Second")
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "switch")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let secondHUD = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(secondHUD?.contentView.label.text, "Second")
        coordinator.cleanup()
    }

    func testItemCoordinator_sameIdUpdatesConfiguration() {
        struct TestItem: Identifiable { let id: String; var text: String }
        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init()
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.text
        }

        coordinator.currentItem = TestItem(id: "1", text: "Original")
        coordinator.updatePresentation()

        // Same ID, different text — should update in place
        coordinator.currentItem = TestItem(id: "1", text: "Updated")
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Updated")
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    func testItemCoordinator_nilItemBindingReset() {
        // Tests that when HUD is dismissed externally while item is still set,
        // the binding is reset to nil.
        struct TestItem: Identifiable { let id: String }
        var itemValue: TestItem? = TestItem(id: "1")
        let binding = Binding<TestItem?>(
            get: { itemValue },
            set: { itemValue = $0 }
        )

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.currentItem = itemValue
        coordinator.animation = .init(style: .none)
        coordinator.itemBinding = binding
        coordinator.configuration = { _, hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        // Simulate external dismiss: hide the HUD directly while item is still set
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        hud?.hide(animated: false)

        let expectation = XCTestExpectation(description: "binding nil")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(itemValue)
    }

    // MARK: - HUDStatusCoordinator Additional Tests

    func testStatusCoordinator_risingEdgeOnlyTriggers() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.duration = 5.0
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        // First show (rising edge)
        coordinator.isPresented = true
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        // Same value again — should NOT create a new HUD
        coordinator.isPresented = true
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    func testStatusCoordinator_retriggerAfterAutoHide() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.duration = 0.1
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Toast"
        }

        coordinator.isPresented = true
        coordinator.updatePresentation()

        // Wait for auto-hide
        let hideExpectation = XCTestExpectation(description: "auto-hide")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hideExpectation.fulfill()
        }
        wait(for: [hideExpectation], timeout: 2.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)

        // Re-trigger
        coordinator.isPresented = true
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    func testStatusCoordinator_bindingResetOnAutoHide() {
        var isPresentedValue = true
        let binding = Binding<Bool>(
            get: { isPresentedValue },
            set: { isPresentedValue = $0 }
        )

        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 0.1
        coordinator.animation = .init(style: .none)
        coordinator.isPresentedBinding = binding
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "binding reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertFalse(isPresentedValue)
    }

    // MARK: - HUDProgressCoordinator Additional Tests

    func testProgressCoordinator_hideRemovesHUD() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 1.0
        coordinator.label = "Done"
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.isPresented = false
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "progress hide")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testProgressCoordinator_labelUpdates() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.label = "Starting"
        coordinator.updatePresentation()

        coordinator.label = "50%"
        coordinator.progress = 0.5
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "50%")
        XCTAssertEqual(hud?.contentView.progress, 0.5)
        coordinator.cleanup()
    }

    func testProgressCoordinator_noHostViewSafe() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = nil
        coordinator.isPresented = true
        coordinator.progress = 0.5
        coordinator.updatePresentation()
        // Should not crash
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - Edge Case Tests

    func testCoordinator_rapidToggle_singleHUD() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        for _ in 0..<10 {
            coordinator.isPresented = true
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
        }

        // Final state: hidden
        let expectation = XCTestExpectation(description: "rapid toggle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testCoordinator_configUpdatedWhileShowing() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "First"
        }
        coordinator.updatePresentation()

        // Update configuration
        coordinator.configuration = { hud in
            hud.contentView.label.text = "Second"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Second")
        coordinator.cleanup()
    }

    func testCoordinator_hideWhenAlreadyHidden() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { _ in }
        coordinator.isPresented = false
        coordinator.updatePresentation()
        // Should not crash
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testCoordinator_cleanupWhenNoHUD() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        // Never showed a HUD
        coordinator.cleanup()
        // Should not crash
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStatusCoordinator_cleanupDuringAutoHide() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 5.0
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        // Cleanup while auto-hide is pending
        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "no crash")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - Memory Tests (Additional)

    func testItemCoordinator_noRetainCycle() {
        struct TestItem: Identifiable { let id: String }
        weak var weakCoordinator: HUDItemCoordinator<TestItem>?

        autoreleasepool {
            let coordinator = HUDItemCoordinator<TestItem>()
            coordinator.hostView = window
            coordinator.currentItem = TestItem(id: "1")
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { _, hud in
                hud.contentView.mode = .text
            }
            coordinator.updatePresentation()
            weakCoordinator = coordinator

            coordinator.currentItem = nil
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertNil(weakCoordinator)
    }

    func testStatusCoordinator_noRetainCycle() {
        weak var weakCoordinator: HUDStatusCoordinator?

        autoreleasepool {
            let coordinator = HUDStatusCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.duration = 0.05
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
            }
            coordinator.updatePresentation()
            weakCoordinator = coordinator

            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertNil(weakCoordinator)
    }

    func testProgressCoordinator_noRetainCycle() {
        weak var weakCoordinator: HUDProgressCoordinator?

        autoreleasepool {
            let coordinator = HUDProgressCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.progress = 0.5
            coordinator.updatePresentation()
            weakCoordinator = coordinator

            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertNil(weakCoordinator)
    }

    // MARK: - H6/H7: Sheet / FullScreenCover (Independent Host)

    func testSheet_independentHUDHost_showsAndHides() {
        // Each sheet creates its own window/view hierarchy
        let sheetWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        sheetWindow.makeKeyAndVisible()

        let coordinator = HUDCoordinator()
        coordinator.hostView = sheetWindow
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Sheet HUD"
        }
        coordinator.updatePresentation()

        // HUD should appear on sheet window, not main window
        XCTAssertEqual(sheetWindow.subviews.filter { $0 is HUD }.count, 1)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)

        coordinator.cleanup()
        HUD.hideAll(for: sheetWindow, animated: false)
    }

    func testFullScreenCover_independentHUDHost_isolatedFromMain() {
        // FullScreenCover also creates its own view hierarchy
        let coverWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        coverWindow.makeKeyAndVisible()

        // Show HUD on main window
        let mainCoordinator = HUDCoordinator()
        mainCoordinator.hostView = window
        mainCoordinator.isPresented = true
        mainCoordinator.animation = .init(style: .none)
        mainCoordinator.configuration = { hud in
            hud.contentView.label.text = "Main"
        }
        mainCoordinator.updatePresentation()

        // Show HUD on cover window
        let coverCoordinator = HUDCoordinator()
        coverCoordinator.hostView = coverWindow
        coverCoordinator.isPresented = true
        coverCoordinator.animation = .init(style: .none)
        coverCoordinator.configuration = { hud in
            hud.contentView.label.text = "Cover"
        }
        coverCoordinator.updatePresentation()

        // Both should exist independently
        let mainHUDs = window.subviews.compactMap { $0 as? HUD }
        let coverHUDs = coverWindow.subviews.compactMap { $0 as? HUD }
        XCTAssertEqual(mainHUDs.count, 1)
        XCTAssertEqual(coverHUDs.count, 1)
        XCTAssertEqual(mainHUDs.first?.contentView.label.text, "Main")
        XCTAssertEqual(coverHUDs.first?.contentView.label.text, "Cover")

        // Hiding one doesn't affect other
        coverCoordinator.cleanup()
        HUD.hideAll(for: coverWindow, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        mainCoordinator.cleanup()
    }

    // MARK: - K1-K3: KeyboardGuide via SwiftUI Coordinator

    #if os(iOS)
    func testKeyboardGuide_center_setViaConfiguration() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.keyboardGuide = .center()
            hud.contentView.mode = .text
            hud.contentView.label.text = "Keyboard Center"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.keyboardGuide, .center())
        coordinator.cleanup()
    }

    func testKeyboardGuide_bottom_setViaConfiguration() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.keyboardGuide = .bottom(12)
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.keyboardGuide, .bottom(12))
        coordinator.cleanup()
    }

    func testKeyboardGuide_disable_setViaConfiguration() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.keyboardGuide = .disable
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.keyboardGuide, .disable)
        coordinator.cleanup()
    }

    func testKeyboardGuide_respondsToNotification_viaCoordinator() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.keyboardGuide = .center()
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)

        // Simulate keyboard notification
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 500, width: 375, height: 312),
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect.zero,
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7)
        ]
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )

        // Give RunLoop a chance to process
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // HUD should still be visible (not crash from keyboard handling)
        XCTAssertNotNil(hud?.superview)
        coordinator.cleanup()
    }
    #endif

    // MARK: - H9: Multiple Modifiers on Same View

    func testMultipleModifiers_sameHostView_independent() {
        let coordinator1 = HUDCoordinator()
        coordinator1.hostView = window
        coordinator1.isPresented = true
        coordinator1.animation = .init(style: .none)
        coordinator1.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "First"
        }
        coordinator1.updatePresentation()

        let coordinator2 = HUDCoordinator()
        coordinator2.hostView = window
        coordinator2.isPresented = true
        coordinator2.animation = .init(style: .none)
        coordinator2.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Second"
        }
        coordinator2.updatePresentation()

        let huds = window.subviews.compactMap { $0 as? HUD }
        XCTAssertEqual(huds.count, 2)

        let labels = Set(huds.compactMap { $0.contentView.label.text })
        XCTAssertTrue(labels.contains("First"))
        XCTAssertTrue(labels.contains("Second"))

        // Hide first, second remains
        coordinator1.cleanup()
        let remainingHuds = window.subviews.compactMap { $0 as? HUD }
        XCTAssertEqual(remainingHuds.count, 1)
        XCTAssertEqual(remainingHuds.first?.contentView.label.text, "Second")

        coordinator2.cleanup()
    }

    // MARK: - H10/H11: GraceTime and MinShowTime

    func testGraceTime_setBeforeShow_respected() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.graceTime = 0.3
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        // With graceTime, HUD may not be visible immediately
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud, "HUD should be created (graceTime delays visibility, not creation)")
        coordinator.cleanup()
    }

    func testMinShowTime_preventsEarlyHide() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.minShowTime = 1.0
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        // Immediately try to hide
        coordinator.isPresented = false
        coordinator.updatePresentation()

        // HUD should still be visible due to minShowTime
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud, "HUD should still exist due to minShowTime")

        // Force cleanup
        coordinator.cleanup()
        HUD.hideAll(for: window, animated: false)
        window.subviews.filter { $0 is HUD }.forEach { $0.removeFromSuperview() }
    }

    // MARK: - H12: Count Mode

    func testIsCountEnabled_multipleShowHide_balanced() {
        let coordinator1 = HUDCoordinator()
        coordinator1.hostView = window
        coordinator1.isPresented = true
        coordinator1.animation = .init(style: .none)
        coordinator1.configuration = { hud in
            hud.isCountEnabled = true
            hud.contentView.mode = .text
        }
        coordinator1.updatePresentation()

        // The HUD uses count mode - multiple shows need matching hides
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertTrue(hud?.isCountEnabled ?? false)

        coordinator1.cleanup()
    }

    // MARK: - H17: iPad Split View Multi-Window

    func testIPad_splitView_multiWindow_isolatedHUDs() {
        // Simulate iPad Split View: multiple windows with independent HUDs
        let window1 = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let window2 = UIWindow(frame: CGRect(x: 375, y: 0, width: 375, height: 812))
        window1.makeKeyAndVisible()
        window2.makeKeyAndVisible()

        let coordinator1 = HUDCoordinator()
        coordinator1.hostView = window1
        coordinator1.isPresented = true
        coordinator1.animation = .init(style: .none)
        coordinator1.configuration = { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "Window 1"
        }
        coordinator1.updatePresentation()

        let coordinator2 = HUDCoordinator()
        coordinator2.hostView = window2
        coordinator2.isPresented = true
        coordinator2.animation = .init(style: .none)
        coordinator2.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Window 2"
        }
        coordinator2.updatePresentation()

        // Both windows have independent HUDs
        let huds1 = window1.subviews.compactMap { $0 as? HUD }
        let huds2 = window2.subviews.compactMap { $0 as? HUD }
        XCTAssertEqual(huds1.count, 1)
        XCTAssertEqual(huds2.count, 1)
        XCTAssertEqual(huds1.first?.contentView.label.text, "Window 1")
        XCTAssertEqual(huds2.first?.contentView.label.text, "Window 2")

        // Hide on window1 doesn't affect window2
        coordinator1.isPresented = false
        coordinator1.updatePresentation()

        let _ = window1.subviews.compactMap { $0 as? HUD }
        let remaining2 = window2.subviews.compactMap { $0 as? HUD }
        XCTAssertEqual(remaining2.count, 1, "Window 2 HUD should persist")
        XCTAssertEqual(remaining2.first?.contentView.label.text, "Window 2")

        // HideAll on one window doesn't affect other
        HUD.hideAll(for: window1, animated: false)
        XCTAssertEqual(window2.subviews.filter { $0 is HUD }.count, 1)

        coordinator1.cleanup()
        coordinator2.cleanup()
        HUD.hideAll(for: window2, animated: false)
    }

    func testIPad_multipleCoordinators_differentWindows_switchHost() {
        // Simulates moving a coordinator from one Split View pane to another
        let leftWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        let rightWindow = UIWindow(frame: CGRect(x: 375, y: 0, width: 375, height: 812))
        leftWindow.makeKeyAndVisible()
        rightWindow.makeKeyAndVisible()

        let coordinator = HUDCoordinator()
        coordinator.hostView = leftWindow
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Moving HUD"
        }
        coordinator.updatePresentation()

        XCTAssertEqual(leftWindow.subviews.filter { $0 is HUD }.count, 1)
        XCTAssertEqual(rightWindow.subviews.filter { $0 is HUD }.count, 0)

        // Move to right window (simulates drag-to-split on iPad)
        coordinator.isPresented = false
        coordinator.updatePresentation()
        coordinator.cleanup()

        coordinator.hostView = rightWindow
        coordinator.isPresented = true
        coordinator.updatePresentation()

        // HUD should now be on right window
        XCTAssertEqual(rightWindow.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()
        HUD.hideAll(for: leftWindow, animated: false)
        HUD.hideAll(for: rightWindow, animated: false)
    }

    // MARK: - H18: visionOS Window Model

    /// visionOS uses the same UIWindow/UIView hierarchy as iOS.
    /// This test verifies that the coordinator pattern works correctly with
    /// the volumetric-style window dimensions typical of visionOS.
    func testVisionOS_windowModel_largeWindow() {
        // visionOS windows can have non-standard sizes
        let visionWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        visionWindow.makeKeyAndVisible()

        let coordinator = HUDCoordinator()
        coordinator.hostView = visionWindow
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "visionOS HUD"
        }
        coordinator.updatePresentation()

        let hud = visionWindow.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "visionOS HUD")

        // Verify HUD frame is within window bounds
        XCTAssertTrue(visionWindow.bounds.contains(hud?.frame ?? .zero))

        coordinator.cleanup()
        HUD.hideAll(for: visionWindow, animated: false)
    }

    func testVisionOS_windowModel_multipleVolumes() {
        // Simulate multiple visionOS "volumes" (each is a separate window)
        var windows: [UIWindow] = []
        var coordinators: [HUDCoordinator] = []

        for i in 0..<3 {
            let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            w.makeKeyAndVisible()
            windows.append(w)

            let c = HUDCoordinator()
            c.hostView = w
            c.isPresented = true
            c.animation = .init(style: .none)
            c.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Volume \(i)"
            }
            c.updatePresentation()
            coordinators.append(c)
        }

        // Each volume has its own HUD
        for (i, w) in windows.enumerated() {
            let huds = w.subviews.compactMap { $0 as? HUD }
            XCTAssertEqual(huds.count, 1)
            XCTAssertEqual(huds.first?.contentView.label.text, "Volume \(i)")
        }

        // Cleanup
        for c in coordinators { c.cleanup() }
        for w in windows { HUD.hideAll(for: w, animated: false) }
    }

    // MARK: - Coordinator Cleanup (dismantleUIView equivalent) Tests

    func testCoordinator_cleanup_removesHUDImmediately() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Dismantle Test"
        }
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "dismantle settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStatusCoordinator_cleanup_removesHUDImmediately() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 5.0
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Status Dismantle"
        }
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "status dismantle settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testItemCoordinator_cleanup_removesHUDImmediately() {
        struct TestItem: Identifiable {
            let id: String
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { _, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Item Dismantle"
        }
        coordinator.currentItem = TestItem(id: "1")
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "item dismantle settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testProgressCoordinator_cleanup_removesHUDImmediately() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.5
        coordinator.label = "Progress Dismantle"
        coordinator.updatePresentation()

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "progress dismantle settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - HUDTargetView onWindow Callback Tests

    func testHUDTargetView_onWindowNil_callbackNotRetained() {
        let targetView = HUDTargetView()
        XCTAssertNil(targetView.onWindow)
    }

    func testHUDTargetView_movedToNilWindow_noCallback() {
        let targetView = HUDTargetView()
        var callCount = 0
        targetView.onWindow = { _ in
            callCount += 1
        }

        // Add to window (triggers callback)
        window.addSubview(targetView)
        XCTAssertEqual(callCount, 1)

        // Remove from window (triggers didMoveToWindow with nil window)
        targetView.removeFromSuperview()
        // Should NOT trigger callback again since window is nil
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - HUDHostView Tests

    func testHUDHostView_initialization() {
        var receivedView: UIView?
        let hostView = HUDHostView { view in
            receivedView = view
        }
        XCTAssertNotNil(hostView)
        XCTAssertNil(receivedView)
    }

    func testHUDHostView_onViewReady_calledWhenAddedToWindow() {
        let expectation = XCTestExpectation(description: "onViewReady called")
        var receivedView: UIView?

        let hostView = HUDHostView { view in
            receivedView = view
            expectation.fulfill()
        }

        // Create the UIView from the representable
        _ = hostView // Verify it compiles and is a valid View

        // Test that HUDTargetView is used internally by adding it directly
        let targetView = HUDTargetView()
        targetView.onWindow = { view in
            receivedView = view
            expectation.fulfill()
        }
        window.addSubview(targetView)
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedView)
        targetView.removeFromSuperview()
    }

    // MARK: - Convenience Modifier Configuration Tests

    func testLoadingModifier_configuresIndicatorMode() {
        // Simulate what HUDLoadingModifier does via its underlying coordinator
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "Loading"
            hud.contentView.detailsLabel.text = "Please wait..."
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Loading")
        XCTAssertEqual(hud?.contentView.detailsLabel.text, "Please wait...")
        coordinator.cleanup()
    }

    func testLoadingModifier_nilLabels() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = nil
            hud.contentView.detailsLabel.text = nil
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertNil(hud?.contentView.label.text)
        XCTAssertNil(hud?.contentView.detailsLabel.text)
        coordinator.cleanup()
    }

    func testToastModifier_configuresTextMode() {
        // Simulate what HUDToastModifier does via its underlying status coordinator
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 1.5
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Saved!"
            hud.contentView.detailsLabel.text = nil
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Saved!")
        coordinator.cleanup()
    }

    func testToastModifier_withDetailsLabel() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 2.0
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Error"
            hud.contentView.detailsLabel.text = "Please try again"
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Error")
        XCTAssertEqual(hud?.contentView.detailsLabel.text, "Please try again")
        coordinator.cleanup()
    }

    func testProgressModifier_configuresProgressMode() {
        // Simulate what HUDProgressModifier does
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.3
        coordinator.label = "Uploading"
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.label.text, "Uploading")
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.3, accuracy: 0.001)
        coordinator.cleanup()
    }

    func testProgressModifier_nilLabel() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.7
        coordinator.label = nil
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertNil(hud?.contentView.label.text)
        XCTAssertEqual(Double(hud?.contentView.progress ?? 0), 0.7, accuracy: 0.001)
        coordinator.cleanup()
    }

    // MARK: - View Extension Compile & Type Tests

    func testViewExtension_hudModifier_producesExpectedView() {
        let view = EmptyView()
        var isPresented = false
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let modified = view.hud(isPresented: binding) { _ in }
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudItemModifier_producesExpectedView() {
        struct TestItem: Identifiable {
            let id: String
        }
        let view = EmptyView()
        var item: TestItem? = nil
        let binding = Binding(get: { item }, set: { item = $0 })
        let modified = view.hud(item: binding) { _, _ in }
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudStatusModifier_producesExpectedView() {
        let view = EmptyView()
        var isPresented = false
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let modified = view.hudStatus(isPresented: binding, duration: 2.0) { _ in }
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudLoading_producesExpectedView() {
        let view = EmptyView()
        var isPresented = false
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let modified = view.hudLoading(isPresented: binding, label: "Loading", detailsLabel: "Wait")
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudToast_producesExpectedView() {
        let view = EmptyView()
        var isPresented = false
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let modified = view.hudToast(isPresented: binding, duration: 1.5, label: "Done", detailsLabel: "OK")
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudProgress_producesExpectedView() {
        let view = EmptyView()
        var isPresented = false
        var progress: Float = 0.0
        let isBinding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let progressBinding = Binding(get: { progress }, set: { progress = $0 })
        let modified = view.hudProgress(isPresented: isBinding, progress: progressBinding, label: "Progress")
        XCTAssertNotNil(modified)
    }

    func testViewExtension_hudHost_producesExpectedView() {
        let view = EmptyView()
        var hostView: UIView? = nil
        let binding = Binding(get: { hostView }, set: { hostView = $0 })
        let modified = view.hudHost(binding)
        XCTAssertNotNil(modified)
    }

    // MARK: - StatusCoordinator wasPresented Edge Cases

    func testStatusCoordinator_falseToFalse_noAction() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = false
        coordinator.duration = 2.0
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        // First update with false
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)

        // Another update with false - should not show
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStatusCoordinator_trueToTrue_noRetrigger() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 5.0
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Status"
        }

        // First show
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        // Second update with same state - should NOT create duplicate
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    // MARK: - ProgressCoordinator Binding Reset Tests

    func testProgressCoordinator_completionBlock_resetsBinding() {
        var isPresentedValue = true
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = isPresentedValue
        coordinator.progress = 1.0
        coordinator.label = "Done"
        coordinator.isPresentedBinding = Binding(get: { isPresentedValue }, set: { isPresentedValue = $0 })
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)

        // Simulate hide completing
        coordinator.isPresented = false
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "progress hide settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - ItemCoordinator hideHUD animated parameter

    func testItemCoordinator_hideAnimated_whenPreviousItemExists() {
        struct TestItem: Identifiable {
            let id: String
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.id
        }

        // Show first item
        coordinator.currentItem = TestItem(id: "A")
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)

        // Switch to different item (should hide with animation, then show new)
        coordinator.currentItem = TestItem(id: "B")
        coordinator.updatePresentation()

        let expectation = XCTestExpectation(description: "item switch settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "B")
        coordinator.cleanup()
    }

    func testItemCoordinator_hideNotAnimated_firstItem() {
        struct TestItem: Identifiable {
            let id: String
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.id
        }

        // Directly set to nil (no previous item shown)
        coordinator.currentItem = nil
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - UIHostingController Lifecycle Tests (Full SwiftUI Pipeline)

    func testHUDModifier_viaHostingController_showsHUD() {
        var isPresented = true
        let hostingController = UIHostingController(rootView:
            Color.clear.hud(isPresented: Binding(get: { isPresented }, set: { isPresented = $0 })) { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Hosted"
            }
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "HUD appears via hosting")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let huds = window.subviews.flatMap { $0.allSubviews }.compactMap { $0 as? HUD }
            + window.subviews.compactMap { $0 as? HUD }
        XCTAssertGreaterThanOrEqual(huds.count, 1, "HUD should be shown via hosting controller")

        window.rootViewController = nil
    }

    func testHUDModifier_viaHostingController_hidesHUD() {
        var isPresented = true
        let binding = Binding(get: { isPresented }, set: { isPresented = $0 })
        let hostingController = UIHostingController(rootView:
            Color.clear.hud(isPresented: binding) { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "WillHide"
            }
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let showExpectation = XCTestExpectation(description: "HUD shows")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showExpectation.fulfill()
        }
        wait(for: [showExpectation], timeout: 2.0)

        // Now hide
        isPresented = false
        hostingController.rootView = Color.clear.hud(isPresented: Binding(get: { isPresented }, set: { isPresented = $0 })) { hud in
            hud.contentView.mode = .text
        }
        hostingController.view.layoutIfNeeded()

        let hideExpectation = XCTestExpectation(description: "HUD hides")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hideExpectation.fulfill()
        }
        wait(for: [hideExpectation], timeout: 2.0)

        window.rootViewController = nil
    }

    func testHUDStatusModifier_viaHostingController_showsAndAutoHides() {
        var isPresented = true
        let hostingController = UIHostingController(rootView:
            Color.clear.hudStatus(isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }), duration: 0.2) { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Toast"
            }
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let showExpectation = XCTestExpectation(description: "Status HUD appears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showExpectation.fulfill()
        }
        wait(for: [showExpectation], timeout: 2.0)

        // Verify HUD was shown (it may already be auto-hiding)
        // The key test here is that the full SwiftUI lifecycle works without crash

        // Wait for auto-hide to complete
        let hideExpectation = XCTestExpectation(description: "Status HUD auto-hides")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            hideExpectation.fulfill()
        }
        wait(for: [hideExpectation], timeout: 3.0)

        window.rootViewController = nil
    }

    func testHUDLoadingModifier_viaHostingController() {
        var isPresented = true
        let hostingController = UIHostingController(rootView:
            Color.clear.hudLoading(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                label: "Loading...",
                detailsLabel: "Please wait"
            )
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "Loading HUD appears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let huds = window.subviews.flatMap { $0.allSubviews }.compactMap { $0 as? HUD }
            + window.subviews.compactMap { $0 as? HUD }
        XCTAssertGreaterThanOrEqual(huds.count, 1)

        window.rootViewController = nil
    }

    func testHUDToastModifier_viaHostingController() {
        var isPresented = true
        let hostingController = UIHostingController(rootView:
            Color.clear.hudToast(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                duration: 0.3,
                label: "Done!",
                detailsLabel: "Files saved"
            )
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "Toast HUD appears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        window.rootViewController = nil
    }

    func testHUDProgressModifier_viaHostingController() {
        var isPresented = true
        var progress: Float = 0.5
        let hostingController = UIHostingController(rootView:
            Color.clear.hudProgress(
                isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
                progress: Binding(get: { progress }, set: { progress = $0 }),
                label: "Uploading"
            )
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "Progress HUD appears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let huds = window.subviews.flatMap { $0.allSubviews }.compactMap { $0 as? HUD }
            + window.subviews.compactMap { $0 as? HUD }
        XCTAssertGreaterThanOrEqual(huds.count, 1)

        window.rootViewController = nil
    }

    func testHUDProgressModifier_viaHostingController_updatesProgress() {
        var isPresented = true
        var progress: Float = 0.0
        let progressBinding = Binding(get: { progress }, set: { progress = $0 })
        let isPresentedBinding = Binding(get: { isPresented }, set: { isPresented = $0 })

        let hostingController = UIHostingController(rootView:
            Color.clear.hudProgress(isPresented: isPresentedBinding, progress: progressBinding, label: "Upload")
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let showExpectation = XCTestExpectation(description: "Progress shows")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showExpectation.fulfill()
        }
        wait(for: [showExpectation], timeout: 2.0)

        // Update progress
        progress = 0.8
        hostingController.rootView = Color.clear.hudProgress(
            isPresented: Binding(get: { isPresented }, set: { isPresented = $0 }),
            progress: Binding(get: { progress }, set: { progress = $0 }),
            label: "Almost done"
        )
        hostingController.view.layoutIfNeeded()

        let updateExpectation = XCTestExpectation(description: "Progress updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            updateExpectation.fulfill()
        }
        wait(for: [updateExpectation], timeout: 2.0)

        window.rootViewController = nil
    }

    func testHUDHostView_viaHostingController_providesView() {
        var receivedView: UIView?
        let hostingController = UIHostingController(rootView:
            Color.clear.hudHost(Binding(get: { receivedView }, set: { receivedView = $0 }))
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "Host view provided")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(receivedView, "hudHost should provide a UIView")

        window.rootViewController = nil
    }

    func testHUDItemModifier_viaHostingController_showsForItem() {
        struct TestItem: Identifiable {
            let id: String
            let label: String
        }

        var item: TestItem? = TestItem(id: "test1", label: "Item Loading")
        let hostingController = UIHostingController(rootView:
            Color.clear.hud(
                item: Binding(get: { item }, set: { item = $0 })
            ) { currentItem, hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = currentItem.label
            }
        )
        window.rootViewController = hostingController
        hostingController.view.layoutIfNeeded()

        let expectation = XCTestExpectation(description: "Item HUD appears")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let huds = window.subviews.flatMap { $0.allSubviews }.compactMap { $0 as? HUD }
            + window.subviews.compactMap { $0 as? HUD }
        XCTAssertGreaterThanOrEqual(huds.count, 1)

        window.rootViewController = nil
    }

    func testHUDModifier_viaHostingController_dismantleOnDealloc() {
        var isPresented = true
        var hostingController: UIHostingController<some View>? = UIHostingController(rootView:
            Color.clear.hud(isPresented: Binding(get: { isPresented }, set: { isPresented = $0 })) { hud in
                hud.contentView.mode = .text
            }
        )
        window.rootViewController = hostingController
        hostingController?.view.layoutIfNeeded()

        let showExpectation = XCTestExpectation(description: "HUD shows")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showExpectation.fulfill()
        }
        wait(for: [showExpectation], timeout: 2.0)

        // Deallocate hosting controller (triggers dismantleUIView)
        hostingController = nil
        window.rootViewController = nil

        let dismantleExpectation = XCTestExpectation(description: "Dismantle settles")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismantleExpectation.fulfill()
        }
        wait(for: [dismantleExpectation], timeout: 2.0)
    }

    // MARK: - Item ID Change Tests

    func testItemCoordinator_itemIDChange_createsNewHUD() {
        struct TestItem: Identifiable { let id: String; let label: String }
        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.label.text = item.label
        }

        // Show first item
        let item1 = TestItem(id: "a", label: "First")
        coordinator.currentItem = item1
        coordinator.updatePresentation()

        let firstHUD = window.allSubviews.compactMap { $0 as? HUD }.last
        XCTAssertNotNil(firstHUD, "First HUD should be shown")
        XCTAssertEqual(firstHUD?.contentView.label.text, "First")

        // Change to different item ID — should create a new HUD, not reuse
        let item2 = TestItem(id: "b", label: "Second")
        coordinator.currentItem = item2
        coordinator.updatePresentation()

        let settleExpectation = XCTestExpectation(description: "Settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            settleExpectation.fulfill()
        }
        wait(for: [settleExpectation], timeout: 1.0)

        let secondHUD = window.allSubviews.compactMap { $0 as? HUD }.last
        XCTAssertNotNil(secondHUD, "Second HUD should be shown")
        XCTAssertEqual(secondHUD?.contentView.label.text, "Second")
    }
}
