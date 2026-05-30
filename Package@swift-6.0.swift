// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlyHUD",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FlyHUD",
            targets: ["FlyHUD"]
        ),
        .library(
            name: "FlyIndicatorHUD",
            targets: ["FlyIndicatorHUD"]
        ),
        .library(
            name: "FlyProgressHUD",
            targets: ["FlyProgressHUD"]
        ),
        .library(
            name: "FlyHUDSwiftUI",
            targets: ["FlyHUDSwiftUI"]
        ),
    ],
    targets: [
        .target(
            name: "FlyHUD",
            path: "Sources/HUD",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "FlyIndicatorHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/IndicatorHUD",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "FlyProgressHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/ProgressHUD",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .target(
            name: "FlyHUDSwiftUI",
            dependencies: ["FlyHUD"],
            path: "Sources/SwiftUIHUD",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
