//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

class RotateImageView: UIImageView, RotateViewable {
    static var loading: RotateImageView { .init(image: UIImage(named: "loading")) }
}

class ViewController: UITableViewController, HUDDelegate {
    private var v: UIView { /*navigationController?.view ??*/ view }

    @IBAction func indicatorButtonClicked(_ sender: UIButton) {
        switch sender.superview?.viewWithTag(1000) {
        case let pv as ProgressView:          showHUD(.progress(pv.style)).with(request(_:))
        case let av as ActivityIndicatorView: showHUD(.indicator(av.style)).with(request(_:))
        case is UIProgressView:               showHUD(.progress()).with(request(_:))
        case is UIActivityIndicatorView:      showHUD(.indicator()).with(request(_:))
        case is RotateImageView:              showHUD(.custom(RotateImageView.loading)).with(request(_:))
        default: assertionFailure()
        }
    }

    @IBAction func statusButtonClicked(_ sender: UIButton) {
        let onlyText = sender.title(for: .normal) == "Toast"
        let iv = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
        let mode: HUD.Mode = onlyText ? .text : .custom(iv)
        showHUD(mode, label: mode.description).with {
            if config.isDefaultModeStyle {
                $0.hide(afterDelay: config.hideAfterDelay)
            } else {
                $0.hide(using: config.currAnimation, afterDelay: config.hideAfterDelay)
            }
        }
    }

    @IBAction func multipleHUDsButtonClicked(_ sender: UIButton) {
    }

    private func showHUD(_ mode: HUD.Mode, label: String? = nil) -> HUD {
        let hud: HUD
        if config.isDefaultModeStyle {
            hud = HUD.show(to: v, mode: mode, label: label) // Default Mode Style
        } else {
            hud = customHUD(mode, label: label) // Custom Mode Style
        }
        if config.isEventDeliveryEnabled && config.isDefaultModeStyle == false {
            hud.detailsLabel.text = "Events are delivered normally to the HUD's parent view"
            hud.detailsLabel.textColor = .systemRed
        }
        hud.delegate = self
        hud.completionBlock = completionBlock
        return hud
    }

    private func customHUD(_ mode: HUD.Mode, label: String?) -> HUD {
        HUD.show(to: v, using: config.currAnimation, mode: mode) { [self] in
            $0.label.text = label ?? (config.isLabelEnabled ? mode.description : nil)
            $0.detailsLabel.text = config.isDetailsLabelEnabled ? "This is the detail label" : nil
            $0.button.setTitle(config.isButtonEnabled ? "Cancel" : nil, for: .normal)
            if config.isButtonEnabled {
                $0.button.addTarget(self, action: #selector(cancelTask), for: .primaryActionTriggered)
            }
            $0.layout = config.layout
            $0.contentColor = config.contentColor.color
            $0.bezelView.style = config.bezelViewStyle
            $0.bezelView.color = config.bezelViewColor == .default ? .HUDBackground : config.bezelViewColor.color
            $0.backgroundView.style = config.backgroundViewStyle
            $0.backgroundView.color = config.backgroundViewColor == .default ? .clear : config.backgroundViewColor.color
            $0.animation = config.animation
            $0.graceTime = config.graceTime
            $0.minShowTime = config.minShowTime
            $0.isCountEnabled = config.isCountEnabled
            $0.isEventDeliveryEnabled = config.isEventDeliveryEnabled
            $0.isMotionEffectsEnabled = config.isMotionEffectsEnabled
        }
    }

    func request(_ hud: HUD) {
        Task.request(config.takeTime) { progress in
            if hud.mode.isProgressView {
                hud.progress = progress
            }
        } completion: { [self] in
            if config.isDefaultModeStyle {
                hud.hide() // Default
            } else {
                hud.hide(using: config.currAnimation)
            }
        }
    }

    // MARK: -

    @objc func cancelTask() {
        print("cancel task.")
        Task.cancelTask()
        HUD.hide(for: v, using: config.currAnimation)
    }

    func hudWasHidden(_ hud: HUD) {
        print("hudWasHidden -> HUD was hidden.")
    }
    var completionBlock: ((_ hud: HUD) -> Void)? = { _ in
        print("completionBlock -> HUD was hidden.")
    }

    var config: Configuration = .init()

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
            case let view as RotateImageView:         view.startRotation()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        initIndicators()
        initControls()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 30.0 }

    // MARK: -

