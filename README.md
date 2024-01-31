# HUD

<!-- [![CI Status](https://img.shields.io/travis/Liam/HUD.svg?style=flat)](https://travis-ci.org/Liam/HUD) -->

[![Version](https://img.shields.io/cocoapods/v/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)
[![License](https://img.shields.io/cocoapods/l/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)
[![Platform](https://img.shields.io/cocoapods/p/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)

This is a lightweight and easy-to-use HUD designed to display the progress and status of ongoing tasks on iOS and tvOS.

## ScreenShots

[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-1-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-1.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-2-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-2.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-3-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-3.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-4-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-4.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-5-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-5.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-6-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-6.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-7-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-7.png)

## Requirements

* iOS 11.0+ 
* Xcode 14.0+
* Swift 5.0+

## Installation

#### Swift Package Manager

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/liam-i/HUD.git`
- Select "Up to Next Minor" with "1.4.0"

#### CocoaPods

HUD is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target 'MyApp' do
  pod 'LPHUD', '~> 1.4.0'
  # or
  pod 'LPHUD', '~> 1.4.0', :subspecs => ['HUDIndicator']
  # or
  pod 'LPHUD', '~> 1.4.0', :subspecs => ['HUDProgress']
end
```

## Usage

Using `HUD` in your application is very simple.

* Shows the status of indeterminate tasks.

```swift
let hud = HUD.show(to: view)
DispatchQueue.global().async {
    // Do something...
    DispatchQueue.main.async {
        hud.hide()
    }
}
```

* Shows the progress of the task.

```swift
let hud = HUD.show(to: view, mode: .progress(), label: "Loading")
Task.request { progress in
    hud.progress = progress
} completion: {
    hud.hide()
}
```

* Show text-only status.

```swift
HUD.showStatus(to: view, label: "Wrong password")
```

* Shows the status of a custom view. e.g. a UIImageView.

```swift
HUD.showStatus(to: view, mode: .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))), label: "Completed")
```

> [!WARNING]
> The main guideline you need to follow when dealing with HUD while running long-running tasks is keeping the main thread work-free, so the UI can be updated promptly. The only way of using HUD is therefore to set it up on the main thread and then spinning the task, that you want to perform, off onto a new thread.

For more examples, including how to use the HUD with asynchronous operations such as URLSession, and how to customize the HUD style, take a look at the bundled demo project. Extensive API documentation is available [here](https://liam-i.github.io/HUD/main/documentation/lphud).

To run the example project, first clone the repo, then `cd` to the root directory and run `pod install`. Then open HUD.xcworkspace in Xcode.

## Documentation

The documentation for releases and `main` are available here:

* [main](https://liam-i.github.io/HUD/main/documentation/lphud)
* [1.4.0](https://liam-i.github.io/HUD/1.4.0/documentation/lphud)

<details>
  <summary>
  Other versions
  </summary>

* [1.3.7](https://liam-i.github.io/HUD/1.3.7/documentation/lphud)

* [1.2.6](https://liam-i.github.io/HUD/1.2.6/documentation/lphud)

* [1.1.0](https://liam-i.github.io/HUD/1.1.0/documentation/lpprogresshud)
  
  </details>

## Credits and thanks

* Thanks a lot to [Jonathan George](https://github.com/jdg) for building [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - all ideas in here and many implementation details were provided by his library.
* Thanks a lot to [Vinh Nguyen](https://github.com/ninjaprox) for building [NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) - many implementation details of the loading animations here are provided by his library.
* Thanks a lot to [Related Code](https://github.com/relatedcode) for building [ProgressHUD](https://github.com/relatedcode/ProgressHUD) - many implementation details of the loading animations here are provided by his library.

## License

HUD is available under the MIT license. See the [LICENSE](./LICENSE) file for more info.
