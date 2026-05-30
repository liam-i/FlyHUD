# FlyHUD Tests

## Structure

```text
Tests/
├── HUD/
│   ├── HUDTests.swift                 # HUD class: init, properties, show/hide, static API
│   ├── HUDStressTests.swift           # Concurrent/stress/performance scenarios
│   ├── ModelTests.swift               # Layout, Animation, Damping, KeyboardGuide
│   ├── Extensions/
│   │   ├── ExtensionsTests.swift      # UIView helpers (RTL, stackView, constraints)
│   │   └── HUDExtendedTests.swift     # HUDExtension protocol, notEqual, then
│   ├── Observables/
│   │   ├── DisplayLinkTests.swift     # Singleton, delegates, weak refs, concurrency
│   │   ├── KeyboardObserverTests.swift # KeyboardInfo, observers, notifications (iOS)
│   │   └── UnfairLockTests.swift      # Mutex backport, thread-safety, Sendable
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
├── ProgressHUD/
│   └── ProgressViewTests.swift        # 5 styles, animation mapping, default sizes
└── SwiftUIHUD/
    ├── SwiftUIHUDTests.swift          # ViewModifier API, HUDHostView, convenience modifiers
    ├── SwiftUIHUDIntegrationTests.swift # Coordinator lifecycle, custom view, item binding
    └── SwiftUIHUDStressTests.swift    # 25 stress scenarios: rapid create/destroy, concurrency, memory
```

## Running Tests

### Quick Start

```bash
# Run all unit tests
./scripts/build.sh test

# Run all UI tests
./scripts/build.sh test ui

# Run both unit + UI tests
./scripts/build.sh test all
```

### By Module

```bash
# HUD core tests
./scripts/build.sh test HUDTests

# HUD stress tests
./scripts/build.sh test HUDStressTests

# Model tests
./scripts/build.sh test ModelTests

# SwiftUI tests
./scripts/build.sh test SwiftUIHUDTests
./scripts/build.sh test SwiftUIHUDIntegrationTests
./scripts/build.sh test SwiftUIHUDStressTests

# Indicator tests
./scripts/build.sh test ActivityIndicatorViewTests

# Progress tests
./scripts/build.sh test ProgressViewTests
```

### Single Method

```bash
./scripts/build.sh test HUDTests/testBasicShow
```

### Build Only (no simulator needed)

```bash
./scripts/build.sh build "Example iOS"
```

> **Note:** `swift test` does not work because UIKit is unavailable on macOS command-line.
> Use `./scripts/build.sh swift` to verify SPM compilation.

### List Available Schemes & Platforms

```bash
./scripts/build.sh list
```

## Coverage

| Module | Test Files | Key Areas |
| ------ | :-: | --- |
| HUD (core) | 16 | Init, show/hide, grace/minShow time, count, animation, keyboard, lock, delegates, stress, views, protocols |
| IndicatorHUD | 1 | 4 styles, animation builders, color, style switching |
| ProgressHUD | 1 | 5 styles, default sizes, progress tint, line width |
| SwiftUIHUD | 3 | Modifiers, coordinators, convenience API, integration, stress (25 scenarios) |

Total: 699 tests, 0 failures.

## Notes

* All test classes use `@MainActor` with `override func setUp() async throws`
* KeyboardObserver tests run only on iOS (`#if os(iOS)`)
* Performance tests use `measure {}` blocks for critical paths
* Memory tests use `weak` references + `autoreleasepool`
* SwiftUI stress tests cover up to 5000 rapid cycles and 100 concurrent coordinators
* Use `animated: false` in tests to avoid flaky timing issues
