//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

class ViewController: UITableViewController, HUDDelegate {
    private var v: UIView { navigationController?.view ?? view }

    @IBAction func indicatorButtonClicked(_ sender: UIButton) {
        switch sender.superview?.viewWithTag(1000) {
        case let pv as ProgressView:
            config.showHUD(to: v, mode: .progress(pv.style)).with(config.request(_:))
        case let pa as ActivityIndicatorView:
            config.showHUD(to: v, mode: .indicator(pa.style)).with(config.request(_:))
        case is UIProgressView:
            config.showHUD(to: v, mode: .progress()).with(config.request(_:))
        case is UIActivityIndicatorView:
            config.showHUD(to: v, mode: .indicator()).with(config.request(_:))
        default:
            print(String(describing: sender.superview))
        }
    }

    @IBAction func statusButtonClicked(_ sender: UIButton) {
        config.showStatusHUD(to: v, onlyText: false)
    }

    @IBAction func toastButtonClicked(_ sender: UIButton) {
        config.showStatusHUD(to: v, onlyText: true)
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        initIndicators()
        initControls()
    }

    private func initIndicators() {
        var (progressViews, idx) = ([ProgressView](), 0)
        progressStackView.arrangedSubviews.forEach {
            ($0 as? UIStackView)?.arrangedSubviews.forEach {
                ($0.viewWithTag(1000) as? ProgressView)?.with({
                    $0.style = ProgressView.Style.allCases[idx]
                    progressViews.append($0)
                    idx += 1
                })
            }
        }
        idx = 0
        indicatorStackView.arrangedSubviews.forEach {
            ($0 as? UIStackView)?.arrangedSubviews.forEach {
                ($0.viewWithTag(1000) as? ActivityIndicatorView)?.with({
                    $0.style = ActivityIndicatorView.Style.allCases[idx]
                    $0.startAnimating()
                    idx += 1
                })
            }
        }
        var systemProgressView: UIProgressView?
        systemIndicatorStackView.arrangedSubviews.forEach {
            switch $0.viewWithTag(1000) {
            case let view as UIProgressView:          systemProgressView = view
            case let view as UIActivityIndicatorView: view.startAnimating()
            default: break
            }
        }
        func updateProgress() {
            Task.request { progress in
                progressViews.forEach {
                    $0.progress = progress
                }
                systemProgressView?.progress = progress
            } completion: {
                Task.request(1) { updateProgress() }
            }
        }
        updateProgress()
    }

    @objc func cancelTask() {
        print("cancel task.")
        Task.cancelTask()
        config.hide(for: v)
    }

    func hudWasHidden(_ hud: HUD) {
        print("hudWasHidden -> HUD was hidden.")
    }

    lazy var config: Configuration = .init(delegate: self) { _ in
        print("completionBlock -> HUD was hidden.")
    }

    // MARK: -

    @IBOutlet weak var progressStackView: UIStackView!
    @IBOutlet weak var indicatorStackView: UIStackView!
    @IBOutlet weak var systemIndicatorStackView: UIStackView!

    @IBAction func propertiesButtonClicked(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return assertionFailure() }
        let text = String(title[title.startIndex...title.index(title.startIndex, offsetBy: 4)])

