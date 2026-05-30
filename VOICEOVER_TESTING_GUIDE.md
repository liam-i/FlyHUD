# FlyHUD VoiceOver 测试指南

本文档详细介绍如何测试 FlyHUD SDK 及 Example 应用的 VoiceOver 无障碍功能。

---

## 目录

1. [环境准备](#1-环境准备)
2. [VoiceOver 基本操作](#2-voiceover-基本操作)
3. [使用 Accessibility Inspector（推荐开发时使用）](#3-使用-accessibility-inspector推荐开发时使用)
4. [FlyHUD SDK 无障碍特性总览](#4-flyhud-sdk-无障碍特性总览)
5. [测试用例：Example iOS](#5-测试用例example-ios)
6. [测试用例：Example SwiftUI](#6-测试用例example-swiftui)
7. [测试用例：Example tvOS](#7-测试用例example-tvos)
8. [自动化 UITest 验证](#8-自动化-uitest-验证)
9. [常见问题排查](#9-常见问题排查)

---

## 1. 环境准备

### 1.1 在真机上开启 VoiceOver

1. 打开 **设置 → 辅助功能 → VoiceOver**
2. 开启 **VoiceOver** 开关
3. （推荐）设置快捷方式：**设置 → 辅助功能 → 辅助功能快捷键** → 勾选 VoiceOver
   - 之后可通过 **连按三次侧边按钮（或 Home 键）** 快速开关 VoiceOver

### 1.2 在模拟器上开启 VoiceOver

1. 在模拟器中：**设置 → 辅助功能 → VoiceOver → 开启**
2. 或者通过 Xcode：**Xcode → Open Developer Tool → Accessibility Inspector**（见第 3 节）

> ⚠️ 模拟器的 VoiceOver 体验不如真机完整，建议关键测试在真机上进行。

### 1.3 开启辅助功能快捷键（模拟器）

- 在模拟器菜单：**Features → Accessibility → VoiceOver**（Xcode 15+）
- 或通过模拟器中的 **设置 → 辅助功能 → 辅助功能快捷键** 配置三击 Home/侧边按钮快捷切换

> 注意：macOS 的 `Cmd + F5` 开启的是 **macOS VoiceOver**，不是模拟器内的 iOS VoiceOver。

---

## 2. VoiceOver 基本操作

| 手势 | 功能 |
| ------ | ------ |
| **单指左/右滑动** | 切换到上/下一个元素 |
| **单指双击** | 激活当前元素（相当于点击） |
| **单指上/下滑动** | 切换转子选项 / 调整值 |
| **双指上滑** | 从头朗读所有内容 |
| **双指双击** | 暂停/恢复朗读 |
| **Z 形手势（双指画 Z）** | 执行"返回"或"关闭"操作 |
| **三指双击** | 静音/恢复 VoiceOver |

### tvOS 遥控器操作

| 操作 | 功能 |
| ------ | ------ |
| **左/右滑动触摸面** | 切换元素 |
| **点击触摸面** | 激活当前元素 |
| **双指向左旋转** | 返回 / 关闭（Escape）（或按 Menu/返回按钮） |

---

## 3. 使用 Accessibility Inspector（推荐开发时使用）

Accessibility Inspector 是 Xcode 内置工具，**无需开启 VoiceOver** 即可检查无障碍属性。

### 3.1 打开方式

```text
Xcode → 菜单栏 → Xcode → Open Developer Tool → Accessibility Inspector
```

### 3.2 使用步骤

1. **选择目标**：在左上角下拉菜单中选择你的模拟器或真机
2. **检查模式**：点击工具栏的 🎯（靶心图标）进入检查模式
3. **点击元素**：在模拟器上点击任意 UI 元素，Inspector 会显示：
   - `Label`：VoiceOver 朗读的文本
   - `Value`：当前值（如进度百分比）
   - `Traits`：元素特性（如 Static Text、Updates Frequently）
   - `Hint`：提示文本
   - `Custom Actions`：自定义操作（如 Cancel 按钮）

### 3.3 审计功能

1. 点击工具栏的 **⚠️ 审计按钮**
2. 点击 **Run Audit**
3. Inspector 会自动检测常见无障碍问题：
   - 缺失 label
   - 对比度不足
   - 触摸目标太小
   - 元素重叠

### 3.4 验证 FlyHUD 的具体步骤

```text
1. 运行 Example iOS 应用
2. 打开 Accessibility Inspector，选择模拟器
3. 点击 🎯 进入检查模式
4. 在 Example 应用中触发一个 HUD（如点击 "Progress Bar"）
5. 在 Inspector 中点击 HUD 区域
6. 检查 Label/Value/Traits/Hint/Actions 是否正确
```

---

## 4. FlyHUD SDK 无障碍特性总览

FlyHUD 的 `ContentView` 是 **唯一的无障碍元素**（单一焦点设计）：

| 属性 | 行为 |
| ------ | ------ |
| `accessibilityLabel` | 组合 `label.text` + `detailsLabel.text`（如 "Loading, Please wait..."） |
| `accessibilityValue` | 进度模式下返回百分比（如 "45%"），非进度模式返回 nil |
| `accessibilityHint` | 指示器模式 → "Loading in progress"；进度模式 → "Task in progress" |
| `accessibilityTraits` | 进度/指示器 → `.updatesFrequently`；纯文本 → `.staticText` |
| `accessibilityCustomActions` | 有按钮时暴露按钮标题作为自定义操作（如 "Cancel"） |
| **Z 形手势关闭** | `accessibilityPerformEscape()` → 自动隐藏 HUD |
| **模态隔离** | 默认 `accessibilityViewIsModal = true`，VoiceOver 无法导航到 HUD 后方元素 |
| **进度播报** | 进度每变化 25% 自动通过 `.announcement` 播报（0%、25%、50%、75%、100%） |
| **焦点管理** | HUD 显示时 → `.screenChanged` 聚焦到 ContentView；隐藏时 → 焦点转移到下一个 HUD 或恢复 |

### 子视图无障碍隔离

所有子视图（Label、Button、ProgressView、ActivityIndicatorView、自定义视图）均设置 `isAccessibilityElement = false`，确保 VoiceOver 只读取一个整合后的元素。

---

## 5. 测试用例：Example iOS

运行 `Example iOS` target，在表格中选择各种 HUD 模式进行测试。

### 5.1 基础 HUD 模式

| 测试项 | 操作 | 期望 VoiceOver 朗读 |
| -------- | ------ | --------------------- |
| Activity Indicator | 点击 "Indicator" | Label: "Loading" / Hint: "Loading in progress" / Traits: Updates Frequently |
| Progress Bar | 点击 "Progress Bar" | Label: "Loading" / Value: "0%" → 逐步增加 → "100%" / Hint: "Task in progress" |
| Text Only | 点击 "Text" | Label: "Message here" / Traits: Static Text / Hint: nil |
| Custom Icon | 点击 "Custom View" | Label 应来自自定义视图的 accessibilityLabel |

### 5.2 进度播报验证

1. 触发一个进度 HUD（Progress Bar 或 Progress Circle）
2. 等待进度变化
3. **期望**：每 25% 自动播报一次（如 "25%", "50%", "75%", "100%"）
4. **验证方式**：Accessibility Inspector 的 Log 面板会显示 `.announcement` 通知

### 5.3 Z 形手势关闭

1. 触发任意 HUD
2. 做 Z 形手势（双指画 Z）
3. **期望**：HUD 被关闭，VoiceOver 播报焦点转移

### 5.4 自定义操作（Cancel 按钮）

1. 进入 **Accessibility** Demo 页面
2. 触发 "Button: Cancel → custom action"
3. VoiceOver 聚焦到 HUD
4. **上/下滑动** 发现自定义操作
5. **期望**：听到 "Cancel" 自定义操作
6. 双击激活该操作

### 5.5 焦点管理

1. 触发一个 HUD
2. **期望**：VoiceOver 焦点自动转移到 HUD 的 ContentView
3. HUD 自动隐藏后
4. **期望**：焦点恢复到之前的位置或下一个 HUD

### 5.6 AccessibilityViewController 专项

在 Example iOS 的 Accessibility 页面，逐一测试每个 Section：

| Section | 验证内容 |
| --------- | ---------- |
| accessibilityLabel | 验证组合文本是否正确 |
| accessibilityHint | 验证不同模式的 hint 文本 |
| accessibilityValue | 验证进度百分比读取 |
| accessibilityTraits | 验证 `.updatesFrequently` vs `.staticText` |
| accessibilityCustomActions | 验证 Cancel 按钮暴露为自定义操作 |

---

## 6. 测试用例：Example SwiftUI

运行 `Example SwiftUI` target。

### 6.1 声明式修饰符

| 测试项 | 路径 | 期望 |
| -------- | ------ | ------ |
| `.hudLoading` | Modifiers → Loading | VoiceOver 读取 label 文本 + "Loading in progress" hint |
| `.hudToast` | Modifiers → Toast | 显示后自动播报，Traits 为 Static Text |
| `.hudProgress` | Modifiers → Progress | 进度值持续更新，每 25% 播报 |

### 6.2 Advanced → Accessibility

SwiftUI 版本的 Accessibility 页面与 iOS UIKit 版本相同，逐一验证各 Section。

### 6.3 自定义视图模式

在 Modes 页面测试：

- Custom Indicator（旋转图标）：验证 hint = "Loading in progress"
- Custom Progress：验证 value 显示百分比
- Custom Icon（checkmark）：验证 accessibilityLabel 来自图片

---

## 7. 测试用例：Example tvOS

运行 `Example tvOS` target（需要 Apple TV 模拟器或真机）。

### 7.1 开启 tvOS VoiceOver

- 模拟器：**设置 → 辅助功能 → VoiceOver → 开启**
- 或使用 Accessibility Inspector 连接 Apple TV 模拟器

### 7.2 测试要点

| 测试项 | 操作 | 期望 |
| -------- | ------ | ------ |
| Progress Bar | 选择并点击按钮 | 进度百分比播报 |
| Toast | 选择并点击 | Label 朗读 + Static Text traits |
| Custom Icon | 选择并点击 | HUD 显示，自定义图标不单独朗读 |
| Mode Switching | 选择并点击 | 模式切换时 label/hint/traits 动态更新 |
| Z 手势关闭 | 按遥控器 Menu/返回按钮 | HUD 关闭 |

---

## 8. 自动化 UITest 验证

项目包含 UITest 用于自动验证 VoiceOver 属性（不需要开启 VoiceOver）：

```bash
# 运行无障碍 UITests
./scripts/build.sh test ui
```

UITest 位置：`UITests/HUD/HUDAccessibilityUITests.swift`

### UITest 验证方式

UITest 通过 XCUIElement 的 accessibility 属性验证：

```swift
// 示例：验证 HUD 的 accessibilityLabel
let hudElement = app.otherElements.matching(
    NSPredicate(format: "label CONTAINS 'Loading'")
).firstMatch
XCTAssertTrue(hudElement.waitForExistence(timeout: 3.0))

// 验证 accessibilityValue（进度）
XCTAssertEqual(hudElement.value as? String, "45%")

// 验证元素存在性（间接验证 traits）
XCTAssertTrue(hudElement.exists, "HUD should be a single accessible element")
```

---

## 9. 常见问题排查

### Q: VoiceOver 没有朗读 HUD 内容？

**可能原因**：

- HUD 的 `contentView.isAccessibilityElement` 被误设为 `false`
- HUD 被其他视图遮挡
- 未发送 `.screenChanged` 通知

**排查步骤**：

1. 用 Accessibility Inspector 检查 HUD 是否可见
2. 检查 `isAccessibilityElement` 是否为 `true`
3. 确认 HUD 的 `isHidden` 不为 `true`

### Q: 进度百分比没有自动播报？

**可能原因**：

- 进度更新太快（节流机制：每 25% 播报一次，共 5 个 milestone）
- `mode` 不是 `.progress` 类型

**排查步骤**：

1. 确认 mode 为 `.progress(...)`
2. 在 Accessibility Inspector 的通知日志中查看是否有 `.announcement`

### Q: Z 形手势无法关闭 HUD？

**可能原因**：

- HUD 的 `accessibilityPerformEscape()` 被子类覆盖
- HUD 已经在隐藏过程中（`isFinished == true`）

**排查步骤**：

1. 确认 VoiceOver 焦点在 HUD 上（不是 HUD 后面的视图）
2. 确认 HUD 的 `isHidden == false` 且 `isFinished == false`

### Q: 自定义操作（Cancel）没有出现？

**条件**：按钮需要同时满足：

1. `button.title(for: .normal)` 非空
2. `button.allControlEvents.rawValue > 0`（有注册 target-action）

**排查步骤**：

1. 确认按钮设置了标题：`button.setTitle("Cancel", for: .normal)`
2. 确认按钮注册了事件：`button.addTarget(target, action:, for: .touchUpInside)`

### Q: Accessibility Inspector 看不到 HUD？

**可能原因**：HUD 的 `graceTime` 导致延迟显示

**解决**：设置 `graceTime = 0` 或等待 graceTime 过后再检查

---

## 快速验证清单

在提交代码前，使用此清单快速验证：

- [ ] HUD 显示时 VoiceOver 焦点自动聚焦到 ContentView
- [ ] `accessibilityLabel` 正确组合 label + detailsLabel
- [ ] 进度模式：`accessibilityValue` 显示正确百分比
- [ ] 进度模式：每 25% 有 `.announcement` 播报（0%、25%、50%、75%、100%）
- [ ] 指示器/进度模式：`accessibilityTraits` 包含 `.updatesFrequently`
- [ ] 纯文本模式：`accessibilityTraits` 为 `.staticText`
- [ ] 有按钮时：`accessibilityCustomActions` 包含按钮标题
- [ ] Z 形手势可以关闭 HUD
- [ ] HUD 隐藏后焦点正确转移
- [ ] 自定义视图设置 `isAccessibilityElement = false`
- [ ] 多个 HUD 堆叠时焦点管理正确
