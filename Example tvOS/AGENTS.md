# Example tvOS - AI Coding Guidelines

## Architecture

- **Lifecycle**: UIScene-based (`SceneDelegate.swift` + scene manifest in `Info.plist`)
- **UI**: `Main.storyboard` for initial view controller with IBAction connections
- **Entry**: `AppDelegate` configures scene session; system auto-creates window from storyboard

## File Map

| File | Purpose |
| ---- | ------- |
| `AppDelegate.swift` | App entry, scene configuration via "Default Configuration" |
| `SceneDelegate.swift` | `UIWindowSceneDelegate`, provides `window` property |
| `ViewController.swift` | Single HUD demo with progress bar and button |
| `Resources/Info.plist` | Scene manifest: delegate class + storyboard reference |
| `Resources/Base.lproj/Main.storyboard` | Initial view controller UI |
| `Resources/Base.lproj/LaunchScreen.storyboard` | Launch screen |

## Scene Configuration

The scene lifecycle uses an explicit `Info.plist` (not auto-generated):

```xml
UISceneConfigurationName: "Default Configuration"
UISceneDelegateClassName: $(PRODUCT_MODULE_NAME).SceneDelegate
UISceneStoryboardFile: Main
```

`AppDelegate.configurationForConnecting` returns a configuration named "Default Configuration", which UIKit looks up in the plist. Since `SceneDelegate` does NOT implement `scene(_:willConnectTo:options:)`, UIKit auto-creates the window from `Main.storyboard`.

## Key Differences from iOS Example

- No keyboard guide (tvOS has no keyboard overlay)
- Focus-based interaction (no touch — uses `primaryActionTriggered` event)
- Simplified demo — single view controller with one button
- Uses storyboard (iOS example is fully programmatic)
- Liquid Glass style adopts automatically on tvOS 26+ via standard UIButton

## Build

```bash
xcodebuild build -scheme "Example tvOS" -destination 'generic/platform=tvOS Simulator' CODE_SIGNING_ALLOWED=NO
```
