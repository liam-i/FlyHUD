//
//  BasicHUDView.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD

// MARK: - Basic Show / Hide

/// Demonstrates the fundamental `HUD.show(to:)` and `hud.hide()` APIs.
///
/// ```swift
/// // Show
/// let hud = HUD.show(to: view, mode: .indicator(), label: "Loading...")
/// // Hide
/// hud.hide(animated: true)
/// ```
struct BasicHUDView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Tap buttons to show/hide HUDs")
                .font(.headline)

            Button("Show Default HUD") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Loading...")
                hud.hide(afterDelay: 2.0)
            }

            Button("Show & Hide Manually") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .indicator(), label: "Working...")
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    hud.hide(animated: true)
                }
            }

            Button("Show with Animation") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, using: .animation(.zoomIn), mode: .indicator(), label: "Zoom In")
                hud.hide(using: .animation(.zoomOut), afterDelay: 2.0)
            }

            Button("Hide All") {
                guard let view = hostView else { return }
                HUD.hideAll(for: view)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Basic HUD")
        .hudHost($hostView)
    }
}

// MARK: - ShowStatus (Auto-Hide)

/// Demonstrates `HUD.showStatus(to:duration:mode:label:)`.
///
/// ```swift
/// HUD.showStatus(to: view, duration: 2.0, mode: .custom(checkmarkView), label: "Done!")
/// ```
struct StatusHUDView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("showStatus auto-hides after duration")
                .font(.headline)

            Button("Success Status") {
                guard let view = hostView else { return }
                let checkmark = UIImageView(image: UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
                HUD.showStatus(to: view, duration: 2.0, mode: .custom(checkmark), label: "Success!")
            }

            Button("Error Status") {
                guard let view = hostView else { return }
                let xmark = UIImageView(image: UIImage(systemName: "xmark.circle")?.withRenderingMode(.alwaysTemplate))
                HUD.showStatus(to: view, duration: 2.0, mode: .custom(xmark), label: "Failed!")
            }

            Button("Warning with Offset") {
                guard let view = hostView else { return }
                let warning = UIImageView(image: UIImage(systemName: "exclamationmark.triangle")?.withRenderingMode(.alwaysTemplate))
                HUD.showStatus(to: view, duration: 3.0, mode: .custom(warning), label: "Warning!", offset: CGPoint(x: 0, y: -50))
            }

            Button("Text Only Status") {
                guard let view = hostView else { return }
                HUD.showStatus(to: view, duration: 1.5, mode: .text, label: "Wrong password")
            }

            Spacer()
        }
        .padding()
        .navigationTitle("ShowStatus")
        .hudHost($hostView)
    }
}

// MARK: - Toast

/// Demonstrates text-only HUD (toast style).
///
/// ```swift
/// HUD.show(to: view, mode: .text, label: "Message sent")
/// ```
struct ToastView: View {
    @State private var hostView: UIView?

    var body: some View {
        VStack(spacing: 20) {
            Text("Text-only HUD as a toast notification")
                .font(.headline)

            Button("Simple Toast") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .text, label: "Message sent")
                hud.hide(afterDelay: 1.5)
            }

            Button("Toast with Details") {
                guard let view = hostView else { return }
                let hud = HUD.show(to: view, mode: .text, label: "Saved") { hud in
                    hud.contentView.detailsLabel.text = "Your changes have been saved"
                }
                hud.hide(afterDelay: 2.0)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Toast")
        .hudHost($hostView)
    }
}
