# Example SwiftUI - AI Coding Guidelines

## Architecture

- **Lifecycle**: SwiftUI App (`@main` in `AppEntry.swift`)
- **UI**: Pure SwiftUI with `UIViewRepresentable` bridge (`HUDHostView`)
- **Navigation**: `NavigationStack` with `ContentListView` as root
- **Pattern**: View-per-feature, each view self-contained

## File Map

| File | Purpose |
| ---- | ------- |
| `App/AppEntry.swift` | `@main` app entry point |
| `App/ContentListView.swift` | Root navigation list |
| `Helpers/HUDHostView.swift` | `UIViewRepresentable` bridge for FlyHUD |
| `Views/Basic/BasicHUDView.swift` | Basic show/hide demos |
| `Views/Modes/ModeViews.swift` | Mode switching demos |
| `Views/Styles/IndicatorStylesView.swift` | Indicator style gallery |
| `Views/Styles/ProgressStylesView.swift` | Progress style gallery |
| `Views/Config/ConfigViews.swift` | Configuration demos |
| `Views/Advanced/AdvancedViews.swift` | Advanced features (timing, keyboard) |
| `Views/LiquidGlass/LiquidGlassView.swift` | iOS 26+ glass style demo |

## HUDHostView Bridge

All HUD interactions go through `HUDHostView` — a `UIViewRepresentable` wrapper:

```swift
HUDHostView { containerView in
    // Access UIView for HUD operations
    HUD.show(to: containerView, mode: .indicator(.large))
}
```

## Concurrency Pattern

Use structured concurrency with explicit `@MainActor` isolation:

```swift
Task { @MainActor in
    HUD.show(to: view, animated: true, mode: .indicator(.large))
    try? await Task.sleep(nanoseconds: 2_000_000_000)
    HUD.hide(for: view)
}
```

**Do NOT use** `Timer.scheduledTimer` — it cannot satisfy Swift 6 Sendable requirements in SwiftUI context.

## Common Tasks

### Adding a New Demo View

1. Create file in appropriate `Views/` subfolder
2. Add navigation link in `ContentListView.swift`
3. Auto-syncs via `PBXFileSystemSynchronizedRootGroup`
