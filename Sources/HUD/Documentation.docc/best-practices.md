# Best Practices

Recommended patterns for using FlyHUD effectively in production apps.

## Lifecycle Management

The following diagram shows the recommended pattern for managing HUD lifecycle with async operations:

![Sequence diagram showing ViewController starting a HUD, performing an async task, then transitioning to success or failure state before auto-hiding.](best-practices-lifecycle.svg)

### Always Hide Your HUDs

Ensure every `show()` has a matching `hide()` to prevent leaked HUD views:

```swift
let hud = HUD.show(to: view)

Task {
    do {
        let result = try await fetchData()
        hud.contentView.mode = .custom(UIImageView(image: UIImage(systemName: "checkmark")))
        hud.contentView.label.text = "Done"
        hud.hide(afterDelay: 1.0)
    } catch {
        hud.contentView.mode = .text
        hud.contentView.label.text = "Failed"
        hud.hide(afterDelay: 2.0)
    }
}
```

### Use removeFromSuperViewOnHide

When using `HUD.show(to:)`, the HUD is automatically removed from its superview
on hide (default behavior). For manually created HUDs, set this explicitly:

```swift
let hud = HUD(with: view)
hud.removeFromSuperViewOnHide = true
view.addSubview(hud)
hud.show()
```

### Avoid Retain Cycles

Use `[weak self]` when referencing `self` in completion blocks:

```swift
hud.completionBlock = { [weak self] _ in
    self?.navigateToNextScreen()
}
```

## View Hierarchy

### Choose the Right Parent View

```swift
// Good: Add to the view controller's view
HUD.show(to: self.view)

// Good: Add to a specific container
HUD.show(to: tableView)

// Caution: Adding to window covers everything
HUD.show(to: view.window!)
```

### Avoid Adding to Scrollable Views

Adding a HUD to a `UIScrollView` or `UITableView` directly may cause
unexpected behavior as the user scrolls. Prefer adding to the view controller's view.

## Async/Await Integration

### With Swift Concurrency

```swift
@MainActor
func loadData() async {
    let hud = HUD.show(to: view)

    do {
        let data = try await api.fetchItems()
        updateUI(with: data)
    } catch {
        showError(error)
    }

    hud.hide()
}
```

### With URLSession

```swift
let hud = HUD.show(to: view, mode: .progress(.roundBar), label: "Downloading")

let observation = task.progress.observe(\.fractionCompleted) { progress, _ in
    DispatchQueue.main.async {
        hud.contentView.progress = Float(progress.fractionCompleted)
    }
}

// Or use observedProgress for automatic binding
hud.contentView.observedProgress = task.progress
```

## Grace Time Usage

Use grace time to avoid HUD flicker for fast operations:

```swift
let hud = HUD(with: view)
hud.graceTime = 0.3          // Don't show for tasks < 300ms
hud.minShowTime = 0.5        // If shown, display for at least 500ms
hud.removeFromSuperViewOnHide = true
view.addSubview(hud)
hud.show()

// Fast task — HUD never appears
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    hud.hide()
}
```

## Activity Count Pattern

Use activity counts for multi-source loading states:

```swift
class DataManager {
    private var hud: HUD?

    func showLoading(on view: UIView) {
        if hud == nil {
            hud = HUD.show(to: view)
            hud?.isCountEnabled = true
        } else {
            hud?.show()
        }
    }

    func hideLoading() {
        hud?.hide()
    }
}
```

## Performance

### Reuse HUD Instances

For repeated show/hide cycles, reuse the same HUD instance:

```swift
class ViewController: UIViewController {
    private lazy var hud: HUD = {
        let hud = HUD(with: view)
        hud.removeFromSuperViewOnHide = false
        view.addSubview(hud)
        return hud
    }()

    func refresh() {
        hud.show()
        // ...
        hud.hide()
    }
}
```

### Avoid Unnecessary Mode Changes

Changing `mode` tears down and rebuilds indicator views. Only change when needed:

```swift
// Avoid in tight loops
// ❌ hud.contentView.mode = .indicator(.large)  // every frame

// ✅ Set once, update progress/labels as needed
hud.contentView.progress = newValue
```

## Error Handling Pattern

![State diagram showing HUD state transitions: Loading → Success (checkmark, short auto-hide) or Failure (text, longer auto-hide), both ending with completionBlock.](error-handling-states.svg)

Transition HUD state on success/failure:

```swift
let hud = HUD.show(to: view, label: "Saving...")

saveDocument { result in
    switch result {
    case .success:
        let checkmark = UIImageView(image: UIImage(systemName: "checkmark"))
        hud.contentView.mode = .custom(checkmark)
        hud.contentView.label.text = "Saved"
        hud.hide(afterDelay: 1.5)

    case .failure(let error):
        hud.contentView.mode = .text
        hud.contentView.label.text = "Error"
        hud.contentView.detailsLabel.text = error.localizedDescription
        hud.hide(afterDelay: 3.0)
    }
}
```

## Accessibility

### Dynamic Type

Enable Dynamic Type for HUD labels:

```swift
hud.contentView.isDynamicTypeEnabled = true
```

### Content Color Contrast

Ensure sufficient contrast between content and background:

```swift
// Dark background with light text
hud.contentView.style = .solidColor
hud.contentView.color = UIColor(white: 0.1, alpha: 0.9)
hud.contentView.contentColor = .white
```
