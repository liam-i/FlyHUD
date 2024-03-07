//
//  HUD-Bridging-OC.swift
//  Example iOS
//
//  Created by liam on 2024/2/27.
//  Copyright © 2024 Liam. All rights reserved.
//

import Foundation
import FlyHUD

class HUDBridgingOC: NSObject {
    @objc class func showMultipleHUDs(to view: UIView, containerView: UIView) {
        HUD.showStatus(to: view,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideDownUp, damping: .default),
                       mode: .custom(UIImageView(image: UIImage(named: "warning"))),
                       label: "You have an unfinished task.",
                       offset: .h.vMinOffset) {
            $0.contentView.indicatorPosition = .leading
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
        HUD.show(to: view,
                 using: .animation(.zoomInOut, damping: .default),
                 label: "Loading") {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .center()
        }
        HUD.showStatus(to: view,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideUpDown, damping: .default),
                       mode: .text,
                       label: "Wrong password",
                       offset: .h.vMaxOffset) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }

        HUD.showStatus(to: containerView,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideDownUp, damping: .default),
                       mode: .custom(UIImageView(image: UIImage(named: "warning"))),
                       label: "You have a message.",
                       offset: CGPoint(x: .h.maxOffset, y: -.h.maxOffset)) {
            $0.contentView.indicatorPosition = .trailing
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
        HUD.show(to: containerView,
                 using: .animation(.zoomOutIn, damping: .default),
                 label: "Loading") {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .center()
            $0.layout.offset.x = .h.maxOffset
        }
        HUD.showStatus(to: containerView,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideUpDown, damping: .default),
                       mode: .text,
                       label: "Wrong password",
                       offset: CGPoint(x: .h.maxOffset, y: .h.maxOffset)) {
            $0.isEventDeliveryEnabled = true
            $0.keyboardGuide = .bottom()
        }
    }

    @objc class func hide(for view: UIView, containerView: UIView) {
        HUD.hide(for: view)
        HUD.hide(for: containerView)
    }

    @objc class func hideAll(for view: UIView, containerView: UIView) {
        HUD.hideAll(for: view)
        HUD.hideAll(for: containerView)
    }
}
