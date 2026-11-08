// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeloraAudio",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MeloraAudio",
            targets: ["MeloraAudio"]
        )
    ],
    dependencies: [
        .package(path: "../MeloraCore"),
        .package(path: "../MeloraData")
    ],
    targets: [
        .target(
            name: "MeloraAudio",
            dependencies: [
                "MeloraCore",
                "MeloraData"
            ],
            path: "Sources/MeloraAudio"
        ),
        .testTarget(
            name: "MeloraAudioTests",
            dependencies: [
                "MeloraAudio",
                "MeloraCore",
                "MeloraData"
            ],
            path: "Tests/MeloraAudioTests"
        )
    ]
)
