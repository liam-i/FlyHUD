<!-- markdownlint-disable MD033 -->
# FlyHUD

![FlyHUD: Easy-to-use HUD in Swift](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/logo-dark.png#gh-dark-mode-only)
![FlyHUD: Easy-to-use HUD in Swift](https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/logo-light.png#gh-light-mode-only)

[![Swift](https://img.shields.io/badge/Swift-5.9_5.10_6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9_5.10_6.0-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_tvOS_visionOS-yellowgreen?style=flat-square)](https://img.shields.io/badge/Platforms-iOS_tvOS_visionOS-Green?style=flat-square)
[![CocoaPods](https://img.shields.io/cocoapods/v/FlyHUD.svg?style=flat)](https://cocoapods.org/pods/FlyHUD)
[![SPM](https://img.shields.io/badge/SPM-supported-DE5C43.svg?style=flat)](https://swift.org/package-manager)
[![Carthage](https://img.shields.io/badge/Carthage-supported-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Doc](https://img.shields.io/badge/Swift-Doc-DE5C43.svg?style=flat)](https://liam-i.github.io/FlyHUD/main/documentation/flyhud)
[![License](https://img.shields.io/cocoapods/l/FlyHUD.svg?style=flat)](https://github.com/liam-i/FlyHUD/blob/main/LICENSE)

简体中文 | [English](./README.md)

这是一款轻量级且易于使用的 HUD，用于显示 iOS 和 tvOS 上正在进行的任务的进度和状态。

## 屏幕截图

### iOS

<a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-1.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-1.png" width="13%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-2.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-2.png" width="13%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-3.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-3.png" width="13%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-4.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-4.png" width="13%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-5.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-5.png" width="13%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/iOS-6.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/iOS-6.png" width="30%"></a>

### tvOS & visionOS

<a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/tvOS.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/tvOS.png" width="49%"></a> <a href="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2/visionOS.png"><img src="https://raw.githubusercontent.com/wiki/liam-i/FlyHUD/Screenshots/v2-small/visionOS.png" width="49%"></a>

## 要求

* iOS 13.0+
* tvOS 13.0+
* visionOS 1.0+
* Xcode 15.0+
* Swift 5.9+

## 安装

### Swift Package Manager

#### ...使用 `swift build`

如果你使用 [Swift Package Manager](https://www.swift.org/documentation/package-manager)，可在你的 `Package.swift` 文件添加依赖，并将 HUD 库导入到所需的目标中：

```swift
dependencies: [
    .package(url: "https://github.com/liam-i/FlyHUD.git", from: "1.6.0")
],
targets: [
    .target(
        name: "MyTarget", dependencies: [
            .product(name: "FlyHUD", package: "FlyHUD"),           // 可选
            .product(name: "FlyHUDSwiftUI", package: "FlyHUD"),    // 可选
            .product(name: "FlyProgressHUD", package: "FlyHUD"),   // 可选
            .product(name: "FlyIndicatorHUD", package: "FlyHUD")   // 可选
        ])
]
```

#### ...使用 Xcode

如果你使用 Xcode，那么你应该：

* File > Add Package Dependencies...
* Add `https://github.com/liam-i/FlyHUD.git`
* Select "Up to Next Minor" with "1.6.0"

> [!TIP]
> 相关详细教程，请查看：[Apple Docs](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app)

### CocoaPods

如果你使用 [CocoaPods](https://cocoapods.org)，可将以下内容添加到你的 `Podfile` 中：

```ruby
source 'https://github.com/CocoaPods/Specs.git'
# 或者使用 CDN 源
# source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'
use_frameworks!

target 'MyApp' do
  # 使用所有组件（FlyHUD、FlyIndicatorHUD、FlyProgressHUD 和 FlyHUDSwiftUI）。
  pod 'FlyHUD', '~> 1.6.0'

  # 或者，只使用 FlyHUD 组件。
  pod 'FlyHUD', '~> 1.6.0', :subspecs => ['FlyHUD']

  # 或者，只使用 FlyHUD 和 FlyIndicatorHUD 组件。
  pod 'FlyHUD', '~> 1.6.0', :subspecs => ['FlyIndicatorHUD']

  # 或者，只使用 FlyHUD 和 FlyProgressHUD 组件。
  pod 'FlyHUD', '~> 1.6.0', :subspecs => ['FlyProgressHUD']

  # 或者，只使用 FlyHUD 和 FlyHUDSwiftUI 组件。
  pod 'FlyHUD', '~> 1.6.0', :subspecs => ['FlyHUDSwiftUI']
end
```

并运行 `pod install`。

> [!IMPORTANT]  
> 需要 CocoaPods 1.13.0 或更高版本。

### Carthage

如果你使用 [Carthage](https://github.com/Carthage/Carthage), 可将以下内容添加到你的 `Cartfile` 中：

```ruby
github "liam-i/FlyHUD" ~> 1.6.0
```

并运行 `carthage update --platform iOS --use-xcframeworks`。

这将在 `Carthage/Build/` 中生成以下 XCFrameworks：

| Framework | 描述 |
| --------- | ---- |
| `FlyHUD.xcframework` | 核心 HUD（必需） |
| `FlyIndicatorHUD.xcframework` | 活动指示器（依赖 FlyHUD） |
| `FlyProgressHUD.xcframework` | 进度视图（依赖 FlyHUD） |
| `FlyHUDSwiftUI.xcframework` | SwiftUI 桥接（依赖 FlyHUD） |

将所需的 frameworks 拖入目标的 **Frameworks, Libraries, and Embedded Content** 部分，并设置为 **Embed & Sign**。

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
    hud.contentView.progress = progress
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

### SwiftUI

FlyHUD 通过 `FlyHUDSwiftUI` 模块提供原生 SwiftUI 支持：

```swift
import FlyHUDSwiftUI

struct ContentView: View {
    @State private var isLoading = false

    var body: some View {
        Button("Load") { isLoading = true }
            .hudLoading(isPresented: $isLoading, label: "Loading...")
    }
}
```

更多声明式修饰符可用：

```swift
// 基于布尔值的 HUD，支持完整配置
.hud(isPresented: $isLoading) { hud in
    hud.contentView.mode = .indicator()
    hud.contentView.label.text = "请稍候..."
}

// 自动消失的 Toast
.hudToast(isPresented: $showSuccess, label: "已保存！")

// 进度追踪
.hudProgress(isPresented: $isUploading, progress: $progress, label: "上传中")
```

> [!TIP]
> 查看 [SwiftUI 集成指南](https://liam-i.github.io/FlyHUD/main/documentation/flyhud/swiftui-integration) 获取完整文档。

有关更多示例，包括如何通过异步操作（例如 URLSession）使用 HUD，以及如何自定义 HUD 样式，请查看项目里的 `example`。这里提供了完整的 [API 文档](https://liam-i.github.io/FlyHUD/main/documentation/flyhud)。

运行 `example` 项目，先克隆存储库，然后在 Xcode 中打开 `FlyHUD.xcworkspace`。

## 无障碍

FlyHUD 提供了完整的 VoiceOver 和无障碍支持：

- **模态焦点** — `accessibilityViewIsModal` 防止 VoiceOver 导航到 HUD 下方的内容
- **自动焦点管理** — 显示时 VoiceOver 焦点移至 HUD，隐藏时焦点返回底层内容
- **退出手势** — 双指 Z 形轻扫（`accessibilityPerformEscape`）可关闭 HUD
- **上下文提示** — `accessibilityHint` 提供语境描述（"Loading in progress" / "Task in progress"）
- **合并播报** — 标题 + 详情文本作为单一描述朗读
- **进度更新** — 每 25% 播报一次里程碑；`accessibilityValue` 报告百分比
- **按钮暴露** — 操作按钮通过 `accessibilityCustomActions` 暴露（上/下滑动发现）
- **动态更新** — HUD 可见时文本/模式变更会触发 VoiceOver 重新朗读
- **事件传递同步** — `isEventDeliveryEnabled` 与 `accessibilityViewIsModal` 保持同步；触摸穿透时 VoiceOver 焦点也可穿透
- **动态字体** — 通过 `isDynamicTypeEnabled` 启用字体缩放

> [!TIP]
> 使用 `.custom(UIView)` 模式时，请在自定义视图上设置 `isAccessibilityElement = false` 以避免重复播报。

## 文档

版本和 `main` 分支的文档可查看此处：

* [main](https://liam-i.github.io/FlyHUD/main/documentation/)
* [1.6.0](https://liam-i.github.io/FlyHUD/1.6.0/documentation/)

<details>
  <summary>
  其他版本
  </summary>

* [1.5.6](https://liam-i.github.io/FlyHUD/1.5.6/documentation/flyhud)
* [1.5.4](https://liam-i.github.io/FlyHUD/1.5.4/documentation/lphud)
* [1.5.3](https://liam-i.github.io/FlyHUD/1.5.3/documentation/lphud)
* [1.4.0](https://liam-i.github.io/FlyHUD/1.4.0/documentation/lphud)
* [1.3.7](https://liam-i.github.io/FlyHUD/1.3.7/documentation/lphud)
* [1.2.6](https://liam-i.github.io/FlyHUD/1.2.6/documentation/lphud)
* [1.1.0](https://liam-i.github.io/FlyHUD/1.1.0/documentation/lpprogresshud)

</details>

## 为什么取名 FlyHUD？

FlyHUD 这个名字结合了 `Fly` 和 `HUD`，在简洁性和表达能力上都很突出。`Fly` 暗示了快速、高效和灵活的含义，与 `HUD` 的实时性和即时性相契合。总体而言，FlyHUD 表达了 `HUD` 能够快速和高效的呈现信息和数据的能力。

## 致谢

* 感谢 [Jonathan George](https://github.com/jdg) 构建的 [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - 我的所有想法和许多实现细节均来自他的库。
* 感谢 [Vinh Nguyen](https://github.com/ninjaprox) 构建的 [NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) - 关于加载动画的许多实现细节来自他的库。
* 感谢 [Related Code](https://github.com/relatedcode) 构建的 [ProgressHUD](https://github.com/relatedcode/ProgressHUD) - 关于加载动画的许多实现细节来自他的库。

## 协议

FlyHUD 使用 MIT 协议。有关详细信息，请参阅 [LICENSE](./LICENSE) 文件。