    @IBOutlet weak var progressStackView: UIStackView!
    @IBOutlet weak var indicatorStackView: UIStackView!
    @IBOutlet weak var systemIndicatorStackView: UIStackView!
    @IBOutlet weak var textField: UITextField!

    @IBAction func showKeyboardButtonClicked(_ sender: UIButton) {
        if sender.tag == 2000 {
            sender.tag = 1000
            textField.resignFirstResponder()
        } else {
            sender.tag = 2000
            textField.becomeFirstResponder()
        }
    }

    @IBOutlet weak var darkMode: UISegmentedControl!
    @IBAction func darkModeClicked(_ sender: UISegmentedControl) {
        guard #available(iOS 13.0, *) else {
            return print("'DarkMode' is only available in iOS 13.0 or newer")
        }
        UIApplication.getKeyWindow?.overrideUserInterfaceStyle = sender.selectedSegmentIndex == 0 ? .dark : .light
    }

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
            var newValue = String(describing: value)
            if let isOn = value as? Bool {
                newValue = isOn.isOn
            }
            mas.append(NSAttributedString(string: "(\(newValue))", attributes: [.foregroundColor: UIColor.systemRed]))
            sender.setAttributedTitle(mas, for: .normal)
        }
        switch text {
        case "UseDe": Alert.switch(title, selected: setTitle(_:)) { self.config.isDefaultModeStyle = $0; self.updateForIsDefaultStyleEnabled() }
        case "Event": Alert.switch(title, selected: setTitle(_:)) { self.config.isEventDeliveryEnabled = $0 }
        case "Label": Alert.switch(title, selected: setTitle(_:)) { self.config.isLabelEnabled = $0 }
        case "Detai": Alert.switch(title, selected: setTitle(_:)) { self.config.isDetailsLabelEnabled = $0 }
        case "Butto": Alert.switch(title, selected: setTitle(_:)) { self.config.isButtonEnabled = $0 }
        case "tintC": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.contentColor = $0 }
        case "taskT": Alert.textField(title, selected: setTitle(_:)) { self.config.takeTime = UInt32($0) }
        case "beBlu": Alert.switch(title, selected: setTitle(_:)) { self.config.bezelViewStyle = $0 ? .blur() : .solidColor }
        case "beCol": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.bezelViewColor = $0 }
        case "bgBlu": Alert.switch(title, selected: setTitle(_:)) { self.config.backgroundViewStyle = $0 ? .blur() : .solidColor }
        case "bgCol": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.backgroundViewColor = $0 }
        case "offse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.offset.y = $0 }
        case "hInse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.left = $0; self.config.layout.edgeInsets.right = $0 }
        case "vInse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.top = $0; self.config.layout.edgeInsets.bottom = $0 }
        case "hMarg": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.hMargin = $0 }
        case "vMarg": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.vMargin = $0 }
        case "spaci": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.spacing = $0 }
        case "minWi": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.minSize.width = $0 }
        case "minHe": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.minSize.height = $0 }
        case "squar": Alert.switch(title, selected: setTitle(_:)) { self.config.layout.isSquare = $0 }
        case "safeL": Alert.switch(title, selected: setTitle(_:)) { self.config.layout.isSafeAreaLayoutGuideEnabled = $0 }
        case "style": Alert.list(title, list: HUD.Animation.Style.allCases, selected: setTitle(_:)) { self.config.animation.style = $0 }
        case "dampi": Alert.switch(title, selected: setTitle(_:)) { self.config.animation.damping = $0 ? .default : .disable }
        case "durat": Alert.textField(title, selected: setTitle(_:)) { self.config.animation.duration = $0 }
        case "isFor": Alert.switch(title, selected: setTitle(_:)) { self.config.isForceAnimationEnabled =  $0; self.updateForIsForceAnimationEnabled() }
        case "fStyl": Alert.list(title, list: HUD.Animation.Style.allCases, selected: setTitle(_:)) { self.config.forceAnimation.style = $0 }
        case "fDamp": Alert.switch(title, selected: setTitle(_:)) { self.config.forceAnimation.damping = $0 ? .default : .disable }
        case "fDura": Alert.textField(title, selected: setTitle(_:)) { self.config.forceAnimation.duration = $0 }
        case "grace": Alert.textField(title, selected: setTitle(_:)) { self.config.graceTime = $0 }
        case "minSh": Alert.textField(title, selected: setTitle(_:)) { self.config.minShowTime = $0 }
        case "Count": Alert.switch(title, selected: setTitle(_:)) { self.config.isCountEnabled = $0 }
        case "Motio": Alert.switch(title, selected: setTitle(_:)) { self.config.isMotionEffectsEnabled = $0 }
        case "hideA": Alert.textField(title, selected: setTitle(_:)) { self.config.hideAfterDelay = $0 }
        default: print("‼️‼️‼️\(text)")
        }
    }

    @IBOutlet var propertiesButton: [UIButton]!
    private func initControls() {
        propertiesButton.forEach { sender in
            guard let title = sender.title(for: .normal) else { return assertionFailure() }
            let text = String(title[title.startIndex...title.index(title.startIndex, offsetBy: 4)])
            func setTitle<T>(_ value: T) {
                let mas = NSMutableAttributedString()
                if let range = title.range(of: " ") {
                    mas.append(NSAttributedString(string: "\(title[title.startIndex..<range.lowerBound]) "))
                } else {
                    mas.append(NSAttributedString(string: "\(title) "))
                }
                var newValue = String(describing: value)
                if let isOn = value as? Bool {
                    newValue = isOn.isOn
                }
                mas.append(NSAttributedString(string: "(\(newValue))", attributes: [.foregroundColor: UIColor.systemRed]))
                sender.setAttributedTitle(mas, for: .normal)
            }
            switch text {
            case "UseDe": setTitle(config.isDefaultModeStyle); updateForIsDefaultStyleEnabled()
            case "Event": setTitle(config.isEventDeliveryEnabled)
            case "Label": setTitle(config.isLabelEnabled)
            case "Detai": setTitle(config.isDetailsLabelEnabled)
            case "Butto": setTitle(config.isButtonEnabled)
            case "tintC": setTitle(config.contentColor.rawValue)
            case "taskT": setTitle(config.takeTime)
            case "beBlu": setTitle(config.bezelViewStyle == .blur())
            case "beCol": setTitle(config.bezelViewColor.rawValue)
            case "bgBlu": setTitle(config.backgroundViewStyle == .blur())
            case "bgCol": setTitle(config.backgroundViewColor.rawValue)
            case "offse": setTitle(config.layout.offset.y)
            case "hInse": setTitle(config.layout.edgeInsets.left)
            case "vInse": setTitle(config.layout.edgeInsets.top)
            case "hMarg": setTitle(config.layout.hMargin)
            case "vMarg": setTitle(config.layout.vMargin)
            case "spaci": setTitle(config.layout.spacing)
            case "minWi": setTitle(config.layout.minSize.width)
            case "minHe": setTitle(config.layout.minSize.height)
            case "squar": setTitle(config.layout.isSquare)
            case "safeL": setTitle(config.layout.isSafeAreaLayoutGuideEnabled)
            case "style": setTitle(config.animation.style)
            case "dampi": setTitle(config.animation.damping == .default)
            case "durat": setTitle(config.animation.duration)
            case "isFor": setTitle(config.isForceAnimationEnabled); updateForIsForceAnimationEnabled()
            case "fStyl": setTitle(config.forceAnimation.style)
            case "fDamp": setTitle(config.forceAnimation.damping == .default)
            case "fDura": setTitle(config.forceAnimation.duration)
            case "grace": setTitle(config.graceTime)
            case "minSh": setTitle(config.minShowTime)
            case "Count": setTitle(config.isCountEnabled)
            case "Motio": setTitle(config.isMotionEffectsEnabled)
            case "hideA": setTitle(config.hideAfterDelay)
            default: print("‼️‼️‼️\(text)")
            }
        }
    }

    private func updateForIsDefaultStyleEnabled() {
        propertiesButton.forEach { sender in
            guard let title = sender.title(for: .normal) else { return assertionFailure() }
            let text = String(title[title.startIndex...title.index(title.startIndex, offsetBy: 4)])
            guard text != "UseDe" else { return }
            sender.isHidden = config.isDefaultModeStyle
            updateForIsForceAnimationEnabled(text, sender: sender)
        }
    }

    private func updateForIsForceAnimationEnabled() {
        propertiesButton.forEach { sender in
            guard let title = sender.title(for: .normal) else { return assertionFailure() }
            let text = String(title[title.startIndex...title.index(title.startIndex, offsetBy: 4)])
            updateForIsForceAnimationEnabled(text, sender: sender)
        }
    }

    private func updateForIsForceAnimationEnabled(_ text: String, sender: UIButton) {
        guard text == "fStyl" || text == "fDamp" || text == "fDura" else { return }
        sender.isHidden = config.isForceAnimationEnabled == false
    }
}
