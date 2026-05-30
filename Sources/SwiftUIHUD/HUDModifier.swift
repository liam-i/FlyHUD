//
//  HUDModifier.swift
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

// MARK: - HUDModifier (isPresented)

/// A ViewModifier that presents a HUD controlled by a Boolean binding.
struct HUDModifier: ViewModifier {
    @Binding private var isPresented: Bool
    private let animation: HUD.Animation
    private let configuration: (HUD) -> Void

    init(isPresented: Binding<Bool>, animation: HUD.Animation, configuration: @escaping (HUD) -> Void) {
        self._isPresented = isPresented
        self.animation = animation
        self.configuration = configuration
    }

    func body(content: Content) -> some View {
        content.background(
            HUDRepresentable(
                isPresented: $isPresented,
                animation: animation,
                configuration: configuration
            )
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - HUDRepresentable

/// The UIViewRepresentable that manages HUD lifecycle via a Coordinator.
private struct HUDRepresentable: UIViewRepresentable {
    @Binding var isPresented: Bool
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
        coordinator.animation = animation
        coordinator.configuration = configuration
        coordinator.isPresentedBinding = $isPresented
        coordinator.updatePresentation()
    }

    func makeCoordinator() -> HUDCoordinator {
        HUDCoordinator()
    }

    static func dismantleUIView(_ uiView: HUDTargetView, coordinator: HUDCoordinator) {
        coordinator.cleanup()
    }
}

// MARK: - HUDCoordinator

/// Manages the lifecycle of a single HUD instance for the declarative modifier.
@MainActor final class HUDCoordinator {
    var hostView: UIView?
    var isPresented: Bool = false
    var animation: HUD.Animation = .init()
    var configuration: ((HUD) -> Void)?
    var isPresentedBinding: Binding<Bool>?

    private var currentHUD: HUD?
    private var hideRequested: Bool = false

    func updatePresentation() {
        if isPresented {
            showHUD()
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

    private func showHUD() {
        guard let hostView else { return }
        if let existing = currentHUD, existing.superview != nil {
            existing.animation = animation
            configuration?(existing)
            if hideRequested {
                // Re-show: cancels the in-progress hide animation
                hideRequested = false
                existing.show(using: animation)
            }
            return
        }
        let hud = HUD(with: hostView)
        hud.animation = animation
        hud.removeFromSuperViewOnHide = true
        hud.completionBlock = { [weak self, weak hud] _ in
            guard let self, let hud, self.currentHUD === hud, hud.isHidden else { return }
            self.currentHUD = nil
            self.hideRequested = false
            if self.isPresented == true {
                self.isPresentedBinding?.wrappedValue = false
            }
        }
        configuration?(hud)
        hostView.addSubview(hud)
        hud.show(using: animation)
        currentHUD = hud
    }

    private func hideHUD() {
        guard let hud = currentHUD else { return }
        hideRequested = true
        hud.hide(using: animation)
    }
}

// MARK: - HUDItemModifier (item)

/// A ViewModifier that presents a HUD controlled by an optional Identifiable item binding.
struct HUDItemModifier<Item: Identifiable>: ViewModifier {
    @Binding private var item: Item?
    private let animation: HUD.Animation
    private let configuration: (Item, HUD) -> Void

    init(item: Binding<Item?>, animation: HUD.Animation, configuration: @escaping (Item, HUD) -> Void) {
        self._item = item
        self.animation = animation
        self.configuration = configuration
    }

    func body(content: Content) -> some View {
        content.background(
            HUDItemRepresentable(
                item: $item,
                animation: animation,
                configuration: configuration
            )
            .frame(width: 0, height: 0)
        )
    }
}

// MARK: - HUDItemRepresentable

/// The UIViewRepresentable that manages HUD lifecycle driven by an Identifiable item.
private struct HUDItemRepresentable<Item: Identifiable>: UIViewRepresentable {
    @Binding var item: Item?
    let animation: HUD.Animation
    let configuration: (Item, HUD) -> Void

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
        coordinator.currentItem = item
        coordinator.animation = animation
        coordinator.configuration = configuration
        coordinator.itemBinding = $item
        coordinator.updatePresentation()
    }

    func makeCoordinator() -> HUDItemCoordinator<Item> {
        HUDItemCoordinator()
    }

    static func dismantleUIView(_ uiView: HUDTargetView, coordinator: HUDItemCoordinator<Item>) {
        coordinator.cleanup()
    }
}

// MARK: - HUDItemCoordinator

/// Manages the lifecycle of a single HUD instance driven by an Identifiable item.
@MainActor final class HUDItemCoordinator<Item: Identifiable> {
    var hostView: UIView?
    var currentItem: Item?
    var animation: HUD.Animation = .init()
    var configuration: ((Item, HUD) -> Void)?
    var itemBinding: Binding<Item?>?

    private var currentHUD: HUD?
    private var currentItemID: Item.ID?

    func updatePresentation() {
        if let item = currentItem {
            let newID: AnyHashable = item.id as AnyHashable
            let oldID: AnyHashable? = currentItemID.map { $0 as AnyHashable }
            if newID != oldID {
                // Disown the old HUD before hiding so its completionBlock guard fails
                if let oldHUD = currentHUD {
                    currentHUD = nil
                    if currentItemID != nil {
                        oldHUD.hide(using: animation)
                    } else {
                        oldHUD.hide(using: .init(style: .none))
                    }
                }
                currentItemID = item.id
            }
            showHUD(with: item)
        } else {
            hideHUD(animated: true)
            currentItemID = nil
        }
    }

    func cleanup() {
        let hud = currentHUD
        currentHUD = nil
        hud?.hide(using: .init(style: .none))
    }

    private func showHUD(with item: Item) {
        guard let hostView else { return }
        if let existing = currentHUD, existing.superview != nil {
            existing.animation = animation
            configuration?(item, existing)
            return
        }
        let hud = HUD(with: hostView)
        hud.animation = animation
        hud.removeFromSuperViewOnHide = true
        hud.completionBlock = { [weak self, weak hud] _ in
            guard let self, let hud, self.currentHUD === hud, hud.isHidden else { return }
            self.currentHUD = nil
            if self.currentItem != nil {
                self.itemBinding?.wrappedValue = nil
            }
        }
        configuration?(item, hud)
        hostView.addSubview(hud)
        hud.show(using: animation)
        currentHUD = hud
    }

    private func hideHUD(animated: Bool) {
        guard let hud = currentHUD else { return }
        if animated {
            hud.hide(using: animation)
        } else {
            hud.hide(using: .init(style: .none))
        }
    }
}
