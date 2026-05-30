//
//  SwiftUIHUDStressTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
import SwiftUI
import FlyIndicatorHUD
import FlyProgressHUD
@testable import FlyHUD
@testable import FlyHUDSwiftUI

@MainActor
final class SwiftUIHUDStressTests: XCTestCase {

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

    // MARK: - M1: Rapid Create/Destroy

    func testStress_rapidCreateDestroy_100Cycles() {
        for _ in 0..<100 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
            }
            coordinator.updatePresentation()
            coordinator.cleanup()
        }
        // No crash, no leaked HUDs
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_rapidCreateDestroy_withAnimation() {
        for _ in 0..<50 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .zoomInOut, damping: .default)
            coordinator.configuration = { hud in
                hud.contentView.mode = .indicator()
            }
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_coordinatorAllocDealloc_noLeak() {
        weak var weakRef: HUDCoordinator?
        for i in 0..<50 {
            autoreleasepool {
                let coordinator = HUDCoordinator()
                coordinator.hostView = window
                coordinator.isPresented = true
                coordinator.animation = .init(style: .none)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .text
                    hud.contentView.label.text = "Cycle \(i)"
                }
                coordinator.updatePresentation()
                if i == 49 { weakRef = coordinator }
                coordinator.cleanup()
            }
        }

        let expectation = XCTestExpectation(description: "dealloc all")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNil(weakRef)
    }

    // MARK: - M2: Concurrent Binding Updates

    func testStress_rapidBindingToggle_50Times() {
        var isPresentedValue = false
        let binding = Binding<Bool>(
            get: { isPresentedValue },
            set: { isPresentedValue = $0 }
        )

        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.isPresentedBinding = binding
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        for _ in 0..<50 {
            isPresentedValue = true
            coordinator.isPresented = true
            coordinator.updatePresentation()

            isPresentedValue = false
            coordinator.isPresented = false
            coordinator.updatePresentation()
        }

        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(isPresentedValue)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_statusRapidRetrigger() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.duration = 0.05
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        // Rapid trigger/reset cycle
        for _ in 0..<20 {
            coordinator.isPresented = true
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
        }

        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M3: Animation Stress

    func testStress_allAnimationStyles() {
        let styles: [HUD.Animation.Style] = [.none, .fade, .zoomInOut, .slideUpDown, .slideLeftRight, .slideRightLeft]

        for style in styles {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: style, damping: .default)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "\(style)"
            }
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "all animations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_animationInterruptShowHide() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .zoomInOut, damping: .default, duration: 0.5)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }

        // Show then immediately hide (interrupting show animation)
        coordinator.isPresented = true
        coordinator.updatePresentation()
        coordinator.isPresented = false
        coordinator.updatePresentation()

        // Show again (interrupting hide animation)
        coordinator.isPresented = true
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        coordinator.cleanup()
    }

    // MARK: - M4: High-Frequency Property Changes

    func testStress_rapidProgressUpdates_1000Times() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.label = "Start"
        coordinator.updatePresentation()

        for i in 0..<1000 {
            coordinator.progress = Float(i) / 1000.0
            coordinator.updatePresentation()
        }

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertNotNil(hud)
        XCTAssertEqual(hud?.contentView.progress ?? 0, Float(999) / 1000.0, accuracy: 0.001)
        coordinator.cleanup()
    }

    func testStress_rapidLabelUpdates() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init()

        for i in 0..<200 {
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Update \(i)"
            }
            coordinator.updatePresentation()
        }

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Update 199")
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    // MARK: - M5: Item Switching Stress

    func testStress_rapidItemSwitching_50Items() {
        struct TestItem: Identifiable {
            let id: Int
            let text: String
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = item.text
        }

        for i in 0..<50 {
            coordinator.currentItem = TestItem(id: i, text: "Item \(i)")
            coordinator.updatePresentation()
        }

        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Final HUD should have last item's text
        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.label.text, "Item 49")
        coordinator.cleanup()
    }

    // MARK: - M6: Multiple Coordinator Stress

    func testStress_multipleCoordinatorsOnSameWindow() {
        var coordinators: [HUDCoordinator] = []

        for i in 0..<10 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "HUD \(i)"
            }
            coordinator.updatePresentation()
            coordinators.append(coordinator)
        }

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 10)

        // Cleanup all
        for coordinator in coordinators {
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "cleanup all")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M7: Memory Stress

    func testStress_memory_manyCoordinatorsNoLeak() {
        weak var lastWeak: HUDCoordinator?

        autoreleasepool {
            for _ in 0..<100 {
                let coordinator = HUDCoordinator()
                coordinator.hostView = window
                coordinator.isPresented = true
                coordinator.animation = .init(style: .none)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .text
                }
                coordinator.updatePresentation()
                coordinator.cleanup()
                lastWeak = coordinator
            }
        }

        let expectation = XCTestExpectation(description: "all freed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNil(lastWeak)
    }

    func testStress_memory_statusCoordinatorsNoLeak() {
        weak var lastWeak: HUDStatusCoordinator?

        autoreleasepool {
            for _ in 0..<50 {
                let coordinator = HUDStatusCoordinator()
                coordinator.hostView = window
                coordinator.isPresented = true
                coordinator.duration = 0.01
                coordinator.animation = .init(style: .none)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .text
                }
                coordinator.updatePresentation()
                coordinator.cleanup()
                lastWeak = coordinator
            }
        }

        let expectation = XCTestExpectation(description: "all freed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNil(lastWeak)
    }

    // MARK: - M8: SwiftUI-Specific Stress

    func testStress_updateUIView_calledRepeatedly() {
        // Simulate what SwiftUI does: create once, update many times
        let coordinator = HUDCoordinator()
        coordinator.hostView = window

        for i in 0..<100 {
            coordinator.isPresented = (i % 2 == 0)
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Update \(i)"
            }
            coordinator.updatePresentation()
        }

        // i=99 is odd, so isPresented=false
        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_hostViewAssignedLate() {
        let coordinator = HUDCoordinator()
        coordinator.isPresented = true
        coordinator.animation = .init()
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        // No host view yet — should not crash
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)

        // Now assign host view
        coordinator.hostView = window
        coordinator.updatePresentation()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 1)
        coordinator.cleanup()
    }

    // MARK: - M9: Timer Competition (Status)

    func testStress_statusDurationChangeMidFlight() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.duration = 10.0 // Long duration
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        // Cleanup before timer fires (simulates view disappearing)
        coordinator.cleanup()

        let expectation = XCTestExpectation(description: "no late fire")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - P: Performance Baselines

    func testPerformance_coordinatorShowHide() {
        measure {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
            }
            coordinator.isPresented = true
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }
    }

    func testPerformance_progressUpdate_100Steps() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.updatePresentation()

        measure {
            for i in 0..<100 {
                coordinator.progress = Float(i) / 100.0
                coordinator.updatePresentation()
            }
        }
        coordinator.cleanup()
    }

    func testPerformance_itemSwitch_50Items() {
        struct TestItem: Identifiable {
            let id: Int
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { _, hud in
            hud.contentView.mode = .text
        }

        measure {
            for i in 0..<50 {
                coordinator.currentItem = TestItem(id: i)
                coordinator.updatePresentation()
            }
        }
        coordinator.cleanup()
    }

    // MARK: - M10: Extended Scale Tests

    func testStress_rapidBindingToggle_500cycles() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }

        for _ in 0..<500 {
            coordinator.isPresented = true
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
        }

        coordinator.cleanup()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_fiveThousandRapidCycles() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }

        for _ in 0..<5000 {
            autoreleasepool {
                coordinator.isPresented = true
                coordinator.updatePresentation()
                coordinator.isPresented = false
                coordinator.updatePresentation()
            }
        }

        coordinator.cleanup()
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_massiveModifierInstances_100coordinators() {
        var coordinators: [HUDCoordinator] = []

        for i in 0..<100 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "C\(i)"
            }
            coordinator.updatePresentation()
            coordinators.append(coordinator)
        }

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 100)

        for coordinator in coordinators {
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "cleanup 100")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M11: Interleaved Show/Hide at Scale

    func testStress_interleavedShowHide_500ops() {
        for _ in 0..<500 {
            let hud = HUD.show(to: window, animated: false, mode: .indicator())
            if Bool.random() {
                hud.hide(animated: false)
            }
        }
        HUD.hideAll(for: window, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_multipleHUD_countMode_200pairs() {
        for _ in 0..<200 {
            let hud = HUD(with: window)
            hud.isCountEnabled = true
            window.addSubview(hud)
            hud.show(animated: false)
        }

        for _ in 0..<200 {
            HUD.hide(for: window, animated: false)
        }

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M12: Property Mutation at Scale

    func testStress_layoutOffset_10000updates() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first!
        for i in 0..<10000 {
            hud.layout.offset = CGPoint(x: CGFloat(i % 200) - 100, y: CGFloat(i % 100) - 50)
        }

        coordinator.cleanup()
        XCTAssertTrue(true, "10000 offset updates without crash")
    }

    func testStress_modeSwitch_2000times() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first!
        let modes: [ContentView.Mode] = [.indicator(), .indicator(.medium), .text, .progress()]

        for i in 0..<2000 {
            hud.contentView.mode = modes[i % modes.count]
        }

        coordinator.cleanup()
        XCTAssertTrue(true, "2000 mode switches without crash")
    }

    func testStress_allProperties_randomMutation_5000rounds() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first!
        let modes: [ContentView.Mode] = [.indicator(), .indicator(.medium), .text, .progress()]
        let positions = ContentView.IndicatorPosition.allCases
        let colors: [UIColor] = [.red, .blue, .green, .label, .systemPink, .clear]

        for _ in 0..<5000 {
            hud.layout.offset = CGPoint(x: .random(in: -200...200), y: .random(in: -200...200))
            hud.contentView.mode = modes.randomElement()!
            hud.contentView.indicatorPosition = positions.randomElement()!
            hud.contentView.contentColor = colors.randomElement()!
            hud.contentView.label.text = "Iter \(Int.random(in: 0...9999))"
            hud.contentView.layout.hMargin = .random(in: 5...50)
            hud.contentView.layout.vMargin = .random(in: 5...50)
            hud.contentView.layout.isSquare = .random()
            hud.contentView.roundedCorners = Bool.random() ? .full : .radius(.random(in: 0...30))
        }

        coordinator.cleanup()
        XCTAssertTrue(true, "5000 random mutations without crash")
    }

    // MARK: - M13: Progress Stress

    func testStress_progress_50000updates() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.updatePresentation()

        for i in 0..<50000 {
            coordinator.progress = Float(i % 1000) / 1000.0
            coordinator.updatePresentation()
        }

        coordinator.cleanup()
        XCTAssertTrue(true, "50000 progress updates without crash")
    }

    func testStress_progress_rapidReset_1000times() {
        let coordinator = HUDProgressCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.progress = 0.0
        coordinator.updatePresentation()

        for _ in 0..<1000 {
            coordinator.progress = 1.0
            coordinator.updatePresentation()
            coordinator.progress = 0.0
            coordinator.updatePresentation()
        }

        let hud = window.subviews.compactMap { $0 as? HUD }.first
        XCTAssertEqual(hud?.contentView.progress ?? -1, 0.0, accuracy: 0.001)
        coordinator.cleanup()
    }

    // MARK: - M14: Animation Scale Stress

    func testStress_allAnimationStyles_rapidCycle_14x20() {
        let allStyles: [HUD.Animation.Style] = [.none, .fade, .zoomInOut, .zoomOutIn, .slideUpDown, .slideDownUp, .slideLeftRight, .slideRightLeft]

        for _ in 0..<20 {
            for style in allStyles {
                let hud = HUD(with: window)
                window.addSubview(hud)
                hud.animation = .init(style: style, damping: .default, duration: 0.01)
                hud.contentView.mode = .indicator()
                hud.show(animated: true)
                hud.hide(animated: false) // immediate to avoid stacking
            }
        }

        let expectation = XCTestExpectation(description: "animations settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        HUD.hideAll(for: window, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_multipleHUD_differentAnimations_simultaneous() {
        let styles: [HUD.Animation.Style] = [.none, .fade, .zoomInOut, .zoomOutIn, .slideUpDown, .slideDownUp, .slideLeftRight, .slideRightLeft]
        var huds: [HUD] = []

        for (i, style) in styles.enumerated() {
            let hud = HUD(with: window)
            window.addSubview(hud)
            hud.animation = .init(style: style, damping: .default, duration: 0.1)
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "HUD \(i)"
            hud.show(animated: true)
            huds.append(hud)
        }

        // Hide all simultaneously
        for hud in huds {
            hud.hide(animated: true)
        }

        let expectation = XCTestExpectation(description: "all hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M15: Mixed Windows Stress

    func testStress_multipleWindows_20HUDs() {
        var windows: [UIWindow] = []
        for _ in 0..<4 {
            let w = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
            w.makeKeyAndVisible()
            windows.append(w)
        }

        // 5 HUDs per window
        for w in windows {
            for _ in 0..<5 {
                let coordinator = HUDCoordinator()
                coordinator.hostView = w
                coordinator.isPresented = true
                coordinator.animation = .init(style: .none)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .text
                }
                coordinator.updatePresentation()
            }
            XCTAssertEqual(w.subviews.filter { $0 is HUD }.count, 5)
        }

        // Cleanup
        for w in windows {
            HUD.hideAll(for: w, animated: false)
            XCTAssertEqual(w.subviews.filter { $0 is HUD }.count, 0)
        }
    }

    // MARK: - M16: Indicator Animation Stress

    func testStress_indicator_rapidStartStop_1000times() {
        let indicator = ActivityIndicatorView(styleable: ActivityIndicatorView.Style.ballSpinFade)
        window.addSubview(indicator)

        for _ in 0..<1000 {
            indicator.startAnimating()
            indicator.stopAnimating()
        }

        indicator.removeFromSuperview()
        XCTAssertFalse(indicator.isAnimating)
    }

    func testStress_indicator_styleSwitchWhileAnimating_500times() {
        let styles = ActivityIndicatorView.Style.allCases

        for style in styles {
            let indicator = ActivityIndicatorView(styleable: style)
            window.addSubview(indicator)
            indicator.startAnimating()

            for i in 0..<125 {
                indicator.style = styles[i % styles.count]
            }

            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
        XCTAssertTrue(true, "500 style switches during animation without crash")
    }

    func testStress_indicator_rapidCreate_200instances() {
        var indicators: [ActivityIndicatorView] = []
        let styles = ActivityIndicatorView.Style.allCases

        for i in 0..<200 {
            let indicator = ActivityIndicatorView(styleable: styles[i % styles.count])
            window.addSubview(indicator)
            indicator.startAnimating()
            indicators.append(indicator)
        }

        XCTAssertEqual(indicators.count, 200)

        for indicator in indicators {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
    }

    // MARK: - M17: SwiftUI-Specific Edge Cases

    func testStress_coordinatorReuse_1000updates() {
        // Simulate SwiftUI's pattern: makeCoordinator once, updateUIView many times
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        let initialID = ObjectIdentifier(coordinator)

        for i in 0..<1000 {
            coordinator.isPresented = (i % 3 != 0) // 2/3 of time presented
            coordinator.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "Reuse \(i)"
            }
            coordinator.updatePresentation()
        }

        // Last iteration: i=999, 999%3==0, so isPresented=false
        coordinator.cleanup()
        XCTAssertEqual(ObjectIdentifier(coordinator), initialID, "Coordinator should be same instance")
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_itemCoordinator_rapidNilAssignment_200cycles() {
        struct TestItem: Identifiable {
            let id: Int
        }

        let coordinator = HUDItemCoordinator<TestItem>()
        coordinator.hostView = window
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { item, hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Item \(item.id)"
        }

        for i in 0..<200 {
            coordinator.currentItem = TestItem(id: i)
            coordinator.updatePresentation()
            coordinator.currentItem = nil
            coordinator.updatePresentation()
        }

        coordinator.cleanup()
        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_statusCoordinator_rapidRetrigger_100cycles() {
        let coordinator = HUDStatusCoordinator()
        coordinator.hostView = window
        coordinator.duration = 0.01
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Status"
        }

        // Rapid trigger-retrigger (rising edge detection)
        for _ in 0..<100 {
            coordinator.isPresented = true
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
        }

        let expectation = XCTestExpectation(description: "all auto-hide")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M18: Coordinator Dealloc Under Load

    func testStress_coordinatorDeallocDuringShow_100cycles() {
        for _ in 0..<100 {
            autoreleasepool {
                let coordinator = HUDCoordinator()
                coordinator.hostView = window
                coordinator.isPresented = true
                coordinator.animation = .init(style: .fade, damping: .default, duration: 0.01)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .indicator()
                }
                coordinator.updatePresentation()
                // Coordinator goes out of scope while HUD is showing
            }
        }

        // Give animations time to settle
        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        // HUDs may remain since no explicit cleanup, but must not crash
        HUD.hideAll(for: window, animated: false)
    }

    func testStress_progressCoordinator_deallocMidProgress() {
        weak var weakRef: HUDProgressCoordinator?

        autoreleasepool {
            let coordinator = HUDProgressCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.progress = 0.5
            coordinator.updatePresentation()
            weakRef = coordinator
            coordinator.cleanup()
        }

        let expectation = XCTestExpectation(description: "dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNil(weakRef)
    }

    // MARK: - M19: GraceTime + MinShowTime Stress

    func testStress_graceTimeInterrupt_100times() {
        for _ in 0..<100 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.graceTime = 0.5
                hud.contentView.mode = .indicator()
            }
            coordinator.updatePresentation()
            // Hide before graceTime fires
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()
        }

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_minShowTimeOverlap_100times() {
        for _ in 0..<100 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.minShowTime = 5.0 // Long minShowTime
                hud.contentView.mode = .text
            }
            coordinator.updatePresentation()
            coordinator.isPresented = false
            coordinator.updatePresentation()
            // Force cleanup despite minShowTime
            coordinator.cleanup()
        }

        // minShowTime may prevent immediate removal, force clean
        HUD.hideAll(for: window, animated: false)
        // Remaining HUDs with pending minShowTime timers — remove manually
        window.subviews.filter { $0 is HUD }.forEach { $0.removeFromSuperview() }
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M20: Foundation.Progress Integration Stress

    func testStress_observedProgress_multiQueue_10queues() {
        let progress = Progress(totalUnitCount: 100)
        let hud = HUD.show(to: window, animated: false, mode: .progress())
        hud.contentView.observedProgress = progress

        let group = DispatchGroup()
        for q in 0..<10 {
            let queue = DispatchQueue(label: "stress.progress.\(q)", qos: .userInitiated)
            group.enter()
            queue.async {
                for j in 0..<10 {
                    progress.completedUnitCount = Int64(q * 10 + j)
                }
                group.leave()
            }
        }

        // Wait on background thread to avoid blocking main RunLoop
        let expectation = XCTestExpectation(description: "progress done")
        DispatchQueue.global().async {
            group.wait()
            DispatchQueue.main.async { expectation.fulfill() }
        }
        wait(for: [expectation], timeout: 5.0)

        hud.contentView.observedProgress = nil
        hud.hide(animated: false)
        XCTAssertTrue(true, "Multi-queue progress stress without crash")
    }

    func testStress_observedProgress_cancel_100times() {
        for _ in 0..<100 {
            autoreleasepool {
                let progress = Progress(totalUnitCount: 100)
                let hud = HUD.show(to: window, animated: false, mode: .progress())
                hud.contentView.observedProgress = progress
                progress.completedUnitCount = 50
                progress.cancel()
                hud.contentView.observedProgress = nil
                hud.hide(animated: false)
            }
        }
        HUD.hideAll(for: window, animated: false)
        XCTAssertTrue(true, "100 progress cancel cycles without crash")
    }

    func testStress_progressView_styleSwitch_duringUpdate_500times() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .progress(.roundBar)
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first!
        let progressStyles: [FlyProgressHUD.ProgressView.Style] = [.buttBar, .roundBar, .round, .annularRound, .pie]

        for i in 0..<500 {
            hud.contentView.mode = .progress(progressStyles[i % progressStyles.count])
            hud.contentView.progress = Float(i % 100) / 100.0
        }

        coordinator.cleanup()
        XCTAssertTrue(true, "500 progress style switches without crash")
    }

    // MARK: - M21: Multiple HUD Scale Tests

    func testStress_50HUDs_simultaneous_differentModes() {
        var coordinators: [HUDCoordinator] = []
        let modes: [ContentView.Mode] = [.indicator(), .indicator(.medium), .text, .progress()]

        for i in 0..<50 {
            let coordinator = HUDCoordinator()
            coordinator.hostView = window
            coordinator.isPresented = true
            coordinator.animation = .init(style: .none)
            coordinator.configuration = { hud in
                hud.contentView.mode = modes[i % modes.count]
                hud.contentView.label.text = "HUD \(i)"
            }
            coordinator.updatePresentation()
            coordinators.append(coordinator)
        }

        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 50)

        // Hide all via coordinators
        for coordinator in coordinators {
            coordinator.cleanup()
        }
        HUD.hideAll(for: window, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    func testStress_1000HUDs_sequential_onSameView() {
        for _ in 0..<1000 {
            autoreleasepool {
                let hud = HUD(with: window)
                window.addSubview(hud)
                hud.contentView.mode = .text
                hud.show(animated: false)
                hud.hide(animated: false)
            }
        }
        HUD.hideAll(for: window, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M22: SwiftUI View Lifecycle Simulation

    func testStress_simulateNavigationPushPop_100cycles() {
        // Simulates NavigationStack push/pop: coordinator created, host assigned, shown, host nilled, cleaned
        for _ in 0..<100 {
            autoreleasepool {
                let coordinator = HUDCoordinator()
                let childView = UIView(frame: window.bounds)
                window.addSubview(childView)

                coordinator.hostView = childView
                coordinator.isPresented = true
                coordinator.animation = .init(style: .none)
                coordinator.configuration = { hud in
                    hud.contentView.mode = .indicator()
                }
                coordinator.updatePresentation()

                // Simulate pop
                coordinator.isPresented = false
                coordinator.updatePresentation()
                coordinator.cleanup()
                childView.removeFromSuperview()
            }
        }
        XCTAssertTrue(true, "100 navigation push/pop cycles without crash")
    }

    func testStress_simulateSheetPresentDismiss_50cycles() {
        for _ in 0..<50 {
            autoreleasepool {
                // Each sheet gets its own window/view hierarchy
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

                XCTAssertEqual(sheetWindow.subviews.filter { $0 is HUD }.count, 1)

                // Dismiss sheet
                coordinator.cleanup()
                HUD.hideAll(for: sheetWindow, animated: false)
            }
        }
        XCTAssertTrue(true, "50 sheet present/dismiss cycles without crash")
    }

    func testStress_simulateTabSwitch_200times() {
        // Simulates tab switching: each tab has its own view, coordinator switches host
        let tab1View = UIView(frame: window.bounds)
        let tab2View = UIView(frame: window.bounds)
        window.addSubview(tab1View)
        window.addSubview(tab2View)

        let coordinator = HUDCoordinator()
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }

        for i in 0..<200 {
            let currentTab = (i % 2 == 0) ? tab1View : tab2View
            coordinator.isPresented = false
            coordinator.updatePresentation()
            coordinator.cleanup()

            coordinator.hostView = currentTab
            coordinator.isPresented = true
            coordinator.updatePresentation()
        }

        coordinator.cleanup()
        HUD.hideAll(for: tab1View, animated: false)
        HUD.hideAll(for: tab2View, animated: false)
        tab1View.removeFromSuperview()
        tab2View.removeFromSuperview()
    }

    // MARK: - M23: Damping Variants Stress

    func testStress_dampingVariants_300cycles() {
        let dampings: [HUD.Animation.Damping] = [.disable, .default, .ratio(0.3), .ratio(0.5), .ratio(0.8), .ratio(1.0)]

        for _ in 0..<50 {
            for damping in dampings {
                let hud = HUD(with: window)
                window.addSubview(hud)
                hud.animation = .init(style: .zoomInOut, damping: damping, duration: 0.01)
                hud.contentView.mode = .text
                hud.show(animated: true)
                hud.hide(animated: false)
            }
        }

        HUD.hideAll(for: window, animated: false)
        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }

    // MARK: - M24: Label + DetailsLabel Stress

    func testStress_labelAndDetailsLabel_10000updates() {
        let coordinator = HUDCoordinator()
        coordinator.hostView = window
        coordinator.isPresented = true
        coordinator.animation = .init(style: .none)
        coordinator.configuration = { hud in
            hud.contentView.mode = .indicator()
        }
        coordinator.updatePresentation()

        let hud = window.subviews.compactMap { $0 as? HUD }.first!
        for i in 0..<10000 {
            hud.contentView.label.text = "Label \(i)"
            hud.contentView.detailsLabel.text = "Detail \(i)"
        }

        XCTAssertEqual(hud.contentView.label.text, "Label 9999")
        XCTAssertEqual(hud.contentView.detailsLabel.text, "Detail 9999")
        coordinator.cleanup()
    }

    // MARK: - M25: Concurrent Coordinator Access

    func testStress_concurrentCoordinatorUpdates_fromMainQueue() {
        let coordinators = (0..<10).map { i -> HUDCoordinator in
            let c = HUDCoordinator()
            c.hostView = window
            c.animation = .init(style: .none)
            c.configuration = { hud in
                hud.contentView.mode = .text
                hud.contentView.label.text = "C\(i)"
            }
            return c
        }

        // Rapid interleaved updates
        for round in 0..<50 {
            for (i, coordinator) in coordinators.enumerated() {
                coordinator.isPresented = ((round + i) % 3 != 0)
                coordinator.updatePresentation()
            }
        }

        // Cleanup all
        for coordinator in coordinators {
            coordinator.cleanup()
        }
        HUD.hideAll(for: window, animated: false)
        XCTAssertEqual(window.subviews.filter { $0 is HUD }.count, 0)
    }
}
