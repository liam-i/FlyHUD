# FlyHUD UI Tests

## Structure

```text
UITests/
├── HUD/
│   ├── HUDAccessibilityUITests.swift   # VoiceOver: labels, values, hints, traits, modal, escape (28 tests)
│   └── HUDUITests.swift                # Show/hide, rotation, keyboard, navigation stability (13 tests)
├── IndicatorHUD/
│   └── IndicatorHUDUITests.swift       # Indicator styles load without crash (1 test)
├── ProgressHUD/
│   └── ProgressHUDUITests.swift        # Progress mode & styles load (2 tests)
└── SwiftUIHUD/
    └── SwiftUIHUDUITests.swift         # Mode switching, config, VoiceOver accessibility (15 tests)
```

## Running UI Tests

### Quick Start

```bash
# Run all UI tests
./scripts/build.sh test ui

# Run both unit + UI tests
./scripts/build.sh test all
```

### By Module

```bash
# HUD core UI tests
./scripts/build.sh test HUDUITests

# Accessibility UI tests (VoiceOver)
./scripts/build.sh test HUDAccessibilityUITests

# SwiftUI UI tests
./scripts/build.sh test SwiftUIHUDUITests

# Indicator UI tests
./scripts/build.sh test IndicatorHUDUITests

# Progress UI tests
./scripts/build.sh test ProgressHUDUITests
```

### List Available Schemes & Platforms

```bash
./scripts/build.sh list
```

## Coverage

| Module | Tests | Key Areas |
| ------ | :-: | --- |
| HUD (core) | 13 | Show/hide lifecycle, rotation layout, keyboard interaction, navigation stability |
| HUD (accessibility) | 28 | VoiceOver labels/values/hints/traits, modal isolation, Z-scrub escape, progress announcements, Dynamic Type |
| IndicatorHUD | 1 | All indicator styles render without crash |
| ProgressHUD | 2 | Progress mode display, style switching |
| SwiftUIHUD | 15 | Mode switching, configuration views, multiple HUDs, observed progress, VoiceOver integration |

Total: 59 UI tests, 0 failures.

## Notes

* UI tests require the Example iOS app target — they exercise the full app UI
* Accessibility tests verify VoiceOver attributes via `XCUIElement` queries
* Some tests use `app.launchArguments` to configure specific demo states
* Rotation tests use `XCUIDevice.shared.orientation`
* Tests are independent (no ordering dependency)
