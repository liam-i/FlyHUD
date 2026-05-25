# FlyHUD - Claude Code Instructions

Refer to [AGENTS.md](./AGENTS.md) for the project overview and sub-directory guides.

## Quick Context

- **Swift 5.0+**, iOS 13+, tvOS 13+, visionOS 1.0+
- SPM targets: `FlyHUD`, `FlyIndicatorHUD`, `FlyProgressHUD`
- `FlyHUD` must **never** import Indicator or Progress modules (reverse deps forbidden)

## Build Commands

```bash
swift build                   # SPM build
swift test                    # SPM test
xcodebuild build -scheme "Example iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme "Example iOS" -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Key Reminders for Claude

- When editing Example iOS files, always check `get_errors` afterward (Xcode auto-syncs may surface type errors)
- Indicator cells are **cached** — never `dequeueReusableCell` for them
- `graceTime` must be set before `show()` — no effect after
- Use `animated: false` in tests — avoids flaky timing
- `@MainActor` is inherited on UIView subclasses — don't add redundantly
- `#if compiler(>=6.2) isolated deinit` with `#else MainActor.assumeIsolated {}` fallback
- Test `setUp`/`tearDown` must use `async throws` variant for `@MainActor` classes

## File Quick Access

| Need | File |
| ---- | ---- |
| Core HUD | `Sources/HUD/HUD.swift` |
| Models | `Sources/HUD/Model.swift` |
| ContentView | `Sources/HUD/Views/ContentView.swift` |
| BackgroundView | `Sources/HUD/Views/BackgroundView.swift` |
| DisplayLink | `Sources/HUD/Observables/DisplayLink.swift` |
| KeyboardObserver | `Sources/HUD/Observables/KeyboardObserver.swift` |
| Indicator view | `Sources/IndicatorHUD/ActivityIndicatorView.swift` |
| Progress view | `Sources/ProgressHUD/ProgressView.swift` |
| Example main | `Example iOS/Views/ViewController.swift` |
| Config inspector | `Example iOS/Views/ConfigViewController.swift` |
| Glass demo | `Example iOS/Views/LiquidGlassViewController.swift` |
| Config enums | `Example iOS/Models/DemoSections.swift` |
| tvOS main | `Example tvOS/ViewController.swift` |
| HUD tests | `Tests/HUD/HUDTests.swift` |
| Stress tests | `Tests/HUD/HUDStressTests.swift` |
| DocC articles | `Sources/HUD/Documentation.docc/*.md` |
| Mermaid diagrams | `Sources/HUD/Documentation.docc/Resources/mermaid-src/*.mmd` |

## Detailed Guides

For comprehensive details, see the sub-directory AGENTS.md files:

- [`Sources/AGENTS.md`](Sources/AGENTS.md) — API surface & protocols
- [`Sources/HUD/Documentation.docc/AGENTS.md`](Sources/HUD/Documentation.docc/AGENTS.md) — DocC writing rules
- [`Example iOS/AGENTS.md`](Example%20iOS/AGENTS.md) — Demo app patterns
- [`Example SwiftUI/AGENTS.md`](Example%20SwiftUI/AGENTS.md) — SwiftUI bridge pattern
- [`Example tvOS/AGENTS.md`](Example%20tvOS/AGENTS.md) — tvOS scene lifecycle
- [`Tests/AGENTS.md`](Tests/AGENTS.md) — Test conventions
