// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MeloraData",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MeloraData",
            targets: ["MeloraData"]
        )
    ],
    dependencies: [
        .package(path: "../MeloraCore")
    ],
    targets: [
        .target(
            name: "MeloraData",
            dependencies: [
                "MeloraCore"
            ],
            path: "Sources/MeloraData"
        ),
        .testTarget(
            name: "MeloraDataTests",
            dependencies: [
                "MeloraData",
                "MeloraCore"
            ],
            path: "Tests/MeloraDataTests"
        )
    ]
)
