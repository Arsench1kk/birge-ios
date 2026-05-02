// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BIRGECore",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "BIRGECore",
            targets: ["BIRGECore"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/groue/GRDB.swift",
            branch: "master"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.25.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-concurrency-extras",
            from: "1.2.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-dependencies",
            from: "1.4.0"
        ),
    ],
    targets: [
        .target(
            name: "BIRGECore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "ConcurrencyExtras",
                    package: "swift-concurrency-extras"
                ),
                .product(
                    name: "Dependencies",
                    package: "swift-dependencies"
                ),
            ]
        ),
        .testTarget(
            name: "BIRGECoreTests",
            dependencies: ["BIRGECore"]
        ),
    ]
)
