# FAQ

Frequently asked questions about FlyHUD.

## General

### What is the difference between FlyHUD, FlyIndicatorHUD, and FlyProgressHUD?

- **FlyHUD** — The core module containing the `HUD` class, layout system, animations,
  and background views. This is all you need for system indicators and custom views.
- **FlyIndicatorHUD** — Provides custom activity indicator styles (ring clip, ball spin,
  circle stroke, arc dot). Depends on FlyHUD.
- **FlyProgressHUD** — Provides custom progress view styles (bar, round, annular, pie).
  Depends on FlyHUD.

You can import only what you need. All three are independent of each other.

### Why was it renamed from LPHUD to FlyHUD?

The library was renamed in version 1.5.6 to better reflect its nature: "Fly" implies
fast, efficient, and flexible — consistent with the real-time nature of a HUD.

### Does FlyHUD support SwiftUI?

FlyHUD is a UIKit library. For SwiftUI integration, wrap HUD display logic in a
`UIViewRepresentable` or use it within a hosting controller. See the Example SwiftUI
project for reference implementations.

## Installation

### Which module should I import?

| Need | Import |
| ---- | ------ |
| System spinner + custom views only | `FlyHUD` |
| Custom indicator animations | `FlyHUD` + `FlyIndicatorHUD` |
| Custom progress styles | `FlyHUD` + `FlyProgressHUD` |
| All features | All three |

### Can I use only CocoaPods subspecs?

Yes. Use subspecs to minimize dependencies:

```ruby
pod 'FlyHUD', :subspecs => ['FlyHUD']           # Core only
pod 'FlyHUD', :subspecs => ['FlyIndicatorHUD']  # Core + indicators
pod 'FlyHUD', :subspecs => ['FlyProgressHUD']   # Core + progress
```

### Why do I get "No such module 'FlyHUD'" in my Xcode project?

Ensure you have:

1. Added the SPM package dependency correctly
2. Added the library product to your target's "Frameworks, Libraries, and Embedded Content"
3. Cleaned build folder (Shift+Cmd+K) and rebuilt

## Usage

### Why does my HUD stay on screen forever?

Every `show()` must be paired with a `hide()`. Common causes:

- Forgetting to call `hide()` on error paths
- Calling `hide()` on a different HUD instance
- Using `isCountEnabled = true` without matching show/hide pairs

### Why does my HUD appear behind other views?

HUD is added as a subview of the view you specify. Ensure no other views are added
after the HUD, or call `view.bringSubviewToFront(hud)`.

### Why doesn't the keyboard guide work?

- Keyboard guide is iOS-only (not available on tvOS or visionOS)
- Ensure `HUD.keyboardGuide` or `hud.keyboardGuide` is set to `.center()` or `.bottom()`
- The keyboard must actually appear (test with a focused text field)

### How do I show HUD on the full screen (over navigation bar)?

Add the HUD to the window instead of the view controller's view:

```swift
if let window = view.window {
    HUD.show(to: window)
}
```

### Can I show multiple HUDs simultaneously?

Yes. Each `HUD.show(to:)` call creates a new HUD instance:

```swift
let hud1 = HUD.show(to: view, label: "Step 1")
let hud2 = HUD.show(to: view, label: "Step 2")
```

Use `HUD.hideAll(for:)` to dismiss all at once.

### How do I update HUD content after showing?

Access the HUD's `contentView` to update labels, mode, or progress:

```swift
let hud = HUD.show(to: view)
// Later...
hud.contentView.label.text = "Almost done..."
hud.contentView.mode = .custom(checkmarkView)
```

## Appearance

### How do I change the HUD's background transparency?

```swift
// Content card background
hud.contentView.color = UIColor.black.withAlphaComponent(0.7)

// Full-screen overlay
hud.backgroundView.color = UIColor.black.withAlphaComponent(0.3)
hud.backgroundView.style = .solidColor
```

### How do I make the HUD larger/smaller?

```swift
// Set minimum size
hud.contentView.layout.minSize = CGSize(width: 150, height: 150)

// Or adjust margins
hud.contentView.layout.hMargin = 30
hud.contentView.layout.vMargin = 30
```

### Can I use SF Symbols as custom views?

Yes:

```swift
let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
let image = UIImage(systemName: "wifi.exclamationmark", withConfiguration: config)
let imageView = UIImageView(image: image)
HUD.showStatus(to: view, mode: .custom(imageView), label: "No Connection")
```

## Threading

### Is FlyHUD thread-safe?

All HUD APIs must be called on the main thread. The library uses `@MainActor` isolation
and debug assertions to enforce this. Background work should dispatch to main before
interacting with HUD:

```swift
DispatchQueue.global().async {
    let result = heavyComputation()
    DispatchQueue.main.async {
        hud.contentView.label.text = result
        hud.hide()
    }
}
```

## Migration

### How do I migrate from MBProgressHUD?

FlyHUD is inspired by MBProgressHUD with a modernized API:

| MBProgressHUD | FlyHUD |
| ------------- | ------ |
| `MBProgressHUD.showAdded(to:animated:)` | `HUD.show(to:animated:)` |
| `MBProgressHUD.hide(for:animated:)` | `HUD.hide(for:animated:)` |
| `hud.mode = .text` | `hud.contentView.mode = .text` |
| `hud.label.text` | `hud.contentView.label.text` |
| `hud.progress` | `hud.contentView.progress` |
| `hud.bezelView` | `hud.contentView` |
| `hud.backgroundView` | `hud.backgroundView` |
