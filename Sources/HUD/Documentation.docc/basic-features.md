# Basic Features

Learn the fundamental display modes, configurations, and lifecycle of FlyHUD.

![State diagram showing HUD lifecycle: Created → Showing → Updating → Hiding → Hidden, including grace time and minimum show time states.](basic-lifecycle.svg)

## Display Modes

FlyHUD supports four primary display modes through ``ContentView/Mode``:

### Text Only

Displays labels and an optional button without any indicator:

```swift
HUD.showStatus(to: view, mode: .text, label: "Network error")
```

### System Activity Indicator

Uses `UIActivityIndicatorView` with configurable style:

```swift
// Large spinner (default)
HUD.show(to: view, mode: .indicator(.large))

// Medium spinner
HUD.show(to: view, mode: .indicator(.medium))
```

### System Progress View

Uses `UIProgressView` with configurable style:

```swift
let hud = HUD.show(to: view, mode: .progress(.default))
hud.contentView.progress = 0.75
```

### Custom View

Display any `UIView` as the HUD indicator:

```swift
let imageView = UIImageView(image: UIImage(systemName: "checkmark.circle"))
HUD.show(to: view, mode: .custom(imageView), label: "Success")
```

## Show and Hide

### Basic Show/Hide

```swift
// Show with default animation
let hud = HUD.show(to: view)

// Hide with default animation
hud.hide()
```

### Animated vs. Immediate

```swift
// Show without animation
let hud = HUD.show(to: view, animated: false)

// Hide without animation
hud.hide(animated: false)
```

### Auto-Hide with Duration

`showStatus` automatically hides after a specified duration:

```swift
// Hides after 2 seconds (default)
HUD.showStatus(to: view, label: "Saved")

// Hides after 5 seconds
HUD.showStatus(to: view, duration: 5.0, label: "Processing complete")
```

### Hide with Delay

```swift
hud.hide(afterDelay: 1.5)
```

### Class-Level Hide

Find and hide HUDs by their parent view:

```swift
// Hide the top-most HUD
HUD.hide(for: view)

// Hide all HUDs on a view
HUD.hideAll(for: view)
```

## Labels

FlyHUD provides two labels for displaying text:

```swift
let hud = HUD.show(to: view)
hud.contentView.label.text = "Loading..."
hud.contentView.detailsLabel.text = "Please wait while we process your request"
```

- **label** — Primary text (bold, single line by default)
- **detailsLabel** — Secondary text (smaller, multi-line)

## Button

A button is included in the content view. It's visible only when a title and action are set:

```swift
let hud = HUD.show(to: view, label: "Downloading")
hud.contentView.button.setTitle("Cancel", for: .normal)
hud.contentView.button.addTarget(self, action: #selector(cancelDownload), for: .touchUpInside)
```

## Progress Tracking

### Manual Progress

```swift
let hud = HUD.show(to: view, mode: .progress(.default))
hud.contentView.progress = 0.0

// Update as work progresses
hud.contentView.progress = 0.5
hud.contentView.progress = 1.0
```

### Observed Progress

Bind to a `Progress` object for automatic updates:

```swift
let hud = HUD.show(to: view, mode: .progress(.default))
hud.contentView.observedProgress = myProgress

// Labels auto-update from Progress.localizedDescription
// and Progress.localizedAdditionalDescription
```

## Content View Layout

![Diagram showing ContentView internal layout with indicator position options (top, leading) and the arrangement of indicator, label, detailsLabel, and button.](content-layout.svg)

## Background Styles

Configure the HUD background via ``BackgroundView``:

```swift
let hud = HUD.show(to: view)

// Blur (default)
hud.contentView.style = .blur(.systemThickMaterial)

// Solid color
hud.contentView.style = .solidColor
hud.contentView.color = UIColor.black.withAlphaComponent(0.8)
```

The full-screen overlay background is also configurable:

```swift
hud.backgroundView.style = .solidColor
hud.backgroundView.color = UIColor.black.withAlphaComponent(0.3)
```

## Indicator Position

Control where the indicator appears relative to labels:

```swift
let hud = HUD.show(to: view, mode: .custom(myImage), label: "Done")

// Position options: .top (default), .bottom, .leading, .trailing
hud.contentView.indicatorPosition = .leading
```

## Content Color

Set a unified color for all content (labels, indicator, button):

```swift
hud.contentView.contentColor = .white
```

Set to `nil` to manage each element's color individually.

## Populator Block

Use the trailing closure to configure HUD properties inline:

```swift
HUD.show(to: view, mode: .indicator(.large), label: "Loading") { hud in
    hud.contentView.detailsLabel.text = "Fetching data..."
    hud.contentView.contentColor = .systemBlue
    hud.layout.offset = .zero
}
```

## Finding HUDs

Retrieve existing HUDs from a view:

```swift
// Get all active HUDs
let allHuds = HUD.huds(for: view)

// Get the top-most HUD
if let topHud = HUD.lastHUD(for: view) {
    topHud.contentView.label.text = "Almost done..."
}
```

## Delegate & Completion

Get notified when a HUD finishes hiding:

```swift
// Via delegate
hud.delegate = self

// Via completion block
hud.completionBlock = { hud in
    print("HUD was hidden")
}
```

Implement `HUDDelegate`:

```swift
func hudWasHidden(_ hud: HUD) {
    // Clean up or navigate
}
```
