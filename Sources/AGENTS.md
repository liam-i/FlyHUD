# Sources - AI Coding Guidelines

## Module Architecture

```text
FlyIndicatorHUD ──depends on──▶ FlyHUD ◀──depends on── FlyProgressHUD
```

> **CRITICAL**: `FlyHUD` must never import `FlyIndicatorHUD` or `FlyProgressHUD`. Reverse dependencies are strictly forbidden.

## FlyHUD Core (`Sources/HUD/`)

| File/Dir | Responsibility |
| -------- | -------------- |
| `HUD.swift` | Main HUD class (~750 lines): lifecycle, show/hide, animations, layout |
| `Model.swift` | Data models: `HUD.Layout`, `HUD.Animation`, `KeyboardGuide` |
| `Views/ContentView.swift` | Content card: indicator + labels + button |
| `Views/BackgroundView.swift` | Background styling: blur, solid color, glass (iOS 26+/tvOS 26+, requires Swift 6.2+ compiler) |
| `Views/BaseView.swift` | Shared base class for content/background views |
| `Views/Label.swift` | Custom label with Dynamic Type support |
| `Views/Button.swift` | HUD action button |
| `Protocols/ActivityIndicatorViewable.swift` | `ActivityIndicatorViewable` protocol |
| `Protocols/ProgressViewable.swift` | `ProgressViewable` protocol |
| `Protocols/RotateViewable.swift` | Simple rotation indicator protocol |
| `Observables/DisplayLink.swift` | `DisplayLink` singleton for progress UI updates |
| `Observables/KeyboardObserver.swift` | `KeyboardObserver` for keyboard tracking |
| `Observables/UnfairLock.swift` | Thread-safe lock (Mutex backport for iOS 13+) |
| `Extensions/` | `HUDExtended` trait, UIColor helpers, etc. |

## FlyIndicatorHUD (`Sources/IndicatorHUD/`)

| File | Responsibility |
| ---- | -------------- |
| `ActivityIndicatorView.swift` | `ActivityIndicatorView` — hosts custom indicator animations |
| `ActivityIndicatorAnimation.swift` | All built-in animation styles (ring, ball spin, etc.) |
| `ShapeBuilder.swift` | CAShapeLayer construction helpers |
| `HUD+ActivityIndicatorView.swift` | Extension on HUD.Mode for `.indicator(Style)` convenience |

## FlyProgressHUD (`Sources/ProgressHUD/`)

| File | Responsibility |
| ---- | -------------- |
| `ProgressView.swift` | `ProgressView` — hosts custom progress animations |
| `ProgressAnimation.swift` | All built-in progress styles (bar, round, pie, etc.) |
| `HUD+ProgressView.swift` | Extension on HUD.Mode for `.progress(Style)` convenience |

## Public API Quick Reference

### HUD Class Methods

| Method | Returns | Description |
| ------ | ------- | ----------- |
| `show(to:animated:mode:label:detailsLabel:populator:)` | `HUD` | Show HUD on view |
| `show(to:using:mode:label:detailsLabel:populator:)` | `HUD` | Show with animation config |
| `showStatus(to:duration:animated:mode:label:offset:populator:)` | `HUD` | Show auto-hiding status |
| `showStatus(to:duration:using:mode:label:offset:populator:)` | `HUD` | Show status with animation config |
| `hide(for:animated:afterDelay:)` | `Bool` | Hide top-most HUD |
| `hide(for:using:afterDelay:)` | `Bool` | Hide with animation override |
| `hideAll(for:animated:afterDelay:)` | `Bool` | Hide all HUDs on view |
| `hideAll(for:using:afterDelay:)` | `Bool` | Hide all with animation override |
| `huds(for:)` | `[HUD]` | Find all HUDs on view |
| `lastHUD(for:)` | `HUD?` | Find top-most HUD |
| `makeHUD(with:)` | `HUD` | Override point for subclassing |

### HUD Instance Methods

| Method | Description |
| ------ | ----------- |
| `show(animated:)` | Show (or increment count if `isCountEnabled`) |
| `show(using:)` | Show with specific animation |
| `hide(animated:afterDelay:)` | Hide (or decrement count) |
| `hide(using:afterDelay:)` | Hide with animation override |

### HUD Properties

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `contentView` | `ContentView` | — | Content card (lazy) |
| `backgroundView` | `BackgroundView` | — | Full-screen overlay (lazy) |
| `layout` | `HUD.Layout` | `.init()` | Position & insets |
| `animation` | `HUD.Animation` | `.fade` | Show/hide animation |
| `graceTime` | `TimeInterval` | `0.0` | Delay before showing (must set before `show()`) |
| `minShowTime` | `TimeInterval` | `0.0` | Minimum display duration |
| `isCountEnabled` | `Bool` | `false` | Activity reference counter mode |
| `isEventDeliveryEnabled` | `Bool` | `false` | Touch pass-through for overlay |
| `keyboardGuide` | `KeyboardGuide?` | `nil` | Per-instance keyboard tracking (iOS) |
| `removeFromSuperViewOnHide` | `Bool` | `true` | Auto-remove on hide |
| `delegate` | `HUDDelegate?` | `nil` | Weak delegate for hide notification |
| `completionBlock` | `((HUD) → Void)?` | `nil` | Called after hide completes |

### Static Properties

