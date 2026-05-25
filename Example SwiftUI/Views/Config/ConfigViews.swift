//
//  ConfigViews.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD

// MARK: - Layout & Positioning

/// Demonstrates HUD.Layout and ContentView.Layout properties.
///
/// ```swift
/// hud.layout.offset = CGPoint(x: 0, y: -50)
/// hud.layout.edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
/// hud.layout.isSafeAreaLayoutGuideEnabled = true
/// hud.contentView.layout.hMargin = 20
/// hud.contentView.layout.minSize = CGSize(width: 150, height: 150)
/// hud.contentView.indicatorPosition = .leading
/// ```
struct LayoutConfigView: View {
    @State private var hostView: UIView?

    var body: some View {
        List {
            Section("HUD.Layout") {
                Button("offset.y = -100 (move up)") {
                    showWith { hud in
                        hud.layout.offset = CGPoint(x: 0, y: -100)
                    }
                }
                Button("edgeInsets = 30") {
                    showWith { hud in
                        hud.layout.edgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
                    }
                }
                Button("isSafeAreaLayoutGuideEnabled = true") {
                    showWith { hud in
                        hud.layout.isSafeAreaLayoutGuideEnabled = true
                    }
                }
            }

            Section("ContentView.Layout") {
                Button("hMargin = 30, vMargin = 30") {
                    showWith { hud in
                        hud.contentView.layout.hMargin = 30
                        hud.contentView.layout.vMargin = 30
                    }
                }
                Button("hSpacing = 20, vSpacing = 20") {
                    showWith { hud in
                        hud.contentView.layout.hSpacing = 20
                        hud.contentView.layout.vSpacing = 20
                    }
                }
                Button("minSize = (200, 200)") {
                    showWith { hud in
                        hud.contentView.layout.minSize = CGSize(width: 200, height: 200)
                    }
                }
                Button("isSquare = true") {
                    showWith { hud in
                        hud.contentView.layout.isSquare = true
                    }
                }
            }

            Section("ContentView.IndicatorPosition") {
                Button("position = .top (default)") {
                    showWith { hud in
                        hud.contentView.indicatorPosition = .top
                    }
                }
                Button("position = .bottom") {
                    showWith { hud in
                        hud.contentView.indicatorPosition = .bottom
                    }
                }
                Button("position = .leading") {
                    showWith { hud in
                        hud.contentView.indicatorPosition = .leading
                    }
                }
                Button("position = .trailing") {
                    showWith { hud in
                        hud.contentView.indicatorPosition = .trailing
                    }
                }
            }

            Section("ContentView.Alignment") {
                Button("alignment = .center (default)") {
                    showWith { hud in
                        hud.contentView.layout.alignment = .center
                    }
                }
                Button("alignment = .leading") {
                    showWith { hud in
                        hud.contentView.layout.alignment = .leading
                    }
                }
                Button("alignment = .trailing") {
                    showWith { hud in
                        hud.contentView.layout.alignment = .trailing
                    }
                }
            }
        }
        .navigationTitle("Layout")
        .hudHost($hostView)
    }

    private func showWith(_ configure: @escaping (HUD) -> Void) {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .indicator(), label: "Loading...") { hud in
            hud.contentView.detailsLabel.text = "Details label"
            configure(hud)
        }
        hud.hide(afterDelay: 2.5)
    }
}

// MARK: - Animation Styles

/// Demonstrates all `HUD.Animation.Style` cases and damping options.
///
/// ```swift
/// let hud = HUD.show(to: view, using: .animation(.slideUp, damping: .ratio(0.6), duration: 0.5))
/// hud.hide(using: .animation(.slideDown))
/// ```
struct AnimationConfigView: View {
    @State private var hostView: UIView?

    private let styles: [(HUD.Animation.Style, String)] = [
        (.fade, "fade"),
        (.zoomInOut, "zoomInOut"),
        (.zoomOutIn, "zoomOutIn"),
        (.zoomIn, "zoomIn"),
        (.zoomOut, "zoomOut"),
        (.slideUpDown, "slideUpDown"),
        (.slideDownUp, "slideDownUp"),
        (.slideUp, "slideUp"),
        (.slideDown, "slideDown"),
        (.slideRightLeft, "slideRightLeft"),
        (.slideLeftRight, "slideLeftRight"),
        (.slideRight, "slideRight"),
        (.slideLeft, "slideLeft"),
    ]

    var body: some View {
        List {
            Section("Animation Styles (14 total)") {
                Button("none (no animation)") {
                    showWithAnimation(.animation(.none))
                }
                ForEach(styles, id: \.1) { style, name in
                    Button(name) {
                        showWithAnimation(.animation(style))
                    }
                }
            }

            Section("Damping") {
                Button("damping = .disable") {
                    showWithAnimation(.animation(.zoomIn, damping: .disable))
                }
                Button("damping = .default") {
                    showWithAnimation(.animation(.zoomIn, damping: .default))
                }
                Button("damping = .ratio(0.4)") {
                    showWithAnimation(.animation(.zoomIn, damping: .ratio(0.4)))
                }
                Button("damping = .ratio(0.8)") {
                    showWithAnimation(.animation(.zoomIn, damping: .ratio(0.8)))
                }
            }

            Section("Duration") {
                Button("duration = 0.1 (fast)") {
                    showWithAnimation(.animation(.fade, duration: 0.1))
                }
                Button("duration = 0.5 (default)") {
                    showWithAnimation(.animation(.fade, duration: 0.5))
                }
                Button("duration = 1.5 (slow)") {
                    showWithAnimation(.animation(.fade, duration: 1.5))
                }
            }
        }
        .navigationTitle("Animation")
        .hudHost($hostView)
    }

