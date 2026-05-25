# ``FlyHUD``

A lightweight and easy-to-use HUD for displaying progress and status of ongoing tasks on iOS, tvOS, and visionOS.

## Overview

FlyHUD provides a simple yet powerful API for displaying Heads-Up Display (HUD) overlays in your app. It supports activity indicators, progress bars, text messages, and fully custom views with rich animation and layout options.

### Key Capabilities

- **Activity Indicators** — Built-in and custom spinner styles
- **Progress Views** — Bar, ring, pie, and annular progress styles
- **Text & Custom Views** — Toast-style messages and arbitrary UIView content
- **Animations** — Fade, zoom, slide with spring damping
- **Keyboard Tracking** — Automatic layout adjustment when keyboard appears
- **Dark Mode** — Full support for light and dark appearance
- **Accessibility** — Dynamic Type support for HUD labels

### Module Architecture

FlyHUD is split into three independent modules:

| Module | Description |
| ------ | ----------- |
| `FlyHUD` | Core HUD class, layout, animation, background |
| `FlyIndicatorHUD` | Custom activity indicator styles |
| `FlyProgressHUD` | Custom progress view styles |

### Platform Support

| Platform | Minimum Version |
| -------- | --------------- |
| iOS | 13.0+ |
| tvOS | 13.0+ |
| visionOS | 1.0+ |

## Topics

### Essentials

- <doc:overview>
- <doc:getting-started>
- <doc:basic-features>

### Guides

- <doc:advanced-features>
- <doc:custom-ui>
- <doc:best-practices>
- <doc:testing>

### Reference

- <doc:faq>
- <doc:privacy>
- <doc:benchmark>
- <doc:release-notes>

### Core Types

- ``HUD``
- ``HUDDelegate``

### Content View

- ``ContentView``
- ``BackgroundView``
- ``BaseView``
- ``Button``
- ``Label``

### Layout & Animation

- ``HUD/Layout``
- ``HUD/Animation``

### Protocols

- ``ActivityIndicatorViewable``
- ``ProgressViewable``
- ``RotateViewable``

### Observables

- ``DisplayLink``
- ``DisplayLinkDelegate``
- ``KeyboardObserver``
- ``KeyboardObservable``
- ``KeyboardInfo``
