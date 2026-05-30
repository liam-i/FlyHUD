# SwiftUI Integration

Use FlyHUD declaratively in SwiftUI with the `FlyHUDSwiftUI` module.

## Overview

`FlyHUDSwiftUI` provides a native SwiftUI API on top of FlyHUD's UIKit core. It offers four levels of abstraction:

| Layer | API | Use Case |
| ----- | --- | -------- |
| Bridge | `.hudHost($hostView)` | Direct UIKit-style control |
| Declarative | `.hud(isPresented:)`, `.hud(item:)`, `.hudStatus(isPresented:)` | Binding-driven state management |
| Convenience | `.hudLoading()`, `.hudToast()`, `.hudProgress()` | Common presets with minimal setup |
| Liquid Glass | `.hudGlass()` | iOS 26+ translucent glass style |

All APIs support iOS 13+, tvOS 13+, and visionOS 1.0+.

### Architecture

The following diagram shows the layered architecture and how each public API flows through internal components to the UIKit core:

![Architecture diagram showing the four API layers of FlyHUDSwiftUI and their relationships to internal components and FlyHUD core](swiftui-architecture.svg)

### How It Works

The following diagram shows the interaction flow between SwiftUI bindings and the UIKit HUD:

![Sequence diagram showing how SwiftUI binding changes flow through HUDModifier, HUDRepresentable, and HUDCoordinator to control HUD visibility](swiftui-bridge.svg)

## Installation

Add `FlyHUDSwiftUI` to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/liam-i/FlyHUD.git", from: "1.7.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "FlyHUDSwiftUI", package: "FlyHUD")
        ]
    )
]
```

Or in Xcode: File → Add Package Dependencies → select `FlyHUDSwiftUI`.

> Note: `FlyHUDSwiftUI` depends on `FlyHUD` automatically. You only need to add `FlyIndicatorHUD` or `FlyProgressHUD` if you use custom indicator/progress styles.

## Import

```swift
import FlyHUDSwiftUI

// Optional — for custom indicator styles
import FlyIndicatorHUD

// Optional — for custom progress styles
import FlyProgressHUD
```

## Layer 1: UIKit Bridge

For maximum control, use `.hudHost()` to obtain a backing UIView, then call UIKit APIs directly:

```swift
struct MyView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack {
            Button("Show HUD") {
                guard let view = hostView else { return }
                HUD.show(to: view, mode: .indicator(), label: "Loading...")
            }
            Button("Hide HUD") {
                guard let view = hostView else { return }
                HUD.hide(for: view)
            }
        }
        .hudHost($hostView)
    }
}
```

This pattern gives you full access to the HUD instance and all configuration options.

## Layer 2: Declarative Modifiers

### Boolean-Driven HUD

Toggle a HUD by binding a Boolean:

```swift
struct DownloadView: View {
    @State private var isLoading = false

    var body: some View {
        Button("Download") {
            isLoading = true
            startDownload { isLoading = false }
        }
        .hud(isPresented: $isLoading) { hud in
            hud.contentView.mode = .indicator()
            hud.contentView.label.text = "Downloading..."
        }
    }
}
```

### Item-Driven HUD

Present different HUD states based on an `Identifiable` item:

```swift
struct HUDItem: Identifiable {
    let id = UUID()
    let mode: ContentView.Mode
    let label: String
}

struct TaskView: View {
    @State private var hudItem: HUDItem?

    var body: some View {
        Button("Start") {
            hudItem = HUDItem(mode: .indicator(), label: "Working...")
        }
        .hud(item: $hudItem) { item, hud in
            hud.contentView.mode = item.mode
            hud.contentView.label.text = item.label
        }
    }
}
```

### Self-Dismissing Status

Show a toast that automatically hides after a duration:

```swift
struct SaveView: View {
    @State private var showSaved = false

    var body: some View {
        Button("Save") {
            save()
            showSaved = true
        }
        .hudStatus(isPresented: $showSaved, duration: 2.0) { hud in
            hud.contentView.mode = .text
            hud.contentView.label.text = "Saved!"
        }
    }
}
```

## Layer 3: Convenience Presets

### Loading Indicator

```swift
MyView()
    .hudLoading(isPresented: $isLoading, label: "Please wait...")
```

### Toast Message

```swift
MyView()
    .hudToast(isPresented: $showToast, duration: 1.5, label: "File deleted")
```

### Progress Tracking

```swift
struct UploadView: View {
    @State private var isUploading = false
    @State private var progress: Float = 0

    var body: some View {
        Button("Upload") { startUpload() }
            .hudProgress(isPresented: $isUploading, progress: $progress, label: "Uploading")
    }
}
```

## Layer 4: Liquid Glass (iOS 26+)

On iOS 26 and later, use the glass style for a modern translucent appearance:

```swift
MyView()
    .hudGlass(isPresented: $isLoading, label: "Loading...")
```

> Important: `.hudGlass()` is only available when compiling with Swift 6.2+ and targeting iOS 26.0 or tvOS 26.0.

## Animation Customization

All declarative modifiers accept an `animation` parameter:

```swift
.hud(isPresented: $isLoading, animation: .init(.zoomInOut, damping: .default)) { hud in
    hud.contentView.mode = .indicator()
}
```

## Migration from UIKit Bridge

If you previously used a local `HUDHostView` helper, you can now:

1. Replace `import FlyHUD` with `import FlyHUDSwiftUI`
2. Remove your local `HUDHostView`, `HUDContainerModifier`, and `hudHost()` definitions
3. The `.hudHost($hostView)` API is now provided by the SDK

For new code, prefer the declarative modifiers (Layer 2/3) over `.hudHost()` for cleaner state management.

## Best Practices

- **One HUD per view hierarchy** — Avoid attaching multiple `.hud()` modifiers to the same view. Use `item:` variant for multiple states.
- **Set binding to `false` on dismissal** — The status modifier does this automatically, but for `.hud(isPresented:)` you must reset the binding yourself.
- **Combine with `FlyIndicatorHUD`/`FlyProgressHUD`** — Custom styles work the same way; just pass them via the configuration closure.
- **Prefer convenience presets** — Use `.hudLoading()`, `.hudToast()`, and `.hudProgress()` for common cases to reduce boilerplate.
