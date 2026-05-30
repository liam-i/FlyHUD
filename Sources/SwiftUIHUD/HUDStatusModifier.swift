//
//  HUDStatusModifier.swift
//  FlyHUDSwiftUI <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/12/1.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import SwiftUI

#if !COCOAPODS && canImport(FlyHUD)
import FlyHUD
#endif // !COCOAPODS && canImport(FlyHUD)

// MARK: - HUDStatusModifier

/// A ViewModifier that presents a self-dismissing HUD (toast/status) controlled by a Boolean binding.
struct HUDStatusModifier: ViewModifier {
    @Binding private var isPresented: Bool
    private let duration: TimeInterval
    private let animation: HUD.Animation
    private let configuration: (HUD) -> Void

    init(isPresented: Binding<Bool>, duration: TimeInterval, animation: HUD.Animation, configuration: @escaping (HUD) -> Void) {
        self._isPresented = isPresented
        self.duration = duration
        self.animation = animation
        self.configuration = configuration
    }

    func body(content: Content) -> some View {
        content.background(
            HUDStatusRepresentable(
                isPresented: $isPresented,
                duration: duration,
                animation: animation,
                configuration: configuration
            )
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - HUDStatusRepresentable

/// The UIViewRepresentable that manages a self-dismissing HUD via a Coordinator.
private struct HUDStatusRepresentable: UIViewRepresentable {
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let animation: HUD.Animation
    let configuration: (HUD) -> Void

    func makeUIView(context: Context) -> HUDTargetView {
        let view = HUDTargetView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.onWindow = { [weak coordinator = context.coordinator] window in
            coordinator?.hostView = window
            coordinator?.updatePresentation()
        }
        return view
    }

    func updateUIView(_ uiView: HUDTargetView, context: Context) {
        let coordinator = context.coordinator
        coordinator.isPresented = isPresented
        coordinator.duration = duration
        coordinator.animation = animation
        coordinator.configuration = configuration
        coordinator.isPresentedBinding = $isPresented
        coordinator.updatePresentation()
    }

    func makeCoordinator() -> HUDStatusCoordinator {
        HUDStatusCoordinator()
    }

    static func dismantleUIView(_ uiView: HUDTargetView, coordinator: HUDStatusCoordinator) {
        coordinator.cleanup()
    }
}

// MARK: - HUDStatusCoordinator

/// Manages the lifecycle of a self-dismissing HUD instance.
@MainActor final class HUDStatusCoordinator {
    var hostView: UIView?
    var isPresented: Bool = false
    var duration: TimeInterval = 2.0
    var animation: HUD.Animation = .init()
    var configuration: ((HUD) -> Void)?
    var isPresentedBinding: Binding<Bool>?

    private var currentHUD: HUD?
    private var wasPresented: Bool = false

    func updatePresentation() {
        if isPresented && !wasPresented {
            showStatusHUD()
        } else if !isPresented && wasPresented {
            hideHUD()
            wasPresented = false
        }
    }

    func cleanup() {
        let hud = currentHUD
        currentHUD = nil
        wasPresented = false
        hud?.hide(using: .init(style: .none))
    }

    private func showStatusHUD() {
        guard let hostView else { return }
        wasPresented = true
        // Hide any existing status HUD first
        if let existing = currentHUD, existing.superview != nil {
            currentHUD = nil // Detach before hide: prevents synchronous completion from resetting binding
            existing.hide(using: .init(style: .none))
        }

        let hud = HUD(with: hostView)
        hud.animation = animation
        hud.removeFromSuperViewOnHide = true
        hud.completionBlock = { [weak self, weak hud] _ in
            guard let self, let hud, self.currentHUD === hud, hud.isHidden else { return }
            self.currentHUD = nil
            self.wasPresented = false
            if self.isPresented == true {
                self.isPresentedBinding?.wrappedValue = false
            }
        }
        configuration?(hud)
        hostView.addSubview(hud)
        hud.show(using: animation)
        hud.hide(using: animation, afterDelay: duration)
        currentHUD = hud
    }

    private func hideHUD() {
        guard let hud = currentHUD else { return }
        hud.hide(using: animation)
    }
}
