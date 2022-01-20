// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "PbEssentials",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
    products: [
        .library(
            name: "PbEssentials",
            targets: ["PbEssentials"]),
    ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
        // .package(path: /* folder */ )
    ],
    targets: [
        .target(
            name: "PbEssentials",
            dependencies: []),
        .testTarget(
            name: "PbEssentialsTests",
            dependencies: ["PbEssentials"]),
    ]
)