    private func showWithAnimation(_ animation: HUD.Animation) {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, using: animation, mode: .indicator(), label: "Animating...")
        hud.hide(using: animation, afterDelay: 2.0)
    }
}

// MARK: - Appearance

/// Demonstrates BackgroundView and ContentView appearance properties.
///
/// ```swift
/// hud.contentView.contentColor = .systemBlue
/// hud.contentView.style = .blur(.systemMaterial)
/// hud.backgroundView.style = .blur(.dark)
/// hud.contentView.roundedCorners = .radius(20)
/// ```
struct AppearanceConfigView: View {
    @State private var hostView: UIView?

    var body: some View {
        List {
            Section("ContentView") {
                Button("contentColor = .systemBlue") {
                    showWith { hud in
                        hud.contentView.contentColor = .systemBlue
                    }
                }
                Button("contentColor = .systemRed") {
                    showWith { hud in
                        hud.contentView.contentColor = .systemRed
                    }
                }
                Button("style = .solidColor, color = .black") {
                    showWith { hud in
                        hud.contentView.style = .solidColor
                        hud.contentView.color = .black
                        hud.contentView.contentColor = .white
                    }
                }
                Button("style = .blur(.dark)") {
                    showWith { hud in
                        hud.contentView.style = .blur(.dark)
                        hud.contentView.contentColor = .white
                    }
                }
                Button("roundedCorners = .radius(20)") {
                    showWith { hud in
                        hud.contentView.roundedCorners = .radius(20)
                    }
                }
                Button("roundedCorners = .full") {
                    showWith { hud in
                        hud.contentView.roundedCorners = .full
                    }
                }
                #if compiler(>=6.2) && !os(visionOS)
                if #available(iOS 26.0, *) {
                    Button("style = .glass") {
                        showWith { hud in
                            hud.contentView.style = .glass
                            hud.contentView.roundedCorners = .radius(20)
                        }
                    }
                    Button("style = .glass, tinted blue") {
                        showWith { hud in
                            hud.contentView.style = .glass
                            hud.contentView.color = .systemBlue
                            hud.contentView.roundedCorners = .radius(20)
                        }
                    }
                }
                #endif
            }

            Section("BackgroundView") {
                Button("style = .solidColor, color = black 50%") {
                    showWith { hud in
                        hud.backgroundView.style = .solidColor
                        hud.backgroundView.color = UIColor.black.withAlphaComponent(0.5)
                    }
                }
                Button("style = .blur(.regular)") {
                    showWith { hud in
                        hud.backgroundView.style = .blur(.regular)
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .hudHost($hostView)
    }

    private func showWith(_ configure: @escaping (HUD) -> Void) {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .indicator(), label: "Styled HUD") { hud in
            hud.contentView.detailsLabel.text = "Custom appearance"
            configure(hud)
        }
        hud.hide(afterDelay: 2.5)
    }
}

// MARK: - Timing & Behavior

/// Demonstrates graceTime, minShowTime, removeFromSuperViewOnHide, isEventDeliveryEnabled.
///
/// ```swift
/// hud.graceTime = 1.0          // Delay before showing
/// hud.minShowTime = 2.0        // Minimum visible duration
/// hud.removeFromSuperViewOnHide = false
/// hud.isEventDeliveryEnabled = true
/// ```
struct TimingConfigView: View {
    @State private var hostView: UIView?

    var body: some View {
        List {
            Section("Timing") {
                Button("graceTime = 1.0 (1s delay)") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Grace Time Demo") { hud in
                        hud.graceTime = 1.0
                    }
                    hud.hide(afterDelay: 2.0)
                }
                Button("minShowTime = 3.0") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Min Show Time") { hud in
                        hud.minShowTime = 3.0
                    }
                    // Hide immediately, but HUD stays for 3s
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        hud.hide()
                    }
                }
            }

            Section("Behavior") {
                Button("removeFromSuperViewOnHide = false") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Will stay in hierarchy") { hud in
                        hud.removeFromSuperViewOnHide = false
                    }
                    hud.hide(afterDelay: 2.0)
                }
                Button("isEventDeliveryEnabled = true") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Touch passes through") { hud in
                        hud.isEventDeliveryEnabled = true
                        hud.contentView.detailsLabel.text = "Tap anywhere - events pass through"
                    }
                    hud.hide(afterDelay: 3.0)
                }
                Button("isMotionEffectsEnabled = true") {
                    guard let view = hostView else { return }
                    let hud = HUD.show(to: view, mode: .indicator(), label: "Tilt your device") { hud in
                        hud.contentView.isMotionEffectsEnabled = true
                    }
                    hud.hide(afterDelay: 3.0)
                }
            }
        }
        .navigationTitle("Timing & Behavior")
        .hudHost($hostView)
    }
}
