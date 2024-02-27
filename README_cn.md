# HUD

[![Swift](https://img.shields.io/badge/Swift-5.7_5.8_5.9-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.7_5.8_5.9-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_tvOS-Green?style=flat-square)
[![CocoaPods](https://img.shields.io/cocoapods/v/LPHUD.svg?style=flat)](https://cocoapods.org/pods/LPHUD)
[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager)
[![Carthage](https://img.shields.io/badge/Carthage-supported-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Doc](https://img.shields.io/badge/Swift-Doc-DE5C43.svg?style=flat)](https://liam-i.github.io/HUD/main/documentation/lphud)
[![License](https://img.shields.io/cocoapods/l/LPHUD.svg?style=flat)](https://github.com/liam-i/HUD/blob/dev/LICENSE)

简体中文 | [English](./README.md)

这是一款轻量级且易于使用的 HUD，用于显示 iOS 和 tvOS 上正在进行的任务的进度和状态。

## 屏幕截图

[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-1-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-1.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-2-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-2.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-3-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-3.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-4-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-4.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-6-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-6.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-8-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-8.png)
[![](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-7-small.png)](https://raw.githubusercontent.com/wiki/liam-i/HUD/Screenshots/1-7.png)

## 要求

* iOS 11.0+ 
* tvOS 11.0+ 
* Xcode 14.1+
* Swift 5.7.1+

## 安装

### Swift Package Manager

#### ...使用 `swift build`

如果你使用 [Swift Package Manager](https://www.swift.org/documentation/package-manager)，可在你的 `Package.swift` 文件添加依赖，并将 HUD 库导入到所需的目标中：

```swift
dependencies: [
    .package(url: "https://github.com/liam-i/HUD.git", from: "1.5.4")
],
targets: [
    .target(
        name: "MyTarget", dependencies: [
            .product(name: "HUD", package: "HUD"),         // 可选
            .product(name: "HUDProgress", package: "HUD"), // 可选
            .product(name: "HUDIndicator", package: "HUD") // 可选
        ])
]
```

#### ...使用 Xcode

如果你使用 Xcode，那么你应该：

- File > Swift Packages > Add Package Dependency
- Add `https://github.com/liam-i/HUD.git`
- Select "Up to Next Minor" with "1.5.4"

> [!TIP]
> 相关详细教程，请查看：[Apple Docs](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

### CocoaPods

如果你使用 [CocoaPods](https://cocoapods.org)，可将一下内容添加到你的 `Podfile` 中：

```ruby
source 'https://github.com/CocoaPods/Specs.git'
# 或者使用 CND 源
# source 'https://cdn.cocoapods.org/'
platform :ios, '11.0'
use_frameworks!

target 'MyApp' do
  # 使用 HUD、HUDIndicator 和 HUDProgress 组件。
  pod 'LPHUD', '~> 1.5.4'

  # 或者，只使用 HUD 组件。
  pod 'LPHUD', '~> 1.5.4', :subspecs => ['HUD']

  # 或者，只使用 HUD 和 HUDIndicator 组件。
  pod 'LPHUD', '~> 1.5.4', :subspecs => ['HUDIndicator']

  # 或者，只使用 HUD 和 HUDProgress 组件。
  pod 'LPHUD', '~> 1.5.4', :subspecs => ['HUDProgress']
end
```

并运行 `pod install`。

> [!IMPORTANT]  
> 需要 CocoaPods 1.14.3 或更高版本。

### Carthage

如果你使用 [Carthage](https://github.com/Carthage/Carthage), 可将以下内容添加到你的 `Cartfile` 中：

```ruby
github "liam-i/HUD" ~> 1.5.4
```

并运行 `carthage update --platform iOS --use-xcframeworks`。

## 用法

在你的应用程序中使用 `HUD` 非常简单。

* 显示不确定任务的状态：

```swift
let hud = HUD.show(to: view)
DispatchQueue.global().async {
    // Do something...
    DispatchQueue.main.async {
        hud.hide()
    }
}
```

* 显示任务进度：

```swift
let hud = HUD.show(to: view, mode: .progress(), label: "Loading")
Task.request { progress in
    hud.progress = progress
} completion: {
    hud.hide()
}
```

* 显示仅文本的状态 HUD：

```swift
HUD.showStatus(to: view, label: "Wrong password")
```

* 显示自定义视图的状态 HUD。例如，自定义一个 `UIImageView`：

```swift
HUD.showStatus(to: view, mode: .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))), label: "Completed")
```

* 显示自定义视图的状态 HUD，并且将 `UIImageView` 位于左侧：

```swift
HUD.showStatus(to: view, mode: .custom(UIImageView(image: UIImage(named: "warning"))), label: "You have an unfinished task.") {
    $0.contentView.indicatorPosition = .leading
}
```

* 设置显示和隐藏 HUD 时所使用的动画。 例如，动画风格、持续时间、弹簧阻尼：

```swift
HUD.showStatus(to: view, using: .animation(.slideUpDown, damping: .default, duration: 0.3), label: "Wrong password")
```

* 启用键盘布局引导，以跟踪键盘在应用布局中的位置：

```swift
HUD.showStatus(to: view, label: "You have a message.") {
    $0.keyboardGuide = .center()
}
```

> [!WARNING]
> HUD 是一个 UI 类，因此只能在主线程上访问。

有关更多示例，包括如何通过异步操作（例如 URLSession）使用 HUD，以及如何自定义 HUD 样式，请查看项目里的 `example`。这里提供了完整的 [API 文档](https://liam-i.github.io/HUD/main/documentation/lphud)。

运行 `example` 项目，先克隆存储库，然后 `cd` 到根目录并运行 `pod install`。 最后在 Xcode 中打开 `HUD.xcworkspace`。

## 文档

版本和 `main` 分支的文档可查看此处：

* [main](https://liam-i.github.io/HUD/main/documentation/lphud)
* [1.5.4](https://liam-i.github.io/HUD/1.5.4/documentation/lphud)

<details>
  <summary>
  其他版本
  </summary>

* [1.5.3](https://liam-i.github.io/HUD/1.5.3/documentation/lphud)
* [1.4.0](https://liam-i.github.io/HUD/1.4.0/documentation/lphud)
* [1.3.7](https://liam-i.github.io/HUD/1.3.7/documentation/lphud)
* [1.2.6](https://liam-i.github.io/HUD/1.2.6/documentation/lphud)
* [1.1.0](https://liam-i.github.io/HUD/1.1.0/documentation/lpprogresshud)

  </details>

## 致谢

* 感谢 [Jonathan George](https://github.com/jdg) 构建的 [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - 我的所有想法和许多实现细节均来自他的库。
* 感谢 [Vinh Nguyen](https://github.com/ninjaprox) 构建的 [NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) - 关于加载动画的许多实现细节来自他的库。
* 感谢 [Related Code](https://github.com/relatedcode) 构建的 [ProgressHUD](https://github.com/relatedcode/ProgressHUD) - 关于加载动画的许多实现细节来自他的库。

## 协议

HUD 使用 MIT 协议。有关详细信息，请参阅 [LICENSE](./LICENSE) 文件。
