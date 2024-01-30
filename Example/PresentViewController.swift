//
//  PresentViewController.swift
//  HUD_Example
//
//  Created by Liam on 2024/1/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit
import LPHUD

class PresentViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!

    @IBAction func showHUDClicked(_ sender: UIButton) {
        HUD.showStatus(to: view, duration: .greatestFiniteMagnitude, using: .animation(.slideDownUp, damping: .default), 
                       mode: .text, label: "You have a message.", offset: .h.vMinOffset) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
        HUD.show(to: view, using: .animation(.zoomInOut, damping: .default), label: "Loading") {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .center()
        }
        HUD.showStatus(to: view, duration: .greatestFiniteMagnitude, using: .animation(.slideUpDown, damping: .default), 
                       mode: .text, label: "Wrong password", offset: .h.vMaxOffset) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }

        HUD.showStatus(to: containerView, duration: .greatestFiniteMagnitude, using: .animation(.slideDownUp, damping: .default),
                       mode: .text, label: "Wrong password", offset: CGPoint(x: .h.maxOffset, y: -.h.maxOffset)) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
        HUD.show(to: containerView, using: .animation(.zoomOutIn, damping: .default), label: "Loading") {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .center()
            $0.layout.offset.x = .h.maxOffset
        }
        HUD.showStatus(to: containerView, duration: .greatestFiniteMagnitude, using: .animation(.slideUpDown, damping: .default),
                       mode: .text, label: "Wrong password", offset: CGPoint(x: .h.maxOffset, y: .h.maxOffset)) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
    }

    @IBAction func hideTopHUDClicked(_ sender: UIButton) {
        HUD.hide(for: view)
        HUD.hide(for: containerView)
    }

    @IBAction func hideAllHUDClicked(_ sender: Any) {
        HUD.hideAll(for: view)
        HUD.hideAll(for: containerView)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        view.endEditing(true)
    }

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        print("PresentView=\(view.safeAreaInsets)")
//    }
}
