# FlyHUD - GitHub Copilot Instructions

Refer to [AGENTS.md](../AGENTS.md) for the project overview and sub-directory guides.

## Quick Reference

- **Swift 5.0+**, iOS 13+, tvOS 13+, visionOS 1.0+
- **SPM targets**: FlyHUD, FlyIndicatorHUD, FlyProgressHUD
- **Dependency rule**: FlyHUD must **never** import Indicator or Progress modules
- **Example iOS**: UIScene lifecycle, programmatic UI, MVVM-light
- Indicator cells are cached (not reuse-pooled) — never `dequeueReusableCell`

## Key API Patterns

```swift
// Show
HUD.show(to: view, mode: .indicator(.large), label: "Loading")
HUD.show(to: view, using: .animation(.zoomInOut, damping: .default), mode: .custom(myView)) { hud in
    hud.contentView.contentColor = .white
}
HUD.showStatus(to: view, duration: 2.0, mode: .text, label: "Saved")

// Hide
HUD.hide(for: view)
hud.hide(afterDelay: 1.5)
```

## Swift 6 / Concurrency

- `@MainActor` inherited on UIView subclasses — don't add redundantly
- `#if compiler(>=6.2) isolated deinit` with `#else MainActor.assumeIsolated {}` fallback
- Tests use `override func setUp() async throws` for `@MainActor` classes
- Two manifests: `Package.swift` (5.9) + `Package@swift-6.0.swift` (6.0)

## Build & Test

```bash
swift build && swift test
# Xcode: Scheme "Example iOS" → iPhone 17 Pro simulator
```

## Common Pitfalls

- `graceTime` must be set before `show()` — no effect after
- Use `animated: false` in unit tests to avoid timing issues
- Don't use `.swiftLanguageMode()` in Package.swift (only tools-version 6.0+)
- Xcode auto-syncs `Example iOS/App/` files — no pbxproj edits needed

## Detailed Guides

- [`Sources/AGENTS.md`](../Sources/AGENTS.md) — API surface & protocols
- [`Sources/HUD/Documentation.docc/AGENTS.md`](../Sources/HUD/Documentation.docc/AGENTS.md) — DocC writing rules
- [`Example iOS/AGENTS.md`](../Example iOS/AGENTS.md) — Demo app patterns
- [`Example SwiftUI/AGENTS.md`](../Example SwiftUI/AGENTS.md) — SwiftUI bridge pattern
- [`Example tvOS/AGENTS.md`](../Example tvOS/AGENTS.md) — tvOS scene lifecycle
- [`Tests/AGENTS.md`](../Tests/AGENTS.md) — Test conventions
