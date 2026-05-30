//
//  IndicatorStylesView.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD
import FlyHUDSwiftUI
import FlyIndicatorHUD

// MARK: - ActivityIndicatorView Styles

/// Demonstrates all `ActivityIndicatorView.Style` cases and configurable properties.
///
/// Properties demonstrated:
/// - `style`: ringClipRotate, ballSpinFade, circleStrokeSpin, circleArcDotSpin
/// - `color`: Indicator color
/// - `trackColor`: Background track color
/// - `lineWidth`: Line thickness
/// - `hidesWhenStopped`: Auto-hide behavior
struct ActivityIndicatorStylesView: View {
    @State private var hostView: UIView?

    private let styles: [(ActivityIndicatorView.Style, String)] = [
        (.ringClipRotate, "Ring Clip Rotate"),
        (.ballSpinFade, "Ball Spin Fade"),
        (.circleStrokeSpin, "Circle Stroke Spin"),
        (.circleArcDotSpin, "Circle Arc Dot Spin"),
    ]

    var body: some View {
        List {
            Section("Tap to show HUD with style") {
                ForEach(styles, id: \.1) { style, name in
                    Button(name) {
                        showIndicator(style: style, name: name)
                    }
                }
            }

            Section("Properties Demo") {
                Button("Custom Color (systemGreen)") {
                    showWithColor(.systemGreen)
                }
                Button("Custom trackColor (systemGray4)") {
                    showWithTrackColor()
                }
                Button("Custom lineWidth (4.0)") {
                    showWithLineWidth(4.0)
                }
                Button("hidesWhenStopped = false") {
                    showHidesWhenStopped()
                }
            }
        }
        .navigationTitle("ActivityIndicatorView")
        .hudHost($hostView)
    }

    private func showIndicator(style: ActivityIndicatorView.Style, name: String) {
        guard let view = hostView else { return }
        let indicator = ActivityIndicatorView(style: style)
        let hud = HUD.show(to: view, mode: .custom(indicator), label: name)
        hud.hide(afterDelay: 3.0)
    }

    private func showWithColor(_ color: UIColor) {
        guard let view = hostView else { return }
        let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
        indicator.color = color
        let hud = HUD.show(to: view, mode: .custom(indicator), label: "color = .systemGreen")
        hud.hide(afterDelay: 3.0)
    }

    private func showWithTrackColor() {
        guard let view = hostView else { return }
        let indicator = ActivityIndicatorView(style: .ringClipRotate)
        indicator.color = .systemBlue
        indicator.trackColor = .systemGray4
        let hud = HUD.show(to: view, mode: .custom(indicator), label: "trackColor = .systemGray4")
        hud.hide(afterDelay: 3.0)
    }

    private func showWithLineWidth(_ width: CGFloat) {
        guard let view = hostView else { return }
        let indicator = ActivityIndicatorView(style: .circleStrokeSpin)
        indicator.lineWidth = width
        let hud = HUD.show(to: view, mode: .custom(indicator), label: "lineWidth = \(width)")
        hud.hide(afterDelay: 3.0)
    }

    private func showHidesWhenStopped() {
        guard let view = hostView else { return }
        let indicator = ActivityIndicatorView(style: .ballSpinFade)
        indicator.hidesWhenStopped = false
        let hud = HUD.show(to: view, mode: .custom(indicator), label: "hidesWhenStopped = false") { hud in
            hud.contentView.detailsLabel.text = "Stops after 2s, stays visible"
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))
            indicator.stopAnimating()
            try? await Task.sleep(for: .seconds(2.0))
            hud.hide()
        }
    }
}
