# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.6.1] - 2026-05-30

### Added

- `.spi.yml` manifest for Swift Package Index build and documentation configuration

### Fixed

- Fixed Swift Package Index builds failing on all platforms due to missing platform configuration

## [1.6.0] - 2026-05-25

### Added

- **FlyHUDSwiftUI module** — Native SwiftUI support with declarative API
  - 4-layer API: `.hudHost()`, `.hud(isPresented:)`, `.hudLoading()/.hudToast()/.hudProgress()`, `.hudGlass()`
  - UIViewRepresentable bridge with @MainActor coordinators (Swift 6 safe)
  - CocoaPods subspec `FlyHUD/FlyHUDSwiftUI`
- **Native visionOS support** — first-class platform target (no longer "Designed for iPhone")
- **Liquid Glass background style** (`.glass`) for iOS 26+ and tvOS 26+
- **DocC documentation** — full article suite: getting-started, overview, basic/advanced features, SwiftUI integration, custom UI, testing, best practices, benchmark, FAQ, privacy policy
- **VoiceOver accessibility** — `accessibilityPerformEscape()` Z-scrub dismissal, mode-aware `accessibilityHint`
- **Dynamic Type** support for HUD labels (`isDynamicTypeEnabled`)
- Swift 6.2 `isolated deinit` support with fallback for older compilers
- `UnfairLock` utility for thread-safe state management (Mutex backport for iOS 13+)
- tvOS example app with UIScene lifecycle and focus interaction
- `scripts/build.sh` — unified build/test/clean script (all platforms, help, DerivedData clean, platform validation)
- `scripts/build-docs.sh` — DocC build, preview, export, and GitHub Pages deploy pipeline
- SPM test targets for all modules (`FlyHUDTests`, `FlyIndicatorHUDTests`, `FlyProgressHUDTests`, `SwiftUIHUDTests`)
- End-to-end UI test suite (59 tests: VoiceOver, lifecycle, rotation, keyboard, navigation)
- `release-notes.md` — version history (symlinked into DocC)

### Changed

- Minimum deployment target raised to iOS 13.0, tvOS 13.0, visionOS 1.0
- Improved keyboard observer to use UIScene-compatible window acquisition
- Removed redundant `proxy` property from `DisplayLink` (lifecycle managed by CADisplayLink)
- Example SwiftUI app migrated from local bridge to `FlyHUDSwiftUI` module
- Test count increased from 279 to 699 (unit + integration + UI)
- All developer documentation (`AGENTS.md`, `CLAUDE.md`, `Tests/README.md`, etc.) updated to use `scripts/build.sh` commands

### Removed

- `Tests/Tests.swift` (migrated to `Tests/HUD/HUDTests.swift`)
- `Example SwiftUI/Helpers/HUDHostView.swift` (replaced by `import FlyHUDSwiftUI`)
- Empty `Frameworks` PBXGroup from Xcode project navigator

### Fixed

- Fixed `isCountEnabled` allowing unbalanced `hide()` calls to fire delegate/completion multiple times
- Fixed old indicator animations not being stopped when switching HUD mode
- Fixed `ProgressView` style change not clearing cached `animationBuilder`, causing stale rendering after switching styles
- Fixed SwiftUI `HUDItemCoordinator` reusing a hiding HUD when item ID changes, causing visual glitches
- Fixed `keyboardGuideView.transform` not reset on hide, causing incorrect HUD position when re-shown with keyboard visible
- Fixed `Button.addTarget`/`removeTarget` not posting VoiceOver `.layoutChanged` notification
- Fixed `KeyboardObserver` redundantly traversing `connectedScenes` twice; now caches the scene array
- Fixed `ProgressAnimation.Bar` using `layer.frame.size` instead of `layer.bounds.size` and `acos` returning NaN when input exceeds [-1, 1]
- Added defensive geometry clamping (`max(0.0, ...)`) in `ShapeBuilder`, `BallSpinFade`, `CircleArcDotSpin`, and `Round` (annular mode) to prevent negative radius/size for extreme bounds
- Fixed documentation comments: incorrect default values, typos, broken URL references
- Fixed test compliance: `UnfairLockTests` Swift 6 concurrency, `ButtonTests`/`LabelTests` nil assertions, `HUDExtendedTests` spurious `@retroactive`

