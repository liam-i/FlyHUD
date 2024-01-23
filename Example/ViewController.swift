//
//  ViewController.swift
//  HUD
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import LPHUD

class RotateImageView: UIImageView, RotateViewable {}

class ViewController: UITableViewController, HUDDelegate {
    private var v: UIView { navigationController?.view ?? view }

    @IBAction func indicatorButtonClicked(_ sender: UIButton) {
        switch sender.superview?.viewWithTag(1000) {
        case let pv as ProgressView:
            showHUD(to: v, mode: .progress(pv.style)).with(request(_:))
        case let pa as ActivityIndicatorView:
            showHUD(to: v, mode: .indicator(pa.style)).with(request(_:))
        case is UIProgressView:
            showHUD(to: v, mode: .progress()).with(request(_:))
        case is UIActivityIndicatorView:
            showHUD(to: v, mode: .indicator()).with(request(_:))
        case is RotateImageView:
            showHUD(to: v, mode: .custom(RotateImageView(image: UIImage(named: "loading")))).with(request(_:))
        default:
            print(String(describing: sender.superview))
        }
    }

    @IBAction func statusButtonClicked(_ sender: UIButton) {
        let onlyText = sender.title(for: .normal) == "Toast"
        let iv = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
        let mode: HUD.Mode = onlyText ? .text : .custom(iv)
        showHUD(to: v, mode: mode, label: mode.description).with {
            if config.isDefaultModeStyle {
                $0.hide(afterDelay: config.hideAfterDelay)
            } else {
                $0.hide(using: config.currAnimation, afterDelay: config.hideAfterDelay)
            }
        }
    }

    @IBAction func multipleHUDsButtonClicked(_ sender: UIButton) {

    }

    private func showHUD(to view: UIView, mode: HUD.Mode, label: String? = nil) -> HUD {
        let hud: HUD
        if config.isDefaultModeStyle {
            hud = HUD.show(to: view, mode: mode, label: label) // Default Mode Style
        } else {
            hud = custom(to: view, mode: mode, label: label) // Custom Mode Style
        }
        if config.isEventDeliveryEnabled && config.isDefaultModeStyle == false {
            hud.detailsLabel.text = "Events are delivered normally to the HUD's parent view"
            hud.detailsLabel.textColor = .systemRed
        }
        hud.delegate = self
        hud.completionBlock = completionBlock
        return hud
    }

