//
//  PresentViewController.swift
//  HUD_Example
//
//  Created by 李鹏 on 2024/1/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import LPHUD

class PresentViewController: UIViewController {
    var offsetY1: CGFloat = -50
    var offsetY2: CGFloat = 50

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func showHUDClicked(_ sender: UIButton) {
        HUD.show(to: view, using: .animation(.slideDownUp, damping: .default), label: "Loading") {
            $0.isEventDeliveryEnabled = true
            $0.layout.offset.y = self.offsetY1
            $0.keyboardGuide = .center()
        }
        HUD.showStatus(to: view, duration: 3, using: .animation(.slideUpDown, damping: .default), mode: .text, label: "Wrong password") {
            $0.isEventDeliveryEnabled = true
            $0.layout.offset.y = self.offsetY2
            $0.keyboardGuide = .bottom()
        }

        offsetY1 += -50
        offsetY2 += 50
        if offsetY1 < -view.bounds.maxY / 2 {
            offsetY1 = -50
        }
        if offsetY2 > view.bounds.maxY / 2 {
            offsetY2 = 50
        }
    }
    
    @IBAction func hideTopHUDClicked(_ sender: UIButton) {
        HUD.hide(for: view)
    }

    @IBAction func hideAllHUDClicked(_ sender: Any) {
        HUD.hideAll(for: view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        view.endEditing(true)
    }
}
