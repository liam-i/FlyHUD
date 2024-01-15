//
//  ViewController.swift
//  HUD_ExampleTV
//
//  Created by liam on 2024/1/15.
//  Copyright © 2024 CocoaPods. All rights reserved.
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
            $0.mode = .determinateHorizontalBar(lineWidth: 10, spacing: 5)
            $0.label.text = NSLocalizedString("Loading...", comment: "HUD loading title")
            $0.label.font = .boldSystemFont(ofSize: 36)
        }

        Self.request { progress in
            hud.progress = progress
        } completion: {
            hud.hide()

            sender.isEnabled = true
        }
    }
    
    static func request(_ sec: UInt32 = 3, progress: @escaping (CGFloat) -> Void, completion: @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100

        DispatchQueue.global().async {
            // 模拟一个任务的完成进度
            var progressValue: CGFloat = 0.0
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
