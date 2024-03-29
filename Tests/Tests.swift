import XCTest
import FlyHUD

class Tests: XCTestCase, HUDDelegate {
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try super.tearDownWithError()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testInitializers() {
        XCTAssertNotNil(HUD(with: UIView()))
        XCTAssertNotNil(HUD(frame: .zero))
        do {
            let dummyUnarchiver = try NSKeyedUnarchiver(forReadingFrom: Data())
            XCTAssertNotNil(HUD(coder: dummyUnarchiver))
        } catch {
//            XCTAssertThrowsError(error)
        }
    }

    func testNonAnimatedConvenienceHUDPresentation() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD.show(to: rootView, animated: false)
        XCTAssertNotNil(hud, "A HUD should be created.")

        FHTestHUDIsVisible(hud, rootView)

        XCTAssertEqual(hud.contentView.alpha, 1.0, "The HUD should be visible.")
        XCTAssertFalse(hud.contentView.layer.animationKeys()?.contains("opacity") ?? false, "The opacity should NOT be animated.")
        XCTAssertEqual(HUD.lastHUD(for: rootView), hud, "The HUD should be found via the convenience operation.")
        XCTAssertTrue(HUD.hide(for: rootView, animated: false), "The HUD should be found and removed.")
        FHTestHUDIsHidenAndRemoved(hud, rootView)
        XCTAssertFalse(HUD.hide(for: rootView, animated: false), "A subsequent HUD hide operation should fail.")
    }

    var hideExpectation: XCTestExpectation?
    var hideChecks: (() -> Void)?

    func testAnimatedConvenienceHUDPresentation() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")

        let hud = HUD.show(to: rootView)
        hud.delegate = self
        XCTAssertNotNil(hud, "A HUD should be created.")
        FHTestHUDIsVisible(hud, rootView)

        XCTAssertEqual(hud.contentView.alpha, 1.0, "The HUD should be visible.")
        XCTAssertTrue(hud.contentView.layer.animationKeys()?.contains("opacity") ?? false, "The opacity should be animated.")

        XCTAssertEqual(HUD.lastHUD(for: rootView), hud, "The HUD should be found via the convenience operation.")

        XCTAssertTrue(HUD.hide(for: rootView), "The HUD should be found and removed.")

        XCTAssertTrue(rootView.subviews.contains(hud), "The HUD should still be part of the view hierarchy.")
        XCTAssertEqual(hud.alpha, 1.0, "The hud should still be visible.")
        XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
        XCTAssertEqual(hud.contentView.alpha, 0.0, "The HUD bezel should be animated out.")
        XCTAssertTrue(hud.contentView.layer.animationKeys()?.contains("opacity") ?? false, "The opacity should be animated.")

        hideChecks = {
            FHTestHUDIsHidenAndRemoved(hud, rootView)
            XCTAssertFalse(HUD.hide(for: rootView), "A subsequent HUD hide operation should fail.")
        }

        waitForExpectations(timeout: 5)
    }

    func testCompletionBlock() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")
        let completionExpectation = expectation(description: "The completionBlock: should have been called.")

        let hud = HUD.show(to: rootView)
        hud.delegate = self
        hud.completionBlock = { hud in
            completionExpectation.fulfill()
        }
        hud.hide()

        waitForExpectations(timeout: 5)
    }

    func testRoundDeterminate() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.contentView.mode = .progress(.roundBar)
        rootView.addSubview(hud)
        hud.show(animated: false)

        FHTestHUDIsVisible(hud, rootView)
        XCTAssertNotNil(hud.firstSubview(ProgressView.self))
        XCTAssertTrue(HUD.hide(for: rootView, animated: false), "The HUD should be found and removed.")
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testBallSpinFade() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.contentView.mode = .indicator(.ballSpinFade)
        rootView.addSubview(hud)
        hud.show(animated: false)

        FHTestHUDIsVisible(hud, rootView)
        XCTAssertNotNil(hud.firstSubview(ActivityIndicatorView.self))
        XCTAssertTrue(HUD.hide(for: rootView, animated: false), "The HUD should be found and removed.")
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testEffectViewOrderAfterSettingBlurStyle() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.contentView.subviews.enumerated().forEach { idx, view in
            XCTAssert(!(view is UIVisualEffectView) || idx == 0, "Just the first subview should be a visual effect view.")
        }
        hud.contentView.style = .blur(.dark)
        hud.contentView.subviews.enumerated().forEach { idx, view in
            XCTAssert(!(view is UIVisualEffectView) || idx == 0, "Just the first subview should be a visual effect view even after changing the blurEffectStyle.")
        }
    }

    func testDelayedHide() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }
        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")

        let hud = HUD.show(to: rootView, animated: false)
        hud.delegate = self

        XCTAssertNotNil(hud, "A HUD should be created.")
        hud.hide(animated: false, afterDelay: 2)

        FHTestHUDIsVisible(hud, rootView)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FHTestHUDIsVisible(hud, rootView)
        }

        let hideCheckExpectation = expectation(description: "Hide check")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // After the grace time passes, the HUD should still not be shown.
            FHTestHUDIsHidenAndRemoved(hud, rootView)
            hideCheckExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testDelayedHideDoesNotRace() {
        // https://github.com/jdg/FHProgressHUD/issues/503
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.removeFromSuperViewOnHide = false
        rootView.addSubview(hud)

        hud.show(animated: true)
        hud.hide(animated: true, afterDelay: 0.3)
        FHTestHUDIsVisible(hud, rootView)

        print("-------------")
        let hideCheckExpectation = expectation(description: "Hide check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("++++++++++++++")
            hud.show(animated: true)
            hud.hide(animated: true, afterDelay: 0.3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                FHTestHUDIsHiden(hud, rootView)
                hideCheckExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5)
        hud.removeFromSuperview()
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }


    func testNonAnimatedHudReuse() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.removeFromSuperViewOnHide = false
        rootView.addSubview(hud)
        hud.show(animated: false)

        XCTAssertNotNil(hud, "A HUD should be created.")

        hud.hide(animated: false)
        hud.show(animated: false)

        FHTestHUDIsVisible(hud, rootView)
        hud.hide(animated: false)
        hud.removeFromSuperview()
    }

    func testUnfinishedHidingAnimation() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD.show(to: rootView, animated: false)
        hud.hide(animated: true)

        // Cancel all animations. It will cause `UIView+animate...` to call completionBlock with `finished = NO`.
        // It's same as if you call `hud.hide(animated: true)` while the app is in background.
        hud.contentView.layer.removeAllAnimations()
        hud.backgroundView.layer.removeAllAnimations()

        let hideCheckExpectation = expectation(description: "Hide check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // After the grace time passes, the HUD should still not be shown.
            FHTestHUDIsHidenAndRemoved(hud, rootView)
            hideCheckExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testAnimatedImmediateHudReuse() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hideExpectation = expectation(description: "The hud should have been hidden.")

        let hud = HUD(with: rootView)
        hud.removeFromSuperViewOnHide = false
        rootView.addSubview(hud)
        hud.show(animated: true)

        XCTAssertNotNil(hud, "A HUD should be created.")

        hud.hide(animated: true)
        hud.show(animated: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            FHTestHUDIsVisible(hud, rootView)
            hud.hide(animated: false)
            hud.removeFromSuperview()
            hideExpectation.fulfill()
        }
        waitForExpectations(timeout: 5)
    }

    func testMinShowTime() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")

        let hud = HUD(with: rootView)
        hud.delegate = self
        hud.minShowTime = 2
        rootView.addSubview(hud)
        hud.show(animated: true)

        XCTAssertNotNil(hud, "A HUD should be created.")

        hud.hide(animated: true)

        var checkedAfterOneSecond = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Check that the hud is still visible
            FHTestHUDIsVisible(hud, rootView)
            checkedAfterOneSecond = true
        }

        hideChecks = {
            XCTAssertTrue(checkedAfterOneSecond)
        }

        waitForExpectations(timeout: 5)
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testGraceTime() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")

        let hud = HUD(with: rootView)
        hud.delegate = self
        hud.graceTime = 2
        rootView.addSubview(hud)
        hud.show(animated: true)

        XCTAssertNotNil(hud, "A HUD should be created.")

        // The HUD should be added to the view but still hidden
        XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
