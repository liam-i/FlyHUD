# FlyHUD Tests

## Structure

```text
Tests/
├── Tests.swift                        # Integration tests (show/hide lifecycle)
├── HUD/
│   ├── HUDTests.swift                 # HUD class: init, properties, show/hide, static API
│   ├── ModelTests.swift               # Layout, Animation, Damping, KeyboardGuide
│   ├── Extensions/
│   │   ├── ExtensionsTests.swift      # UIView helpers (RTL, stackView, constraints)
│   │   └── HUDExtendedTests.swift     # HUDExtension protocol, notEqual, then
│   ├── Observables/
│   │   ├── DisplayLinkTests.swift     # Singleton, delegates, weak refs, concurrency
│   │   └── KeyboardObserverTests.swift # KeyboardInfo, observers, notifications (iOS)
│   ├── Protocols/
│   │   ├── ActivityIndicatorViewableTests.swift
│   │   ├── ProgressViewableTests.swift
│   │   └── RotateViewableTests.swift
│   └── Views/
│       ├── BaseViewTests.swift        # commonInit, init, memory
│       ├── BackgroundViewTests.swift   # Blur/solid styles, rounded corners
│       ├── ContentViewTests.swift     # Mode, Layout, IndicatorPosition, progress
│       ├── LabelTests.swift           # isDynamicTypeEnabled, intrinsicContentSize
│       └── ButtonTests.swift          # RoundedCorners, border, title, highlight
├── IndicatorHUD/
│   └── ActivityIndicatorViewTests.swift # 4 styles, animation builders, color
└── ProgressHUD/
    └── ProgressViewTests.swift        # 5 styles, animation mapping, default sizes
```

## Running Tests

```bash
# All tests (requires iOS Simulator)
xcodebuild test \
  -scheme "Example iOS" \
  -destination 'platform=iOS Simulator,OS=latest,arch=arm64' \
  -quiet

# Specific test class
xcodebuild test \
  -scheme "Example iOS" \
  -destination 'platform=iOS Simulator,OS=latest,arch=arm64' \
  -only-testing:"Example Tests/HUDTests"
```

> **Note:** `swift test` does not work because UIKit is unavailable on macOS command-line.

## Coverage

| Module | Test File Count | Key Areas |
| ------ | :-: | --- |
| HUD (core) | 11 | Init, show/hide, grace/minShow time, count, animation, keyboard, delegates |
| IndicatorHUD | 1 | 4 styles, animation builders, color, style switching |
| ProgressHUD | 1 | 5 styles, default sizes, progress tint, line width |
| Integration | 1 | Full lifecycle: show → animate → delay → hide → dealloc |

Total: 279 tests, 0 failures.

## Notes

* KeyboardObserver tests run only on iOS (`#if os(iOS)`)
* Integration tests (`Tests.swift`) require a key window (host app)
* Performance tests use `measure {}` blocks for critical paths
* Memory tests use `weak` references + `autoreleasepool`
