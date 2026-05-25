# Example iOS - AI Coding Guidelines

## Architecture

- **Lifecycle**: UIScene-based (`SceneDelegate.swift` + `Info.plist` manifest)
- **UI**: Fully programmatic (no storyboards except LaunchScreen). All layouts via Auto Layout in code.
- **Pattern**: MVVM-light (`ViewController` ↔ `DemoViewModel` ↔ `Configuration`)
- **Navigation**: `UINavigationController` as root
- **ObjC Bridge**: `HUD-Bridging-OC.swift` exposes Swift HUD API; `OCPresentViewController.m` demos it

## File Map

| File | Purpose |
| ---- | ------- |
| `App/SceneDelegate.swift` | Creates window, sets root VC |
| `App/AppDelegate.swift` | App entry, global keyboard guide config |
| `Views/ViewController.swift` | Main table view with indicator demos |
| `Views/PresentViewController.swift` | Swift HUD demo (modal presentation) |
| `Views/LiquidGlassViewController.swift` | iOS 26+ glass style demo |
| `Views/ConfigViewController.swift` | Inspector sheet for HUD configuration |
| `Views/Cells/Cells.swift` | IndicatorStripCell, ConfigCell, DemoActionCell, ToolCell |
| `Models/DemoSections.swift` | `DemoSection`, `DemoAction`, `ConfigItem` enums |
| `Models/Configuration.swift` | All HUD config options in one struct |
| `ViewModels/DemoViewModel.swift` | HUD presentation logic + config state |
| `Helpers/Task.swift` | Simulated async task helpers |
| `Helpers/Util.swift` | Utility extensions |
| `ObjC/HUD-Bridging-OC.swift` | Swift → ObjC bridge |
| `ObjC/OCPresentViewController.m` | ObjC HUD usage demo |

## Table View Structure (ViewController)

Sections are defined by `DemoSection` enum (raw Int values):

1. **ProgressView Styles** — cached cells (NOT dequeued)
2. **ActivityIndicatorView Styles** — cached cells (NOT dequeued)
3. **System Indicators** — cached cells (NOT dequeued)
4. **Demos** — `DemoAction` cases → push/present

> **CRITICAL**: Indicator cells (sections 0–2) are **cached as instance properties**. Never use `dequeueReusableCell` for them. Only Config/Demo cells use the reuse pool.

## Configuration System (Inspector Sheet)

`ConfigViewController` is presented as a `.medium`/`.large` detent sheet via the gear button.

### Config Groups (DemoSection)

| Section | Items |
| ------- | ----- |
| General | mode, label text, details text |
| Content | contentColor, indicatorPosition, dynamicType |
| Appearance | contentStyle, backgroundColor, roundedCorners |
| Layout | offset, margins, spacing, minSize, isSquare |
| Animation | style, damping, duration |
| Timing | graceTime, minShowTime, hideDelay |
| Behavior | isCountEnabled, isEventDeliveryEnabled, removeOnHide |

### ConfigItem Pattern

Each `ConfigItem` case provides:

- `.section` → which `DemoSection` it belongs to
- `.currentValue(from:)` → read from `Configuration` struct
- `.editDescriptor` → defines the editing UI (switch, stepper, picker, etc.)
- Apply method → writes value back to `Configuration`
- `.isCustomOnly` / `.isForceAnimOnly` → conditional visibility

### Data Flow

```text
ConfigViewController
    ↕ (reads/writes)
Configuration struct (value type)
    ↕ (viewModel.onConfigChanged callback)
DemoViewModel
    ↕ (applies to)
HUD instances
```

## Cell Architecture

| Cell Type | Reuse Strategy | Purpose |
| --------- | -------------- | ------- |
| `IndicatorStripCell` | Cached property | Displays indicator preview |
| `ConfigCell` | `dequeueReusableCell` | Shows config item with edit control |
| `DemoActionCell` | `dequeueReusableCell` | Navigation to demo screens |
| `ToolCell` | `dequeueReusableCell` | Toolbar-style action buttons |

## Common Tasks

### Adding a new ConfigItem

1. Add case to `ConfigItem` enum in `DemoSections.swift`
2. Set readable raw value string (e.g. `"My Option"`)
3. Add to appropriate `section` in `var section: DemoSection` switch
4. Implement `currentValue(from:)` and `editDescriptor`
5. Add apply logic in Configuration
6. Set `isCustomOnly` / `isForceAnimOnly` if needed

### Adding a new Demo

1. Add case to `DemoAction` enum in `DemoSections.swift`
2. Handle in `ViewController.handleDemoAction(_:)` → push or present

### Adding a new ViewController

1. Create file in `Example iOS/Views/`
2. It auto-syncs via `PBXFileSystemSynchronizedRootGroup` — no pbxproj edit needed
3. Add navigation from `ViewController` via `DemoAction`

## Keyboard Guide Setup

```swift
// In AppDelegate.didFinishLaunching:
HUD.keyboardGuide = .center()

// Window acquisition (UIScene compatible):
// self.window → UIApplication.shared.connectedScenes fallback
```
