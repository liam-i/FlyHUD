//
//  DemoSections.swift
//  Example iOS
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import UIKit
import FlyHUD

// MARK: - Table Section

enum DemoSection: Int, CaseIterable {
    case progressIndicators
    case activityIndicators
    case systemIndicators
    case demos
    case configGeneral
    case configContent
    case configAppearance
    case configLayout
    case configAnimation
    case configTiming
    case configBehavior

    var title: String {
        switch self {
        case .progressIndicators:  return "ProgressView Styles"
        case .activityIndicators:  return "ActivityIndicatorView Styles"
        case .systemIndicators:    return "System Indicators"
        case .demos:               return "Demos"
        case .configGeneral:       return "⚙️ General"
        case .configContent:       return "📝 Content"
        case .configAppearance:    return "🎨 Appearance"
        case .configLayout:        return "📐 Layout"
        case .configAnimation:     return "✨ Animation"
        case .configTiming:        return "⏱️ Timing"
        case .configBehavior:      return "🔧 Behavior"
        }
    }

    var isConfigSection: Bool {
        switch self {
        case .configGeneral, .configContent, .configAppearance,
             .configLayout, .configAnimation, .configTiming, .configBehavior:
            return true
        default:
            return false
        }
    }
}

// MARK: - Demo Action

enum DemoAction: String, CaseIterable {
    case statusCustom     = "Status (Custom Icon)"
    case toast            = "Toast (Text Only)"
    case showStatus       = "ShowStatus (Auto-Hide)"
    case multipleHUDs     = "Multiple HUDs (Count)"
    case modeSwitching    = "Mode Switching"
    case urlSession       = "URLSession Download"
    case observedProgress = "Observed Progress"
    case dynamicType      = "Dynamic Type Labels"
    case liquidGlass      = "Liquid Glass (iOS 26)"
    case presentVC        = "Present VC Demo"
    case ocPresentVC      = "OC Present VC Demo"
}

// MARK: - Config Item

/// Each case represents one configurable HUD property.
/// The raw value is displayed as the row title.
enum ConfigItem: String, CaseIterable {
    // General
    case showTo              = "Show To"
    case useDefaultStyle     = "Use Default Style"
    case eventDelivery       = "Event Delivery"

    // Content
    case labelEnabled        = "Label"
    case detailsLabelEnabled = "Details Label"
    case buttonEnabled       = "Button"
    case position            = "Position"
    case alignment           = "Alignment"
    case tintColor           = "Tint Color"

    // ContentView appearance
    case contentViewBlur     = "Content View Blur"
    case contentViewColor    = "Content View Color"
    case backgroundViewBlur  = "Background Blur"
    case backgroundViewColor = "Background Color"

    // HUD Layout
    case offset              = "Vertical Offset"
    case hInsets             = "Horizontal Insets"
    case vInsets             = "Vertical Insets"
    case safeAreaLayout      = "Safe Area Layout"

    // Content Layout
    case hMargin             = "Horizontal Margin"
    case vMargin             = "Vertical Margin"
    case hSpacing            = "Horizontal Spacing"
    case vSpacing            = "Vertical Spacing"
    case minWidth            = "Min Width"
    case minHeight           = "Min Height"
    case square              = "Square"

    // Animation
    case animStyle           = "Animation Style"
    case animDamping         = "Damping"
    case animDuration        = "Duration"
    case forceAnimEnabled    = "Force Animation"
    case forceAnimStyle      = "Force Anim Style"
    case forceAnimDamping    = "Force Damping"
    case forceAnimDuration   = "Force Duration"

    // Timing
    case graceTime           = "Grace Time"
    case minShowTime         = "Min Show Time"
    case hideAfterDelay      = "Hide After Delay"
    case taskTime            = "Task Time"

    // Behavior
    case countEnabled        = "Count Enabled"
    case removeOnHide        = "Remove On Hide"
    case motionEffects       = "Motion Effects"
    case dynamicType         = "Dynamic Type"
    case roundedCorners      = "Rounded Corners"
    case keyboardGuide       = "Keyboard Guide"

    /// Items only shown when `isDefaultModeStyle` is false (custom mode).
    var isCustomOnly: Bool {
        switch self {
        case .showTo, .useDefaultStyle: return false
        default: return true
        }
    }

    /// Items only shown when force animation is enabled.
    var isForceAnimOnly: Bool {
        switch self {
        case .forceAnimStyle, .forceAnimDamping, .forceAnimDuration: return true
        default: return false
        }
    }

