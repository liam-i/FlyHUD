//
//  ViewController.swift
//  Example iOS
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import FlyHUD
import FlyIndicatorHUD
import FlyProgressHUD

// MARK: - RotateImageView

class RotateImageView: UIImageView, RotateViewable {
    static var loading: RotateImageView { .init(named: "loading") }
}

// MARK: - ViewController (View Layer)

final class ViewController: UITableViewController, HUDDelegate {

    private let viewModel = DemoViewModel()

    // MARK: - Indicator Views (retained for progress animation)

    private var progressViews: [ProgressView] = []
    private var systemProgressView: UIProgressView?

    // MARK: - Cached Indicator Cells (never reused)

    private var progressBarCell: IndicatorStripCell?
    private var progressCircleCell: IndicatorStripCell?
    private var activityCell: IndicatorStripCell?
    private var systemCell: IndicatorStripCell?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FlyHUD"
        #if os(iOS)
        tableView.keyboardDismissMode = .onDrag
        #endif
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        registerCells()
        bindViewModel()
        setupNavigationItems()
        setupToolbar()
        startIndicatorProgress()
    }

    private func registerCells() {
        tableView.register(DemoActionCell.self, forCellReuseIdentifier: DemoActionCell.reuseID)
    }

    private func bindViewModel() {
        viewModel.onConfigChanged = { [weak self] in
            guard let self else { return }
            HUD.huds(for: self.targetView).forEach {
                DemoViewModel.applyConfig(self.viewModel.config, to: $0, label: nil)
            }
        }
    }

    private var targetView: UIView {
        switch viewModel.config.showTo {
        case .view:    return view
        case .navView: return navigationController?.view ?? view
        case .window:  return view.window ?? view
        }
    }

    // MARK: - DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        4 // progressIndicators, activityIndicators, systemIndicators, demos
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch DemoSection(rawValue: section)! {
        case .progressIndicators:  return 2
        case .activityIndicators:  return 1
        case .systemIndicators:    return 1
        case .demos:               return DemoAction.allCases.count
        default:                   return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        DemoSection(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 32 }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { .leastNonzeroMagnitude }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch DemoSection(rawValue: indexPath.section)! {
        case .progressIndicators, .activityIndicators: return 72
        case .systemIndicators: return 64
        default: return UITableView.automaticDimension
        }
    }

    // MARK: - CellForRow

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch DemoSection(rawValue: indexPath.section)! {
        case .progressIndicators:  return progressCell(for: indexPath)
        case .activityIndicators:  return activityCell(for: indexPath)
        case .systemIndicators:    return systemCell(for: indexPath)
        case .demos:               return demoCell(for: indexPath)
        default:                   return UITableViewCell()
        }
    }

    // MARK: - Selection

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if DemoSection(rawValue: indexPath.section) == .demos {
            handleDemoAction(DemoAction.allCases[indexPath.row])
        }
    }

    // MARK: - Indicator Cells

    private func progressCell(for indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if let cached = progressBarCell { return cached }
        } else {
            if let cached = progressCircleCell { return cached }
        }

        let cell = IndicatorStripCell(style: .default, reuseIdentifier: nil)

        let barStyles: [ProgressView.Style] = [.buttBar, .roundBar]
        let circularStyles: [ProgressView.Style] = [.round, .annularRound, .pie]
        let styles = indexPath.row == 0 ? barStyles : circularStyles

        let views: [ProgressView] = styles.map { style in
            let pv = ProgressView()
            pv.style = style
            pv.isLabelEnabled = (style == .round || style == .annularRound)
            return pv
        }
        progressViews.append(contentsOf: views)

        views.forEach { pv in
            let size = pv.style.defaultSize == .zero ? CGSize(width: 44, height: 44) : pv.style.defaultSize
            let style = pv.style as! ProgressView.Style
            cell.addIndicator(pv, size: size) { [weak self] in
                let newPV = ProgressView(style: style)
                newPV.isLabelEnabled = (style == .round || style == .annularRound)
                self?.showIndicatorHUD(mode: .custom(newPV))
            }
        }

        if indexPath.row == 0 { progressBarCell = cell } else { progressCircleCell = cell }
        return cell
    }

    private func activityCell(for indexPath: IndexPath) -> UITableViewCell {
        if let cached = activityCell { return cached }

        let cell = IndicatorStripCell(style: .default, reuseIdentifier: nil)

        ActivityIndicatorView.Style.allCases.forEach { style in
            let av = ActivityIndicatorView()
            av.style = style
            av.startAnimating()
            cell.addIndicator(av, size: CGSize(width: 44, height: 44)) { [weak self] in
                self?.showIndicatorHUD(mode: .custom(ActivityIndicatorView(style: style).h.then { $0.startAnimating() }))
            }
        }

        activityCell = cell
        return cell
    }

    private func systemCell(for indexPath: IndexPath) -> UITableViewCell {
        if let cached = systemCell { return cached }

        let cell = IndicatorStripCell(style: .default, reuseIdentifier: nil)

        // UIActivityIndicatorView
        let sysAI = UIActivityIndicatorView(style: .large)
        sysAI.color = .secondaryLabel
        sysAI.startAnimating()
        cell.addIndicator(sysAI) { [weak self] in
            self?.showIndicatorHUD(mode: .indicator())
        }

        // UIProgressView
        let sysPV = UIProgressView(progressViewStyle: .default)
        sysPV.progressTintColor = .secondaryLabel
        sysPV.trackTintColor = .systemFill
        sysPV.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([sysPV.widthAnchor.constraint(equalToConstant: 80)])
        systemProgressView = sysPV
        cell.addIndicator(sysPV) { [weak self] in
            self?.showIndicatorHUD(mode: .progress())
        }

        // RotateImageView
        let rotView = RotateImageView(named: "loading")
        rotView.image = rotView.image?.withRenderingMode(.alwaysTemplate)
        rotView.tintColor = .secondaryLabel
        rotView.startRotating()
        cell.addIndicator(rotView, size: CGSize(width: 37, height: 37)) { [weak self] in
            self?.showIndicatorHUD(mode: .custom(RotateImageView.loading))
        }

        systemCell = cell
        return cell
    }

    private func showIndicatorHUD(mode: ContentView.Mode) {
        let hud = viewModel.showHUD(on: targetView, mode: mode)
        hud.delegate = self
        hud.completionBlock = completionBlock
        if viewModel.config.isButtonEnabled {
            hud.contentView.button.addTarget(self, action: #selector(cancelTask), for: .touchUpInside)
        }
        viewModel.simulateTask(for: hud, on: targetView)
    }

    // MARK: - Demo Cells

    private func demoCell(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DemoActionCell.reuseID, for: indexPath) as! DemoActionCell
        cell.configure(title: DemoAction.allCases[indexPath.row].rawValue)
        return cell
    }

    private func handleDemoAction(_ action: DemoAction) {
        switch action {
        case .statusCustom:
            let hud = viewModel.showStatus(on: targetView, onlyText: false)
            hud.delegate = self
        case .toast:
            let hud = viewModel.showStatus(on: targetView, onlyText: true)
            hud.delegate = self
        case .showStatus:
            viewModel.showStatusDemo(on: targetView)
        case .multipleHUDs:
            viewModel.showMultipleHUDs(on: targetView)
        case .modeSwitching:
            viewModel.showModeSwitching(on: targetView)
        case .urlSession:
            viewModel.showURLSession(on: targetView)
        case .observedProgress:
            viewModel.showObservedProgress(on: targetView)
        case .dynamicType:
            viewModel.showDynamicType(on: targetView)
        case .liquidGlass:
            showLiquidGlassDemo()
        case .presentVC:
            let vc = PresentViewController()
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        case .ocPresentVC:
            let vc = OCPresentViewController()
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
    }

    // MARK: - Liquid Glass Demo

    private func showLiquidGlassDemo() {
        #if compiler(>=6.2) && !os(visionOS)
        if #available(iOS 26.0, *) {
            let vc = LiquidGlassViewController()
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
            return
        }
        #endif
        // Fallback for pre-iOS 26: just show a hint HUD
        let hud = HUD.show(to: targetView, mode: .text, label: "Requires iOS 26+")
        hud.hide(afterDelay: 2.0)
    }

    // MARK: - Navigation Bar Items

    private func setupNavigationItems() {
        let gearItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showConfigSheet)
        )
        let darkModeItem = UIBarButtonItem(
            image: UIImage(systemName: "moon.circle"),
            style: .plain,
            target: self,
            action: #selector(toggleDarkMode)
        )
        let keyboardItem = UIBarButtonItem(
            image: UIImage(systemName: "keyboard"),
            style: .plain,
            target: self,
            action: #selector(toggleKeyboard)
        )
        navigationItem.rightBarButtonItems = [gearItem, keyboardItem, darkModeItem]
    }

    @objc private func showConfigSheet() {
        let configVC = ConfigViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: configVC)
        #if os(iOS)
        if #available(iOS 15.0, *), let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        #endif
        present(nav, animated: true)
    }

    @objc private func toggleDarkMode() {
        guard let window = UIApplication.getKeyWindow else { return }
        let isDark = window.overrideUserInterfaceStyle == .dark
        window.overrideUserInterfaceStyle = isDark ? .light : .dark
        navigationItem.rightBarButtonItems?[2].image = UIImage(systemName: isDark ? "moon.circle" : "sun.max.circle")
    }

    // MARK: - Toolbar

    private func setupToolbar() {
        navigationController?.isToolbarHidden = false

        #if compiler(>=6.2) && !os(visionOS)
        if #available(iOS 26.0, *) {
            let showButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Show HUD") { [weak self] _ in
                self?.showHUDFromToolbar()
            })
            let showItem = UIBarButtonItem(customView: showButton)

            let hideButton = UIButton(configuration: .glass(), primaryAction: UIAction(title: "Hide") { [weak self] _ in
                self?.hideHUDFromToolbar()
            })
            let hideItem = UIBarButtonItem(customView: hideButton)

            let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [showItem, flex, hideItem]
        } else {
            setupToolbarLegacy()
        }
        #else
        setupToolbarLegacy()
        #endif
    }

    private func setupToolbarLegacy() {
        let showItem = UIBarButtonItem(
            title: "Show HUD",
            style: .done,
            target: self,
            action: #selector(showHUDFromToolbar)
        )
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let hideItem = UIBarButtonItem(
            title: "Hide",
            style: .plain,
            target: self,
            action: #selector(hideHUDFromToolbar)
        )
        toolbarItems = [showItem, flex, hideItem]
    }

    @objc private func showHUDFromToolbar() {
        let hud = viewModel.showHUD(on: targetView, mode: .indicator())
        hud.delegate = self
        hud.completionBlock = completionBlock
        if viewModel.config.isButtonEnabled {
            hud.contentView.button.addTarget(self, action: #selector(cancelTask), for: .touchUpInside)
        }
        viewModel.simulateTask(for: hud, on: targetView)
    }

    @objc private func hideHUDFromToolbar() {
        HUD.hide(for: targetView, using: viewModel.config.currAnimation)
    }

    // MARK: - Tool Actions

    private lazy var hiddenTextField: UITextField = {
        let tf = UITextField(frame: .zero)
        view.addSubview(tf)
        return tf
    }()

    @objc private func toggleKeyboard() {
        if hiddenTextField.isFirstResponder {
            hiddenTextField.resignFirstResponder()
        } else {
            hiddenTextField.becomeFirstResponder()
        }
    }

    // MARK: - Progress Animation

    private func startIndicatorProgress() {
        func loop() {
            Task.request { [weak self] progress in
                self?.progressViews.forEach { $0.progress = progress }
                self?.systemProgressView?.progress = progress
            } completion: { [weak self] in
                guard self != nil else { return }
                Task.request(1) { loop() }
            }
        }
        loop()
    }

    // MARK: - HUDDelegate

    func hudWasHidden(_ hud: HUD) {
        print("hudWasHidden -> HUD was hidden.")
    }

    var completionBlock: ((_ hud: HUD) -> Void)? = { _ in
        print("completionBlock -> HUD was hidden.")
    }

    @objc private func cancelTask() {
        Task.cancelTask()
        HUD.hide(for: targetView, using: viewModel.config.currAnimation)
    }
}
