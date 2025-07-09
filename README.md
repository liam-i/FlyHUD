![FlyHUD: Easy-to-use HUD in Swift](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/logo-dark.png#gh-dark-mode-only)
![FlyHUD: Easy-to-use HUD in Swift](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/logo-light.png#gh-light-mode-only)

[![Swift](https://img.shields.io/badge/Swift-5.7_5.8_5.9_5.10-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.7_5.8_5.9_5.10-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS_visionOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_tvOS_visionOS-Green?style=flat-square)
[![CocoaPods](https://img.shields.io/cocoapods/v/FlyHUD.svg?style=flat)](https://cocoapods.org/pods/FlyHUD)
[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager)
[![Carthage](https://img.shields.io/badge/Carthage-supported-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Doc](https://img.shields.io/badge/Swift-Doc-DE5C43.svg?style=flat)](https://liam-i.github.io/FlyHUD/main/documentation/flyhud)
[![License](https://img.shields.io/cocoapods/l/FlyHUD.svg?style=flat)](https://github.com/liam-i/FlyHUD/blob/main/LICENSE)

English | [简体中文](./README_CN.md)

This is a lightweight and easy-to-use HUD designed to display the progress and status of ongoing tasks on iOS and tvOS.

## ScreenShots

[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-1-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-1.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-2-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-2.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-3-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-3.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-4-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-4.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-6-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-6.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-8-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-8.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-7-small.png)](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/1-7.png)

## Requirements

* iOS 13.0+ 
* tvOS 13.0+ 
* Xcode 14.1+
* Swift 5.7.1+

## Installation

### Swift Package Manager

#### ...using `swift build`

If you are using the [Swift Package Manager](https://www.swift.org/documentation/package-manager), add a dependency to your `Package.swift` file and import the HUD library into the desired targets:
```swift
dependencies: [
    .package(url: "https://github.com/liam-i/FlyHUD.git", from: "1.5.12")
],
targets: [
    .target(
        name: "MyTarget", dependencies: [
            .product(name: "FlyHUD", package: "FlyHUD"),         // Optional
            .product(name: "FlyProgressHUD", package: "FlyHUD"), // Optional
            .product(name: "FlyIndicatorHUD", package: "FlyHUD") // Optional
        ])
]
```

#### ...using Xcode

If you are using Xcode, then you should:

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/liam-i/FlyHUD.git`
- Select "Up to Next Minor" with "1.5.12"

> [!TIP]
> For detailed tutorials, see: [Apple Docs](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

### CocoaPods

If you're using [CocoaPods](https://cocoapods.org), add this to your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
# Or use CND source
# source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'
use_frameworks!

target 'MyApp' do
  # Use the FlyHUD, FlyIndicatorHUD and FlyProgressHUD components.
  pod 'FlyHUD', '~> 1.5.12'

  # Or, just use the FlyHUD component.
  pod 'FlyHUD', '~> 1.5.12', :subspecs => ['FlyHUD']

  # Or, just use the FlyHUD and FlyIndicatorHUD components.
  pod 'FlyHUD', '~> 1.5.12', :subspecs => ['FlyIndicatorHUD']

  # Or, just use the FlyHUD and FlyProgressHUD components.
  pod 'FlyHUD', '~> 1.5.12', :subspecs => ['FlyProgressHUD']
end
```

And run `pod install`.

> [!IMPORTANT]  
> CocoaPods 1.13.0 or newer is required.

### Carthage

If you're using [Carthage](https://github.com/Carthage/Carthage), add this to your `Cartfile`:

```ruby
github "liam-i/FlyHUD" ~> 1.5.12
```

And run `carthage update --platform iOS --use-xcframeworks`.

## Usage

Using `HUD` in your application is very simple.

* Displays the status HUD of an indeterminate tasks:

```swift
let hud = HUD.show(to: view)
DispatchQueue.global().async {
    // Do something...
    DispatchQueue.main.async {
        hud.hide()
    }
}
```

* Displays a task's progress HUD:

```swift
let hud = HUD.show(to: view, mode: .progress(), label: "Loading")
Task.request { progress in
    hud.progress = progress
} completion: {
    hud.hide()
}
```

* Displays a text-only status HUD:

```swift
HUD.showStatus(to: view, label: "Wrong password")
```

* Displays a custom view's status HUD. e.g. a UIImageView:

```swift
HUD.showStatus(to: view, mode: .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))), label: "Completed")
```

* Displays a custom view's status HUD. And the UIImageView is on the left:

```swift
HUD.showStatus(to: view, mode: .custom(UIImageView(image: UIImage(named: "warning"))), label: "You have an unfinished task.") {
    $0.contentView.indicatorPosition = .leading
}
```

* Sets the animation that should be used when showing and hiding the HUD. E.g. style, duration, spring damping:

```swift
HUD.showStatus(to: view, using: .animation(.slideUpDown, damping: .default, duration: 0.3), label: "Wrong password")
```

* Enable keyboard layout guide to track the keyboard's position in your app’s layout:

```swift
HUD.showStatus(to: view, label: "You have a message.") {
    $0.keyboardGuide = .center()
}
```

> [!WARNING]
> HUD is a UI class and should therefore only be accessed on the main thread.

For more examples, including how to use the HUD with asynchronous operations such as URLSession, and how to customize the HUD style, take a look at the bundled example project. Extensive API documentation is available [here](https://liam-i.github.io/FlyHUD/main/documentation/flyhud).

To run the example project, first clone the repo, then `cd` to the root directory and run `pod install`. Then open HUD.xcworkspace in Xcode.

## Documentation

The documentation for releases and `main` are available here:

* [main](https://liam-i.github.io/FlyHUD/main/documentation/flyhud)
* [1.5.6](https://liam-i.github.io/FlyHUD/1.5.6/documentation/flyhud)

<details>
  <summary>
  Other versions
  </summary>

* [1.5.4](https://liam-i.github.io/FlyHUD/1.5.4/documentation/lphud)
* [1.5.3](https://liam-i.github.io/FlyHUD/1.5.3/documentation/lphud)
* [1.4.0](https://liam-i.github.io/FlyHUD/1.4.0/documentation/lphud)
* [1.3.7](https://liam-i.github.io/FlyHUD/1.3.7/documentation/lphud)
* [1.2.6](https://liam-i.github.io/FlyHUD/1.2.6/documentation/lphud)
* [1.1.0](https://liam-i.github.io/FlyHUD/1.1.0/documentation/lpprogresshud)

  </details>

## Why the name FlyHUD?

The name FlyHUD combines `Fly` and `HUD` and stands out for its simplicity and expressiveness. `Fly` implies fast, efficient and flexible meaning, which is consistent with the real-time and immediacy of `HUD`. Overall, FlyHUD expresses the ability of `HUD` to present information and data quickly and efficiently.

## Credits and thanks

* Thanks a lot to [Jonathan George](https://github.com/jdg) for building [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - all ideas in here and many implementation details were provided by his library.
* Thanks a lot to [Vinh Nguyen](https://github.com/ninjaprox) for building [NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) - many implementation details of the loading animations here are provided by his library.
* Thanks a lot to [Related Code](https://github.com/relatedcode) for building [ProgressHUD](https://github.com/relatedcode/ProgressHUD) - many implementation details of the loading animations here are provided by his library.

## License

FlyHUD is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.
