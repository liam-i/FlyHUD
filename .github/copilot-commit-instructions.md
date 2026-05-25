You MUST generate Git commit messages in **English**. All subject, body, and footer content must be written in English.
You MUST strictly follow the format below when generating Git commit messages. Do not add any extra text, emojis, gitmoji, quotes, or modify the structure.
Do NOT wrap the response in Markdown code blocks (e.g. ```). Output the raw commit message only.

# Core Principles

1. **One commit = one logical change** — do not mix unrelated modifications in the same commit
2. **Subject must independently convey the change intent** — understandable without reading the body
3. **Scope must be based on actual file paths** — do not guess or use unlisted scopes
4. **Use precise technical terms** — CADisplayLink, NSHashTable, @MainActor, Sendable, SPM, CocoaPods, etc.

# Format

## Single scope change

<type>(<scope>): <subject>

<body>

<footer>

## Cross-module change (multiple scopes)

When a single commit modifies multiple independent modules, separate scopes with commas:

<type>(<scope1>,<scope2>): <subject>

<body>

<footer>

Scope selection rules (by priority):

1. Change is concentrated in a single module → use that module's scope
2. Change involves 2–3 modules with logical relation → comma-separated, most critical scope first
3. Change involves 3+ modules or is a repo-wide refactor → use `all`

# type (required)

| type | Description |
| -------- | -------- |
| feat | New feature, new API, new animation mode |
| fix | Bug fix |
| perf | Performance optimization (animation frame rate, memory usage, etc.) |
| refactor | Code restructuring, not a new feature or bug fix |
| style | Code formatting changes, no functional modification |
| docs | Documentation updates (DocC, README, AGENTS.md, etc.) |
| test | Test code changes |
| chore | Build tools, dependencies, CI pipeline, version bumps, etc. |

# scope (required)

Use the following project-specific scopes. Determine scope based on actual file paths of modified files. Do not guess or use unlisted scopes:

**Core Library** (`Sources/HUD/`)

- `hud` — `Sources/HUD/` (HUD.swift, Model.swift, and other core files)
- `views` — `Sources/HUD/Views/` (ContentView, BackgroundView, BezelView, etc.)
- `animation` — `Sources/HUD/Extensions/` (animation-related extensions)
- `observables` — `Sources/HUD/Observables/` (DisplayLink, KeyboardObserver, UnfairLock)
- `protocols` — `Sources/HUD/Protocols/` (protocol definitions)

**Extension Modules**

- `indicator` — `Sources/IndicatorHUD/` (activity indicator views)
- `progress` — `Sources/ProgressHUD/` (progress views)

**Example Apps**

- `example-ios` — `Example iOS/` (iOS example app)
- `example-swiftui` — `Example SwiftUI/` (SwiftUI example app)
- `example-tvos` — `Example tvOS/` (tvOS example app)

**Tests**

- `test` — `Tests/` (unit tests, stress tests)

**Project Configuration**

- `docs` — `Sources/HUD/Documentation.docc/`, `README.md`, `AGENTS.md`, etc.
- `deps` — `Package.swift`, `Package@swift-6.0.swift`, `FlyHUD.podspec`
- `project` — `FlyHUD.xcodeproj/`, `FlyHUD.xcworkspace/`
- `ci` — CI/CD pipeline configuration, GitHub Actions
- `all` — broad cross-module impact (3+ modules affected)

# subject (required)

- English description, no more than 50 characters
- Start with a lowercase imperative verb (e.g.: add, fix, remove, refactor, simplify, support, update, extract, split)
- Do not end with a period
- Accurately reflect the core content of the change; avoid vague descriptions like "update code" or "modify files"
- Name specific types/protocols when relevant (e.g. "remove redundant proxy property from DisplayLink" not "clean up code")

# body (conditionally required)

**Body is required when:**

- 3 or more files are modified
- Public API changes are involved
- Swift concurrency / Sendable changes are involved
- Fixing a non-obvious bug (explain root cause)

**Body writing rules:**

- Use `-` bullet list for each specific change
- Each line no more than 72 characters
- Explain "what changed" and "why", avoid restating code
- Note old interface → new interface for API changes
- Note affected platforms (iOS/tvOS/visionOS) for multi-platform changes

# footer (optional)

- Breaking changes: start with `BREAKING CHANGE:` and describe impact and migration path
- Closing issues: start with `ISSUES CLOSED:`

# Prohibitions

- **Do NOT** start subject with uppercase (use lowercase imperative mood)
- **Do NOT** use gitmoji, emoji, or any decorative symbols
- **Do NOT** restate code in body (e.g. "change let to var"); explain intent instead
- **Do NOT** use scopes not listed above
- **Do NOT** mix formatting or import sorting changes into feature commits
- **Do NOT** include file names or paths in subject (put them in body)

# Examples

## Single scope commits

refactor(observables): remove redundant proxy property from DisplayLink

- CADisplayLink already strongly retains its target; extra proxy storage is unnecessary
- proxy is automatically deallocated when invalidate() releases target

feat(hud): add graceTime delayed display support

- Delay actual HUD presentation after show() by specified duration
- Prevents flickering for short-lived operations

fix(views): fix ContentView color not updating in Dark Mode

- contentColor did not respond to traitCollectionDidChange causing stale colors
- Add trait change observation and refresh color accordingly

feat(indicator): add ballPulse animation type

- Implement three-ball pulse animation with customizable spacing and color
- Register in ActivityIndicatorAnimation enum

chore(deps): raise minimum deployment target to iOS 13

- Update platforms in both Package.swift and podspec
- Remove iOS 12 compatibility code

## Cross-module commits

feat(hud,indicator): add Liquid Glass style HUD support

- Add .glass style enum to BackgroundView
- Adapt ActivityIndicatorView contrast for glass backgrounds
- Requires iOS 26+ compile environment

test(test,hud): add HUD lifecycle unit tests

- Add timing accuracy tests for graceTime and minShowTime
- Use animated: false to avoid animation timing interference

## 多 scope 提交

feat(domain,application): 新增物品过期提醒 UseCase 完整链路

- Domain: 定义 ScheduleExpiryRemindersUseCase 协议
- Application: 实现批量过期通知调度逻辑
- 支持 daily/weekly/monthly 三种频率

fix(inventory,uifoundation): 修复空间详情页导航栈深度丢失

- SpaceDetailView NavigationLink 目标改为 AppDestination 枚举
- AppRouter 补充 .storageUnitDetail case 处理递归导航

refactor(di,infra,application): DI 注册迁移至协议+实现双注册模式

- Composition.swift 每个 Repository 同时注册协议与具体类型
- 解决 UseCase 注入时 resolve 返回 nil 的问题

## Lattice 架构常见提交模式

### 新增完整功能链路（Domain → Application → Infrastructure → DI → Feature）

feat(domain,application,infra): 新增物品过期提醒完整链路

- Domain: 定义 ExpiryReminder Entity 和 ReminderRepository 协议
- Application: 实现 ScheduleExpiryRemindersUseCase（struct + Sendable）
- Infrastructure: 实现 ReminderRepositoryImpl（actor + SwiftData）
- DI: Composition.swift 注册协议与实现双绑定

### Domain Entity 迁移（class → struct）

refactor(domain): 迁移 Item Entity 从 class 至纯 struct

- Item 改为 struct + Sendable，移除 @Model 标注
- 对象引用替换为 ID 引用（parentStorageUnit → parentStorageUnitId）
- 所有消费方适配值类型语义（let → var）

BREAKING CHANGE: Item 不再是 PersistentModel，消费方需通过 Repository 持久化

### Repository actor 迁移

refactor(infra): 将 SpaceRepository 从 class 迁移至 actor

- SpaceRepositoryImpl 标记为 actor 消除数据竞争
- 内部 SwiftData 操作改用 SDSpace 模型映射
- toDomain() / update(from:) 实现双向转换

### 合规修复（脚本检测到违规）

fix(inventory): 修复 ViewModel 缺少 @MainActor 标注的合规违规

- InventoryViewModel 补充 @MainActor @Observable 标注
- 符合 Lattice verify-viewmodel-rules.sh 检查要求
