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
    private var v: UIView {
        switch config.showTo {
        case .view:     return view
        case .navView:  return navigationController!.view
        case .window:   return view.window!
        }
    }

    @IBAction func indicatorButtonClicked(_ sender: UIButton) {
        switch sender.superview?.viewWithTag(1000) {
        case let pv as ProgressView:          showHUD(.progress(pv.style)).h.then(request(_:))
        case let av as ActivityIndicatorView: showHUD(.indicator(av.style)).h.then(request(_:))
        case is UIProgressView:               showHUD(.progress()).h.then(request(_:))
        case is UIActivityIndicatorView:      showHUD(.indicator()).h.then(request(_:))
        case is RotateImageView:              showHUD(.custom(RotateImageView.loading)).h.then(request(_:))
        default: assertionFailure()
        }
    }

    @IBAction func statusButtonClicked(_ sender: UIButton) {
        let onlyText = sender.title(for: .normal) == "Toast"
        let mode: ContentView.Mode = onlyText ? .text : .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
        showHUD(mode, label: mode.description).h.then {
            if config.isDefaultModeStyle {
                $0.hide(afterDelay: config.hideAfterDelay)
            } else {
                $0.hide(using: config.currAnimation, afterDelay: config.hideAfterDelay)
            }
        }
    }

    @IBAction func multipleHUDsButtonClicked(_ sender: UIButton) {
        var (request, response) = (0, 0)
        let hud = HUD(with: v).h.then {
            $0.isCountEnabled = true
            v.addSubview($0)
        }

        func startRequest() {
            request += 1

            hud.show()
            hud.contentView.label.text = "Count: \(hud.count)"
            hud.contentView.detailsLabel.text = "Request: \(request), Response: \(response)"

            Task.request(.random(in: 1...5)) {
                response += 1

                hud.hide(afterDelay: 1)
                hud.contentView.label.text = "Count: \(hud.count)"
                hud.contentView.detailsLabel.text = "Request: \(request), Response: \(response)"
            }
        }

        startRequest()
        startRequest()
        startRequest()
    }

    @IBAction func hudButtonClicked(_ sender: UIButton) {
        switch sender.tag {
        case 1000: // Mode Switching
            let hud = showHUD(.indicator(), label: "Preparing...")

            Task.requestMultiTask {
                hud.contentView.progress = $0
            } completion: {
                switch $0 {
                case 3:
                    hud.contentView.layout.minSize = CGSize(width: 200.0, height: 100.0)
                    hud.layout.offset = .h.vMinOffset
                    hud.contentView.mode = .progress(.round)
                    hud.contentView.label.text = "Loading..."
                case 2:
                    hud.contentView.layout.minSize = CGSize(width: 150.0, height: 300.0)
                    hud.layout.offset = .h.vMaxOffset
                    hud.contentView.mode = .indicator()
                    hud.contentView.label.text = "Cleaning up..."
                case 1:
                    hud.contentView.layout.minSize = CGSize(width: 180.0, height: 200.0)
                    hud.layout.offset = CGPoint(x: .h.maxOffset, y: .h.maxOffset)
                    hud.contentView.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
                    hud.contentView.label.text = "Completed"
                case 0:
                    hud.hide()
                default:
                    assertionFailure()
                }
            }
        case 1001: // URLSession
            showHUD(.indicator(), label: "Preparing...").h.then { hud in
                hud.contentView.layout.minSize = CGSize(width: 150.0, height: 100.0)
                hud.contentView.mode = .progress(.annularRound)

                Task.download { progress in
                    hud.contentView.progress = progress
                } completion: {
                    hud.contentView.mode = .custom(UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate)))
                    hud.contentView.label.text = "Completed"
                    hud.hide(afterDelay: 3.0)
                }
            }
        default: // Determinate with Progress
            showHUD(.progress(.round)).h.then { hud in
                Task.resume { progress in
                    hud.contentView.observedProgress = progress
                    hud.contentView.button.setTitle("Cancel", for: .normal)
                    hud.contentView.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)

                    // feat #639: https://github.com/jdg/MBProgressHUD/issues/639
                    // label.text and detailLabel.text takes their info from the progressObject.
                    // They can be customized or use the default text.
                    // To suppress one (or both) of the labels, set the descriptions to empty strings.
                    //progress.localizedDescription = ""
                    //progress.localizedAdditionalDescription = ""
                } completion: {
                    hud.hide()
                }
            }
        }
    }

    private func showHUD(_ mode: ContentView.Mode, label: String? = nil) -> HUD {
        let hud: HUD
        if config.isDefaultModeStyle {
            hud = HUD.show(to: v, mode: mode, label: label) // Default Mode Style
        } else {
            hud = customHUD(mode, label: label) // Custom Mode Style
        }
        if config.isEventDeliveryEnabled && config.isDefaultModeStyle == false {
            hud.contentView.detailsLabel.text = "Events are delivered normally to the HUD's parent view"
            hud.contentView.detailsLabel.textColor = .systemRed
        }
        hud.delegate = self
        hud.completionBlock = completionBlock
        return hud
    }

    private func customHUD(_ mode: ContentView.Mode, label: String?) -> HUD {
        if case let .custom(view) = mode, let progressView = view as? ProgressView {
            progressView.isLabelEnabled = progressView.style.isEqual(ProgressView.Style.round) || progressView.style.isEqual(ProgressView.Style.annularRound)
        }
        return HUD.show(to: v, using: config.currAnimation, mode: mode) { [self] in
            $0.contentView.label.text = label ?? (config.isLabelEnabled ? mode.description : nil)
            $0.contentView.detailsLabel.text = config.isDetailsLabelEnabled ? "This is the detail label" : nil
            $0.contentView.button.setTitle(config.isButtonEnabled ? "Cancel" : nil, for: .normal)
            if config.isButtonEnabled {
                $0.contentView.button.addTarget(self, action: #selector(cancelTask), for: .touchUpInside)
            }
            $0.layout = config.layout
            $0.contentView.contentColor = config.contentColor.color
            $0.contentView.style = config.contentViewStyle
            $0.contentView.color = config.contentViewColor == .default ? .h.background : config.contentViewColor.color
            $0.backgroundView.style = config.backgroundViewStyle
            $0.backgroundView.color = config.backgroundViewColor == .default ? .clear : config.backgroundViewColor.color
            $0.animation = config.animation
            $0.graceTime = config.graceTime
            $0.minShowTime = config.minShowTime
            $0.isCountEnabled = config.isCountEnabled
            $0.isEventDeliveryEnabled = config.isEventDeliveryEnabled
            $0.contentView.isMotionEffectsEnabled = config.isMotionEffectsEnabled
            $0.keyboardGuide = config.keyboardGuide
        }
    }

    func request(_ hud: HUD) {
        Task.request(config.takeTime) { progress in
            if hud.contentView.mode.isProgressView {
                hud.contentView.progress = progress
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
                ($0.viewWithTag(1000) as? ProgressView)?.h.then({
                    let style = ProgressView.Style.allCases[idx]
                    $0.style = style
                    $0.isLabelEnabled = style == .round || style == .annularRound
                    progressViews.append($0)
                    idx += 1
                })
            }
        }
        idx = 0
        indicatorStackView.arrangedSubviews.forEach {
            ($0 as? UIStackView)?.arrangedSubviews.forEach {
                ($0.viewWithTag(1000) as? ActivityIndicatorView)?.h.then({
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
            case let view as RotateImageView:         view.startRotating()
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

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 28.0 }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 0.10 }

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
        case "ShowT": Alert.list(title, list: ShowTo.allCases, selected: setTitle(_:)) { self.config.showTo = $0 }
        case "UseDe": Alert.switch(title, selected: setTitle(_:)) { self.config.isDefaultModeStyle = $0; self.updateForIsDefaultStyleEnabled() }
        case "Event": Alert.switch(title, selected: setTitle(_:)) { self.config.isEventDeliveryEnabled = $0 }
        case "Label": Alert.switch(title, selected: setTitle(_:)) { self.config.isLabelEnabled = $0 }
        case "Detai": Alert.switch(title, selected: setTitle(_:)) { self.config.isDetailsLabelEnabled = $0 }
        case "Butto": Alert.switch(title, selected: setTitle(_:)) { self.config.isButtonEnabled = $0 }
        case "tintC": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.contentColor = $0 }
        case "taskT": Alert.textField(title, selected: setTitle(_:)) { self.config.takeTime = UInt32($0) }
        case "beBlu": Alert.switch(title, selected: setTitle(_:)) { self.config.contentViewStyle = $0 ? .blur() : .solidColor }
        case "beCol": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.contentViewColor = $0 }
        case "bgBlu": Alert.switch(title, selected: setTitle(_:)) { self.config.backgroundViewStyle = $0 ? .blur() : .solidColor }
        case "bgCol": Alert.list(title, list: Color.allCases, selected: setTitle(_:)) { self.config.backgroundViewColor = $0 }
        case "offse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.offset.y = $0 }
        case "hInse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.left = $0; self.config.layout.edgeInsets.right = $0 }
        case "vInse": Alert.textField(title, selected: setTitle(_:)) { self.config.layout.edgeInsets.top = $0; self.config.layout.edgeInsets.bottom = $0 }
        case "hMarg": Alert.textField(title, selected: setTitle(_:)) { self.config.contentLayout.hMargin = $0 }
        case "vMarg": Alert.textField(title, selected: setTitle(_:)) { self.config.contentLayout.vMargin = $0 }
        case "spaci": Alert.textField(title, selected: setTitle(_:)) { self.config.contentLayout.spacing = $0 }
        case "minWi": Alert.textField(title, selected: setTitle(_:)) { self.config.contentLayout.minSize.width = $0 }
        case "minHe": Alert.textField(title, selected: setTitle(_:)) { self.config.contentLayout.minSize.height = $0 }
        case "squar": Alert.switch(title, selected: setTitle(_:)) { self.config.contentLayout.isSquare = $0 }
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
        case "Keybo": Alert.list(title, list: HUD.KeyboardGuide.allCases, selected: setTitle(_:)) { self.config.keyboardGuide = HUD.KeyboardGuide($0) }
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
            case "ShowT": setTitle(config.showTo)
            case "UseDe": setTitle(config.isDefaultModeStyle); updateForIsDefaultStyleEnabled()
            case "Event": setTitle(config.isEventDeliveryEnabled)
            case "Label": setTitle(config.isLabelEnabled)
            case "Detai": setTitle(config.isDetailsLabelEnabled)
            case "Butto": setTitle(config.isButtonEnabled)
            case "tintC": setTitle(config.contentColor.rawValue)
            case "taskT": setTitle(config.takeTime)
            case "beBlu": setTitle(config.contentViewStyle == .blur())
            case "beCol": setTitle(config.contentViewColor.rawValue)
            case "bgBlu": setTitle(config.backgroundViewStyle == .blur())
            case "bgCol": setTitle(config.backgroundViewColor.rawValue)
            case "offse": setTitle(config.layout.offset.y)
            case "hInse": setTitle(config.layout.edgeInsets.left)
            case "vInse": setTitle(config.layout.edgeInsets.top)
            case "hMarg": setTitle(config.contentLayout.hMargin)
            case "vMarg": setTitle(config.contentLayout.vMargin)
            case "spaci": setTitle(config.contentLayout.spacing)
            case "minWi": setTitle(config.contentLayout.minSize.width)
            case "minHe": setTitle(config.contentLayout.minSize.height)
            case "squar": setTitle(config.contentLayout.isSquare)
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
            case "Keybo": setTitle(config.keyboardGuide)
            default: print("‼️‼️‼️\(text)")
            }
        }
    }

    private func updateForIsDefaultStyleEnabled() {
        propertiesButton.forEach { sender in
            guard let title = sender.title(for: .normal) else { return assertionFailure() }
            let text = String(title[title.startIndex...title.index(title.startIndex, offsetBy: 4)])
            guard text != "UseDe" && text != "ShowT" else { return }
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

//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        print("view=\(view.safeAreaInsets), \(navigationController!.view.safeAreaInsets)")
//    }
}
