//
//  Cells.swift
//  Example iOS
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit

// MARK: - IndicatorStripCell

/// Horizontal strip of indicator views. Tappable to trigger HUD demo.
final class IndicatorStripCell: UITableViewCell {
    static let reuseID = "IndicatorStripCell"

    let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 1
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .secondarySystemBackground
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    /// Add an indicator view as a tappable element in the strip.
    func addIndicator(_ indicator: UIView, size: CGSize? = nil, action: @escaping () -> Void) {
        let wrapper = TappableView(action: action)
        wrapper.backgroundColor = .systemBackground
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        wrapper.addSubview(indicator)

        var constraints = [
            indicator.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
            wrapper.widthAnchor.constraint(greaterThanOrEqualToConstant: 72)
        ]
        if let size {
            constraints += [
                indicator.widthAnchor.constraint(equalToConstant: size.width),
                indicator.heightAnchor.constraint(equalToConstant: size.height)
            ]
        }
        NSLayoutConstraint.activate(constraints)
        stackView.addArrangedSubview(wrapper)
    }
}

// MARK: - TappableView

final class TappableView: UIView {
    private var action: (() -> Void)?

    convenience init(action: @escaping () -> Void) {
        self.init(frame: .zero)
        self.action = action
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }

    @objc private func tapped() { action?() }
}

// MARK: - DemoActionCell

/// Simple disclosure-style cell for demo actions.
final class DemoActionCell: UITableViewCell {
    static let reuseID = "DemoActionCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        textLabel?.font = .preferredFont(forTextStyle: .body)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String) {
        textLabel?.text = title
    }
}

// MARK: - ConfigCell

/// Displays a configuration key-value pair.
final class ConfigCell: UITableViewCell {
    static let reuseID = "ConfigCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .body)
        l.adjustsFontForContentSizeCategory = true
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .callout)
        l.adjustsFontForContentSizeCategory = true
        l.textColor = .systemRed
        l.textAlignment = .right
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value
    }
}
