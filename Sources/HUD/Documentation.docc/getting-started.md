# Getting Started

Install FlyHUD and display your first HUD in minutes.

## Installation

### Swift Package Manager

Add FlyHUD to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/liam-i/FlyHUD.git", from: "1.6.0")
],
targets: [
    .target(
        name: "MyTarget",
        dependencies: [
            .product(name: "FlyHUD", package: "FlyHUD"),
            .product(name: "FlyIndicatorHUD", package: "FlyHUD"),  // Optional
            .product(name: "FlyProgressHUD", package: "FlyHUD")    // Optional
        ]
    )
]
```

Or in Xcode:

1. File → Add Package Dependencies
2. Enter `https://github.com/liam-i/FlyHUD.git`
3. Select "Up to Next Minor" with "1.6.0"
4. Choose the library products you need

### CocoaPods

```ruby
platform :ios, '13.0'
use_frameworks!

target 'MyApp' do
  pod 'FlyHUD', '~> 1.6.0'
end
```

Run `pod install` to install.

### Carthage

```ruby
github "liam-i/FlyHUD" ~> 1.6.0
```

Run `carthage update --platform iOS --use-xcframeworks`.

## Import

Import the modules you need:

```swift
import FlyHUD

// Optional — for custom indicator styles
import FlyIndicatorHUD

// Optional — for custom progress styles
import FlyProgressHUD
```

## Hello World

### Show a Loading HUD

```swift
// Show a loading spinner
let hud = HUD.show(to: view)

// Perform async work
DispatchQueue.global().async {
    // ... your task ...
    DispatchQueue.main.async {
        hud.hide()
    }
}
```

### Show a Progress HUD

```swift
let hud = HUD.show(to: view, mode: .progress(), label: "Downloading")

// Update progress (0.0 to 1.0)
hud.contentView.progress = 0.5

// Hide when done
hud.hide()
```

### Show a Status Message

```swift
// Toast-style message that auto-hides after 2 seconds
HUD.showStatus(to: view, label: "File saved successfully")
```

### Show a Custom View

```swift
let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
HUD.showStatus(to: view, mode: .custom(checkmark), label: "Done!")
```

## Lifecycle Flow

The typical HUD lifecycle follows this pattern:

@Image(source: "lifecycle.svg", alt: "HUD lifecycle state diagram showing transitions from Created through Showing, Updating, Hiding, to Hidden states")

```text
┌─────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Create  │────▶│   Show   │────▶│  Update  │────▶│   Hide   │
│          │     │(animated)│     │(progress,│     │(animated)│
│HUD.show()│     │          │     │ label)   │     │hud.hide()│
└─────────┘     └──────────┘     └──────────┘     └──────────┘
                                                         │
                                                         ▼
                                                   ┌──────────┐
                                                   │ Callback │
                                                   │delegate/ │
                                                   │completion│
                                                   └──────────┘
```

## Thread Safety

> Warning: HUD is a UI class and must only be accessed on the main thread.

All HUD operations — show, hide, property changes — must be performed on
the main thread. The library asserts this in debug builds.

```swift
DispatchQueue.global().async {
    // Do background work...
    DispatchQueue.main.async {
        // Always interact with HUD on main thread
        hud.hide()
    }
}
```

## Next Steps

- <doc:basic-features> — Explore all display modes and configurations
- <doc:advanced-features> — Keyboard tracking, animation customization, activity counts
- <doc:custom-ui> — Build your own indicator and progress views
