# Example tvOS - AI Coding Guidelines

## Architecture

- **Lifecycle**: UIScene-based (`SceneDelegate.swift` + `Info.plist` manifest)
- **UI**: Fully programmatic layout (`UIStackView` button grid). No storyboards except LaunchScreen.
- **Pattern**: Single ViewController with demo methods
- **Interaction**: Focus-based (tvOS remote — `primaryActionTriggered` events)

## File Map

| File | Purpose |
| ---- | ------- |
| `AppDelegate.swift` | App entry, scene configuration |
| `SceneDelegate.swift` | `UIWindowSceneDelegate`, provides `window` |
| `ViewController.swift` | Multi-demo HUD showcase (8 demos) |
| `Resources/Info.plist` | Scene manifest |
| `Resources/Base.lproj/LaunchScreen.storyboard` | Launch screen |

## Demo Layout

Two-row button grid (4 buttons per row):

| Row 1 | Row 2 |
| ----- | ----- |
| Indicator | Custom Icon |
| Progress Bar | Mode Switching |
| Circular Progress | Observed Progress |
| Toast | Activity Indicators |

## Scene Configuration

Uses `Info.plist` manifest (not auto-generated):

- `UISceneConfigurationName`: "Default Configuration"
- `UISceneDelegateClassName`: `$(PRODUCT_MODULE_NAME).SceneDelegate`

`SceneDelegate.scene(_:willConnectTo:options:)` creates the window and sets `ViewController` as root.

## Key Differences from iOS Example

- No keyboard guide (tvOS has no keyboard overlay)
- Focus-based interaction (`primaryActionTriggered` not touch)
- Single ViewController (no navigation controller, no table view)
- Larger fonts (36pt/24pt) for TV viewing distance
- No config system — demos use hardcoded settings
- Liquid Glass style adopts automatically on tvOS 26+ via standard UIButton

## Common Tasks

- **New demo**: Add `@objc private func showXxx()` → add `(title, selector)` tuple in `setupUI()`
- **New file**: Add to `Example tvOS/` directory (auto-syncs via `PBXFileSystemSynchronizedRootGroup`)

## Build

```bash
./scripts/build.sh build "Example tvOS" tvos
```