//        XCTAssertEqual(hud.alpha, 0.0, "The HUD should not be visible.")
//        XCTAssertFalse(hud.isHidden, "The HUD should be visible.")
        XCTAssertTrue(hud.isHidden, "The HUD should not be visible.")
        XCTAssertEqual(hud.contentView.alpha, 0.0, "The HUD should not be visible.")


        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // The HUD should be added to the view but still hidden
            XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
//            XCTAssertEqual(hud.alpha, 0.0, "The HUD should not be visible.")
//            XCTAssertFalse(hud.isHidden, "The HUD should be visible.")
            XCTAssertTrue(hud.isHidden, "The HUD should not be visible.")
            XCTAssertEqual(hud.contentView.alpha, 0.0, "The HUD should not be visible.")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // After the grace time passes, the HUD should be shown.
            FHTestHUDIsVisible(hud, rootView)
            hud.hide(animated: true)
        }

        waitForExpectations(timeout: 5)
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testHideBeforeGraceTimeElapsed() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        hideExpectation = expectation(description: "The hudWasHidden: delegate should have been called.")

        let hud = HUD(with: rootView)
        hud.delegate = self
        hud.graceTime = 2
        rootView.addSubview(hud)
        hud.show(animated: true)

        XCTAssertNotNil(hud, "A HUD should be created.")

        // The HUD should be added to the view but still hidden
        XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
