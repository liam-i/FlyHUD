//
//  PresentViewController.swift
//  Example iOS
//
//  Created by Liam on 2024/1/25.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit
import FlyHUD

class PresentViewController: UIViewController {
    private let containerView = UIView()
    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Present VC"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Hide All", style: .plain, target: self, action: #selector(hideAllHUDClicked)),
            UIBarButtonItem(title: "Hide Top", style: .plain, target: self, action: #selector(hideTopHUDClicked)),
            UIBarButtonItem(title: "Show", style: .plain, target: self, action: #selector(showHUDClicked))
        ]
        setupUI()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupUI() {
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        textField.placeholder = "Tap here to show keyboard"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)

        let hintLabel = UILabel()
        hintLabel.text = "👆 Tap screen to dismiss keyboard"
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 300),
            containerView.heightAnchor.constraint(equalToConstant: 300),

            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 36),

            hintLabel.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 8),
            hintLabel.leadingAnchor.constraint(equalTo: textField.leadingAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func showHUDClicked() {
        // HUDs on parent view at different positions
        HUD.showStatus(to: view,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideDownUp, damping: .default),
                       mode: .custom(UIImageView(image: UIImage(named: "warning")).h.then { $0.isAccessibilityElement = false }),
                       label: "You have an unfinished task.",
                       offset: .h.vMinOffset) {
            $0.contentView.indicatorPosition = .leading
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .bottom()
            #endif
        }
        HUD.show(to: view,
                 using: .animation(.zoomInOut, damping: .default),
                 label: "Loading") {
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .center()
            #endif
        }
        HUD.showStatus(to: view,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideUpDown, damping: .default),
                       mode: .text,
                       label: "Wrong password",
                       offset: .h.vMaxOffset) {
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .bottom()
            #endif
        }

        // HUDs on container view
        HUD.showStatus(to: containerView,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideDownUp, damping: .default),
                       mode: .custom(UIImageView(image: UIImage(named: "warning")).h.then { $0.isAccessibilityElement = false }),
                       label: "You have a message.",
                       offset: CGPoint(x: .h.maxOffset, y: -.h.maxOffset)) {
            $0.contentView.indicatorPosition = .trailing
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .bottom()
            #endif
        }
        HUD.show(to: containerView,
                 using: .animation(.zoomOutIn, damping: .default),
                 label: "Loading") {
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .center()
            #endif
            $0.layout.offset.x = .h.maxOffset
        }
        HUD.showStatus(to: containerView,
                       duration: .greatestFiniteMagnitude,
                       using: .animation(.slideUpDown, damping: .default),
                       mode: .text,
                       label: "Wrong password",
                       offset: CGPoint(x: .h.maxOffset, y: .h.maxOffset)) {
            $0.isEventDeliveryEnabled = true
            #if os(iOS)
            $0.keyboardGuide = .bottom()
            #endif
        }
    }

    @objc private func hideTopHUDClicked() {
        HUD.hide(for: view)
        HUD.hide(for: containerView)
    }

    @objc private func hideAllHUDClicked() {
        HUD.hideAll(for: view)
        HUD.hideAll(for: containerView)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc private func tapToDismissKeyboard() {
        view.endEditing(true)
    }
}
