//
//  LiquidGlassView.swift
//  Example SwiftUI
//
//  Created by Liam on 2025/7/18.
//  Copyright © 2025 Liam. All rights reserved.
//

import SwiftUI
import FlyHUD

// MARK: - Liquid Glass Demo

/// Demonstrates FlyHUD with Liquid Glass style (iOS 26+).
struct LiquidGlassView: View {
    @State private var hostView: UIView?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                hudDemoSection
            }
            .padding()
        }
        .background(backgroundGradient)
        .navigationTitle("Glass HUD")
        .hudHost($hostView)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2), .orange.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - HUD Demo

    private var hudDemoSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("HUD with Glass Style")
                .font(.headline)

            Text("BackgroundView.Style.glass on the HUD contentView")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()

            #if compiler(>=6.2) && !os(visionOS)
            if #available(iOS 26.0, *) {
                VStack(spacing: 16) {
                    Button("Glass HUD") { showGlassHUD() }
                        .buttonStyle(.glass)

                    Button("Tinted Glass HUD") { showTintedGlassHUD() }
                        .buttonStyle(.glass)

                    Button("Full Rounded Glass") { showFullRoundedGlassHUD() }
                        .buttonStyle(.glass)

                    Button("Text-Only Glass") { showTextGlassHUD() }
                        .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity)
            } else {
                unavailableHint
            }
            #else
            unavailableHint
            #endif
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - HUD Actions

    #if compiler(>=6.2) && !os(visionOS)
    @available(iOS 26.0, *)
    private func showGlassHUD() {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .indicator(), label: "Loading...") {
            $0.contentView.style = .glass
            $0.contentView.roundedCorners = .radius(20)
        }
        hud.hide(afterDelay: 2.5)
    }

    @available(iOS 26.0, *)
    private func showTintedGlassHUD() {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .indicator(), label: "Syncing...") {
            $0.contentView.style = .glass
            $0.contentView.color = .systemBlue
            $0.contentView.roundedCorners = .radius(20)
        }
        hud.hide(afterDelay: 2.5)
    }

    @available(iOS 26.0, *)
    private func showFullRoundedGlassHUD() {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .indicator(), label: "Done") {
            $0.contentView.style = .glass
            $0.contentView.roundedCorners = .full
        }
        hud.hide(afterDelay: 2.5)
    }

    @available(iOS 26.0, *)
    private func showTextGlassHUD() {
        guard let view = hostView else { return }
        let hud = HUD.show(to: view, mode: .text, label: "Saved!", detailsLabel: "Your changes have been saved") {
            $0.contentView.style = .glass
            $0.contentView.roundedCorners = .radius(16)
        }
        hud.hide(afterDelay: 2.0)
    }
    #endif

    // MARK: - Unavailable

    private var unavailableHint: some View {
        Text("Requires iOS 26+ (compile with Xcode 26 SDK)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }
}
