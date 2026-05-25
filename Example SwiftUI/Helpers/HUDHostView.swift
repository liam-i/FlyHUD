//
//  HUDHostView.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD

// MARK: - UIView Host for HUD

/// A UIView subclass that reports when it's added to a window.
final class HUDTargetView: UIView {
    var onWindow: ((UIView) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        // Use window directly — adding subviews to UIHostingController.view is not supported.
        onWindow?(window)
    }
}

/// A UIViewRepresentable that provides access to a UIView for presenting HUDs.
struct HUDHostView: UIViewRepresentable {
    let onViewReady: (UIView) -> Void

    func makeUIView(context: Context) -> HUDTargetView {
        let view = HUDTargetView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.onWindow = onViewReady
        return view
    }

    func updateUIView(_ uiView: HUDTargetView, context: Context) {}
}

// MARK: - HUD Container Modifier

/// A ViewModifier that overlays a transparent UIView for HUD presentation.
struct HUDContainerModifier: ViewModifier {
    @Binding var hostView: UIView?

    func body(content: Content) -> some View {
        content.background(
            HUDHostView { view in
                Task { @MainActor in
                    hostView = view
                }
            }
            .frame(width: 0, height: 0)
        )
    }
}

extension View {
    /// Attaches a HUD host to this view, exposing the backing UIView via binding.
    func hudHost(_ hostView: Binding<UIView?>) -> some View {
        modifier(HUDContainerModifier(hostView: hostView))
    }
}
