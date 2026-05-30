# Sources - AI Coding Guidelines

## Module Architecture

```text
FlyIndicatorHUD ──depends on──▶ FlyHUD ◀──depends on── FlyProgressHUD
                                  ▲
                                  │
                            FlyHUDSwiftUI
```

> **CRITICAL**: `FlyHUD` must never import `FlyIndicatorHUD`, `FlyProgressHUD`, or `FlyHUDSwiftUI`. Reverse dependencies are strictly forbidden.

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

## FlyHUDSwiftUI (`Sources/SwiftUIHUD/`)

| File | Responsibility |
| ---- | -------------- |
| `View+HUD.swift` | Public `View` extensions: `.hudHost()`, `.hud()`, `.hudStatus()`, `.hudLoading()`, `.hudToast()`, `.hudProgress()`, `.hudGlass()` |
| `HUDHostView.swift` | `HUDTargetView` (bridge UIView), `HUDHostView` (UIViewRepresentable), `HUDContainerModifier` |
| `HUDModifier.swift` | `HUDModifier` (Bool binding), `HUDRepresentable`, `HUDCoordinator` |
| `HUDStatusModifier.swift` | `HUDStatusModifier` (auto-dismiss), `HUDStatusRepresentable`, `HUDStatusCoordinator` |
| `HUDConvenienceModifiers.swift` | `HUDLoadingModifier`, `HUDToastModifier`, `HUDProgressModifier`, `HUDProgressRepresentable` |

### SwiftUI API Layers

| Layer | Modifier | Description |
| ----- | -------- | ----------- |
| 1. Basic Bridge | `.hudHost($hostView)` | Expose UIView binding for direct UIKit-style control |
| 2. Declarative | `.hud(isPresented:)` | Bool-controlled HUD |
| 2. Declarative | `.hud(item:)` | Item-controlled HUD (Identifiable) |
| 2. Declarative | `.hudStatus(isPresented:duration:)` | Self-dismissing status HUD |
| 3. Convenience | `.hudLoading(isPresented:label:)` | Simple loading indicator preset |
| 3. Convenience | `.hudToast(isPresented:label:)` | Self-dismissing text toast preset |
| 3. Convenience | `.hudProgress(isPresented:progress:)` | Progress HUD with bound value |
| 4. Liquid Glass | `.hudGlass(isPresented:label:)` | iOS 26+ glass style preset |

## Public API Quick Reference

### Key HUD Methods

```swift
// Class methods (all return HUD or Bool)
HUD.show(to:animated:mode:label:detailsLabel:populator:)
HUD.show(to:using:mode:label:detailsLabel:populator:)      // with Animation config
HUD.showStatus(to:duration:animated:mode:label:offset:populator:)
HUD.hide(for:animated:afterDelay:) / HUD.hideAll(for:...)
HUD.huds(for:) / HUD.lastHUD(for:)
HUD.makeHUD(with:)                                          // Override point for subclassing

// Instance methods
hud.show(animated:) / hud.show(using:)       // show (or increment count if isCountEnabled)
hud.hide(animated:afterDelay:) / hud.hide(using:afterDelay:)
```

### Key Properties (non-obvious defaults)

| Property | Default | Note |
| -------- | ------- | ---- |
| `graceTime` | `0.0` | **Must set before `show()`** — no effect after |
| `minShowTime` | `0.0` | Prevents flicker for fast tasks |
| `isCountEnabled` | `false` | Reference counter mode (show/hide must balance) |
| `isEventDeliveryEnabled` | `false` | Touch pass-through; syncs with VoiceOver modal |
| `removeFromSuperViewOnHide` | `true` | Set `false` to reuse HUD |
| `contentView.mode` | `.indicator(.large)` | `.text`, `.indicator(_)`, `.progress(_)`, `.custom(_)` |
| `contentView.observedProgress` | `nil` | Auto-binding to Foundation `Progress` |
| `backgroundView.style` | `.solidColor` | `.blur(_)`, `.glass` (iOS 26+/tvOS 26+) |

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

```swift
.fade                                    // default
.animation(.zoomInOut, damping: .default) // with spring bounce
.animation(.slideUp, duration: 0.5)      // custom duration
```

**14 styles**: `.none`, `.fade`, `.zoomInOut`, `.zoomOutIn`, `.zoomIn`, `.zoomOut`, `.slideUpDown`, `.slideDownUp`, `.slideUp`, `.slideDown`, `.slideRightLeft`, `.slideLeftRight`, `.slideRight`, `.slideLeft`

**Damping**: `.disable` (no spring) | `.default` (0.65) | `.ratio(CGFloat)` (custom)

## KeyboardGuide (iOS only)

`.disable` (default) | `.center(offsetY)` (center above keyboard) | `.bottom(spacing)` (relative to keyboard top)

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

## Accessibility (VoiceOver)

### Single-Element Pattern

`ContentView` is the **sole VoiceOver focus element**. All child views (`Label`, `Button`, `ActivityIndicatorView`, `ProgressView`, `HUDTargetView`) have `isAccessibilityElement = false`.

- `HUD`: `accessibilityViewIsModal = true` (prevents focus escape), implements `accessibilityPerformEscape()` for Z-scrub dismissal
- `BackgroundView`: `accessibilityElementsHidden = true`
- `isEventDeliveryEnabled` syncs with `accessibilityViewIsModal`

### ContentView Dynamic Properties

| Property | Value |
| -------- | ----- |
| `accessibilityLabel` | `label.text + ", " + detailsLabel.text` |
| `accessibilityHint` | "Loading in progress" (indicator) / "Task in progress" (progress) / `nil` |
| `accessibilityValue` | `"\(Int(progress * 100))%"` when progress mode, else `nil` |
| `accessibilityTraits` | `.updatesFrequently` (progress/indicator) / `.staticText` (other) |
| `accessibilityCustomActions` | Button action (when button has title + events) |

### Notifications

- Show → `.screenChanged` with `contentView`; Hide → `.screenChanged` with `nil`
- Mode/label/button change → `.layoutChanged`
- Progress milestone (25%) → `.announcement` with percentage string

### Custom View Rule

Views passed via `.custom(UIView)` must set `isAccessibilityElement = false` — ContentView handles all accessibility.
