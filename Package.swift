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
            name: "HUDIndicatorView",
            targets: ["HUDIndicatorView"]
        ),
        .library(
            name: "HUDProgressView",
            targets: ["HUDProgressView"]
        ),
    ],
    targets: [
        .target(
            name: "HUD"
        ),
        .target(
            name: "HUDIndicatorView",
            dependencies: ["HUD"]
        ),
        .target(
            name: "HUDProgressView",
            dependencies: ["HUD"]
        ),
    ]
)
