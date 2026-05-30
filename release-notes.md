# Release Notes

Detailed release notes for all FlyHUD versions. For the full changelog, see the
<doc:CHANGELOG> file.

## 1.6.0 (May 25, 2026)

### Highlights

- **SwiftUI Support** — New `FlyHUDSwiftUI` module with 4-layer declarative API (`.hudHost()`, `.hud(isPresented:)`, convenience modifiers, `.hudGlass()`)
- **visionOS** — First-class platform support (no longer "Designed for iPhone")
- **Liquid Glass** — New `.glass` background style for iOS 26+ and tvOS 26+
- **VoiceOver** — Z-scrub dismissal and mode-aware accessibility hints
- **Dynamic Type** — HUD labels scale with user font size preference

### Other Additions

- Swift 6.2 `isolated deinit` support
- `UnfairLock` thread-safety utility (Mutex backport for iOS 13+)
- Full DocC documentation suite
- tvOS example app
- Unified build scripts (`scripts/build.sh`, `scripts/build-docs.sh`)
- 699 automated tests (unit + integration + UI)

### Changes

- Minimum deployment: iOS 13.0, tvOS 13.0, visionOS 1.0
- Keyboard observer uses UIScene-compatible window acquisition
- Example SwiftUI app uses `FlyHUDSwiftUI` module (replaced local bridge)

### Fixes

- Fixed unbalanced `hide()` calls firing delegate/completion multiple times
- Fixed old indicator animations not stopped when switching HUD mode
- Fixed stale rendering when switching `ProgressView` styles
- Fixed SwiftUI HUD reuse glitch when item ID changes rapidly
- Fixed keyboard transform not reset causing mispositioned HUD on re-show
- Fixed VoiceOver `.layoutChanged` not posted on button target changes
- Fixed `ProgressAnimation.Bar` geometry errors (wrong coordinate space and potential NaN)
- Added defensive clamping in `ShapeBuilder` / `ActivityIndicatorAnimation` / `ProgressAnimation` to prevent negative radius for extreme bounds
- Improved `KeyboardObserver` performance by caching `connectedScenes`

**Full Changelog:** [1.5.13...1.6.0](https://github.com/liam-i/FlyHUD/compare/1.5.13...1.6.0)

---

## 1.5.13 (August 1, 2025)

### New Features

- Condition comments for platform-specific code
- Xcode 26 adaptation

### Fixes

- Extension conformance of imported type 'Mode' to imported protocol
  'CustomStringConvertible' warning resolved
- `keyWindow` deprecation replaced with UIScene-compatible window acquisition
- `didChangeStatusBarOrientationNotification` replaced with
  `UIDevice.orientationDidChangeNotification`
- Overriding declaration requires an 'override' keyword
  ([#4](https://github.com/liam-i/FlyHUD/issues/4))

**Full Changelog:** [1.5.12...1.5.13](https://github.com/liam-i/FlyHUD/compare/1.5.12...1.5.13)

---

## 1.5.12 (May 9, 2024)

### New Features

- Privacy manifest (`PrivacyInfo.xcprivacy`) for App Store compliance
- visionOS support added to CocoaPods podspec

### Changes

- Bumped CocoaPods minimum version requirement

**Full Changelog:** [1.5.11...1.5.12](https://github.com/liam-i/FlyHUD/compare/1.5.11...1.5.12)

---

## 1.5.11 (May 9, 2024)

### Changes

- Default to dynamic library for SPM

**Full Changelog:** [1.5.10...1.5.11](https://github.com/liam-i/FlyHUD/compare/1.5.10...1.5.11)

---

## 1.5.10 (March 29, 2024)

### New Features

- visionOS platform support

### Fixes

- Bug fixes

**Full Changelog:** [1.5.9...1.5.10](https://github.com/liam-i/FlyHUD/compare/1.5.9...1.5.10)

---

## 1.5.9 (March 28, 2024)

### Fixes

- Version-specific Package.swift improvements

**Full Changelog:** [1.5.8...1.5.9](https://github.com/liam-i/FlyHUD/compare/1.5.8...1.5.9)

---

## 1.5.8 (March 28, 2024)

### Fixes

- Fix defining a version-specific Package.swift

**Full Changelog:** [1.5.7...1.5.8](https://github.com/liam-i/FlyHUD/compare/1.5.7...1.5.8)

---

## 1.5.7 (March 27, 2024)

### Changes

- Internal improvements

**Full Changelog:** [1.5.6...1.5.7](https://github.com/liam-i/FlyHUD/compare/1.5.6...1.5.7)

---

## 1.5.6 (March 8, 2024)

### Breaking Changes

- Renamed from LPHUD to FlyHUD

### Changes

- Upgraded iOS and tvOS deployment targets to 12.0

**Full Changelog:** [1.5.4...1.5.6](https://github.com/liam-i/FlyHUD/compare/1.5.4...1.5.6)

---

## 1.5.4 (February 5, 2024)

### New Features

- Carthage support

**Full Changelog:** [1.5.3...1.5.4](https://github.com/liam-i/FlyHUD/compare/1.5.3...1.5.4)

---

## 1.5.3 (February 4, 2024)

### New Features

- Right-to-left (RTL) layout support (e.g. Arabic)

### Changes

- Updated access levels
- Improved documentation comments

**Full Changelog:** [1.4.0...1.5.3](https://github.com/liam-i/FlyHUD/compare/1.4.0...1.5.3)

---

## 1.4.0 (January 30, 2024)

### Breaking Changes

- Redesigned public API with HUDExtension pattern

### Changes

- Major architecture refactoring
- Modularized into FlyHUD, FlyIndicatorHUD, and FlyProgressHUD targets

**Full Changelog:** [1.3.7...1.4.0](https://github.com/liam-i/FlyHUD/compare/1.3.7...1.4.0)

---

## 1.3.7 (January 15, 2024)

### Changes

- Internal improvements and optimizations

**Full Changelog:** [1.2.6...1.3.7](https://github.com/liam-i/FlyHUD/compare/1.2.6...1.3.7)

---

## 1.2.6 (June 17, 2022)

### Changes

- Code style adjustments

**Full Changelog:** [1.1.0...1.2.6](https://github.com/liam-i/FlyHUD/compare/1.1.0...1.2.6)

---

## 1.1.0 (March 13, 2020)

### Initial Release

- Activity indicator styles
- Progress view styles
- Text-only HUD mode
- Custom view HUD mode
- Animation system (fade, zoom, slide)
- Keyboard layout guide
- Dark mode support
- CocoaPods support
