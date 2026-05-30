//
//  View+HUD.swift
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

// MARK: - Layer 1: Basic Bridge

public extension View {
    /// Attaches a HUD host to this view, exposing the backing UIView via binding.
    ///
    /// Use this for direct UIKit-style HUD control:
    /// ```swift
    /// @State private var hostView: UIView?
    ///
    /// MyView()
    ///     .hudHost($hostView)
    ///
    /// // Then use:
    /// if let view = hostView {
    ///     HUD.show(to: view, mode: .indicator(), label: "Loading...")
    /// }
    /// ```
    func hudHost(_ hostView: Binding<UIView?>) -> some View {
        modifier(HUDContainerModifier(hostView: hostView))
    }
}

// MARK: - Layer 2: Declarative Modifiers

public extension View {
    /// Presents a HUD controlled by a Boolean binding.
    ///
    /// ```swift
    /// @State private var isLoading = false
    ///
    /// MyView()
    ///     .hud(isPresented: $isLoading) { hud in
    ///         hud.contentView.mode = .indicator()
    ///         hud.contentView.label.text = "Loading..."
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - animation: The animation style for show/hide transitions.
    ///   - configuration: A closure that configures the HUD instance.
    func hud(
        isPresented: Binding<Bool>,
        animation: HUD.Animation = .init(),
        configuration: @escaping (HUD) -> Void = { _ in }
    ) -> some View {
        modifier(HUDModifier(isPresented: isPresented, animation: animation, configuration: configuration))
    }

    /// Presents a HUD controlled by an optional Identifiable item binding.
    ///
    /// The HUD is shown when `item` is non-nil, and hidden when set to `nil`.
    ///
    /// ```swift
    /// @State private var hudItem: MyHUDItem?
    ///
    /// MyView()
    ///     .hud(item: $hudItem) { item, hud in
    ///         hud.contentView.mode = item.mode
    ///         hud.contentView.label.text = item.label
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - item: A binding to an optional Identifiable item.
    ///   - animation: The animation style for show/hide transitions.
    ///   - configuration: A closure that configures the HUD instance with the current item.
    func hud<Item: Identifiable>(
        item: Binding<Item?>,
        animation: HUD.Animation = .init(),
        configuration: @escaping (Item, HUD) -> Void
    ) -> some View {
        modifier(HUDItemModifier(item: item, animation: animation, configuration: configuration))
    }

    /// Presents a self-dismissing status HUD (toast).
    ///
    /// The HUD automatically hides after the specified duration and resets the binding to `false`.
    ///
    /// ```swift
    /// @State private var showSuccess = false
    ///
    /// MyView()
    ///     .hudStatus(isPresented: $showSuccess, duration: 2.0) { hud in
    ///         hud.contentView.mode = .text
    ///         hud.contentView.label.text = "Saved!"
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - duration: Time in seconds before the HUD auto-hides.
    ///   - animation: The animation style for show/hide transitions.
    ///   - configuration: A closure that configures the HUD instance.
    func hudStatus(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 2.0,
        animation: HUD.Animation = .init(),
        configuration: @escaping (HUD) -> Void = { _ in }
    ) -> some View {
        modifier(HUDStatusModifier(isPresented: isPresented, duration: duration, animation: animation, configuration: configuration))
    }
}

// MARK: - Layer 3: Convenience Presets

public extension View {
    /// Presents a simple loading indicator HUD.
    ///
    /// ```swift
    /// MyView().hudLoading(isPresented: $isLoading, label: "Loading...")
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - label: An optional label below the indicator.
    ///   - detailsLabel: An optional details label below the main label.
    func hudLoading(
        isPresented: Binding<Bool>,
        label: String? = nil,
        detailsLabel: String? = nil
    ) -> some View {
        modifier(HUDLoadingModifier(isPresented: isPresented, label: label, detailsLabel: detailsLabel))
    }

    /// Presents a self-dismissing text toast.
    ///
    /// ```swift
    /// MyView().hudToast(isPresented: $showToast, label: "Saved!")
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - duration: Time in seconds before the toast auto-hides.
    ///   - label: The main text to display.
    ///   - detailsLabel: An optional details text below the main label.
    func hudToast(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 1.5,
        label: String,
        detailsLabel: String? = nil
    ) -> some View {
        modifier(HUDToastModifier(isPresented: isPresented, duration: duration, label: label, detailsLabel: detailsLabel))
    }

    /// Presents a progress HUD with a bound progress value.
    ///
    /// ```swift
    /// MyView().hudProgress(isPresented: $isUploading, progress: $progress, label: "Uploading")
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - progress: A binding to the current progress value (0.0 to 1.0).
    ///   - label: An optional label below the progress indicator.
    func hudProgress(
        isPresented: Binding<Bool>,
        progress: Binding<Float>,
        label: String? = nil
    ) -> some View {
        modifier(HUDProgressModifier(isPresented: isPresented, progress: progress, label: label))
    }
}

// MARK: - Layer 4: iOS 26+ Liquid Glass

#if compiler(>=6.2) && !os(visionOS)
@available(iOS 26.0, tvOS 26.0, *)
public extension View {
    /// Presents a HUD with Liquid Glass style (iOS 26+).
    ///
    /// ```swift
    /// MyView().hudGlass(isPresented: $isLoading, label: "Loading...")
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding that controls HUD visibility.
    ///   - label: An optional label below the indicator.
    ///   - detailsLabel: An optional details label.
    func hudGlass(
        isPresented: Binding<Bool>,
        label: String? = nil,
        detailsLabel: String? = nil
    ) -> some View {
        modifier(
            HUDModifier(
                isPresented: isPresented,
                animation: .init(),
                configuration: { hud in
                    hud.contentView.mode = .indicator()
                    hud.contentView.style = .glass
                    hud.contentView.label.text = label
                    hud.contentView.detailsLabel.text = detailsLabel
                }
            )
        )
    }
}
#endif
