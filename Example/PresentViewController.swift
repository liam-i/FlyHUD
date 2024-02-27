//
//  PresentViewController.swift
//  Example iOS
//
//  Created by Liam on 2024/1/25.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit

class PresentViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!

    @IBAction func showHUDClicked(_ sender: UIButton) {
        HUDBridgingOC.showMultipleHUDs(to: view, containerView: containerView)
    }

    @IBAction func hideTopHUDClicked(_ sender: UIButton) {
        HUDBridgingOC.hide(for: view, containerView: containerView)
    }

    @IBAction func hideAllHUDClicked(_ sender: UIButton) {
        HUDBridgingOC.hideAll(for: view, containerView: containerView)
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
