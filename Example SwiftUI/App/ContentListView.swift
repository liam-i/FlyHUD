//
//  ContentListView.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI

// MARK: - Main Navigation

struct ContentListView: View {
    var body: some View {
        List {
            Section("SwiftUI Modifiers") {
                NavigationLink(".hud(isPresented:)") {
                    HUDIsPresentedView()
                }
                NavigationLink(".hud(item:)") {
                    HUDItemView()
                }
                NavigationLink(".hudStatus()") {
                    HUDStatusModifierView()
                }
                NavigationLink(".hudLoading()") {
                    HUDLoadingView()
                }
                NavigationLink(".hudToast()") {
                    HUDToastView()
                }
                NavigationLink(".hudProgress()") {
                    HUDProgressModifierView()
                }
                NavigationLink(".hudGlass() (iOS 26+)") {
                    HUDGlassModifierView()
                }
                NavigationLink("HUDHostView (Low-Level)") {
                    HUDHostViewDemoView()
                }
            }

            Section("Basic Usage") {
                NavigationLink("Show / Hide HUD") {
                    BasicHUDView()
                }
                NavigationLink("ShowStatus (Auto-Hide)") {
                    StatusHUDView()
                }
                NavigationLink("Toast (Text Only)") {
                    ToastView()
                }
                NavigationLink("Icon Position (Leading / Trailing)") {
                    IconPositionView()
                }
            }

            Section("Modes") {
                NavigationLink("Indicator Mode") {
                    IndicatorModeView()
                }
                NavigationLink("Progress Mode") {
                    ProgressModeView()
                }
                NavigationLink("Custom View Mode") {
                    CustomModeView()
                }
            }

            Section("IndicatorHUD Styles") {
                NavigationLink("ActivityIndicatorView Styles") {
                    ActivityIndicatorStylesView()
                }
            }

            Section("ProgressHUD Styles") {
                NavigationLink("ProgressView Styles") {
                    ProgressStylesView()
                }
            }

            Section("Configuration") {
                NavigationLink("Layout & Positioning") {
                    LayoutConfigView()
                }
                NavigationLink("Animation Styles") {
                    AnimationConfigView()
                }
                NavigationLink("Appearance") {
                    AppearanceConfigView()
                }
                NavigationLink("Timing & Behavior") {
                    TimingConfigView()
                }
            }

            Section("Liquid Glass (iOS 26+)") {
                NavigationLink("Glass Effects & HUD") {
                    LiquidGlassView()
                }
            }

            Section("Advanced") {
                NavigationLink("GraceTime (Skip Fast Tasks)") {
                    GraceTimeView()
                }
                NavigationLink("MinShowTime (Minimum Display)") {
                    MinShowTimeView()
                }
                NavigationLink("Download Progress") {
                    URLSessionDownloadView()
                }
                NavigationLink("Multiple HUDs (Count)") {
                    MultipleHUDsView()
                }
                NavigationLink("Mode Switching") {
                    ModeSwitchingView()
                }
                NavigationLink("Observed Progress") {
                    ObservedProgressView()
                }
                #if os(iOS)
                NavigationLink("Keyboard Guide") {
                    KeyboardGuideView()
                }
                #endif
                NavigationLink("Dynamic Type") {
                    DynamicTypeView()
                }
                NavigationLink("Delegate & Completion") {
                    DelegateCompletionView()
                }
                NavigationLink("VoiceOver Accessibility") {
                    AccessibilityView()
                }
            }
        }
        .navigationTitle("FlyHUD SwiftUI")
    }
}
