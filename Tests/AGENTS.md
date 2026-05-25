# Tests - AI Coding Guidelines

## Organization

```text
Tests/
├── Tests.swift                    → Shared test utilities / imports
├── HUD/
│   ├── HUDTests.swift             → Core show/hide lifecycle
│   ├── HUDStressTests.swift       → Concurrent/stress scenarios
│   ├── ModelTests.swift           → Layout, Animation, KeyboardGuide models
│   ├── Extensions/                → Extension tests
│   ├── Observables/               → DisplayLink, Keyboard tests
│   ├── Protocols/                 → Protocol conformance tests
│   └── Views/                     → ContentView, BackgroundView tests
├── IndicatorHUD/
│   └── ActivityIndicatorViewTests.swift
└── ProgressHUD/
    └── ProgressViewTests.swift
```

## Test Conventions

### @MainActor Test Classes

All HUD test classes must be `@MainActor` annotated:

```swift
@MainActor
final class HUDTests: XCTestCase {
    override func setUp() async throws {  // MUST use async throws variant
        try await super.setUp()
        // setup
    }

    override func tearDown() async throws {
        // cleanup
        try await super.tearDown()
    }
}
```

### Always Use `animated: false`

Animations introduce timing dependencies. Always disable in unit tests:

```swift
// ✅ Correct
let hud = HUD.show(to: containerView, animated: false)
hud.hide(animated: false)
XCTAssertFalse(containerView.subviews.contains(hud))

// ❌ Wrong — will be flaky
let hud = HUD.show(to: containerView)  // animated by default
hud.hide()
// State may not be settled yet
```

### Container View Pattern

Create a fixed-size container for each test:

```swift
var containerView: UIView!

override func setUp() async throws {
    try await super.setUp()
    containerView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
}

override func tearDown() async throws {
    containerView = nil
    try await super.tearDown()
}
```

### Testing Show/Hide State

```swift
func testShowAddsHUDToView() {
    let hud = HUD.show(to: containerView, animated: false)
    XCTAssertTrue(containerView.subviews.contains(hud))
    hud.hide(animated: false)
}
```

## Module Split

Tests mirror the Sources directory:

- `Tests/HUD/` tests `Sources/HUD/` (import `@testable import FlyHUD`)
- `Tests/IndicatorHUD/` tests `Sources/IndicatorHUD/` (import `@testable import FlyIndicatorHUD`)
- `Tests/ProgressHUD/` tests `Sources/ProgressHUD/` (import `@testable import FlyProgressHUD`)

## Running Tests

```bash
# SPM (all tests)
swift test

# Xcode (specific scheme)
xcodebuild test -scheme "Example iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Single test file in Xcode
# Cmd+U in test navigator
```

## Mocking Pattern

For app-level tests that use HUD, abstract behind a protocol:

```swift
@MainActor
protocol HUDDisplayable {
    func showLoading(on view: UIView, label: String?)
    func showSuccess(on view: UIView, label: String?)
    func showError(on view: UIView, label: String?)
    func hide(from view: UIView)
}
```

Provide `RealHUDService` (production, imports FlyHUD) and `MockHUDService` (tests, no dependency).

## Test Coverage Priorities

1. Show/hide lifecycle + state transitions
2. Grace time + min show time timing logic
3. Activity count reference management
4. ContentView mode switching
5. Event delivery (hit testing)
6. Delegate & completion callbacks
7. Keyboard guide positioning (iOS)
8. Custom indicator start/stop
9. Progress value clamping
10. Background style transitions
