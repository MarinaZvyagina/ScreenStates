// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenStates",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ScreenStates",
            targets: ["ScreenStates"]
        )
    ],
    targets: [
        .target(
            name: "ScreenStates"
        ),
        .testTarget(
            name: "ScreenStatesTests",
            dependencies: ["ScreenStates"]
        )
    ]
)
