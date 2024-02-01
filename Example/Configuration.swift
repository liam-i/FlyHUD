//
//  Configuration.swift
//  HUD_Example
//
//  Created by liam on 2021/7/9.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import LPHUD

enum ShowTo: CaseIterable {
    case view
    case navView
    case window
}

struct Configuration {
    var showTo: ShowTo = .view
    var isDefaultModeStyle: Bool = true
    var isEventDeliveryEnabled: Bool = false

    var isLabelEnabled: Bool = true
    var isDetailsLabelEnabled: Bool = false
    var isButtonEnabled: Bool = false

//    var mode: ContentView.Mode = .indicator()
    var position: ContentView.Mode.Position = .top
    var layout: HUD.Layout = .init()
    var contentLayout: ContentView.Layout = .init()
    var contentColor: Color = .default
    var contentViewStyle: BackgroundView.Style = .blur()
    var backgroundViewStyle: BackgroundView.Style = .solidColor
    var contentViewColor: Color = .default
    var backgroundViewColor: Color = .default

//    var progress: Float = 0.0
//    var observedProgress: Progress?
    var animation: HUD.Animation = .init()
    var forceAnimation: HUD.Animation = .init()
    var isForceAnimationEnabled: Bool = false
    var currAnimation: HUD.Animation { isForceAnimationEnabled ? forceAnimation : animation }

    var graceTime: TimeInterval = 0.0
    var minShowTime: TimeInterval = 0.0
//    var removeFromSuperViewOnHide: Bool = true
    var isCountEnabled: Bool = false

    var keyboardGuide: HUD.KeyboardGuide?

    var isMotionEffectsEnabled: Bool = false
//    weak var delegate: (ViewController & HUDDelegate)?
//    var completionBlock: ((_ hud: HUD) -> Void)?

    var hideAfterDelay: TimeInterval = 2.0 // status hud.
    var takeTime: UInt32 = 3 // task time.
}

extension ContentView.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .text:                                 return "Wrong password"
        case .indicator:                            return "UIActivityIndicatorView"
        case .progress:                             return "UIProgressView"
        case .custom(let view):
            switch view {
            case let view as ProgressView:          return "\(view.style)"
            case let view as ActivityIndicatorView: return "\(view.style)"
            default:                                return "Done"
            }
        }
    }

    var isProgressView: Bool {
        switch self {
        case .progress:         return true
        case .custom(let view): return view is ProgressViewable
        default:                return false
        }
    }
}

extension HUD.KeyboardGuide {
    public static var allCases: [String] { ["disable", "center", "bottom", "default"] }

    public init?(_ name: String) {
        switch name {
        case "disable": self = .disable
        case "center": self = .center()
        case "bottom": self = .bottom()
        default: return nil
        }
    }
}
