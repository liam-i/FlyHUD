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

[body]

[footer]

## Cross-module change (multiple scopes)

When a single commit modifies multiple independent modules, separate scopes with commas:

<type>(<scope1>,<scope2>): <subject>

[body]

[footer]

> `[body]` is conditionally required (see below). `[footer]` is always optional.

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
- `extensions` — `Sources/HUD/Extensions/` (UIKit/Foundation convenience extensions)
- `observables` — `Sources/HUD/Observables/` (DisplayLink, KeyboardObserver, UnfairLock)
- `protocols` — `Sources/HUD/Protocols/` (protocol definitions)

**Extension Modules**

- `indicator` — `Sources/IndicatorHUD/` (activity indicator views)
- `progress` — `Sources/ProgressHUD/` (progress views)
- `swiftui` — `Sources/SwiftUIHUD/` (SwiftUI modifiers and host bridge)

**Example Apps**

- `example-ios` — `Example iOS/` (iOS example app)
- `example-swiftui` — `Example SwiftUI/` (SwiftUI example app)
- `example-tvos` — `Example tvOS/` (tvOS example app)

**Tests**

- `test` — `Tests/` (unit tests, stress tests)
- `uitest` — `UITests/` (UI tests, accessibility tests)

**Project Configuration**

- `docs` — `Sources/HUD/Documentation.docc/`, `.github/*.md`, `CLAUDE.md`, and root `*.md` files (`README.md`, `README_CN.md`, `AGENTS.md`, `CHANGELOG.md`, `release-notes.md`)
- `deps` — `Package.swift`, `Package@swift-6.0.swift`, `FlyHUD.podspec`
- `project` — `FlyHUD.xcodeproj/`, `FlyHUD.xcworkspace/`
- `scripts` — `scripts/` (build.sh, build-docs.sh)
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
- Closing issues: use GitHub auto-close keywords, e.g. `Closes #123` or `Fixes #456`

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

refactor(hud,test): extract HUD timer logic into dedicated helper

- Move graceTime/minShowTime scheduling from HUD.swift to TimerScheduler
- Update HUDTests to use new helper directly for timing assertions
- Reduces HUD.swift by ~40 lines

## Commits without body (simple changes)

fix(views): fix label truncation when text exceeds bounds

style(hud): normalize import ordering

test(test): add missing assertion for hide(afterDelay:)
