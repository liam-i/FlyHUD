# Example SwiftUI - AI Coding Guidelines

## Architecture

- **Lifecycle**: SwiftUI App (`@main` in `AppEntry.swift`)
- **UI**: Pure SwiftUI with `FlyHUDSwiftUI` module bridge
- **Navigation**: `NavigationStack` with `ContentListView` as root
- **Pattern**: View-per-feature, each view self-contained

## File Map

| File | Purpose |
| ---- | ------- |
| `App/AppEntry.swift` | `@main` app entry point |
| `App/ContentListView.swift` | Root navigation list |
| `Views/Basic/BasicHUDView.swift` | Basic show/hide demos |
| `Views/Modes/ModeViews.swift` | Mode switching demos |
| `Views/Styles/IndicatorStylesView.swift` | Indicator style gallery |
| `Views/Styles/ProgressStylesView.swift` | Progress style gallery |
| `Views/Config/ConfigViews.swift` | Configuration demos |
| `Views/Modifiers/DeclarativeModifiersView.swift` | Declarative modifier demos (Layer 2 & 3) |
| `Views/Advanced/AdvancedViews.swift` | Advanced features (timing, keyboard) |
| `Views/Advanced/AccessibilityView.swift` | VoiceOver accessibility demos |
| `Views/LiquidGlass/LiquidGlassView.swift` | iOS 26+ glass style demo |

## FlyHUDSwiftUI Bridge Patterns

Two approaches to present HUDs:

### 1. Host Bridge (Layer 1 — UIKit-style control)

```swift
import FlyHUDSwiftUI

@State private var hostView: UIView?

MyView()
    .hudHost($hostView)

// Then:
if let view = hostView {
    HUD.show(to: view, mode: .indicator(), label: "Loading...")
}
```

### 2. Declarative Modifiers (Layer 2 & 3)

```swift
import FlyHUDSwiftUI

@State private var isLoading = false

MyView()
    .hud(isPresented: $isLoading) { hud in
        hud.contentView.mode = .indicator()
        hud.contentView.label.text = "Loading..."
    }

// Or convenience presets:
MyView().hudLoading(isPresented: $isLoading, label: "Loading...")
MyView().hudToast(isPresented: $showToast, label: "Saved!")
MyView().hudProgress(isPresented: $isUploading, progress: $progress)
```

## Concurrency Pattern

Use structured concurrency with explicit `@MainActor` isolation:

```swift
Task { @MainActor in
    HUD.show(to: view, animated: true, mode: .indicator())
    try? await Task.sleep(for: .seconds(2.0))
    HUD.hide(for: view)
}
```

**Do NOT use** `Timer.scheduledTimer` — it cannot satisfy Swift 6 Sendable requirements in SwiftUI context.

## Common Tasks

### Adding a New Demo View

1. Create file in appropriate `Views/` subfolder
2. Add navigation link in `ContentListView.swift`
3. Auto-syncs via `PBXFileSystemSynchronizedRootGroup`
