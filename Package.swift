// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenStates",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ScreenStates",
            targets: ["ScreenStates"]
        )
    ],
    targets: [
        .target(
            name: "ScreenStates",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ScreenStatesTests",
            dependencies: ["ScreenStates"]
        )
    ]
)
