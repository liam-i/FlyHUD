# FlyHUD - GitHub Copilot Instructions

> [AGENTS.md](../AGENTS.md) is the primary reference (auto-loaded alongside this file). This file adds Copilot-specific notes only.

## Copilot-Specific Tips

- After editing `Example iOS/` files, check `get_errors` — Xcode auto-syncs may surface type errors
- `swift test` doesn't work (UIKit unavailable on macOS CLI) — use `./scripts/build.sh test`
- Read sub-directory `AGENTS.md` files on demand when working in those areas:
  - [`Sources/AGENTS.md`](../Sources/AGENTS.md) — API surface & protocols
  - [`Sources/HUD/Documentation.docc/AGENTS.md`](../Sources/HUD/Documentation.docc/AGENTS.md) — DocC writing rules
  - [`Example iOS/AGENTS.md`](../Example%20iOS/AGENTS.md) — Demo app patterns
  - [`Example SwiftUI/AGENTS.md`](../Example%20SwiftUI/AGENTS.md) — SwiftUI bridge pattern
  - [`Example tvOS/AGENTS.md`](../Example%20tvOS/AGENTS.md) — tvOS scene lifecycle
  - [`Tests/AGENTS.md`](../Tests/AGENTS.md) — Test conventions