    private func custom(to view: UIView, mode: HUD.Mode, label: String?) -> HUD {
        HUD.show(to: view, using: config.currAnimation, mode: mode) { [self] in
            $0.label.text = label ?? (config.isLabelEnabled ? mode.description : nil)
            $0.detailsLabel.text = config.isDetailsLabelEnabled ? "This is the detail label" : nil
            $0.button.setTitle(config.isButtonEnabled ? "Cancel" : nil, for: .normal)
            if config.isButtonEnabled {
                $0.button.addTarget(self, action: #selector(cancelTask), for: .primaryActionTriggered)
            }
            $0.layout = config.layout
            $0.contentColor = config.contentColor.color
            $0.contentView.style = config.contentViewStyle
            $0.contentView.color = config.contentViewColor == .default ? .HUDBackground : config.contentViewColor.color
            $0.backgroundView.style = config.backgroundViewStyle
            $0.backgroundView.color = config.backgroundViewColor == .default ? .clear : config.backgroundViewColor.color
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
                newValue = isOn ? "on" : "off"
            }
            mas.append(NSAttributedString(string: "(\(newValue))", attributes: [.foregroundColor: UIColor.systemRed]))
            sender.setAttributedTitle(mas, for: .normal)
        }
        switch text {
        case "UseDe": alertSwitch(title, selected: setTitle(_:)) { self.config.isDefaultModeStyle = $0; self.updateForIsDefaultStyleEnabled() }
        case "Event": alertSwitch(title, selected: setTitle(_:)) { self.config.isEventDeliveryEnabled = $0 }
        case "Label": alertSwitch(title, selected: setTitle(_:)) { self.config.isLabelEnabled = $0 }
        case "Detai": alertSwitch(title, selected: setTitle(_:)) { self.config.isDetailsLabelEnabled = $0 }
        case "Butto": alertSwitch(title, selected: setTitle(_:)) { self.config.isButtonEnabled = $0 }
        case "tintC": alertListPicker(title, list: Color.allCaseValues, selected: setTitle(_:)) { self.config.contentColor = Color.make($0) }
        case "taskT": alertTextField(title, selected: setTitle(_:)) { self.config.takeTime = UInt32($0) }
        case "cBlur": alertSwitch(title, selected: setTitle(_:)) { self.config.contentViewStyle = $0 ? .blur() : .solidColor }
        case "cColo": alertListPicker(title, list: Color.allCaseValues, selected: setTitle(_:)) { self.config.contentViewColor = Color.make($0) }
        case "bgBlu": alertSwitch(title, selected: setTitle(_:)) { self.config.backgroundViewStyle = $0 ? .blur() : .solidColor }
        case "bgCol": alertListPicker(title, list: Color.allCaseValues, selected: setTitle(_:)) { self.config.backgroundViewColor = Color.make($0) }
        case "offse": alertTextField(title, selected: setTitle(_:)) { self.config.layout.offset.y = $0 }
        case "hInse": alertTextField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.left = $0; self.config.layout.edgeInsets.right = $0 }
        case "vInse": alertTextField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.top = $0; self.config.layout.edgeInsets.bottom = $0 }
        case "hMarg": alertTextField(title, selected: setTitle(_:)) { self.config.layout.hMargin = $0 }
        case "vMarg": alertTextField(title, selected: setTitle(_:)) { self.config.layout.vMargin = $0 }
        case "spaci": alertTextField(title, selected: setTitle(_:)) { self.config.layout.spacing = $0 }
        case "minWi": alertTextField(title, selected: setTitle(_:)) { self.config.layout.minSize.width = $0 }
        case "minHe": alertTextField(title, selected: setTitle(_:)) { self.config.layout.minSize.height = $0 }
        case "isSqu": alertSwitch(title, selected: setTitle(_:)) { self.config.layout.isSquare = $0 }
        case "style": alertListPicker(title, list: HUD.Animation.Style.allCaseValues, selected: setTitle(_:)) { self.config.animation.style = .init($0) }
        case "dampi": alertSwitch(title, selected: setTitle(_:)) { self.config.animation.damping = $0 ? .default : .disable }
        case "durat": alertTextField(title, selected: setTitle(_:)) { self.config.animation.duration = $0 }
        case "isFor": alertSwitch(title, selected: setTitle(_:)) { self.config.isForceAnimationEnabled =  $0; self.updateForIsForceAnimationEnabled() }
        case "fStyl": alertListPicker(title, list: HUD.Animation.Style.allCaseValues, selected: setTitle(_:)) { self.config.forceAnimation.style = .init($0) }
        case "fDamp": alertSwitch(title, selected: setTitle(_:)) { self.config.forceAnimation.damping = $0 ? .default : .disable }
        case "fDura": alertTextField(title, selected: setTitle(_:)) { self.config.forceAnimation.duration = $0 }
        case "grace": alertTextField(title, selected: setTitle(_:)) { self.config.graceTime = $0 }
        case "minSh": alertTextField(title, selected: setTitle(_:)) { self.config.minShowTime = $0 }
        case "Count": alertSwitch(title, selected: setTitle(_:)) { self.config.isCountEnabled = $0 }
        case "Motio": alertSwitch(title, selected: setTitle(_:)) { self.config.isMotionEffectsEnabled = $0 }
        case "hideA": alertTextField(title, selected: setTitle(_:)) { self.config.hideAfterDelay = $0 }
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
                    newValue = isOn ? "on" : "off"
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
            case "cBlur": setTitle(config.contentViewStyle == .blur())
            case "cColo": setTitle(config.contentViewColor.rawValue)
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
            case "isSqu": setTitle(config.layout.isSquare)
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
