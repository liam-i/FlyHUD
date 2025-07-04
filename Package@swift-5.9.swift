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
    ],
    targets: [
        .target(
            name: "FlyHUD",
            path: "Sources/HUD",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "FlyIndicatorHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/IndicatorHUD",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "FlyProgressHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/ProgressHUD",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
    ]
)
