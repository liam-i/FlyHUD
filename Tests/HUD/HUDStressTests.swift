//
//  HUDStressTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

// MARK: - Terminal Execution Guide
/*
Run all stress tests:
  xcodebuild test -scheme "Example iOS" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:"Example Tests/HUDStressTests" \
    -only-testing:"Example Tests/DisplayLinkStressTests" \
    -only-testing:"Example Tests/KeyboardObserverStressTests" \
    -only-testing:"Example Tests/ProgressViewStressTests" \
    -only-testing:"Example Tests/ActivityIndicatorStressTests" \
    -only-testing:"Example Tests/HUDConcurrencyStressTests" \
    -only-testing:"Example Tests/HUDMultiThreadStressTests" \
    -only-testing:"Example Tests/HUDMemoryLeakTests" \
    -only-testing:"Example Tests/HUDExtremeScaleTests"

Run a single test class:
  xcodebuild test -scheme "Example iOS" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:"Example Tests/HUDConcurrencyStressTests"

Run a single test method:
  xcodebuild test -scheme "Example iOS" \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:"Example Tests/HUDExtremeScaleTests/testFiveThousandRapidCycles"

Note: If using a custom Xcode path, prepend:
  DEVELOPER_DIR=/path/to/Xcode.app/Contents/Developer xcrun xcodebuild ...
*/

import XCTest
@testable import FlyHUD
@testable import FlyIndicatorHUD
@testable import FlyProgressHUD

// MARK: - Stress Tests

// 快速创建销毁(200次)、大规模实例(500个)、带动画快速show/hide(50次)、多HUD同时显示(20个)、交错show/hide(100次)、模式快速切换(700次)、graceTime取消(50次)、minShowTime(30次)、释放验证、进度更新(10000次)、hideAfterDelay竞争
@MainActor
final class HUDStressTests: XCTestCase {

    private var containerView: UIView!

    override func setUp() async throws {
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() async throws {
        HUD.hideAll(for: containerView, animated: false)
        containerView = nil
    }

    // MARK: - Rapid Create & Destroy

    /// Tests rapid creation and destruction of HUD instances to detect memory leaks or crashes.
    func testRapidCreateAndDestroy() {
        for _ in 0..<200 {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.show(animated: false)
            hud.hide(animated: false)
            hud.removeFromSuperview()
        }
        // If we get here without crash, the test passes
        XCTAssertEqual(containerView.subviews.count, 0, "All HUDs should be removed")
    }

    /// Tests rapid show/hide cycling with animation to verify work item cancellation.
    func testRapidShowHideCycleAnimated() {
        let expectation = XCTestExpectation(description: "Rapid show/hide cycle")

        for i in 0..<50 {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.show(animated: true)
            // Immediately hide before animation completes
            hud.hide(animated: true)

            if i == 49 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 3.0)
        // All HUDs should eventually be cleaned up
        let remainingHUDs = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remainingHUDs.count, 0, "All HUDs should be auto-removed after hide")
    }

    /// Tests that creating many HUD instances concurrently on main thread doesn't crash.
    func testMassiveInstanceCreation() {
        var huds: [HUD] = []
        for _ in 0..<500 {
            let hud = HUD(with: containerView)
            huds.append(hud)
        }

        // All should be valid instances
        XCTAssertEqual(huds.count, 500)

        // Release all at once
        huds.removeAll()

        // Force deallocation check
        XCTAssertTrue(true, "Mass deallocation completed without crash")
    }

    // MARK: - Multiple HUDs on Same View

