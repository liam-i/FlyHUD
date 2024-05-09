// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlyHUD",
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
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
            exclude: ["PrivacyInfo.xcprivacy"]
        ),
        .target(
            name: "FlyIndicatorHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/IndicatorHUD",
            exclude: ["PrivacyInfo.xcprivacy"]
        ),
        .target(
            name: "FlyProgressHUD",
            dependencies: ["FlyHUD"],
            path: "Sources/ProgressHUD",
            exclude: ["PrivacyInfo.xcprivacy"]
        ),
    ]
)
