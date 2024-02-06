//
//  ViewController.swift
//  Example tvOS
//
//  Created by liam on 2024/1/15.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit
import LPHUD

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buttonClicked(_ sender: UIButton) {
        sender.isEnabled = false

        let hud = HUD.show(to: view) {
            $0.contentView.mode = .custom(ProgressView(style: .buttBar, size: CGSize(width: 320, height: 40), populator: {
                $0.lineWidth = 10
            }))
            $0.contentView.label.text = NSLocalizedString("Loading...", comment: "HUD loading title")
            $0.contentView.label.font = .boldSystemFont(ofSize: 36)
        }

        Self.request { progress in
            hud.contentView.progress = progress
        } completion: {
            hud.hide()

            sender.isEnabled = true
        }
    }
    
    static func request(_ sec: UInt32 = 3, progress: @escaping (Float) -> Void, completion: @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100

        DispatchQueue.global().async {
            // 模拟一个任务的完成进度
            var progressValue: Float = 0.0
            while progressValue < 1.0 {
                progressValue += 0.01 // 1 / 0.01 = 100

                /// 回到主线程刷新UI
                DispatchQueue.main.async {
                    progress(progressValue)
                }

                usleep(us)
            }

            DispatchQueue.main.async(execute: completion)
        }
    }
}
