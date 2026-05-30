# FlyHUD - Claude Code Instructions

> All project details are in [AGENTS.md](./AGENTS.md). This file adds Claude-specific workflow tips only.

## Workflow Tips

- After editing `Example iOS/` files, run `./scripts/build.sh build "Example iOS"` to catch type errors (Xcode auto-syncs)
- Use `./scripts/build.sh test HUDTests` to validate specific changes
- SPM build: `./scripts/build.sh swift` (note: `swift test` doesn't work — UIKit unavailable on macOS CLI)
- Read sub-directory `AGENTS.md` files on demand when working in those areas

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
| SwiftUI modifiers | `Sources/SwiftUIHUD/View+HUD.swift` |
| SwiftUI host bridge | `Sources/SwiftUIHUD/HUDHostView.swift` |
| SwiftUI coordinator | `Sources/SwiftUIHUD/HUDModifier.swift` |
| Example main | `Example iOS/Views/ViewController.swift` |
| Config inspector | `Example iOS/Views/ConfigViewController.swift` |
| Glass demo | `Example iOS/Views/LiquidGlassViewController.swift` |
| Config enums | `Example iOS/Models/DemoSections.swift` |
| tvOS main | `Example tvOS/ViewController.swift` |
| HUD tests | `Tests/HUD/HUDTests.swift` |
| Stress tests | `Tests/HUD/HUDStressTests.swift` |
| Accessibility UITests | `UITests/HUD/HUDAccessibilityUITests.swift` |
| DocC articles | `Sources/HUD/Documentation.docc/*.md` |
| Mermaid diagrams | `Sources/HUD/Documentation.docc/Resources/mermaid-src/*.mmd` |
