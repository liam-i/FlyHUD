# Overview

A comprehensive introduction to FlyHUD's architecture, capabilities, and use cases.

## SDK Positioning

FlyHUD is a lightweight, high-performance HUD (Heads-Up Display) library for Apple platforms.
It serves as a drop-in solution for displaying transient status information — such as
loading spinners, progress bars, success/error indicators, and toast messages — without
blocking the user interface or requiring complex view controller orchestration.

### Core Design Principles

- **Minimal footprint** — No external dependencies; pure UIKit
- **Thread-safe API** — All public methods are `@MainActor`-isolated
- **Composable** — Mix and match indicator, progress, and custom views
- **Customizable** — Fine-grained control over layout, animation, and appearance
- **Accessible** — Supports Dynamic Type, VoiceOver, and RTL layouts

## Architecture

FlyHUD follows a modular architecture with clear dependency boundaries:

@Image(source: "architecture.svg", alt: "FlyHUD module architecture diagram showing the dependency relationships between FlyIndicatorHUD, FlyProgressHUD, and the core FlyHUD module")

```text
┌─────────────────────────────────────────────────┐
│                  Your App                        │
├────────────────┬────────────────┬───────────────┤
│ FlyIndicatorHUD│  FlyProgressHUD│   (optional)  │
├────────────────┴────────────────┴───────────────┤
│                    FlyHUD                        │
│  ┌──────────┐ ┌───────────┐ ┌────────────────┐ │
│  │   HUD    │ │ContentView│ │ BackgroundView │ │
│  │ (root)   │ │(indicator,│ │ (blur, solid,  │ │
│  │          │ │ labels,   │ │  glass)        │ │
│  │          │ │ button)   │ │                │ │
│  └──────────┘ └───────────┘ └────────────────┘ │
│  ┌──────────────────────────────────────────┐   │
│  │  Observables: DisplayLink, Keyboard      │   │
│  └──────────────────────────────────────────┘   │
├─────────────────────────────────────────────────┤
│                    UIKit                         │
└─────────────────────────────────────────────────┘
```

### Module Responsibilities

| Module | Target | Responsibility |
| ------ | ------ | -------------- |
| FlyHUD | `FlyHUD` | Core HUD container, layout engine, animation system, background styles, keyboard tracking |
| FlyIndicatorHUD | `FlyIndicatorHUD` | Custom activity indicator animations (ring, ball spin, circle stroke, arc dot) |
| FlyProgressHUD | `FlyProgressHUD` | Custom progress view styles (bar, round, annular, pie) |

### Dependency Direction

```text
FlyIndicatorHUD ──depends on──▶ FlyHUD ◀──depends on── FlyProgressHUD
```

> Important: `FlyHUD` must never import `FlyIndicatorHUD` or `FlyProgressHUD`.
> Reverse dependencies are strictly forbidden.

## View Hierarchy

When displayed, a HUD instance creates the following view hierarchy:

@Image(source: "view-hierarchy.svg", alt: "FlyHUD view hierarchy diagram showing the tree structure from HUD root to BackgroundView, ContentView, and child UI elements")

```text
UIView (superview)
└── HUD (full-screen overlay)
    ├── BackgroundView (blur/solid/glass)
    └── keyboardGuideView (keyboard offset container)
        └── ContentView (rounded card)
            ├── hStackView
            │   ├── indicator (UIView)
            │   └── vStackView
            │       ├── label (UILabel)
            │       ├── detailsLabel (UILabel)
            │       └── button (UIButton)
            └── ...
```

## Interaction Flow

The following sequence diagram illustrates a typical HUD show → update → hide cycle:

@Image(source: "sequence.svg", alt: "Sequence diagram showing the interaction between App, HUD, ContentView, BackgroundView, and Animation during a complete show-update-hide cycle")

## Use Cases

### Loading States

Display a spinner while fetching data, uploading files, or performing background work.

### Progress Tracking

Show determinate progress for downloads, uploads, file processing, or multi-step workflows.

### Status Messages

Show brief toast-style messages for success, error, or informational feedback.

### Custom Indicators

Display branded or app-specific indicator views with full animation control.

## Platform Compatibility

| Platform | Min Version | Notes |
| -------- | ----------- | ----- |
| iOS | 13.0+ | Full feature set |
| tvOS | 13.0+ | No keyboard guide |
| visionOS | 1.0+ | No keyboard guide, no glass style |

## What's Next

- <doc:getting-started> — Install and display your first HUD
- <doc:basic-features> — Learn the core API
- <doc:advanced-features> — Keyboard tracking, animations, counts
- <doc:custom-ui> — Build custom indicators and progress views
