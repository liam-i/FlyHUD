//
//  ViewController.swift
//  Example tvOS
//
//  Created by liam on 2024/1/15.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Standard UIButton automatically adopts Liquid Glass on focus (tvOS 26+).
    }

    @IBAction func buttonClicked(_ sender: UIButton) {
        sender.isEnabled = false

        let hud = HUD.show(to: view) {
            $0.contentView.mode = .custom(ProgressView(style: .buttBar, size: CGSize(width: 320, height: 40)).h.then {
                $0.lineWidth = 10
            })
            $0.contentView.label.text = NSLocalizedString("Loading...", comment: "HUD loading title")
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Task {
            await Self.simulateProgress { progress in
                hud.contentView.progress = progress
            }
            hud.hide()
            sender.isEnabled = true
        }
    }

    /// Simulates a progress task using structured concurrency.
    static func simulateProgress(
        duration: UInt32 = 3,
        onProgress: @MainActor @Sendable @escaping (Float) -> Void
    ) async {
        let steps = 100
        let intervalNanoseconds = UInt64(duration) * 1_000_000_000 / UInt64(steps)

        for step in 1...steps {
            try? await Task.sleep(nanoseconds: intervalNanoseconds)
            let progress = Float(step) / Float(steps)
            await MainActor.run { onProgress(progress) }
        }
    }
}
