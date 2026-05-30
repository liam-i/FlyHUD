# Tests - AI Coding Guidelines

## Organization

```text
Tests/
├── HUD/
│   ├── HUDTests.swift             → Core show/hide lifecycle
│   ├── HUDStressTests.swift       → Concurrent/stress scenarios
│   ├── ModelTests.swift           → Layout, Animation, KeyboardGuide models
│   ├── Extensions/                → Extension tests
│   ├── Observables/               → DisplayLink, Keyboard tests
│   ├── Protocols/                 → Protocol conformance tests
│   └── Views/                     → ContentView, BackgroundView tests (incl. VoiceOver)
├── IndicatorHUD/
│   └── ActivityIndicatorViewTests.swift
├── ProgressHUD/
│   └── ProgressViewTests.swift
└── SwiftUIHUD/
    ├── SwiftUIHUDTests.swift             → SwiftUI modifier unit tests
    ├── SwiftUIHUDStressTests.swift       → SwiftUI stress/performance
    └── SwiftUIHUDIntegrationTests.swift  → Indicator/Progress integration
```

UI tests (`UITests/`) complement unit tests:

```text
UITests/
└── HUD/
    ├── HUDUITests.swift               → Core show/hide, rotation, keyboard, stability
    └── HUDAccessibilityUITests.swift  → VoiceOver label/value/hint/traits/escape validation
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
./scripts/build.sh test                   # All unit tests
./scripts/build.sh test HUDTests          # Specific class
./scripts/build.sh test HUDTests/testBasicShow  # Single method
./scripts/build.sh test ui                # UI tests
```

> `swift test` doesn't work — UIKit unavailable on macOS CLI.

## Mocking Pattern

For app-level tests, abstract HUD behind a protocol (`HUDDisplayable`) with `RealHUDService` (production) and `MockHUDService` (tests, no FlyHUD dependency).

## Test Coverage Priorities

Lifecycle → grace/min time → count management → mode switching → event delivery → delegate/completion → keyboard guide → custom indicator → progress clamping → background styles → VoiceOver accessibility
