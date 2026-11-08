// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MeloraCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MeloraCore",
            targets: ["MeloraCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MeloraCore",
            dependencies: [],
            path: "Sources/MeloraCore"
        ),
        .testTarget(
            name: "MeloraCoreTests",
            dependencies: ["MeloraCore"],
            path: "Tests/MeloraCoreTests"
        )
    ]
)
