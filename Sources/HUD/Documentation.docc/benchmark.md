# Performance Benchmark

FlyHUD's performance characteristics including binary size, memory usage, and rendering overhead.

## Binary Size Impact

Measured with Release configuration, arm64 architecture, dead code stripping enabled:

| Module | Approximate Size |
| ------ | ---------------- |
| FlyHUD | ~80 KB |
| FlyIndicatorHUD | ~25 KB |
| FlyProgressHUD | ~30 KB |
| **Total (all modules)** | **~135 KB** |

> Note: Actual sizes vary by Swift compiler version and optimization level.
> These measurements were taken with Xcode 15+ and Swift 5.9.

### Size Reduction Tips

- Import only the modules you need
- Enable Link-Time Optimization (LTO) in your release build
- Dead code stripping is enabled by default with SPM

## Memory Usage

### HUD Instance

| Component | Approximate Heap |
| --------- | ---------------- |
| HUD (container view) | ~2 KB |
| ContentView (labels + stack) | ~3 KB |
| BackgroundView (blur) | ~1.5 KB |
| UIActivityIndicatorView | ~1 KB |
| ActivityIndicatorView (custom) | ~2 KB |
| ProgressView (custom) | ~1.5 KB |
| **Typical HUD (indicator + labels)** | **~8 KB** |

### Memory Lifecycle

- HUD memory is allocated on `show()` (or `init`)
- Memory is released when `removeFromSuperViewOnHide = true` and HUD hides
- `KeyboardObserver` and `DisplayLink` are singletons (~0.5 KB each, shared)
- No persistent caches or retained data

### Concurrent HUDs

Each additional concurrent HUD adds approximately 8 KB. Avoid showing more than
necessary — use `HUD.hideAll(for:)` to clean up.

## Rendering Performance

### Main Thread Impact

| Operation | Typical Duration |
| --------- | ---------------- |
| `HUD.show()` (no animation) | < 1 ms |
| `HUD.show()` (with animation) | < 2 ms (triggers animation) |
| `hud.hide()` (no animation) | < 0.5 ms |
| Progress update (`progress = x`) | < 0.1 ms |
| Layout update (offset change) | < 0.5 ms |

### Animation Frame Budget

All animations use `UIView.animate` with spring damping. The animation system:

- Does not use `CADisplayLink` for show/hide animations
- Uses `CADisplayLink` only for `observedProgress` polling (fires once per frame)
- All indicator animations use `CAAnimation` (GPU-composited, off main thread)

### GPU Compositing

Custom indicators (`ActivityIndicatorView`) use `CAShapeLayer` + `CAAnimation`:

- Animations run on the render server (GPU thread)
- No `draw(_:)` calls during animation
- Minimal main thread involvement after setup

Custom progress views (`ProgressView`) use `draw(_:)`:

- Redrawn only when `progress` value changes
- Drawing occurs in `drawRect` on main thread
- Typically completes in < 0.5 ms per frame

## Stress Test Results

The stress test suite (350 tests) validates:

| Scenario | Result |
| -------- | ------ |
| 100 concurrent HUD creations | No memory leaks |
| Rapid show/hide cycles (1000x) | No crashes, no UI corruption |
| Simultaneous mode changes | Consistent state |
| Thread safety assertions | All pass on @MainActor |
| Grace time + min show time | Correct timing behavior |
| Activity count stress | Accurate reference counting |

## Comparison with Alternatives

| Library | Binary Size | Dependencies | Min iOS |
| ------- | ----------- | ------------ | ------- |
| **FlyHUD** | ~135 KB | 0 | 13.0 |
| MBProgressHUD | ~60 KB | 0 | 14.0 |
| SVProgressHUD | ~45 KB | 0 | 14.0 |
| JGProgressHUD | ~80 KB | 0 | 14.0 |

> Note: FlyHUD includes more features (custom animations, progress styles,
> keyboard guide) which accounts for the larger size.

## Optimization Recommendations

### Minimize Redraws

- Avoid setting `progress` in a tight loop; batch updates or use `observedProgress`
- Set `mode` once rather than switching frequently

### Reduce Allocation

- Reuse HUD instances with `removeFromSuperViewOnHide = false`
- Use `graceTime` to avoid creating/destroying HUDs for fast operations

### Minimize Layer Count

- `ActivityIndicatorView` styles create 2–8 sublayers
- Prefer simpler styles (`.ringClipRotate` = 2 layers) for lists/cells
- Complex styles (`.ballSpinFade` = 8 layers) are fine for full-screen HUDs
