# Testing Guide

Strategies for unit testing, integration testing, and mocking FlyHUD in your app.

## Unit Testing HUD Logic

### Testing HUD Display State

```swift
import XCTest
@testable import FlyHUD

@MainActor
final class HUDDisplayTests: XCTestCase {
    var containerView: UIView!

    override func setUp() {
        super.setUp()
        containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    }

    override func tearDown() {
        containerView = nil
        super.tearDown()
    }

    func testShowAddsHUDToView() {
        let hud = HUD.show(to: containerView, animated: false)
        XCTAssertTrue(containerView.subviews.contains(hud))
        hud.hide(animated: false)
    }

    func testHideRemovesHUDFromView() {
        let hud = HUD.show(to: containerView, animated: false)
        hud.hide(animated: false)
        XCTAssertFalse(containerView.subviews.contains(hud))
    }

    func testActivityCount() {
        let hud = HUD.show(to: containerView, animated: false)
        hud.isCountEnabled = true

        hud.show(animated: false)  // count = 2
        hud.show(animated: false)  // count = 3

        hud.hide(animated: false)  // count = 2
        XCTAssertTrue(containerView.subviews.contains(hud))

        hud.hide(animated: false)  // count = 1
        XCTAssertTrue(containerView.subviews.contains(hud))

        hud.hide(animated: false)  // count = 0, hides
        XCTAssertFalse(containerView.subviews.contains(hud))
    }
}
```

### Testing Content Configuration

```swift
@MainActor
func testLabelText() {
    let hud = HUD.show(to: containerView, animated: false, label: "Loading")
    XCTAssertEqual(hud.contentView.label.text, "Loading")
    hud.hide(animated: false)
}

@MainActor
func testModeChange() {
    let hud = HUD.show(to: containerView, animated: false)
    hud.contentView.mode = .text
    XCTAssertTrue(hud.contentView.mode.isText)
    hud.hide(animated: false)
}

@MainActor
func testProgressUpdate() {
    let hud = HUD.show(to: containerView, animated: false, mode: .progress(.default))
    hud.contentView.progress = 0.5
    XCTAssertEqual(hud.contentView.progress, 0.5)
    hud.hide(animated: false)
}
```

## Mocking HUD in App Tests

![Class diagram showing HUDDisplayable protocol with RealHUDService (production) and MockHUDService (test) conformances, and ViewModel depending on the protocol.](testing-mock.svg)

### Protocol-Based Abstraction

Abstract HUD operations behind a protocol for testability:

```swift
// In your app code
@MainActor
protocol HUDDisplayable {
    func showLoading(on view: UIView, label: String?)
    func showSuccess(on view: UIView, label: String?)
    func showError(on view: UIView, label: String?)
    func hide(from view: UIView)
}

@MainActor
final class RealHUDService: HUDDisplayable {
    func showLoading(on view: UIView, label: String?) {
        HUD.show(to: view, label: label)
    }

    func showSuccess(on view: UIView, label: String?) {
        let image = UIImageView(image: UIImage(systemName: "checkmark"))
        HUD.showStatus(to: view, mode: .custom(image), label: label)
    }

    func showError(on view: UIView, label: String?) {
        HUD.showStatus(to: view, mode: .text, label: label)
    }

    func hide(from view: UIView) {
        HUD.hide(for: view)
    }
}
```

### Mock Implementation for Tests

```swift
@MainActor
final class MockHUDService: HUDDisplayable {
    var showLoadingCalled = false
    var showSuccessCalled = false
    var showErrorCalled = false
    var hideCalled = false
    var lastLabel: String?

    func showLoading(on view: UIView, label: String?) {
        showLoadingCalled = true
        lastLabel = label
    }

    func showSuccess(on view: UIView, label: String?) {
        showSuccessCalled = true
        lastLabel = label
    }

    func showError(on view: UIView, label: String?) {
        showErrorCalled = true
        lastLabel = label
    }

    func hide(from view: UIView) {
        hideCalled = true
    }
}
```

### Using the Mock in Tests

```swift
@MainActor
final class ViewModelTests: XCTestCase {
    func testFetchShowsAndHidesHUD() async {
        let mockHUD = MockHUDService()
        let viewModel = MyViewModel(hudService: mockHUD)

        await viewModel.fetchData()

        XCTAssertTrue(mockHUD.showLoadingCalled)
        XCTAssertTrue(mockHUD.hideCalled)
    }
}
```

## Testing Animations

Animations are difficult to unit test directly. Use these strategies:

### Disable Animations in Tests

```swift
@MainActor
func testHideWithoutAnimation() {
    let hud = HUD.show(to: containerView, animated: false)
    hud.hide(animated: false)
    // Assert immediately — no animation delay
    XCTAssertTrue(hud.isHidden)
}
```

### Use Animation Style `.none`

```swift
let hud = HUD.show(to: containerView, using: .animation(.none))
hud.hide(using: .animation(.none))
```

## Testing Delegates

```swift
@MainActor
final class DelegateTests: XCTestCase, HUDDelegate {
    var hudDidHide = false

    func hudWasHidden(_ hud: HUD) {
        hudDidHide = true
    }

    func testDelegateCalledOnHide() {
        let hud = HUD.show(to: containerView, animated: false)
        hud.delegate = self
        hud.hide(animated: false)
        XCTAssertTrue(hudDidHide)
    }
}
```

## Testing Custom Indicators

### ActivityIndicatorView Tests

```swift
@MainActor
func testActivityIndicatorStartStop() {
    let indicator = ActivityIndicatorView(style: .ringClipRotate)
    XCTAssertFalse(indicator.isAnimating)

    indicator.startAnimating()
    XCTAssertTrue(indicator.isAnimating)
    XCTAssertFalse(indicator.isHidden)

    indicator.stopAnimating()
    XCTAssertFalse(indicator.isAnimating)
    XCTAssertTrue(indicator.isHidden) // hidesWhenStopped = true
}
```

### ProgressView Tests

```swift
@MainActor
func testProgressViewBounds() {
    let progressView = ProgressView(style: .round)
    XCTAssertEqual(progressView.progress, 0.0)

    progressView.progress = 0.75
    XCTAssertEqual(progressView.progress, 0.75)
}
```

## Test Strategy

![Flowchart showing test strategy decision tree: HUD display logic → use animated:false; Business logic → use Mock; Custom indicators → test state; Delegates → assert callbacks.](testing-strategy.svg)

## Running Tests

### SPM

```bash
swift test
```

### Xcode

Select the test target and press Cmd+U, or run individual tests via the test navigator.

## Test Organization

```text
Tests/
├── HUD/
│   ├── HUDTests.swift              # Core show/hide behavior
│   ├── HUDStressTests.swift        # Concurrent and stress scenarios
│   ├── ModelTests.swift            # Layout, Animation models
│   ├── Extensions/                 # Extension tests
│   ├── Observables/                # DisplayLink, Keyboard tests
│   ├── Protocols/                  # Protocol conformance tests
│   └── Views/                      # ContentView, BackgroundView tests
├── IndicatorHUD/
│   └── ActivityIndicatorViewTests.swift
└── ProgressHUD/
    └── ProgressViewTests.swift
```