| Property | Type | Platform | Description |
| -------- | ---- | -------- | ----------- |
| `HUD.keyboardGuide` | `KeyboardGuide` | iOS | Global keyboard guide setting |

### ContentView

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `mode` | `Mode` | `.indicator(.large)` | Display mode |
| `label` | `UILabel` | — | Primary text (bold) |
| `detailsLabel` | `UILabel` | — | Secondary text (multi-line) |
| `button` | `Button` | — | Action button |
| `indicatorPosition` | `IndicatorPosition` | `.top` | Where indicator sits relative to labels |
| `contentColor` | `UIColor?` | system | Unified color for all content |
| `isDynamicTypeEnabled` | `Bool` | `false` | Dynamic Type for labels |
| `isMotionEffectsEnabled` | `Bool` | `false` | Parallax tilt effect |
| `progress` | `Float` | `0.0` | Manual progress (0.0–1.0) |
| `observedProgress` | `Progress?` | `nil` | Auto-binding progress |
| `layout` | `ContentView.Layout` | — | Margins, spacing, alignment |
| `style` | `Style` | `.blur(...)` | Background style for card |
| `color` | `UIColor?` | — | Background color for card |
| `roundedCorners` | `RoundedCorners` | `.radius(...)` | Corner style |

### ContentView.Mode Cases

| Case | Description |
| ---- | ----------- |
| `.text` | Labels only, no indicator |
| `.indicator(UIActivityIndicatorView.Style)` | System spinner |
| `.progress(UIProgressView.Style)` | System progress bar |
| `.custom(UIView)` | Any custom view |

### BackgroundView

| Property | Type | Default | Description |
| -------- | ---- | ------- | ----------- |
| `style` | `Style` | `.solidColor` | solidColor, blur, or glass (iOS 26+/tvOS 26+) |
| `color` | `UIColor?` | `.clear` | Background color |
| `roundedCorners` | `RoundedCorners` | `.radius(0)` | Corner radius |

### Protocols for Custom Views

| Protocol | Purpose | Key Requirements |
| -------- | ------- | ---------------- |
| `ActivityIndicatorViewStyleable` | Define indicator style | `makeAnimation()`, `defaultSize`, `defaultColor` |
| `ActivityIndicatorAnimationBuildable` | Build CALayer animation | `make(in:color:trackColor:lineWidth:)` |
| `ProgressViewStyleable` | Define progress style | `makeAnimation()`, `defaultSize`, `defaultProgressTintColor` |
| `ProgressAnimationBuildable` | Draw progress layers | `makeShape(in:progress:color:trackColor:lineWidth:)` |
| `RotateViewable` | Rotation-only indicator | `duration: CFTimeInterval` |
| `ProgressViewable` | Full progress contract | `progress`, `progressTintColor`, `observedProgress` |
| `HUDDelegate` | Hide notification | `hudWasHidden(_:)` |
| `ActivityIndicatorViewable` | Indicator lifecycle | `startAnimating()`, `stopAnimating()`, `isAnimating` |

## Animation System

### HUD.Animation

```swift
// Static constructors
.fade                                    // default
.animation(.fade)                        // explicit
.animation(.zoomInOut, damping: .default) // with spring bounce
.animation(.slideUp, duration: 0.5)      // custom duration
```

### Available Styles (14 total)

`.none`, `.fade`, `.zoomInOut`, `.zoomOutIn`, `.zoomIn`, `.zoomOut`,
`.slideUpDown`, `.slideDownUp`, `.slideUp`, `.slideDown`,
`.slideRightLeft`, `.slideLeftRight`, `.slideRight`, `.slideLeft`

### Damping Options

| Case | Effect |
| ---- | ------ |
| `.disable` | No spring (smooth deceleration) |
| `.default` | Standard bounce (0.65 ratio) |
| `.ratio(CGFloat)` | Custom ratio (lower = more bounce) |

## KeyboardGuide (iOS only)

| Mode | Behavior |
| ---- | -------- |
| `.disable` | No keyboard tracking (default) |
| `.center(offsetY)` | Center HUD in visible area above keyboard |
| `.bottom(spacing)` | Position bottom relative to keyboard top |

## Concurrency & Thread Safety

### Actor Isolation

All UIView subclasses (`HUD`, `ContentView`, `BackgroundView`, `Label`, `Button`) inherit `@MainActor` from UIKit. Do NOT add `@MainActor` redundantly.

### Thread-Safe Singletons

| Type | Protection | Usage |
| ---- | ---------- | ----- |
| `DisplayLink.shared` | `@unchecked Sendable` + `UnfairLock` | Manages delegate list thread-safely |
| `KeyboardObserver.shared` | `@unchecked Sendable` + `UnfairLock` | Manages observer list thread-safely |

### deinit Pattern (Swift 6.2+)

```swift
#if compiler(>=6.2)
    isolated deinit {
        // Direct MainActor-isolated cleanup
    }
#else
    deinit {
        MainActor.assumeIsolated {
            // Cleanup requiring MainActor
        }
    }
#endif
```

### UnfairLock (Mutex Backport)

`UnfairLock` in `Observables/` is a lightweight synchronization primitive for protecting shared mutable state in `@unchecked Sendable` types. It wraps `os_unfair_lock` with `withLock(_:)` API similar to Swift 6's `Mutex`.
