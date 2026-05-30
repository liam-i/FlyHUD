//
//  HUDHostView.swift
//  FlyHUDSwiftUI <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import SwiftUI

#if !COCOAPODS && canImport(FlyHUD)
import FlyHUD
#endif // !COCOAPODS && canImport(FlyHUD)

// MARK: - HUDTargetView

/// A UIView subclass that reports when it's added to a window.
final class HUDTargetView: UIView {
    var onWindow: ((UIView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        // VoiceOver: This is an invisible 0×0 bridge view used only to access the window.
        // Hidden from accessibility to prevent VoiceOver from focusing an empty element.
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else { return }
        onWindow?(window)
    }
}

// MARK: - HUDHostView

/// A UIViewRepresentable that provides access to a UIView (window) for presenting HUDs.
///
/// This is the low-level bridge between SwiftUI and UIKit. Most users should prefer
/// the higher-level `.hud(isPresented:)` modifier instead.
public struct HUDHostView: UIViewRepresentable {
    private let onViewReady: (UIView) -> Void

    public init(onViewReady: @escaping (UIView) -> Void) {
        self.onViewReady = onViewReady
    }

    public func makeUIView(context: Context) -> some UIView {
        let view = HUDTargetView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.onWindow = onViewReady
        return view
    }

    public func updateUIView(_ uiView: some UIView, context: Context) {}
}

// MARK: - HUDContainerModifier

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