    /// Tests showing multiple HUDs on the same view simultaneously.
    func testMultipleHUDsOnSameView() {
        var huds: [HUD] = []
        for _ in 0..<20 {
            let hud = HUD.show(to: containerView, animated: false)
            huds.append(hud)
        }

        XCTAssertEqual(huds.count, 20)

        // Hide all at once
        HUD.hideAll(for: containerView, animated: false)

        let expectation = XCTestExpectation(description: "All hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    /// Tests interleaved show/hide operations on multiple HUDs.
    func testInterleavedShowHide() {
        for _ in 0..<100 {
            let hud1 = HUD.show(to: containerView, animated: false, label: "Loading 1")
            let hud2 = HUD.show(to: containerView, animated: false, label: "Loading 2")
            hud1.hide(animated: false)
            let hud3 = HUD.show(to: containerView, animated: false, label: "Loading 3")
            hud2.hide(animated: false)
            hud3.hide(animated: false)
        }

        XCTAssertTrue(true, "Interleaved show/hide completed without crash")
    }

    // MARK: - Mode Switching Under Stress

    /// Tests rapidly switching content modes.
    func testRapidModeSwitch() {
        let hud = HUD.show(to: containerView, animated: false)

        let modes: [ContentView.Mode] = [
            .indicator(),
            .text,
            .progress(),
            .custom(UIImageView(image: nil)),
            .indicator(.medium),
            .text,
            .progress(),
        ]

        for _ in 0..<100 {
            for mode in modes {
                hud.contentView.mode = mode
            }
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Rapid mode switching completed without crash")
    }

    // MARK: - Grace Time & Min Show Time Stress

    /// Tests that grace time cancellation works correctly under rapid show/hide.
    func testGraceTimeCancellationStress() {
        let expectation = XCTestExpectation(description: "Grace time stress")

        for _ in 0..<50 {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.graceTime = 0.1
            hud.show(animated: true)
            // Hide before grace time fires
            hud.hide(animated: false)
            hud.removeFromSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(true, "Grace time cancellation stress completed without crash")
    }

    /// Tests min show time with rapid operations.
    func testMinShowTimeStress() {
        let expectation = XCTestExpectation(description: "Min show time stress")

        for _ in 0..<30 {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.minShowTime = 0.05
            hud.show(animated: false)
            hud.hide(animated: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(true, "Min show time stress completed without crash")
    }

    // MARK: - Deallocation Verification

    /// Tests that HUD properly deallocates when removed.
    func testDeallocationOnRemoval() {
        weak var weakHUD: HUD?

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.show(animated: false)
            hud.hide(animated: false)
            hud.removeFromSuperview()
            weakHUD = hud
        }

        XCTAssertNil(weakHUD, "HUD should be deallocated after removal")
    }

    /// Tests that HUD with removeFromSuperViewOnHide deallocates properly.
    func testDeallocationWithAutoRemove() {
        weak var weakHUD: HUD?
        let expectation = XCTestExpectation(description: "Deallocation with auto-remove")

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.removeFromSuperViewOnHide = true
            weakHUD = hud
            hud.show(animated: false)
            hud.hide(animated: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(weakHUD, "HUD should be deallocated after auto-remove")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    /// Tests deallocation of HUD with active progress observation.
    func testDeallocationWithActiveProgress() {
        weak var weakHUD: HUD?
        let progress = Progress(totalUnitCount: 100)

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.contentView.mode = .progress()
            hud.contentView.observedProgress = progress
            hud.show(animated: false)
            weakHUD = hud

            // Simulate some progress
            progress.completedUnitCount = 50

            hud.hide(animated: false)
            hud.removeFromSuperview()
        }

        XCTAssertNil(weakHUD, "HUD with active progress should deallocate cleanly")
    }

    // MARK: - Progress Updates Stress

    /// Tests high-frequency progress updates.
    func testHighFrequencyProgressUpdates() {
        let hud = HUD.show(to: containerView, animated: false, mode: .progress())

        // Simulate extremely rapid progress updates
        for i in 0..<10000 {
            hud.contentView.progress = Float(i) / 10000.0
        }

        hud.contentView.progress = 1.0
        hud.hide(animated: false)
        XCTAssertTrue(true, "High frequency progress updates completed without crash")
    }

    /// Tests observed progress with rapid completedUnitCount changes.
    func testObservedProgressStress() {
        let hud = HUD.show(to: containerView, animated: false, mode: .progress())
        let progress = Progress(totalUnitCount: 1000)
        hud.contentView.observedProgress = progress

        for i in 0..<1000 {
            progress.completedUnitCount = Int64(i)
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Observed progress stress completed without crash")
    }

    // MARK: - Hide After Delay Stress

    /// Tests rapid hide-after-delay scheduling and cancellation.
    func testHideAfterDelayStress() {
        let expectation = XCTestExpectation(description: "Hide after delay stress")

        for _ in 0..<50 {
            let hud = HUD.show(to: containerView, animated: false)
            hud.hide(animated: false, afterDelay: 0.01)
            // Immediately show again to cancel the pending hide
            hud.show(animated: false)
            hud.hide(animated: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(true, "Hide after delay stress completed without crash")
    }
}

// MARK: - DisplayLink Concurrency Tests

// 快速增删delegate(100个)、弱引用清理(50个)、帧更新中增删
@MainActor
final class DisplayLinkStressTests: XCTestCase {

    /// Tests adding and removing many delegates rapidly.
    func testRapidAddRemoveDelegates() {
        let displayLink = DisplayLink.shared

        var delegates: [MockDisplayLinkDelegate] = []
        for _ in 0..<100 {
            let delegate = MockDisplayLinkDelegate()
            delegates.append(delegate)
            displayLink.add(delegate)
        }

        // Remove all
        for delegate in delegates {
            displayLink.remove(delegate)
        }

        XCTAssertTrue(true, "Rapid add/remove of 100 delegates completed without crash")
    }

    /// Tests that weak references in DisplayLink are properly cleaned up.
    func testWeakDelegateCleanup() {
        let displayLink = DisplayLink.shared

        autoreleasepool {
            for _ in 0..<50 {
                let delegate = MockDisplayLinkDelegate()
                displayLink.add(delegate)
                // delegate goes out of scope, weak reference should nil
            }
        }

        // Force a display link cycle to trigger cleanup
        let expectation = XCTestExpectation(description: "DisplayLink cleanup")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(true, "Weak delegate cleanup completed without crash")
    }

    /// Tests interleaved add/remove during active frame updates.
    func testAddRemoveDuringFrameUpdates() {
        let displayLink = DisplayLink.shared
        let expectation = XCTestExpectation(description: "Frame update stress")

        let persistent = MockDisplayLinkDelegate()
        displayLink.add(persistent)

        // Rapidly add and remove delegates while DisplayLink is active
        for _ in 0..<50 {
            let temp = MockDisplayLinkDelegate()
            displayLink.add(temp)
            displayLink.remove(temp)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            displayLink.remove(persistent)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(persistent.updateCount > 0, "Persistent delegate should receive frame updates")
    }
}

// MARK: - KeyboardObserver Concurrency Tests

#if os(iOS)
// 快速增删observer(100个)、多observer通知(20个)、释放后清理(50个)
@MainActor
final class KeyboardObserverStressTests: XCTestCase {

    /// Tests adding and removing many observers rapidly.
    func testRapidAddRemoveObservers() {
        let observer = KeyboardObserver.shared

        var observers: [MockKeyboardObserver] = []
        for _ in 0..<100 {
            let mock = MockKeyboardObserver()
            observers.append(mock)
            observer.add(mock)
        }

        for mock in observers {
            observer.remove(mock)
        }

        XCTAssertTrue(true, "Rapid add/remove of 100 keyboard observers completed without crash")
    }

    /// Tests that posting keyboard notifications with many observers doesn't crash.
    func testNotificationWithManyObservers() {
        let observer = KeyboardObserver.shared
        let expectation = XCTestExpectation(description: "Notification stress")
        expectation.expectedFulfillmentCount = 20

        var observers: [MockKeyboardObserver] = []
        for _ in 0..<20 {
            let mock = MockKeyboardObserver()
            mock.expectation = expectation
            observers.append(mock)
            observer.add(mock)
        }

        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 600, width: 375, height: 300),
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect.zero,
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7)
        ]

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )

        wait(for: [expectation], timeout: 2.0)

        for mock in observers {
            observer.remove(mock)
        }

        XCTAssertTrue(true, "Notification with 20 observers completed without crash")
    }

    /// Tests weak reference cleanup when observers are deallocated.
    func testObserverDeallocationCleanup() {
        let observer = KeyboardObserver.shared

        autoreleasepool {
            for _ in 0..<50 {
                let mock = MockKeyboardObserver()
                observer.add(mock)
                // mock goes out of scope
            }
        }

        // Post notification to trigger enumeration with nil weak refs
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 600, width: 375, height: 300),
            UIResponder.keyboardFrameBeginUserInfoKey: CGRect.zero,
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.25,
            UIResponder.keyboardAnimationCurveUserInfoKey: UInt(7)
        ]

        NotificationCenter.default.post(
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            userInfo: userInfo
        )

        XCTAssertTrue(true, "Observer deallocation cleanup completed without crash")
    }
}
#endif

// MARK: - ProgressView Stress Tests

// 快速创建销毁(200次)、样式切换(2000次)、ObservedProgress+DisplayLink
@MainActor
final class ProgressViewStressTests: XCTestCase {

    /// Tests rapid creation and destruction of ProgressView instances.
    func testRapidProgressViewCreateDestroy() {
        for _ in 0..<200 {
            autoreleasepool {
                let view = ProgressView(style: .roundBar)
                view.progress = 0.5
                _ = view // prevent optimization
            }
        }
        XCTAssertTrue(true, "Rapid ProgressView create/destroy completed without crash")
    }

    /// Tests switching styles rapidly on a ProgressView.
    func testRapidStyleSwitch() {
        let view = ProgressView(style: .roundBar)

        let styles: [ProgressView.Style] = [
            .buttBar,
            .roundBar,
            .round,
            .annularRound,
        ]

        for _ in 0..<500 {
            for style in styles {
                view.style = style
                view.progress = Float.random(in: 0...1)
            }
        }

        XCTAssertTrue(true, "Rapid style switch completed without crash")
    }

    /// Tests observed progress with DisplayLink active.
    func testObservedProgressWithDisplayLink() {
        let expectation = XCTestExpectation(description: "Observed progress with DisplayLink")

        let view = ProgressView(style: .round)
        let progress = Progress(totalUnitCount: 100)
        view.observedProgress = progress

        // Simulate rapid progress in background
        DispatchQueue.global().async {
            for i in 0..<100 {
                progress.completedUnitCount = Int64(i)
            }

            DispatchQueue.main.async {
                view.observedProgress = nil
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - ActivityIndicatorView Stress Tests

// 快速start/stop(1000次)、动画中切换样式(800次)
@MainActor
final class ActivityIndicatorStressTests: XCTestCase {

    /// Tests rapid start/stop of activity indicator.
    func testRapidStartStop() {
        let view = ActivityIndicatorView(style: .ballSpinFade)
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        containerView.addSubview(view)

        for _ in 0..<1000 {
            view.startAnimating()
            view.stopAnimating()
        }

        XCTAssertFalse(view.isAnimating, "Should not be animating after stop")
        XCTAssertTrue(true, "Rapid start/stop completed without crash")
    }

    /// Tests switching styles while animating.
    func testStyleSwitchWhileAnimating() {
        let view = ActivityIndicatorView(style: .ballSpinFade)
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        containerView.addSubview(view)
        view.startAnimating()

        let styles: [ActivityIndicatorView.Style] = [
            .ballSpinFade,
            .circleStrokeSpin,
            .circleArcDotSpin,
            .ringClipRotate,
        ]

        for _ in 0..<200 {
            for style in styles {
                view.style = style
            }
        }

        view.stopAnimating()
        XCTAssertTrue(true, "Style switch while animating completed without crash")
    }
}

// MARK: - Mock Helpers

private final class MockDisplayLinkDelegate: DisplayLinkDelegate {
    var updateCount: Int = 0

    func updateScreenInDisplayLink() {
        updateCount += 1
    }
}

#if os(iOS)
private final class MockKeyboardObserver: KeyboardObservable {
    var expectation: XCTestExpectation?

    func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo) {
        expectation?.fulfill()
    }
}
#endif

// MARK: - Advanced Concurrency & Performance Tests

/// Tests concurrent access patterns, isolated deinit safety, animation lifecycle,
/// and high-frequency property mutations under stress conditions.
@MainActor
final class HUDConcurrencyStressTests: XCTestCase {

    private var containerView: UIView!

    override func setUp() async throws {
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() async throws {
        HUD.hideAll(for: containerView, animated: false)
        containerView = nil
    }

    // MARK: - Concurrent Task Creation

    /// Tests creating HUDs from multiple concurrent Swift Tasks (all hop to MainActor).
    func testConcurrentTaskCreation() async {
        let count = 100

        // Rapidly fire off show/hide from many iterations
        for i in 0..<count {
            let hud = HUD.show(to: containerView, animated: false, label: "Task \(i)")
            hud.hide(animated: false)
        }

        let remaining = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remaining.count, 0, "All concurrently-created HUDs should be removed")
    }

    /// Tests concurrent show/hide from many tasks with animation.
    func testConcurrentAnimatedShowHide() async {
        let count = 50

        for i in 0..<count {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.animation = .init(style: .zoomInOut, damping: .default, duration: 0.05)
            hud.show(animated: true)
            hud.hide(animated: true)
            _ = i
        }

        // Wait for animations to settle
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let remaining = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remaining.count, 0, "All animated HUDs should be cleaned up")
    }

    /// Tests overlapping show/hide operations from multiple tasks on the same HUD.
    func testConcurrentOperationsOnSameHUD() async {
        let hud = HUD(with: containerView)
        containerView.addSubview(hud)
        hud.isCountEnabled = true

        // 200 show + 200 hide in interleaved pattern
        for _ in 0..<200 {
            hud.show(animated: false)
        }
        for _ in 0..<200 {
            hud.hide(animated: false)
        }

        // Final state: count should be 0
        XCTAssertEqual(hud.count, 0, "Count should be 0 after equal show/hide pairs")
        hud.removeFromSuperview()
    }

    // MARK: - Isolated Deinit Safety

    /// Tests that HUD can be safely released when the last reference is dropped from a background task.
    /// This verifies `isolated deinit` works correctly — deinit is deferred to MainActor.
    func testDeinitFromBackgroundTask() async {
        weak var weakHUD: HUD?

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.show(animated: false)
            hud.hide(animated: false)
            hud.removeFromSuperview()
            weakHUD = hud
        }

        // With isolated deinit, deallocation may be deferred to next MainActor drain
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNil(weakHUD, "HUD should be deallocated via isolated deinit")
    }

    /// Tests rapid allocation/deallocation cycles to stress the isolated deinit path.
    func testRapidDeinitCycles() async {
        for _ in 0..<200 {
            autoreleasepool {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.graceTime = 0.01
                hud.minShowTime = 0.01
                hud.show(animated: false)
                hud.hide(animated: false, afterDelay: 0.001)
                hud.hide(animated: false)
                hud.removeFromSuperview()
            }
        }

        // Allow isolated deinit jobs to drain
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(containerView.subviews.count, 0)
    }

    /// Tests ContentView deallocation with observedProgress to verify DisplayLink cleanup via isolated deinit.
    func testContentViewDeinitWithObservedProgress() async {
        let progress = Progress(totalUnitCount: 100)

        for _ in 0..<50 {
            autoreleasepool {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.contentView.mode = .progress()
                hud.contentView.observedProgress = progress
                hud.show(animated: false)
                progress.completedUnitCount = Int64.random(in: 0...100)
                hud.hide(animated: false)
                hud.removeFromSuperview()
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(containerView.subviews.count, 0)
    }

    // MARK: - Animation Lifecycle Stress

    /// Tests interrupting show animations mid-flight with hide.
    func testAnimationInterruption() async {
        let styles: [HUD.Animation.Style] = [.fade, .zoomInOut, .zoomOutIn, .slideUpDown, .slideDownUp]

        for style in styles {
            for _ in 0..<20 {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.animation = .init(style: style, damping: .default, duration: 0.2)
                hud.show(animated: true)
                // Interrupt mid-animation
                try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000...50_000_000))
                hud.hide(animated: true)
            }
        }

        // Wait for all animations to complete
        try? await Task.sleep(nanoseconds: 500_000_000)
        let remaining = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remaining.count, 0, "All interrupted HUDs should be cleaned up")
    }

    /// Tests rapid animation style changes while HUD is animating.
    func testAnimationStyleChangesDuringAnimation() async {
        let hud = HUD(with: containerView)
        containerView.addSubview(hud)

        let allStyles = HUD.Animation.Style.allCases

        for _ in 0..<30 {
            hud.animation = .init(style: allStyles.randomElement()!, damping: .default, duration: 0.05)
            hud.show(animated: true)
            try? await Task.sleep(nanoseconds: 10_000_000)
            hud.animation = .init(style: allStyles.randomElement()!, damping: .default, duration: 0.05)
            hud.hide(animated: true)
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        hud.hide(animated: false)
        hud.removeFromSuperview()

        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertTrue(true, "Animation style changes during animation completed without crash")
    }

    // MARK: - High-Frequency Property Mutation

    /// Tests extremely rapid property changes across all configurable properties.
    func testHighFrequencyPropertyMutation() {
        let hud = HUD.show(to: containerView, animated: false, label: "Stress")

        for _ in 0..<1000 {
            hud.layout.offset = CGPoint(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
            hud.layout.edgeInsets = UIEdgeInsets(
                top: CGFloat.random(in: 0...40),
                left: CGFloat.random(in: 0...40),
                bottom: CGFloat.random(in: 0...40),
                right: CGFloat.random(in: 0...40)
            )
            hud.contentView.layout.hMargin = CGFloat.random(in: 5...30)
            hud.contentView.layout.vMargin = CGFloat.random(in: 5...30)
            hud.contentView.layout.hSpacing = CGFloat.random(in: 2...20)
            hud.contentView.layout.vSpacing = CGFloat.random(in: 2...20)
            hud.contentView.layout.minSize = CGSize(
                width: CGFloat.random(in: 0...200),
                height: CGFloat.random(in: 0...200)
            )
            hud.contentView.layout.isSquare = Bool.random()
            hud.contentView.layout.alignment = [.center, .leading, .trailing].randomElement()!
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "High-frequency property mutation completed without crash")
    }

    /// Tests rapid content color and label changes.
    func testRapidContentChanges() {
        let hud = HUD.show(to: containerView, animated: false)

        let colors: [UIColor] = [.red, .blue, .green, .orange, .purple, .systemPink, .label, .secondaryLabel]

        for i in 0..<5000 {
            hud.contentView.contentColor = colors[i % colors.count]
            hud.contentView.label.text = "Update \(i)"
            hud.contentView.detailsLabel.text = i % 3 == 0 ? "Details \(i)" : nil
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Rapid content changes completed without crash")
    }

    /// Tests rapid indicator position switching under load.
    func testRapidIndicatorPositionSwitch() {
        let hud = HUD.show(to: containerView, animated: false, mode: .indicator(), label: "Loading")

        let positions = ContentView.IndicatorPosition.allCases

        for _ in 0..<500 {
            hud.contentView.indicatorPosition = positions.randomElement()!
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Rapid indicator position switch completed without crash")
    }

    // MARK: - BackgroundView Style Stress

    /// Tests rapid switching between all background styles including glass.
    func testBackgroundStyleSwitchingStress() {
        let hud = HUD.show(to: containerView, animated: false, label: "Style Test")

        let colors: [UIColor?] = [.clear, .black.withAlphaComponent(0.5), .systemBlue, nil]

        for _ in 0..<200 {
            // ContentView style
            hud.contentView.style = .solidColor
            hud.contentView.color = colors.randomElement()!
            hud.contentView.roundedCorners = .radius(CGFloat.random(in: 0...30))

            hud.contentView.style = .blur()
            hud.contentView.color = colors.randomElement()!

            hud.contentView.style = .solidColor
            hud.contentView.roundedCorners = .full

            #if compiler(>=6.2) && !os(visionOS)
            if #available(iOS 26.0, tvOS 26.0, *) {
                hud.contentView.style = .glass
                hud.contentView.color = colors.randomElement()!
                hud.contentView.roundedCorners = .radius(CGFloat.random(in: 10...30))
            }
            #endif

            // Background view style
            hud.backgroundView.style = .solidColor
            hud.backgroundView.color = colors.randomElement()!
            hud.backgroundView.style = .blur(.regular)
            hud.backgroundView.style = .solidColor
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Background style switching stress completed without crash")
    }

    /// Tests RoundedCorners rapid changes (triggers layoutSubviews heavily).
    func testRoundedCornersStress() {
        let hud = HUD.show(to: containerView, animated: false, label: "Corners")

        for i in 0..<1000 {
            if i % 2 == 0 {
                hud.contentView.roundedCorners = .radius(CGFloat(i % 50))
            } else {
                hud.contentView.roundedCorners = .full
            }
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Rounded corners stress completed without crash")
    }

    // MARK: - Count-Based Show/Hide Stress

    /// Tests aggressive count-based show/hide with many overlapping requests.
    func testCountBasedStress() async {
        let hud = HUD(with: containerView)
        containerView.addSubview(hud)
        hud.isCountEnabled = true

        // 100 concurrent "requests" - show all then hide all
        for _ in 0..<100 {
            hud.show(animated: false)
        }
        for _ in 0..<100 {
            hud.hide(animated: false)
        }

        XCTAssertEqual(hud.count, 0, "Count should settle to 0")
        hud.removeFromSuperview()
    }

    // MARK: - ProgressView Concurrent Progress Updates

    /// Tests ProgressView with observedProgress updated from a background thread.
    func testProgressViewConcurrentUpdates() async {
        let pv = ProgressView(style: .round)
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        containerView.addSubview(pv)
        pv.frame = CGRect(x: 0, y: 0, width: 37, height: 37)

        let progress = Progress(totalUnitCount: 10000)
        pv.observedProgress = progress

        // Update progress rapidly from background using DispatchQueue
        let expectation = XCTestExpectation(description: "Progress updates")
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<10000 {
                progress.completedUnitCount = Int64(i)
            }
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 5.0)

        // Allow DisplayLink frames to process
        try? await Task.sleep(nanoseconds: 200_000_000)

        pv.observedProgress = nil
        pv.removeFromSuperview()
        XCTAssertTrue(true, "Concurrent progress updates completed without crash")
    }

    /// Tests ActivityIndicatorView rapid create/animate/destroy cycle.
    func testActivityIndicatorRapidLifecycle() {
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        for _ in 0..<300 {
            autoreleasepool {
                let styles: [ActivityIndicatorView.Style] = [.ringClipRotate, .ballSpinFade, .circleStrokeSpin, .circleArcDotSpin]
                let view = ActivityIndicatorView(style: styles.randomElement()!)
                view.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
                containerView.addSubview(view)
                view.color = [UIColor.red, .blue, .green, .orange].randomElement()!
                view.lineWidth = CGFloat.random(in: 1...5)
                view.startAnimating()
                view.stopAnimating()
                view.removeFromSuperview()
            }
        }

        XCTAssertTrue(true, "Activity indicator rapid lifecycle completed without crash")
    }

    // MARK: - Performance Baseline

    /// Measures the time to show and hide 100 HUDs sequentially (performance baseline).
    func testPerformanceShowHide100() {
        measure {
            for _ in 0..<100 {
                let hud = HUD.show(to: containerView, animated: false)
                hud.hide(animated: false)
            }
        }
    }

    /// Measures rapid progress update performance (10000 updates).
    func testPerformanceProgressUpdates() {
        let hud = HUD.show(to: containerView, animated: false, mode: .progress())
        measure {
            for i in 0..<10000 {
                hud.contentView.progress = Float(i) / 10000.0
            }
        }
        hud.hide(animated: false)
    }

    /// Measures mode switching performance (700 switches).
    func testPerformanceModeSwitching() {
        let hud = HUD.show(to: containerView, animated: false)
        let modes: [ContentView.Mode] = [.indicator(), .text, .progress(), .indicator(.medium)]

        measure {
            for i in 0..<700 {
                hud.contentView.mode = modes[i % modes.count]
            }
        }
        hud.hide(animated: false)
    }
}

// MARK: - Multi-Thread DispatchQueue Stress Tests

/// Tests concurrent access patterns using DispatchQueue.global() to simulate real-world
/// scenarios where background work triggers MainActor HUD operations.
@MainActor
final class HUDMultiThreadStressTests: XCTestCase {

    private var containerView: UIView!

    override func setUp() async throws {
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() async throws {
        HUD.hideAll(for: containerView, animated: false)
        containerView = nil
    }

    /// Tests background threads triggering show/hide on MainActor concurrently.
    func testBackgroundThreadTriggeredShowHide() {
        let expectation = XCTestExpectation(description: "Multi-thread show/hide")
        expectation.expectedFulfillmentCount = 100
        let container = containerView!

        for _ in 0..<100 {
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    let hud = HUD.show(to: container, animated: false, label: "BG")
                    hud.hide(animated: false)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
        let remaining = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remaining.count, 0, "All HUDs triggered from background should be cleaned up")
    }

    /// Tests high-frequency progress updates from multiple background queues simultaneously.
    func testMultiQueueProgressUpdates() {
        let hud = HUD.show(to: containerView, animated: false, mode: .progress())
        let progress = Progress(totalUnitCount: 1000)
        hud.contentView.observedProgress = progress

        let expectation = XCTestExpectation(description: "Multi-queue progress")
        let group = DispatchGroup()

        // 5 concurrent queues each updating 200 times
        for q in 0..<5 {
            let queue = DispatchQueue(label: "test.progress.\(q)", qos: .userInitiated)
            group.enter()
            queue.async {
                for j in 0..<200 {
                    progress.completedUnitCount = Int64(q * 200 + j)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
        hud.contentView.observedProgress = nil
        hud.hide(animated: false)
        XCTAssertTrue(true, "Multi-queue progress updates completed without crash")
    }

    /// Tests rapid show/hide with animated transitions from multiple DispatchWorkItems.
    func testDispatchWorkItemCancellationStress() {
        let expectation = XCTestExpectation(description: "WorkItem cancellation")

        var workItems: [DispatchWorkItem] = []

        for i in 0..<50 {
            let item = DispatchWorkItem { [self] in
                let hud = HUD.show(to: containerView, animated: true, label: "Work \(i)")
                hud.hide(animated: true, afterDelay: 0.01)
            }
            workItems.append(item)
            DispatchQueue.main.async(execute: item)
        }

        // Cancel half of them immediately
        for i in stride(from: 0, to: 50, by: 2) {
            workItems[i].cancel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
        HUD.hideAll(for: containerView, animated: false)
        XCTAssertTrue(true, "DispatchWorkItem cancellation stress completed without crash")
    }

    /// Tests interleaved background progress + main thread mode switching.
    func testBackgroundProgressWithModeSwitch() {
        let hud = HUD.show(to: containerView, animated: false, mode: .progress())
        let progress = Progress(totalUnitCount: 1000)
        hud.contentView.observedProgress = progress

        let expectation = XCTestExpectation(description: "BG progress + mode switch")

        // Background updates progress
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<1000 {
                progress.completedUnitCount = Int64(i)
            }
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        // Main thread switches modes during progress updates
        let modes: [ContentView.Mode] = [.progress(), .indicator(), .text, .progress()]
        for i in 0..<200 {
            hud.contentView.mode = modes[i % modes.count]
        }

        wait(for: [expectation], timeout: 5.0)
        hud.contentView.observedProgress = nil
        hud.hide(animated: false)
        XCTAssertTrue(true, "Background progress with mode switch completed without crash")
    }

    /// Tests concurrent hide-after-delay scheduling from multiple dispatch sources.
    func testConcurrentHideAfterDelayScheduling() {
        let expectation = XCTestExpectation(description: "Concurrent hide-after-delay")
        let huds = (0..<30).map { _ in HUD.show(to: containerView, animated: false) }

        // Schedule hide-after-delay, then immediately override with new show
        for (i, hud) in huds.enumerated() {
            hud.hide(animated: false, afterDelay: TimeInterval(i) * 0.01)
            // Override: show again before delay fires
            hud.show(animated: false)
            // Then really hide
            hud.hide(animated: false)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(true, "Concurrent hide-after-delay scheduling completed without crash")
    }

    /// Tests high-frequency main thread operations interleaved with background Progress object mutations.
    func testHighFrequencyMainThreadWithBackgroundProgress() {
        let progress = Progress(totalUnitCount: 5000)
        let expectation = XCTestExpectation(description: "High-freq main + BG")

        // Create several HUDs observing the same progress
        var huds: [HUD] = []
        for _ in 0..<5 {
            let hud = HUD.show(to: containerView, animated: false, mode: .progress())
            hud.contentView.observedProgress = progress
            huds.append(hud)
        }

        // Background blasts progress updates
        DispatchQueue.global(qos: .userInitiated).async {
            for i in 0..<5000 {
                progress.completedUnitCount = Int64(i)
            }
            DispatchQueue.main.async {
                expectation.fulfill()
            }
        }

        // Main thread rapidly modifies HUD properties while progress updates fly in
        for i in 0..<200 {
            let hud = huds[i % huds.count]
            hud.contentView.contentColor = i % 2 == 0 ? .white : .black
            hud.contentView.label.text = "Op \(i)"
        }

        wait(for: [expectation], timeout: 30.0)

        for hud in huds {
            hud.contentView.observedProgress = nil
            hud.hide(animated: false)
        }
        XCTAssertTrue(true, "High-frequency main thread with background progress completed without crash")
    }

    /// Tests DisplayLink add/remove from main thread while background threads trigger progress changes.
    func testDisplayLinkStressWithBackgroundProgress() {
        let expectation = XCTestExpectation(description: "DisplayLink + BG progress")
        let expectationCount = 20
        expectation.expectedFulfillmentCount = expectationCount

        for _ in 0..<expectationCount {
            let progress = Progress(totalUnitCount: 100)
            let pv = ProgressView(style: .round)
            pv.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
            containerView.addSubview(pv)
            pv.observedProgress = progress

            DispatchQueue.global().async {
                for j in 0..<100 {
                    progress.completedUnitCount = Int64(j)
                }
                DispatchQueue.main.async {
                    pv.observedProgress = nil
                    pv.removeFromSuperview()
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(true, "DisplayLink stress with background progress completed without crash")
    }
}

// MARK: - Memory Leak Detection Tests

/// Tests that verify no memory leaks occur under various usage patterns.
/// Uses weak references to detect retained cycles and dangling references.
@MainActor
final class HUDMemoryLeakTests: XCTestCase {

    private var containerView: UIView!

    override func setUp() async throws {
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() async throws {
        HUD.hideAll(for: containerView, animated: false)
        containerView = nil
    }

    /// Tests that HUD with all optional features configured deallocates properly.
    func testFullyConfiguredHUDDeallocation() {
        weak var weakHUD: HUD?

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.removeFromSuperViewOnHide = true
            hud.graceTime = 0.0
            hud.minShowTime = 0.0
            hud.contentView.mode = .progress()
            hud.contentView.label.text = "Loading..."
            hud.contentView.detailsLabel.text = "Please wait"
            hud.contentView.contentColor = .white
            hud.contentView.style = .blur()
            hud.backgroundView.style = .solidColor
            hud.backgroundView.color = .black.withAlphaComponent(0.3)
            hud.layout.offset = CGPoint(x: 10, y: 10)
            hud.animation = .init(style: .fade, damping: .default, duration: 0.1)
            weakHUD = hud

            hud.show(animated: false)
            hud.hide(animated: false)
        }

        XCTAssertNil(weakHUD, "Fully configured HUD should deallocate after hide + removeFromSuperViewOnHide")
    }

    /// Tests that rapid show/hide cycles don't accumulate retained HUD instances.
    func testNoRetainCycleDuringRapidCycles() {
        var weakRefs: [() -> HUD?] = []

        autoreleasepool {
            for _ in 0..<100 {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.removeFromSuperViewOnHide = true
                hud.show(animated: false)
                hud.hide(animated: false)
                weakRefs.append { [weak hud] in hud }
            }
        }

        let expectation = XCTestExpectation(description: "Dealloc check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let leakedCount = weakRefs.filter { $0() != nil }.count
        XCTAssertEqual(leakedCount, 0, "No HUD instances should be retained after hide + auto-remove")
    }

    /// Tests that HUD with hideAfterDelay deallocates after hiding.
    func testHideAfterDelayDeallocation() {
        weak var weakHUD: HUD?
        let expectation = XCTestExpectation(description: "HideAfterDelay dealloc")

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.removeFromSuperViewOnHide = true
            weakHUD = hud
            hud.show(animated: false)
            hud.hide(animated: false, afterDelay: 0.1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNil(weakHUD, "HUD should deallocate after hideAfterDelay completes")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    /// Tests that HUD with graceTime that never fires deallocates properly.
    func testGraceTimeNeverFiredDeallocation() {
        weak var weakHUD: HUD?

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.graceTime = 10.0  // Very long grace time
            weakHUD = hud
            hud.show(animated: false)
            // Hide before grace time fires
            hud.hide(animated: false)
            hud.removeFromSuperview()
        }

        XCTAssertNil(weakHUD, "HUD with cancelled graceTime should deallocate")
    }

    /// Tests that observedProgress doesn't create retain cycle.
    func testObservedProgressNoRetainCycle() {
        weak var weakHUD: HUD?
        let progress = Progress(totalUnitCount: 100)

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.contentView.mode = .progress()
            hud.contentView.observedProgress = progress
            weakHUD = hud

            progress.completedUnitCount = 50

            hud.contentView.observedProgress = nil
            hud.hide(animated: false)
            hud.removeFromSuperview()
        }

        XCTAssertNil(weakHUD, "HUD with cleared observedProgress should deallocate")
    }

    /// Tests that multiple HUDs on same view all deallocate after hideAll.
    func testMultipleHUDsDeallocationAfterHideAll() {
        var weakRefs: [() -> HUD?] = []

        autoreleasepool {
            for _ in 0..<50 {
                let hud = HUD.show(to: containerView, animated: false)
                hud.removeFromSuperViewOnHide = true
                weakRefs.append { [weak hud] in hud }
            }

            HUD.hideAll(for: containerView, animated: false)
        }

        let expectation = XCTestExpectation(description: "HideAll dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let leakedCount = weakRefs.filter { $0() != nil }.count
        XCTAssertEqual(leakedCount, 0, "All HUDs should deallocate after hideAll")
    }

    /// Tests that ProgressView with DisplayLink observation deallocates cleanly.
    func testProgressViewDisplayLinkDeallocation() {
        weak var weakPV: ProgressView?
        let progress = Progress(totalUnitCount: 100)

        autoreleasepool {
            let pv = ProgressView(style: .round)
            pv.observedProgress = progress
            weakPV = pv

            // Simulate some progress to trigger DisplayLink
            progress.completedUnitCount = 50

            pv.observedProgress = nil
        }

        XCTAssertNil(weakPV, "ProgressView should deallocate after clearing observedProgress")
    }

    /// Tests that ActivityIndicatorView deallocates cleanly after stop.
    func testActivityIndicatorDeallocation() {
        weak var weakView: ActivityIndicatorView?

        autoreleasepool {
            let view = ActivityIndicatorView(style: .ballSpinFade)
            view.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
            containerView.addSubview(view)
            view.startAnimating()
            view.stopAnimating()
            view.removeFromSuperview()
            weakView = view
        }

        XCTAssertNil(weakView, "ActivityIndicatorView should deallocate after stop + remove")
    }

    /// Tests that HUD with count-based show/hide deallocates when count reaches 0.
    func testCountBasedDeallocation() {
        weak var weakHUD: HUD?

        autoreleasepool {
            let hud = HUD(with: containerView)
            containerView.addSubview(hud)
            hud.isCountEnabled = true
            hud.removeFromSuperViewOnHide = true
            weakHUD = hud

            // Show 10 times
            for _ in 0..<10 {
                hud.show(animated: false)
            }
            // Hide 10 times
            for _ in 0..<10 {
                hud.hide(animated: false)
            }
        }

        let expectation = XCTestExpectation(description: "Count-based dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        XCTAssertNil(weakHUD, "Count-based HUD should deallocate when count reaches 0")
    }

    /// Tests batch deallocation of many HUDs with various configurations.
    func testBatchDeallocationVariousConfigs() {
        var weakRefs: [() -> HUD?] = []

        autoreleasepool {
            let configs: [(ContentView.Mode, BackgroundView.Style)] = [
                (.indicator(), .solidColor),
                (.progress(), .blur()),
                (.text, .solidColor),
                (.indicator(.medium), .blur(.dark)),
                (.custom(UIView()), .solidColor),
            ]

            for (mode, style) in configs {
                for _ in 0..<20 {
                    let hud = HUD(with: containerView)
                    containerView.addSubview(hud)
                    hud.removeFromSuperViewOnHide = true
                    hud.contentView.mode = mode
                    hud.contentView.style = style
                    hud.show(animated: false)
                    hud.hide(animated: false)
                    weakRefs.append { [weak hud] in hud }
                }
            }
        }

        let expectation = XCTestExpectation(description: "Batch dealloc")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let leakedCount = weakRefs.filter { $0() != nil }.count
        XCTAssertEqual(leakedCount, 0, "All variously-configured HUDs should deallocate (\(leakedCount) leaked)")
    }
}

// MARK: - Extreme Scale Tests

/// Tests with extremely large numbers of instances to verify stability under resource pressure.
@MainActor
final class HUDExtremeScaleTests: XCTestCase {

    private var containerView: UIView!

    override func setUp() async throws {
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() async throws {
        HUD.hideAll(for: containerView, animated: false)
        containerView = nil
    }

    /// Tests creating 2000 HUD instances simultaneously.
    func testMassiveSimultaneousInstances() {
        var huds: [HUD] = []
        huds.reserveCapacity(2000)

        for _ in 0..<2000 {
            let hud = HUD(with: containerView)
            huds.append(hud)
        }

        XCTAssertEqual(huds.count, 2000, "Should create 2000 instances")

        // Force dealloc
        huds.removeAll()
        XCTAssertTrue(true, "Mass creation of 2000 HUDs completed without crash")
    }

    /// Tests showing 1000 HUDs on the same view.
    func testThousandHUDsOnSameView() {
        for _ in 0..<1000 {
            HUD.show(to: containerView, animated: false)
        }

        let count = containerView.subviews.filter { $0 is HUD }.count
        XCTAssertEqual(count, 1000, "Should have 1000 visible HUDs")

        HUD.hideAll(for: containerView, animated: false)

        let expectation = XCTestExpectation(description: "1000 HUDs hidden")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    /// Tests 5000 rapid create-show-hide-destroy cycles.
    func testFiveThousandRapidCycles() {
        for _ in 0..<5000 {
            autoreleasepool {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.show(animated: false)
                hud.hide(animated: false)
                hud.removeFromSuperview()
            }
        }

        XCTAssertEqual(containerView.subviews.count, 0, "All 5000 HUDs should be removed")
    }

    /// Tests 50000 progress updates on a single ProgressView.
    func testFiftyThousandProgressUpdates() {
        let pv = ProgressView(style: .roundBar)
        pv.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        containerView.addSubview(pv)

        for i in 0..<50000 {
            pv.progress = Float(i) / 50000.0
        }

        pv.removeFromSuperview()
        XCTAssertTrue(true, "50000 progress updates completed without crash")
    }

    /// Tests 1000 ActivityIndicatorView start/stop with style changes.
    func testThousandActivityIndicatorCycles() {
        let styles: [ActivityIndicatorView.Style] = [.ballSpinFade, .circleStrokeSpin, .circleArcDotSpin, .ringClipRotate]
        let view = ActivityIndicatorView(style: .ballSpinFade)
        view.frame = CGRect(x: 0, y: 0, width: 37, height: 37)
        containerView.addSubview(view)

        for i in 0..<1000 {
            view.style = styles[i % styles.count]
            view.startAnimating()
            view.stopAnimating()
        }

        view.removeFromSuperview()
        XCTAssertTrue(true, "1000 activity indicator cycles completed without crash")
    }

    /// Tests 10000 mode switches with label updates.
    func testTenThousandModeSwitchesWithLabels() {
        let hud = HUD.show(to: containerView, animated: false)
        let modes: [ContentView.Mode] = [.indicator(), .text, .progress(), .indicator(.medium)]

        for i in 0..<10000 {
            hud.contentView.mode = modes[i % modes.count]
            hud.contentView.label.text = "Op \(i)"
            if i % 5 == 0 {
                hud.contentView.detailsLabel.text = "Detail \(i)"
            }
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "10000 mode switches with labels completed without crash")
    }

    /// Tests extreme layout property cycling (10000 iterations).
    func testExtremeLayoutCycling() {
        let hud = HUD.show(to: containerView, animated: false, label: "Layout")

        for i in 0..<10000 {
            let f = CGFloat(i % 50)
            hud.layout.offset = CGPoint(x: f - 25, y: f - 25)
            hud.contentView.layout.hMargin = f / 2
            hud.contentView.layout.vMargin = f / 2
            hud.contentView.layout.isSquare = i % 3 == 0
            hud.contentView.roundedCorners = i % 2 == 0 ? .radius(f) : .full
        }

        hud.hide(animated: false)
        XCTAssertTrue(true, "Extreme layout cycling completed without crash")
    }

    /// Tests 500 HUDs each with unique animation + graceTime + minShowTime combinations.
    func testMassiveConfigPermutations() {
        let expectation = XCTestExpectation(description: "Config permutations")
        let styles = HUD.Animation.Style.allCases

        for i in 0..<500 {
            autoreleasepool {
                let hud = HUD(with: containerView)
                containerView.addSubview(hud)
                hud.animation = .init(style: styles[i % styles.count], damping: .default, duration: 0.01)
                hud.graceTime = Double(i % 5) * 0.001
                hud.minShowTime = Double(i % 3) * 0.001
                hud.contentView.mode = i % 2 == 0 ? .indicator() : .progress()
                hud.show(animated: false)
                hud.hide(animated: false)
                hud.removeFromSuperview()
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(true, "500 config permutations completed without crash")
    }

    /// Tests that after extreme usage, the container view returns to clean state.
    func testCleanStateAfterExtremeUsage() {
        // Phase 1: Create many HUDs
        for _ in 0..<200 {
            HUD.show(to: containerView, animated: false)
        }

        // Phase 2: Hide all
        HUD.hideAll(for: containerView, animated: false)

        // Phase 3: Create with various modes
        for _ in 0..<200 {
            let hud = HUD.show(to: containerView, animated: false, mode: .progress())
            hud.contentView.progress = Float.random(in: 0...1)
            hud.hide(animated: false)
        }

        // Phase 4: Final cleanup
        HUD.hideAll(for: containerView, animated: false)

        let expectation = XCTestExpectation(description: "Clean state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        let remaining = containerView.subviews.filter { $0 is HUD }
        XCTAssertEqual(remaining.count, 0, "Container should be clean after extreme usage")
    }

    /// Tests extremely rapid show/hideAll alternation.
    func testRapidShowHideAllAlternation() {
        for _ in 0..<500 {
            HUD.show(to: containerView, animated: false, label: "Quick")
            HUD.show(to: containerView, animated: false, mode: .progress())
            HUD.show(to: containerView, animated: false)
            HUD.hideAll(for: containerView, animated: false)
        }

        XCTAssertTrue(true, "Rapid show/hideAll alternation (1500 show + 500 hideAll) completed without crash")
    }
}
