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

    @IBOutlet weak var defaultModeStyleSwitch: UISwitch!
    @IBAction func defaultModeStyleSwitchClicked(_ sender: UISwitch) {
        config.isDefaultModeStyle = sender.isOn
    }
    @IBOutlet weak var eventDeliverySwitch: UISwitch!
    @IBAction func eventDeliverySwitchClicked(_ sender: UISwitch) {
        config.isEventDeliveryEnabled = sender.isOn
    }
    @IBOutlet weak var showLabelSwitch: UISwitch!
    @IBAction func showLabelSwitchClicked(_ sender: UISwitch) {
        config.isLabelEnabled = sender.isOn
    }
    @IBOutlet weak var showDetailsLabelSwitch: UISwitch!
    @IBAction func showDetailsLabelSwitchClicked(_ sender: UISwitch) {
        config.isDetailsLabelEnabled = sender.isOn
    }
    @IBOutlet weak var showButtonSwitch: UISwitch!
    @IBAction func showButtonSwitchClicked(_ sender: UISwitch) {
        config.isButtonEnabled = sender.isOn
    }
    @IBOutlet weak var offsetVTextFiled: UITextField!
    @IBAction func offsetVTextFiledClicked(_ sender: UITextField) {
        config.layout.offset.y = sender.textOfFloat
    }
    @IBOutlet weak var insetHTextFiled: UITextField!
    @IBAction func insetHTextFiledClicked(_ sender: UITextField) {
        config.layout.edgeInsets.left = sender.textOfFloat
        config.layout.edgeInsets.right = config.layout.edgeInsets.left
    }
    @IBOutlet weak var insetVTextFiled: UITextField!
    @IBAction func insetVTextFiledClicked(_ sender: UITextField) {
        config.layout.edgeInsets.top = sender.textOfFloat
        config.layout.edgeInsets.bottom = config.layout.edgeInsets.top
    }
    @IBOutlet weak var hMargin: UITextField!
    @IBAction func hMarginClicked(_ sender: UITextField) {
        config.layout.hMargin = sender.textOfFloat
    }
    @IBOutlet weak var vMargin: UITextField!
    @IBAction func vMarginClicked(_ sender: UITextField) {
        config.layout.vMargin = sender.textOfFloat
    }
    @IBOutlet weak var spacing: UITextField!
    @IBAction func spacingClicked(_ sender: UITextField) {
        config.layout.spacing = sender.textOfFloat
    }
    @IBOutlet weak var minWidth: UITextField!
    @IBAction func minWidth(_ sender: UITextField) {
        config.layout.minSize.width = sender.textOfFloat
    }
    @IBOutlet weak var minHeight: UITextField!
    @IBAction func minHeightClicked(_ sender: UITextField) {
        config.layout.minSize.height = sender.textOfFloat
    }
    @IBOutlet weak var square: UISwitch!
    @IBAction func squareClicked(_ sender: UISwitch) {
        config.layout.isSquare = sender.isOn
    }
    @IBAction func contentColorClicked(_ sender: UISegmentedControl) {
        config.updateContentColor(sender.selectedSegmentIndex)
    }
    @IBAction func animationStyle1Clicked(_ sender: UISegmentedControl) {
        config.animationStyle(sender.selectedSegmentIndex)
    }
    @IBAction func animationStyle2Clicked(_ sender: UISegmentedControl) {
        config.animationStyle(sender.selectedSegmentIndex + 5)
    }
    @IBOutlet weak var animationDamping: UISwitch!
    @IBAction func animationDampingClicked(_ sender: UISwitch) {
        config.animation.damping = sender.isOn ? .default : .disable
    }
    @IBOutlet weak var animationDuration: UITextField!
    @IBAction func animationDurationClicked(_ sender: UITextField) {
        config.animation.duration = sender.textOfFloat
    }
    @IBAction func forceAnimationStyle1Clicked(_ sender: UISegmentedControl) {
        config.forceAnimationStyle(sender.selectedSegmentIndex)
    }
    @IBAction func forceAnimationStyle2Clicked(_ sender: UISegmentedControl) {
        config.forceAnimationStyle(sender.selectedSegmentIndex + 6)
    }
    @IBOutlet weak var forceAnimationDamping: UISwitch!
    @IBAction func forceAnimationDampingClicked(_ sender: UISwitch) {
        config.forceAnimationDamping(sender.isOn)
    }
    @IBOutlet weak var forceAnimationDuration: UITextField!
    @IBAction func forceAnimationDurationClicked(_ sender: UITextField) {
        config.forceAnimationDuration(sender.textOfFloat)
    }
    @IBOutlet weak var graceTime: UITextField!
    @IBAction func graceTimeClicked(_ sender: UITextField) {
        config.graceTime = sender.textOfFloat
    }
    @IBOutlet weak var minShowTime: UITextField!
    @IBAction func minShowTime(_ sender: UITextField) {
        config.minShowTime = sender.textOfFloat
    }
    @IBOutlet weak var isCountEnabled: UISwitch!
    @IBAction func isCountEnabledClicked(_ sender: UISwitch) {
        config.isCountEnabled = sender.isOn
    }
    @IBOutlet weak var isMotionEffectsEnabled: UISwitch!
    @IBAction func isMotionEffectsEnabledClicked(_ sender: UISwitch) {
        config.isMotionEffectsEnabled = sender.isOn
    }
    @IBOutlet weak var hideAfterDelay: UITextField!
    @IBAction func hideAfterDelayClicked(_ sender: UITextField) {
        config.hideAfterDelay = sender.textOfFloat
    }

    private func initControls() {
        defaultModeStyleSwitch.isOn = config.isDefaultModeStyle
        eventDeliverySwitch.isOn = config.isEventDeliveryEnabled
        showLabelSwitch.isOn = config.isLabelEnabled
        showDetailsLabelSwitch.isOn = config.isDetailsLabelEnabled
        showButtonSwitch.isOn = config.isButtonEnabled
        offsetVTextFiled.text = String(Int(config.layout.offset.y))
        insetHTextFiled.text = String(Int(config.layout.edgeInsets.left))
        insetVTextFiled.text = String(Int(config.layout.edgeInsets.bottom))
        hMargin.text = String(Int(config.layout.hMargin))
        vMargin.text = String(Int(config.layout.vMargin))
        spacing.text = String(Int(config.layout.spacing))
        minWidth.text = String(Int(config.layout.minSize.width))
        minHeight.text = String(Int(config.layout.minSize.height))
        square.isOn = config.layout.isSquare
        animationDamping.isOn = config.animation.damping == .default
        animationDuration.text = String(Int(config.animation.duration))
        if let forceAnimation = config.forceAnimation {
            forceAnimationDamping.isOn = forceAnimation.damping == .default
            forceAnimationDuration.text = String(Int(forceAnimation.duration))
        }
        graceTime.text = String(Int(config.graceTime))
        minShowTime.text = String(Int(config.minShowTime))
        isCountEnabled.isOn = config.isCountEnabled
        isMotionEffectsEnabled.isOn = config.isMotionEffectsEnabled
        hideAfterDelay.text = String(Int(config.hideAfterDelay))
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