## [1.5.13] - 2025-08-01

### Added

- Condition comments for platform-specific code
- Xcode 26 adaptation

### Fixed

- Extension declares a conformance of imported type 'Mode' to imported protocol 'CustomStringConvertible'; this will not behave correctly if the owners of 'FlyHUD' introduce this conformance in the future
- `keyWindow` was deprecated in iOS 13.0: Should not be used for applications that support multiple scenes as it returns a key window across all connected scenes
- `didChangeStatusBarOrientationNotification` was deprecated in iOS 13.0: Use `UIDevice.orientationDidChangeNotification`
- Overriding declaration requires an 'override' keyword ([#4](https://github.com/liam-i/FlyHUD/issues/4))

## [1.5.12] - 2024-05-09

### Added

- Privacy manifest (`PrivacyInfo.xcprivacy`)
- visionOS support to the CocoaPods podspec

### Changed

- Bumped CocoaPods minimum version requirement

## [1.5.11] - 2024-05-09

### Changed

- Default to dynamic library for SPM

## [1.5.10] - 2024-03-29

### Added

- visionOS platform support

### Fixed

- Bug fixes

## [1.5.9] - 2024-03-28

### Fixed

- Version-specific Package.swift improvements

## [1.5.8] - 2024-03-28

### Fixed

- Fix defining a version-specific Package.swift

## [1.5.7] - 2024-03-27

### Changed

- Internal improvements

## [1.5.6] - 2024-03-08

### Changed

- Renamed from LPHUD to FlyHUD
- Upgraded iOS and tvOS deployment targets to 12.0

## [1.5.4] - 2024-02-05

### Added

- Carthage support

## [1.5.3] - 2024-02-04

### Added

- Right-to-left (RTL) layout support (e.g. Arabic)

### Changed

- Updated access levels
- Improved documentation comments

## [1.4.0] - 2024-01-30

### Changed

- Major architecture refactoring
- Modularized into FlyHUD, FlyIndicatorHUD, and FlyProgressHUD targets
- Redesigned public API with HUDExtension pattern

## [1.3.7] - 2024-01-15

### Changed

- Internal improvements and optimizations

## [1.2.6] - 2022-06-17

### Changed

- Code style adjustments

## [1.1.0] - 2020-03-13

### Added

- Initial public release with CocoaPods support
- Activity indicator styles
- Progress view styles
- Text-only HUD mode
- Custom view HUD mode
- Animation system (fade, zoom, slide)
- Keyboard layout guide
- Dark mode support

[1.6.1]: https://github.com/liam-i/FlyHUD/compare/1.6.0...1.6.1
[1.6.0]: https://github.com/liam-i/FlyHUD/compare/1.5.13...1.6.0
[1.5.13]: https://github.com/liam-i/FlyHUD/compare/1.5.12...1.5.13
[1.5.12]: https://github.com/liam-i/FlyHUD/compare/1.5.11...1.5.12
[1.5.11]: https://github.com/liam-i/FlyHUD/compare/1.5.10...1.5.11
[1.5.10]: https://github.com/liam-i/FlyHUD/compare/1.5.9...1.5.10
[1.5.9]: https://github.com/liam-i/FlyHUD/compare/1.5.8...1.5.9
[1.5.8]: https://github.com/liam-i/FlyHUD/compare/1.5.7...1.5.8
[1.5.7]: https://github.com/liam-i/FlyHUD/compare/1.5.6...1.5.7
[1.5.6]: https://github.com/liam-i/FlyHUD/compare/1.5.4...1.5.6
[1.5.4]: https://github.com/liam-i/FlyHUD/compare/1.5.3...1.5.4
[1.5.3]: https://github.com/liam-i/FlyHUD/compare/1.4.0...1.5.3
[1.4.0]: https://github.com/liam-i/FlyHUD/compare/1.3.7...1.4.0
[1.3.7]: https://github.com/liam-i/FlyHUD/compare/1.2.6...1.3.7
[1.2.6]: https://github.com/liam-i/FlyHUD/compare/1.1.0...1.2.6
[1.1.0]: https://github.com/liam-i/FlyHUD/releases/tag/1.1.0