    /// Which config section this item belongs to.
    var section: DemoSection {
        switch self {
        case .showTo, .useDefaultStyle, .eventDelivery:
            return .configGeneral
        case .labelEnabled, .detailsLabelEnabled, .buttonEnabled, .position, .alignment, .tintColor:
            return .configContent
        case .contentViewBlur, .contentViewColor, .backgroundViewBlur, .backgroundViewColor:
            return .configAppearance
        case .offset, .hInsets, .vInsets, .safeAreaLayout, .hMargin, .vMargin, .hSpacing, .vSpacing, .minWidth, .minHeight, .square:
            return .configLayout
        case .animStyle, .animDamping, .animDuration, .forceAnimEnabled, .forceAnimStyle, .forceAnimDamping, .forceAnimDuration:
            return .configAnimation
        case .graceTime, .minShowTime, .hideAfterDelay, .taskTime:
            return .configTiming
        case .countEnabled, .removeOnHide, .motionEffects, .dynamicType, .roundedCorners, .keyboardGuide:
            return .configBehavior
        }
    }

    // MARK: - Value Reading

    func currentValue(from config: Configuration) -> String {
        switch self {
        case .showTo:              return "\(config.showTo)"
        case .useDefaultStyle:     return config.isDefaultModeStyle.isOn
        case .eventDelivery:       return config.isEventDeliveryEnabled.isOn
        case .labelEnabled:        return config.isLabelEnabled.isOn
        case .detailsLabelEnabled: return config.isDetailsLabelEnabled.isOn
        case .buttonEnabled:       return config.isButtonEnabled.isOn
        case .position:            return "\(config.position)"
        case .alignment:           return "\(config.contentLayout.alignment)"
        case .tintColor:           return config.contentColor.rawValue
        case .contentViewBlur:     return (config.contentViewStyle == .blur()).isOn
        case .contentViewColor:    return config.contentViewColor.rawValue
        case .backgroundViewBlur:  return (config.backgroundViewStyle == .blur()).isOn
        case .backgroundViewColor: return config.backgroundViewColor.rawValue
        case .offset:              return "\(config.layout.offset.y)"
        case .hInsets:             return "\(config.layout.edgeInsets.left)"
        case .vInsets:             return "\(config.layout.edgeInsets.top)"
        case .safeAreaLayout:      return config.layout.isSafeAreaLayoutGuideEnabled.isOn
        case .hMargin:             return "\(config.contentLayout.hMargin)"
        case .vMargin:             return "\(config.contentLayout.vMargin)"
        case .hSpacing:            return "\(config.contentLayout.hSpacing)"
        case .vSpacing:            return "\(config.contentLayout.vSpacing)"
        case .minWidth:            return "\(config.contentLayout.minSize.width)"
        case .minHeight:           return "\(config.contentLayout.minSize.height)"
        case .square:              return config.contentLayout.isSquare.isOn
        case .animStyle:           return "\(config.animation.style)"
        case .animDamping:         return (config.animation.damping == .default).isOn
        case .animDuration:        return "\(config.animation.duration)"
        case .forceAnimEnabled:    return config.isForceAnimationEnabled.isOn
        case .forceAnimStyle:      return "\(config.forceAnimation.style)"
        case .forceAnimDamping:    return (config.forceAnimation.damping == .default).isOn
        case .forceAnimDuration:   return "\(config.forceAnimation.duration)"
        case .graceTime:           return "\(config.graceTime)"
        case .minShowTime:         return "\(config.minShowTime)"
        case .hideAfterDelay:      return "\(config.hideAfterDelay)"
        case .taskTime:            return "\(config.takeTime)"
        case .countEnabled:        return config.isCountEnabled.isOn
        case .removeOnHide:        return config.removeFromSuperViewOnHide.isOn
        case .motionEffects:       return config.isMotionEffectsEnabled.isOn
        case .dynamicType:         return config.isDynamicTypeEnabled.isOn
        case .roundedCorners:      return "\(config.roundedCorners)"
        case .keyboardGuide:
            #if os(iOS)
            return config.keyboardGuide?.description ?? "nil"
            #else
            return "N/A"
            #endif
        }
    }

    // MARK: - Value Editing

    /// Describes how this config item should be edited.
    enum EditDescriptor {
        case toggle
        case list([String])
        case textField
    }

