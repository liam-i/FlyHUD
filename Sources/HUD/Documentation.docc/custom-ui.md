# Custom UI

Build custom activity indicators, progress views, and display modes.

The following diagram shows the protocol hierarchy for custom indicators and progress views:

![Class diagram showing the relationships between ActivityIndicatorViewStyleable, ProgressViewStyleable, RotateViewable, ProgressViewable protocols and their concrete implementations.](custom-protocols.svg)

## Custom Activity Indicators

### Using FlyIndicatorHUD Built-in Styles

Import `FlyIndicatorHUD` to access pre-built indicator styles:

```swift
import FlyIndicatorHUD

// Ring clip rotation
HUD.show(to: view, mode: .indicator(.ringClipRotate))

// Ball spin fade
HUD.show(to: view, mode: .indicator(.ballSpinFade))

// Circle stroke spin
HUD.show(to: view, mode: .indicator(.circleStrokeSpin))

// Circle arc dot spin
HUD.show(to: view, mode: .indicator(.circleArcDotSpin))
```

### Customizing ActivityIndicatorView Properties

```swift
let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
indicator.color = .systemBlue
indicator.trackColor = UIColor.systemBlue.withAlphaComponent(0.2)
indicator.lineWidth = 3.0

HUD.show(to: view, mode: .custom(indicator), label: "Loading")
```

### Choosing Your Customization Approach

![Flowchart decision tree: Simple rotation → RotateViewable; Complex animation → ActivityIndicatorViewStyleable; Any UIView → .custom(view).](custom-indicator-decision.svg)

### Implementing ActivityIndicatorViewStyleable

Create entirely custom indicator animations:

```swift
struct PulseStyle: ActivityIndicatorViewStyleable {
    func isEqual(_ object: Any) -> Bool {
        object is PulseStyle
    }

    func makeAnimation() -> ActivityIndicatorAnimationBuildable {
        PulseAnimation()
    }

    var defaultSize: CGSize { CGSize(width: 40, height: 40) }
    var defaultColor: UIColor { .systemPurple }
    var defaultTrackColor: UIColor? { nil }
    var defaultLineWidth: CGFloat { 0 }
}

struct PulseAnimation: ActivityIndicatorAnimationBuildable {
    func make(in layer: CALayer, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
        let circle = CAShapeLayer()
        circle.path = UIBezierPath(ovalIn: layer.bounds).cgPath
        circle.fillColor = color.cgColor

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.5
        animation.toValue = 1.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        circle.add(animation, forKey: "pulse")

        layer.addSublayer(circle)
    }
}

// Usage
HUD.show(to: view, mode: .indicator(PulseStyle()))
```

### Implementing RotateViewable

For simple rotation-based indicators, conform to `RotateViewable`:

```swift
class SpinnerView: UIView, RotateViewable {
    var duration: CFTimeInterval { 0.5 }

    override init(frame: CGRect) {
        super.init(frame: frame)
        // VoiceOver: ContentView handles accessibility for the HUD.
        // Custom indicators should not be separate focus elements.
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 37, height: 37)
    }

    override func draw(_ rect: CGRect) {
        // Draw your custom shape
    }
}

// Usage — rotation is handled automatically
let spinner = SpinnerView()
HUD.show(to: view, mode: .custom(spinner))
```

## Custom Progress Views

### Using FlyProgressHUD Built-in Styles

Import `FlyProgressHUD` for pre-built progress styles:

```swift
import FlyProgressHUD

// Bar progress (butt cap)
HUD.show(to: view, mode: .progress(.buttBar))

// Bar progress (round cap)
HUD.show(to: view, mode: .progress(.roundBar))

// Circular progress ring
HUD.show(to: view, mode: .progress(.round))

// Annular ring
HUD.show(to: view, mode: .progress(.annularRound))

// Pie chart
HUD.show(to: view, mode: .progress(.pie))
```

### Customizing ProgressView Properties

