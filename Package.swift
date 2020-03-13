// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LPProgressHUD",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(name: "LPProgressHUD", targets: ["LPProgressHUD"]),
    ],
    targets: [
        .target(name: "LPProgressHUD", path: "LPProgressHUD/Source"),
    ],
    swiftLanguageVersions: [.v5]
)