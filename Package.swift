// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HUD",
    platforms: [.iOS(.v12), .tvOS(.v12)],
    products: [
        .library(
            name: "HUD",
            targets: ["HUD"]
        ),
        .library(
            name: "HUDIndicator",
            targets: ["HUDIndicator"]
        ),
        .library(
            name: "HUDProgress",
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
