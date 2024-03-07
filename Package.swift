// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FlyHUD",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(
            name: "FlyHUD",
            targets: ["HUD"]
        ),
        .library(
            name: "FlyHUDIndicator",
            targets: ["HUDIndicator"]
        ),
        .library(
            name: "FlyHUDProgress",
            targets: ["HUDProgress"]
        ),
    ],
    targets: [
        .target(
            name: "HUD"
        ),
        .target(
            name: "HUDIndicator",
            dependencies: ["HUD"]
        ),
        .target(
            name: "HUDProgress",
            dependencies: ["HUD"]
        ),
    ]
)
