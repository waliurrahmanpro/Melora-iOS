// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeloraUI",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MeloraUI",
            targets: ["MeloraUI"]
        )
    ],
    dependencies: [
        .package(path: "../MeloraCore"),
        .package(path: "../MeloraData"),
        .package(path: "../MeloraAudio")
    ],
    targets: [
        .target(
            name: "MeloraUI",
            dependencies: [
                "MeloraCore",
                "MeloraData",
                "MeloraAudio"
            ],
            path: "Sources/MeloraUI"
        ),
        .testTarget(
            name: "MeloraUITests",
            dependencies: [
                "MeloraUI",
                "MeloraCore",
                "MeloraData",
                "MeloraAudio"
            ],
            path: "Tests/MeloraUITests"
        )
    ]
)