//        XCTAssertEqual(hud.alpha, 0.0, "The HUD should not be visible.")
//        XCTAssertFalse(hud.isHidden, "The HUD should be visible.")
        XCTAssertTrue(hud.isHidden, "The HUD should not be visible.")
        XCTAssertEqual(hud.contentView.alpha, 0.0, "The HUD should not be visible.")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // The HUD should be added to the view but still hidden
            XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
//            XCTAssertEqual(hud.alpha, 0.0, "The HUD should not be visible.")
//            XCTAssertFalse(hud.isHidden, "The HUD should be visible.")
            XCTAssertTrue(hud.isHidden, "The HUD should not be visible.")
            XCTAssertEqual(hud.contentView.alpha, 0.0, "The HUD should not be visible.")
            hud.hide(animated: true)
        }

        let hideCheckExpectation = expectation(description: "Hide check")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // After the grace time passes, the HUD should still not be shown.
            FHTestHUDIsHidenAndRemoved(hud, rootView)
            hideCheckExpectation.fulfill()
        }

        waitForExpectations(timeout: 5)
        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func testShape() {
        let rootView = UIApplication.getKeyWindow?.rootViewController?.view
        XCTAssertNotNil(rootView)
        guard let rootView else { return }

        let hud = HUD(with: rootView)
        hud.layout.offset = CGPoint(x: 50, y: 50)
        hud.contentView.layout.isSquare = true
        hud.contentView.label.text = "Some long text..."
        rootView.addSubview(hud)
        hud.show(animated: false)

        hud.setNeedsLayout()
        hud.layoutIfNeeded()
        let frame = hud.contentView.frame
        XCTAssertEqual(frame.width, frame.height)
        hud.hide(animated: false)

        FHTestHUDIsHidenAndRemoved(hud, rootView)
    }

    func hudWasHidden(_ hud: FlyHUD.HUD) {
        hideChecks?()
        hideChecks = nil

        hideExpectation?.fulfill()
        hideExpectation = nil
    }
}

func FHTestHUDIsVisible(_ hud: HUD, _ rootView: UIView) {
    XCTAssertEqual(hud.superview, rootView, "The hud should be added to the view.")
    XCTAssertEqual(hud.alpha, 1.0, "The HUD should be visible.")
    XCTAssertFalse(hud.isHidden, "The HUD should be visible.")
    XCTAssertEqual(hud.contentView.alpha, 1.0, "The HUD should be visible.")
}

func FHTestHUDIsHidenAndRemoved(_ hud: HUD, _ rootView: UIView) {
    XCTAssertFalse(rootView.subviews.contains(hud), "The HUD should not be part of the view hierarchy.")
    FHTestHUDIsHiden(hud, rootView)
    XCTAssertNil(hud.superview, "The HUD should not have a superview.")
}

func FHTestHUDIsHiden(_ hud: HUD, _ rootView: UIView) {
    print("hud.isHidden=\(hud.isHidden)")
    XCTAssertTrue(hud.isHidden, "The hud should be faded out.")
//    XCTAssertEqual(hud.alpha, 0.0, "The hud should be faded out.")
}

extension UIView {
    fileprivate func firstSubview(_ clazz: UIView.Type) -> UIView? {
        for subview in subviews where subview.isKind(of: clazz) {
            return subview
        }

        var theView: UIView?
        for subview in subviews {
            theView = subview.firstSubview(clazz)
            if theView != nil { break }
        }
        return theView
    }
}
