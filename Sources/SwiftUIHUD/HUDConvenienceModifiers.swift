//
//  HUDConvenienceModifiers.swift
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

// MARK: - HUDLoadingModifier

/// A ViewModifier that presents a simple loading HUD.
struct HUDLoadingModifier: ViewModifier {
    @Binding private var isPresented: Bool
    private let label: String?
    private let detailsLabel: String?

    init(isPresented: Binding<Bool>, label: String?, detailsLabel: String?) {
        self._isPresented = isPresented
        self.label = label
        self.detailsLabel = detailsLabel
    }

    func body(content: Content) -> some View {
        content.modifier(
            HUDModifier(
                isPresented: $isPresented,
                animation: .init(),
                configuration: { hud in
                    hud.contentView.mode = .indicator()
                    hud.contentView.label.text = label
                    hud.contentView.detailsLabel.text = detailsLabel
                }
            )
        )
    }
}

// MARK: - HUDToastModifier

/// A ViewModifier that presents a self-dismissing text toast.
struct HUDToastModifier: ViewModifier {
    @Binding private var isPresented: Bool
    private let duration: TimeInterval
    private let label: String
    private let detailsLabel: String?

    init(isPresented: Binding<Bool>, duration: TimeInterval, label: String, detailsLabel: String?) {
        self._isPresented = isPresented
        self.duration = duration
        self.label = label
        self.detailsLabel = detailsLabel
    }

    func body(content: Content) -> some View {
        content.modifier(
            HUDStatusModifier(
                isPresented: $isPresented,
                duration: duration,
                animation: .init(),
                configuration: { hud in
                    hud.contentView.mode = .text
                    hud.contentView.label.text = label
                    hud.contentView.detailsLabel.text = detailsLabel
                }
            )
        )
    }
}

// MARK: - HUDProgressModifier

/// A ViewModifier that presents a progress HUD with a bound progress value.
struct HUDProgressModifier: ViewModifier {
    @Binding private var isPresented: Bool
    @Binding private var progress: Float
    private let label: String?

    init(isPresented: Binding<Bool>, progress: Binding<Float>, label: String?) {
        self._isPresented = isPresented
        self._progress = progress
        self.label = label
    }

    func body(content: Content) -> some View {
        content.background(
            HUDProgressRepresentable(
                isPresented: $isPresented,
                progress: $progress,
                label: label
            )
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - HUDProgressRepresentable

/// The UIViewRepresentable that manages a progress HUD via a Coordinator.
private struct HUDProgressRepresentable: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var progress: Float
    let label: String?

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
        coordinator.progress = progress
        coordinator.label = label
        coordinator.isPresentedBinding = $isPresented
        coordinator.updatePresentation()
    }

    func makeCoordinator() -> HUDProgressCoordinator {
        HUDProgressCoordinator()
    }

    static func dismantleUIView(_ uiView: HUDTargetView, coordinator: HUDProgressCoordinator) {
        coordinator.cleanup()
    }
}

// MARK: - HUDProgressCoordinator

/// Manages the lifecycle of a progress HUD instance.
@MainActor final class HUDProgressCoordinator {
    var hostView: UIView?
    var isPresented: Bool = false
    var progress: Float = 0.0
    var label: String?
    var isPresentedBinding: Binding<Bool>?

    private var currentHUD: HUD?
    private var hideRequested: Bool = false

    func updatePresentation() {
        if isPresented {
            showOrUpdateHUD()
        } else {
            hideHUD()
        }
    }

    func cleanup() {
        let hud = currentHUD
        currentHUD = nil
        hideRequested = false
        hud?.hide(using: .init(style: .none))
    }

    private func showOrUpdateHUD() {
        guard let hostView else { return }
        if let existing = currentHUD, existing.superview != nil {
            existing.contentView.progress = progress
            existing.contentView.label.text = label
            if hideRequested {
                // Re-show: cancels the in-progress hide animation
                hideRequested = false
                existing.show(animated: true)
            }
            return
        }
        let hud = HUD(with: hostView)
        hud.removeFromSuperViewOnHide = true
        hud.completionBlock = { [weak self, weak hud] _ in
            guard let self, let hud, self.currentHUD === hud, hud.isHidden else { return }
            self.currentHUD = nil
            self.hideRequested = false
            if self.isPresented == true {
                self.isPresentedBinding?.wrappedValue = false
            }
        }
        hud.contentView.mode = .progress()
        hud.contentView.label.text = label
        hud.contentView.progress = progress
        hostView.addSubview(hud)
        hud.show(animated: true)
        currentHUD = hud
    }

    private func hideHUD() {
        guard let hud = currentHUD else { return }
        hideRequested = true
        hud.hide(animated: true)
    }
}
