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
            ]
        ),
        .testTarget(
            name: "BIRGECoreTests",
            dependencies: ["BIRGECore"]
        ),
    ]
)
