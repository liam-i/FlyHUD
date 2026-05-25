//
//  ConfigViewController.swift
//  Example iOS
//
//  Created by Liam on 2024/1/23.
//  Copyright (c) 2024 Liam. All rights reserved.
//

import UIKit
import FlyHUD

/// Inspector-style config screen presented as a half-sheet.
final class ConfigViewController: UITableViewController {

    private let viewModel: DemoViewModel

    /// Called whenever a config value changes so the main screen can react.
    var onConfigChanged: (() -> Void)?

    init(viewModel: DemoViewModel) {
        self.viewModel = viewModel
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Configuration"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:))
        )
        tableView.register(ConfigCell.self, forCellReuseIdentifier: ConfigCell.reuseID)
    }

    @objc private func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Sections

    /// Extra "Display" section index (always section 0)
    private let displaySectionIndex = 0

    private enum DisplayRow: Int, CaseIterable {
        case layoutDirection
        case darkMode

        var title: String {
            switch self {
            case .layoutDirection: return "Layout Direction"
            case .darkMode:       return "Dark Mode"
            }
        }
    }

    private var configSections: [DemoSection] {
        DemoSection.allCases.filter { $0.isConfigSection && !viewModel.visibleConfigItems(for: $0).isEmpty }
    }

    private var isRTL: Bool {
        UIView.appearance().semanticContentAttribute == .forceRightToLeft
    }

    // MARK: - DataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        configSections.count + 1  // +1 for Display section
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == displaySectionIndex { return DisplayRow.allCases.count }
        return viewModel.visibleConfigItems(for: configSections[section - 1]).count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == displaySectionIndex { return "🖥️ Display" }
        return configSections[section - 1].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == displaySectionIndex {
            let cell = tableView.dequeueReusableCell(withIdentifier: ConfigCell.reuseID, for: indexPath) as! ConfigCell
            let row = DisplayRow(rawValue: indexPath.row)!
            switch row {
            case .layoutDirection:
                cell.configure(title: row.title, value: isRTL ? "RTL (العربية)" : "LTR")
            case .darkMode:
                let isDark = UIApplication.getKeyWindow?.overrideUserInterfaceStyle == .dark
                cell.configure(title: row.title, value: isDark ? "Dark" : "Light")
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: ConfigCell.reuseID, for: indexPath) as! ConfigCell
        let item = viewModel.visibleConfigItems(for: configSections[indexPath.section - 1])[indexPath.row]
        cell.configure(title: item.rawValue, value: item.currentValue(from: viewModel.config))
        return cell
    }

    // MARK: - Selection

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == displaySectionIndex {
            handleDisplayTap(DisplayRow(rawValue: indexPath.row)!)
            return
        }
        let item = viewModel.visibleConfigItems(for: configSections[indexPath.section - 1])[indexPath.row]
        handleConfigTap(item)
    }

    // MARK: - Display Actions

    private func handleDisplayTap(_ row: DisplayRow) {
        switch row {
        case .layoutDirection:
            let alert = UIAlertController(title: "Layout Direction", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "LTR (Left to Right)", style: isRTL ? .default : .cancel) { [weak self] _ in
                self?.applyLayoutDirection(rtl: false)
            })
            alert.addAction(UIAlertAction(title: "RTL (Right to Left / العربية)", style: isRTL ? .cancel : .default) { [weak self] _ in
                self?.applyLayoutDirection(rtl: true)
            })
            present(alert, animated: true)
        case .darkMode:
            guard let window = UIApplication.getKeyWindow else { return }
            let isDark = window.overrideUserInterfaceStyle == .dark
            window.overrideUserInterfaceStyle = isDark ? .light : .dark
            tableView.reloadRows(at: [IndexPath(row: row.rawValue, section: displaySectionIndex)], with: .none)
        }
    }

    private func applyLayoutDirection(rtl: Bool) {
        let attribute: UISemanticContentAttribute = rtl ? .forceRightToLeft : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = attribute
        UINavigationBar.appearance().semanticContentAttribute = attribute

        // Dismiss this sheet, then rebuild the entire window
        dismiss(animated: true) {
            guard let window = UIApplication.getKeyWindow else { return }

            // Recreate root view controller to fully apply direction
            let vc = ViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.view.semanticContentAttribute = attribute
            window.rootViewController = nav
            window.semanticContentAttribute = attribute
            window.makeKeyAndVisible()
        }
    }

    // MARK: - Editing

    private func handleConfigTap(_ item: ConfigItem) {
        let reload: () -> Void = { [weak self] in
            self?.tableView.reloadData()
            self?.onConfigChanged?()
        }

        switch item.editDescriptor {
        case .toggle:
            showToggleAlert(title: item.rawValue) { [weak self] value in
                guard let self else { return }
                item.applyToggle(value, to: &self.viewModel.config)
                reload()
            }
        case .list(let options):
            showListAlert(title: item.rawValue, options: options) { [weak self] index in
                guard let self else { return }
                item.applyListSelection(index, to: &self.viewModel.config)
                reload()
            }
        case .textField:
            showTextFieldAlert(title: item.rawValue) { [weak self] value in
                guard let self else { return }
                item.applyValue(value, to: &self.viewModel.config)
                reload()
            }
        }
    }

    // MARK: - Alert Helpers

    private func showToggleAlert(title: String, handler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Off", style: .destructive) { _ in handler(false) })
        alert.addAction(UIAlertAction(title: "On", style: .default) { _ in handler(true) })
        present(alert, animated: true)
    }

    private func showListAlert(title: String, options: [String], handler: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        for (idx, option) in options.enumerated() {
            alert.addAction(UIAlertAction(title: option, style: .default) { _ in handler(idx) })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func showTextFieldAlert(title: String, handler: @escaping (CGFloat) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let value = alert.textFields?.first?.floatOfText ?? 0
            handler(value)
        })
        present(alert, animated: true)
    }
}