```swift
let progressView = ProgressView(style: .annularRound)
progressView.progressTintColor = .systemGreen
progressView.trackTintColor = UIColor.systemGreen.withAlphaComponent(0.15)
progressView.lineWidth = 4.0
progressView.isLabelEnabled = true  // Show percentage text
progressView.labelFont = .boldSystemFont(ofSize: 12)

let hud = HUD.show(to: view, mode: .custom(progressView))
```

### Implementing ProgressViewStyleable

Create entirely custom progress animations:

```swift
struct GradientBarStyle: ProgressViewStyleable {
    func isEqual(_ object: Any) -> Bool {
        object is GradientBarStyle
    }

    func makeAnimation() -> ProgressAnimationBuildable {
        GradientBarAnimation()
    }

    var defaultSize: CGSize { CGSize(width: 120, height: 12) }
    var defaultProgressTintColor: UIColor { .systemBlue }
    var defaultTrackTintColor: UIColor? { .systemGray5 }
    var defaultLineWidth: CGFloat { 0 }
    var defaultIsLabelEnabled: Bool { false }
    var defaultLabelFont: UIFont { .boldSystemFont(ofSize: 8) }
}

struct GradientBarAnimation: ProgressAnimationBuildable {
    func makeShape(in layer: CALayer, progress: CGFloat, color: UIColor, trackColor: UIColor?, lineWidth: CGFloat) {
        let size = layer.bounds.size
        let radius = size.height / 2.0

        // Track
        if let trackColor {
            let trackPath = UIBezierPath(roundedRect: layer.bounds, cornerRadius: radius)
            trackColor.setFill()
            trackPath.fill()
        }

        // Progress fill
        let progressWidth = size.width * progress
        let progressRect = CGRect(x: 0, y: 0, width: progressWidth, height: size.height)
        let progressPath = UIBezierPath(roundedRect: progressRect, cornerRadius: radius)
        color.setFill()
        progressPath.fill()
    }
}
```

### Implementing ProgressViewable Protocol

For full control, implement `ProgressViewable` on your own UIView subclass:

```swift
class CustomProgressView: UIView, ProgressViewable {
    var progress: Float = 0.0 {
        didSet { setNeedsDisplay() }
    }
    var progressTintColor: UIColor? = .systemBlue
    var trackTintColor: UIColor? = .systemGray5
    var observedProgress: Progress?

    override var intrinsicContentSize: CGSize {
        CGSize(width: 100, height: 100)
    }

    override func draw(_ rect: CGRect) {
        // Your custom drawing
    }
}
```

## Custom Background Styles

### Blur Styles

```swift
hud.contentView.style = .blur(.systemUltraThinMaterial)
hud.backgroundView.style = .blur(.systemMaterial)
```

### Solid Color

```swift
hud.contentView.style = .solidColor
hud.contentView.color = UIColor(white: 0.1, alpha: 0.9)
```

### Liquid Glass (iOS 26+)

```swift
if #available(iOS 26.0, *) {
    hud.contentView.style = .glass
    hud.contentView.color = .systemBlue  // Glass tint color
}
```

### Rounded Corners

```swift
// Custom radius
hud.contentView.roundedCorners = .radius(12.0)

// Fully rounded (capsule)
hud.contentView.roundedCorners = .full
```

## Combining Custom Elements

Build complex HUD configurations by combining elements:

```swift
// Custom indicator with progress-style layout
let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
indicator.color = .white

let hud = HUD.show(to: view, mode: .custom(indicator)) { hud in
    hud.contentView.label.text = "Syncing..."
    hud.contentView.detailsLabel.text = "3 of 10 files"
    hud.contentView.contentColor = .white
    hud.contentView.style = .solidColor
    hud.contentView.color = UIColor.black.withAlphaComponent(0.85)
    hud.contentView.roundedCorners = .radius(16)
    hud.contentView.layout.hMargin = 24
    hud.contentView.layout.vMargin = 20
    hud.animation = .animation(.zoomInOut, damping: .default)
    hud.backgroundView.style = .solidColor
    hud.backgroundView.color = UIColor.black.withAlphaComponent(0.2)
}
```
