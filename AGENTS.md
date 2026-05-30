# FlyHUD - AI Coding Guidelines

## Project Overview

FlyHUD is a lightweight HUD (Heads-Up Display) library for iOS/tvOS, providing progress indicators, activity indicators, and toast-style notifications. Version: 1.6.0.

- **Repo**: <https://github.com/liam-i/FlyHUD>
- **Language**: Swift 5.0+
- **Platforms**: iOS 13.0+, tvOS 13.0+, visionOS 1.0+
- **Package Managers**: SPM (primary), CocoaPods
- **License**: MIT

## Sub-Directory Guides

| Path | Content |
| ---- | ------- |
| [`Sources/AGENTS.md`](Sources/AGENTS.md) | Module architecture, public API surface, protocol details, animation system |
| [`Sources/HUD/Documentation.docc/AGENTS.md`](Sources/HUD/Documentation.docc/AGENTS.md) | DocC conventions, diagram workflow, article inventory |
| [`Example iOS/AGENTS.md`](Example%20iOS/AGENTS.md) | Demo app architecture, cell patterns, config system |
| [`Example SwiftUI/AGENTS.md`](Example%20SwiftUI/AGENTS.md) | SwiftUI bridge pattern, structured concurrency |
| [`Example tvOS/AGENTS.md`](Example%20tvOS/AGENTS.md) | tvOS scene lifecycle, focus interaction |
| [`Tests/AGENTS.md`](Tests/AGENTS.md) | Test organization, conventions, @MainActor patterns |

## Module Architecture

```text
Sources/
├── HUD/              → Target: FlyHUD (core)
├── IndicatorHUD/     → Target: FlyIndicatorHUD (depends on FlyHUD)
├── ProgressHUD/      → Target: FlyProgressHUD (depends on FlyHUD)
└── SwiftUIHUD/       → Target: FlyHUDSwiftUI (depends on FlyHUD)
```

### Dependency Direction

```text
FlyIndicatorHUD ──▶ FlyHUD ◀── FlyProgressHUD
                       ▲
                       │
                 FlyHUDSwiftUI
```

**FlyHUD must never import FlyIndicatorHUD, FlyProgressHUD, or FlyHUDSwiftUI.** Reverse dependencies are strictly forbidden.

## Code Conventions

### Swift Style

- Prefer `final class` for non-inheritable classes
- Use `[weak self]` in closures, guard-let pattern
- Extensions for conformance grouping (`// MARK: -` headers)
- No storyboards/xibs (only LaunchScreen.storyboard for system use)
- Concise raw value strings for user-facing enum labels

### HUD Display Patterns

```swift
// Simple API (default style)
HUD.show(to: view, mode: .custom(indicator), label: "Loading")

// Custom API (full config)
HUD.show(to: view, using: .animation(.zoomInOut, damping: .default), mode: .custom(indicator)) { hud in
    hud.contentView.contentColor = .white
}

// Auto-hiding status toast
HUD.showStatus(to: view, duration: 2.0, mode: .text, label: "Saved")

// Hide
HUD.hide(for: view)
hud.hide(afterDelay: 1.5)

// SwiftUI (FlyHUDSwiftUI module)
MyView().hud(isPresented: $isLoading) { hud in
    hud.contentView.mode = .indicator()
    hud.contentView.label.text = "Loading..."
}
MyView().hudLoading(isPresented: $isLoading, label: "Loading...")
MyView().hudToast(isPresented: $showToast, label: "Saved!")
MyView().hudProgress(isPresented: $isUploading, progress: $progress)
```

## Build & Test

```bash
./scripts/build.sh                        # Build all frameworks (iOS)
./scripts/build.sh build "Example iOS"    # Build specific scheme
./scripts/build.sh build FlyHUD tvos      # Build for tvOS
./scripts/build.sh build "Example tvOS" tvos
./scripts/build.sh all                    # Build everything for all platforms
./scripts/build.sh swift                  # SPM build
./scripts/build.sh test                   # Run unit tests
./scripts/build.sh test ui                # Run UI tests
./scripts/build.sh test HUDTests          # Run specific test class
./scripts/build.sh test HUDTests/testBasicShow  # Run specific method
./scripts/build.sh clean                  # Clean (includes DerivedData)
./scripts/build.sh list                   # Show available schemes/platforms
```

### Xcode Project Notes

- `FlyHUD.xcodeproj` uses `PBXFileSystemSynchronizedRootGroup` — files in `Example iOS/App/` are auto-synced, no manual pbxproj edits needed
- Debug config uses `dwarf` (not dwarf-with-dsym) to avoid dSYM warnings

## Swift 6 Concurrency

- `@MainActor` inherited on all UIView subclasses — don't add redundantly
- `#if compiler(>=6.2) isolated deinit` with `#else MainActor.assumeIsolated {}` fallback in `deinit` blocks
- `UnfairLock` in `Sources/HUD/Observables/` — Mutex backport for iOS 13+
- `@unchecked Sendable` on singletons protected by UnfairLock
- `nonisolated(unsafe)` for static vars with external lock protection
- Two Package manifests: `Package.swift` (5.9, StrictConcurrency) + `Package@swift-6.0.swift` (6.0, v6 mode)
- Test `setUp`/`tearDown` must use `async throws` variant for `@MainActor` classes

## Common Pitfalls

1. **Never add reverse imports** — FlyHUD core must not import Indicator/Progress/SwiftUI modules
2. **Never `dequeueReusableCell` for indicator cells** — they're cached as instance properties
3. **`graceTime` must be set before `show()`** — no effect after
4. **Use `animated: false` in tests** — avoids flaky timing issues
5. **Don't use `.swiftLanguageMode()` in Package.swift** — only for tools-version 6.0
6. **Don't add `@MainActor` on UIView subclasses** — already inherited
7. **Don't use `Package@swift-5.9.swift`** — removed; only 5.9 (base) and 6.0 exist
8. **Don't set `isAccessibilityElement = true` on HUD child views** — only ContentView is the accessible element; children are hidden
9. **Custom views via `.custom()` should set `isAccessibilityElement = false`** — ContentView handles all accessibility
10. **Don't override `accessibilityPerformEscape()` on ContentView** — it's implemented on HUD to dismiss via Z-scrub