        func setTitle<T>(_ value: T) {
            let mas = NSMutableAttributedString()
            if let range = title.range(of: " ") {
                mas.append(NSAttributedString(string: "\(title[title.startIndex..<range.lowerBound]) "))
            } else {
                mas.append(NSAttributedString(string: "\(title) "))
            }
            mas.append(NSAttributedString(string: "(\(value))", 
                                          attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemRed]))
            sender.setAttributedTitle(mas, for: .normal)
        }
        switch text {
        case "Defau":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isDefaultModeStyle = isOn
            }
        case "Event":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isDefaultModeStyle = isOn
            }
        case "Label":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isLabelEnabled = isOn
            }
        case "Detai":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isDetailsLabelEnabled = isOn
            }
        case "Butto":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isButtonEnabled = isOn
            }
        case "conte":
            let list = ["default", "systemRed", "systemYellow", "systemOrange", "systemPurple"]
            alertListPicker(title, list: list, selected1: setTitle(_:)) { value in
                switch value {
                case "systemRed":    self.config.contentColor = .systemRed
                case "systemYellow": self.config.contentColor = .systemYellow
                case "systemOrange": self.config.contentColor = .systemOrange
                case "systemPurple": self.config.contentColor = .systemPurple
                default:             self.config.contentColor = .contentOfHUD
                }
            }
        case "offset":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.offset.y = value
            }
        case "hInse":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.edgeInsets.left = value
                self.config.layout.edgeInsets.right = value
            }
        case "vInse":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.edgeInsets.top = value
                self.config.layout.edgeInsets.bottom = value
            }
        case "hMarg":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.hMargin = value
            }
        case "vMarg":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.vMargin = value
            }
        case "spaci":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.spacing = value
            }
        case "minWi":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.minSize.width = value
            }
        case "minHe":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.layout.minSize.height = value
            }
        case "isSqu":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.layout.isSquare = isOn
            }
        case "style":
            let list = ["none", "fade", "zoomInOut", "zoomOutIn", "zoomIn", "zoomOut", "slideUpDown", "slideDownUp", "slideUp", "slideDown"]
            alertListPicker(title, list: list, selected1: setTitle(_:)) { value in
                switch value {
                case "none": self.config.animation.style = .none
                case "fade": self.config.animation.style = .fade
                case "zoomInOut": self.config.animation.style = .zoomInOut
                case "zoomOutIn": self.config.animation.style = .zoomOutIn
                case "zoomIn": self.config.animation.style = .zoomIn
                case "zoomOut": self.config.animation.style = .zoomOut
                case "slideUpDown": self.config.animation.style = .slideUpDown
                case "slideDownUp": self.config.animation.style = .slideDownUp
                case "slideUp": self.config.animation.style = .slideUp
                case "slideDown": self.config.animation.style = .slideDown
                default: print(value)
                }
            }
        case "dampi":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.animation.damping = isOn ? .default : .disable
            }
        case "durat":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.animation.duration = value
            }
        case "isFor":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isForceAnimationEnabled =  isOn
            }
        case "fStyl":
            let list = ["none", "fade", "zoomInOut", "zoomOutIn", "zoomIn", "zoomOut", "slideUpDown", "slideDownUp", "slideUp", "slideDown"]
            alertListPicker(title, list: list, selected1: setTitle(_:)) { value in
                switch value {
                case "none": self.config.forceAnimation.style = .none
                case "fade": self.config.forceAnimation.style = .fade
                case "zoomInOut": self.config.forceAnimation.style = .zoomInOut
                case "zoomOutIn": self.config.forceAnimation.style = .zoomOutIn
                case "zoomIn": self.config.forceAnimation.style = .zoomIn
                case "zoomOut": self.config.forceAnimation.style = .zoomOut
                case "slideUpDown": self.config.forceAnimation.style = .slideUpDown
                case "slideDownUp": self.config.forceAnimation.style = .slideDownUp
                case "slideUp": self.config.forceAnimation.style = .slideUp
                case "slideDown": self.config.forceAnimation.style = .slideDown
                default: print(value)
                }
            }
        case "fDamp":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.forceAnimation.damping = isOn ? .default : .disable
            }
        case "fDura":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.forceAnimation.duration = value
            }
        case "grace":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.graceTime = value
            }
        case "minSh":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.minShowTime = value
            }
        case "Count":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isCountEnabled = isOn
            }
        case "Motio":
            alertSwitch(title, selected1: setTitle(_:)) { isOn in
                self.config.isMotionEffectsEnabled = isOn
            }
        case "hideA":
            alertTextField(title, selected1: setTitle(_:)) { value in
                self.config.hideAfterDelay = value
            }
        default:
            print(text)
        }
    }

    private func initControls() {
//        defaultModeStyleSwitch.isOn = config.isDefaultModeStyle
//        eventDeliverySwitch.isOn = config.isEventDeliveryEnabled
//        showLabelSwitch.isOn = config.isLabelEnabled
//        showDetailsLabelSwitch.isOn = config.isDetailsLabelEnabled
//        showButtonSwitch.isOn = config.isButtonEnabled
//        offsetVTextFiled.text = String(Int(config.layout.offset.y))
//        insetHTextFiled.text = String(Int(config.layout.edgeInsets.left))
//        insetVTextFiled.text = String(Int(config.layout.edgeInsets.bottom))
//        hMargin.text = String(Int(config.layout.hMargin))
//        vMargin.text = String(Int(config.layout.vMargin))
//        spacing.text = String(Int(config.layout.spacing))
//        minWidth.text = String(Int(config.layout.minSize.width))
//        minHeight.text = String(Int(config.layout.minSize.height))
//        square.isOn = config.layout.isSquare
//        animationDamping.isOn = config.animation.damping == .default
//        animationDuration.text = String(Int(config.animation.duration))
//        if let forceAnimation = config.forceAnimation {
//            forceAnimationDamping.isOn = forceAnimation.damping == .default
//            forceAnimationDuration.text = String(Int(forceAnimation.duration))
//        }
//        graceTime.text = String(Int(config.graceTime))
//        minShowTime.text = String(Int(config.minShowTime))
//        isCountEnabled.isOn = config.isCountEnabled
//        isMotionEffectsEnabled.isOn = config.isMotionEffectsEnabled
//        hideAfterDelay.text = String(Int(config.hideAfterDelay))
    }
}

extension UITextField {
    var textOfFloat: CGFloat {
        var value: CGFloat = 0.0
        if let text = text, let f = Float(text) {
            value = CGFloat(f)
        }
        print("UITextField.text -> CGFloat = \(value)")
        return value
    }
}

extension ViewController {
    private func alertSwitch(_ title: String, selected1: @escaping(_ isOn: Bool) -> Void, selected2: @escaping(_ isOn: Bool) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with {
            $0.addAction(UIAlertAction(title: "off", style: .destructive, handler: { _ in
                selected1(false); selected2(false)
            }))
            $0.addAction(UIAlertAction(title: "on", style: .default, handler: { _ in
                selected1(true); selected2(true)
            }))
            present($0, animated: true)
        }
    }
    private func alertTextField(_ title: String, selected1: @escaping(_ value: CGFloat) -> Void, selected2: @escaping(_ value: CGFloat) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with { alert in
            alert.addTextField { textField in
                textField.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { _ in
                let value = alert.textFields?.first?.textOfFloat ?? 0.0
                selected1(value); selected2(value)
            }))
            present(alert, animated: true)
        }
    }
    private func alertListPicker(_ title: String, list: [String], selected1: @escaping(_ value: String) -> Void, selected2: @escaping(_ value: String) -> Void) {
        UIAlertController(title: title, message: nil, preferredStyle: .alert).with { alert in
            list.forEach {
                alert.addAction(UIAlertAction(title: $0, style: .default, handler: {
                    selected1($0.title!); selected2($0.title!)
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
}
