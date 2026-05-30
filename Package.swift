// swift-tools-version: 5.9
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
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .target(
            name: "FlyIndicatorHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/IndicatorHUD",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .target(
            name: "FlyProgressHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/ProgressHUD",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
        .target(
            name: "FlyHUDSwiftUI",
            dependencies: ["FlyHUD"],
            path: "Sources/SwiftUIHUD",
            swiftSettings: [.enableUpcomingFeature("StrictConcurrency")]
        ),
    ]
)
