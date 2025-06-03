// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "progress-tests",
    platforms: [.macOS("15"), .iOS("18"), .tvOS("18"), .watchOS("11")],
    products: [
        .executable(name: "progress-tests", targets: ["progress-tests"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/chloe-yeo/swift-foundation.git",
            branch: "implementation/progress-reporter"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "progress-tests",
            dependencies: [
                .product(name: "FoundationEssentials", package: "swift-foundation")
            ]
        )
    ]
)