    var editDescriptor: EditDescriptor {
        switch self {
        case .showTo:              return .list(ShowTo.allCases.map { "\($0)" })
        case .useDefaultStyle:     return .toggle
        case .eventDelivery:       return .toggle
        case .labelEnabled:        return .toggle
        case .detailsLabelEnabled: return .toggle
        case .buttonEnabled:       return .toggle
        case .position:            return .list(ContentView.IndicatorPosition.allCases.map { "\($0)" })
        case .alignment:           return .list(ContentView.Alignment.allCases.map { "\($0)" })
        case .tintColor:           return .list(Color.allCases.map { $0.rawValue })
        case .contentViewBlur:     return .toggle
        case .contentViewColor:    return .list(Color.allCases.map { $0.rawValue })
        case .backgroundViewBlur:  return .toggle
        case .backgroundViewColor: return .list(Color.allCases.map { $0.rawValue })
        case .offset:              return .textField
        case .hInsets:             return .textField
        case .vInsets:             return .textField
        case .safeAreaLayout:      return .toggle
        case .hMargin:             return .textField
        case .vMargin:             return .textField
        case .hSpacing:            return .textField
        case .vSpacing:            return .textField
        case .minWidth:            return .textField
        case .minHeight:           return .textField
        case .square:              return .toggle
        case .animStyle:           return .list(HUD.Animation.Style.allCases.map { "\($0)" })
        case .animDamping:         return .toggle
        case .animDuration:        return .textField
        case .forceAnimEnabled:    return .toggle
        case .forceAnimStyle:      return .list(HUD.Animation.Style.allCases.map { "\($0)" })
        case .forceAnimDamping:    return .toggle
        case .forceAnimDuration:   return .textField
        case .graceTime:           return .textField
        case .minShowTime:         return .textField
        case .hideAfterDelay:      return .textField
        case .taskTime:            return .textField
        case .countEnabled:        return .toggle
        case .removeOnHide:        return .toggle
        case .motionEffects:       return .toggle
        case .dynamicType:         return .toggle
        case .roundedCorners:      return .textField
        case .keyboardGuide:
            #if os(iOS)
            return .list(HUD.KeyboardGuide.allCases)
            #else
            return .textField
            #endif
        }
    }

    /// Apply a toggle value to the configuration.
    func applyToggle(_ value: Bool, to config: inout Configuration) {
        switch self {
        case .useDefaultStyle:     config.isDefaultModeStyle = value
        case .eventDelivery:       config.isEventDeliveryEnabled = value
        case .labelEnabled:        config.isLabelEnabled = value
        case .detailsLabelEnabled: config.isDetailsLabelEnabled = value
        case .buttonEnabled:       config.isButtonEnabled = value
        case .contentViewBlur:     config.contentViewStyle = value ? .blur() : .solidColor
        case .backgroundViewBlur:  config.backgroundViewStyle = value ? .blur() : .solidColor
        case .safeAreaLayout:      config.layout.isSafeAreaLayoutGuideEnabled = value
        case .square:              config.contentLayout.isSquare = value
        case .animDamping:         config.animation.damping = value ? .default : .disable
        case .forceAnimEnabled:    config.isForceAnimationEnabled = value
        case .forceAnimDamping:    config.forceAnimation.damping = value ? .default : .disable
        case .countEnabled:        config.isCountEnabled = value
        case .removeOnHide:        config.removeFromSuperViewOnHide = value
        case .motionEffects:       config.isMotionEffectsEnabled = value
        case .dynamicType:         config.isDynamicTypeEnabled = value
        default: break
        }
    }

    /// Apply a list selection (by index) to the configuration.
    func applyListSelection(_ index: Int, to config: inout Configuration) {
        switch self {
        case .showTo:              config.showTo = ShowTo.allCases[index]
        case .position:            config.position = ContentView.IndicatorPosition.allCases[index]
        case .alignment:           config.contentLayout.alignment = ContentView.Alignment.allCases[index]
        case .tintColor:           config.contentColor = Color.allCases[index]
        case .contentViewColor:    config.contentViewColor = Color.allCases[index]
        case .backgroundViewColor: config.backgroundViewColor = Color.allCases[index]
        case .animStyle:           config.animation.style = HUD.Animation.Style.allCases[index]
        case .forceAnimStyle:      config.forceAnimation.style = HUD.Animation.Style.allCases[index]
        case .keyboardGuide:
            #if os(iOS)
            config.keyboardGuide = HUD.KeyboardGuide(HUD.KeyboardGuide.allCases[index])
            #endif
        default: break
        }
    }

    /// Apply a numeric value to the configuration.
    func applyValue(_ value: CGFloat, to config: inout Configuration) {
        switch self {
        case .offset:          config.layout.offset.y = value
        case .hInsets:         config.layout.edgeInsets.left = value; config.layout.edgeInsets.right = value
        case .vInsets:         config.layout.edgeInsets.top = value; config.layout.edgeInsets.bottom = value
        case .hMargin:         config.contentLayout.hMargin = value
        case .vMargin:         config.contentLayout.vMargin = value
        case .hSpacing:        config.contentLayout.hSpacing = value
        case .vSpacing:        config.contentLayout.vSpacing = value
        case .minWidth:        config.contentLayout.minSize.width = value
        case .minHeight:       config.contentLayout.minSize.height = value
        case .animDuration:    config.animation.duration = value
        case .forceAnimDuration: config.forceAnimation.duration = value
        case .graceTime:       config.graceTime = value
        case .minShowTime:     config.minShowTime = value
        case .hideAfterDelay:  config.hideAfterDelay = value
        case .taskTime:        config.takeTime = UInt32(value)
        case .roundedCorners:  config.roundedCorners = value
        default: break
        }
    }
}
