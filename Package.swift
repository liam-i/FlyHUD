// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LPProgressHUD",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(name: "HUD", targets: ["HUD"]),
    ],
    targets: [
        .target(name: "HUD", path: "HUD/Sources"),
    ],
    swiftLanguageVersions: [.v5]
)
