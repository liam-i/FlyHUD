# Advanced Features

Explore keyboard tracking, animations, grace time, activity counts, and more.

## Animation System

FlyHUD provides a rich animation system for showing and hiding the HUD.

![State diagram showing animation transitions: Hidden → AnimatingIn (fade/zoom/slide) → Visible → AnimatingOut → Hidden, with spring damping and per-hide override.](animation-states.svg)

### Animation Styles

Configure via ``HUD/Animation``:

```swift
// Fade (default)
HUD.show(to: view, using: .animation(.fade))

// Zoom in when appearing, zoom out when disappearing
HUD.show(to: view, using: .animation(.zoomInOut))

// Slide up when appearing, slide down when disappearing
HUD.show(to: view, using: .animation(.slideUpDown))
```

Available styles:

| Style | Description |
| ----- | ----------- |
| `.none` | No animation |
| `.fade` | Opacity transition |
| `.zoomInOut` | Zoom in on show, zoom out on hide |
| `.zoomOutIn` | Zoom out on show, zoom in on hide |
| `.zoomIn` | Always zoom in |
| `.zoomOut` | Always zoom out |
| `.slideUpDown` | Slide up on show, slide down on hide |
| `.slideDownUp` | Slide down on show, slide up on hide |
| `.slideUp` | Always slide up |
| `.slideDown` | Always slide down |
| `.slideRightLeft` | Slide right on show, slide left on hide |
| `.slideLeftRight` | Slide left on show, slide right on hide |
| `.slideRight` | Always slide right |
| `.slideLeft` | Always slide left |

### Spring Damping

Add bounce effects with spring damping:

```swift
// Default damping (0.65)
HUD.show(to: view, using: .animation(.zoomInOut, damping: .default))

// Custom damping ratio (lower = more bounce)
HUD.show(to: view, using: .animation(.slideUpDown, damping: .ratio(0.5)))

// No damping (smooth deceleration)
HUD.show(to: view, using: .animation(.fade, damping: .disable))
```

### Animation Duration

```swift
HUD.show(to: view, using: .animation(.fade, duration: 0.5))
```

### Per-Hide Animation

Override animation when hiding:

```swift
let hud = HUD.show(to: view, using: .animation(.slideUp))

// Hide with a different animation
hud.hide(using: .animation(.slideDown))
```

## Keyboard Layout Guide (iOS)

FlyHUD can automatically adjust its position when the keyboard appears.

### Global Configuration

Set once in `AppDelegate` or `SceneDelegate`:

```swift
// Center HUD in the visible area above keyboard
HUD.keyboardGuide = .center()

// Center with vertical offset
HUD.keyboardGuide = .center(-20.0)

// Keep content bottom above keyboard
HUD.keyboardGuide = .bottom(8.0)
```

### Per-Instance Configuration

Override the global setting for individual HUDs:

```swift
let hud = HUD.show(to: view, label: "Verifying...")
hud.keyboardGuide = .center()
```

### Keyboard Guide Modes

| Mode | Behavior |
| ---- | -------- |
| `.disable` | No keyboard tracking (default) |
| `.center(offsetY)` | Center HUD in visible area above keyboard |
| `.bottom(spacing)` | Position content bottom relative to keyboard top |

> Note: Keyboard guide is only available on iOS. It has no effect on tvOS or visionOS.

## Grace Time

The following diagram illustrates how `graceTime` and `minShowTime` interact:

![Grace Time and MinShowTime sequence diagram showing two scenarios: a fast task where the HUD never appears, and a slow task where the HUD respects minimum display duration.](grace-time.svg)

Prevent HUD from appearing for very short tasks:

```swift
let hud = HUD(with: view)
hud.graceTime = 0.5  // Don't show if task completes within 0.5s
view.addSubview(hud)
hud.show()

// If hide() is called within 0.5s, HUD never appears
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    hud.hide()  // HUD was never shown
}
```

> Important: `graceTime` must be set before calling `show()`. The convenience
> method `HUD.show(to:)` does not support grace time — use manual initialization instead.

## Minimum Show Time

Prevent HUD from flickering by enforcing a minimum display duration:

```swift
let hud = HUD(with: view)
hud.minShowTime = 1.0  // Show for at least 1 second
view.addSubview(hud)
hud.show()

// Even if hide() is called immediately, HUD stays for 1s
hud.hide()
```

## Activity Count

![State diagram showing activity count reference counter: Idle(0) → Active(1) → Active(2) → Active(3), decrements on hide(), HUD only hides when count reaches 0.](activity-count.svg)

Track multiple show/hide pairs with a reference counter:

```swift
let hud = HUD.show(to: view)
hud.isCountEnabled = true

// Each show increments count
hud.show()  // count = 2
hud.show()  // count = 3

// Each hide decrements count; HUD hides only when count reaches 0
hud.hide()  // count = 2, still visible
hud.hide()  // count = 1, still visible
hud.hide()  // count = 0, hides
```

This is useful when multiple subsystems independently request the HUD.

## Event Delivery

Control whether touches pass through the HUD overlay:

```swift
// Default: HUD blocks all touches
hud.isEventDeliveryEnabled = false

// Allow touches outside contentView to pass through
hud.isEventDeliveryEnabled = true
```

When enabled, only touches within the content card are captured by the HUD.
Touches in the surrounding overlay area pass through to the parent view.

## Layout Configuration

### Offset

Position the HUD content relative to center:

```swift
// Bottom of screen
hud.layout.offset = .h.vMaxOffset

// Top of screen
hud.layout.offset = .h.vMinOffset

// Centered (default)
hud.layout.offset = .zero
```

### Edge Insets

Set minimum distance from HUD edges:

```swift
hud.layout.edgeInsets = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
```

### Safe Area

Control whether safe area insets are respected:

```swift
hud.layout.isSafeAreaLayoutGuideEnabled = true  // Default
```

> Warning: `isSafeAreaLayoutGuideEnabled` must be set before the first `show()` call.

## Content View Layout

Fine-tune the content card's internal layout:

```swift
// Margins between card edge and content
hud.contentView.layout.hMargin = 24.0
hud.contentView.layout.vMargin = 24.0

// Spacing between elements
hud.contentView.layout.hSpacing = 12.0
hud.contentView.layout.vSpacing = 8.0

// Minimum content size
hud.contentView.layout.minSize = CGSize(width: 100, height: 100)

// Force square aspect ratio
hud.contentView.layout.isSquare = true

// Text alignment
hud.contentView.layout.alignment = .leading
```

## Motion Effects

Add a parallax tilt effect to the content view:

```swift
hud.contentView.isMotionEffectsEnabled = true
```

## Subclassing

`HUD` is an `open` class. Override `makeHUD(with:)` to provide custom instances:

```swift
class MyHUD: HUD {
    override class func makeHUD(with view: UIView) -> HUD {
        let hud = MyHUD(frame: view.bounds)
        // Custom setup
        return hud
    }
}
```
