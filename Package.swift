// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaithQuestCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        // FaithQuestCore: Platform-independent core library
        // Contains the fundamental models and logic for the Unified Grand Loop
        .library(
            name: "FaithQuestCore",
            targets: ["FaithQuestCore"]),
    ],
    dependencies: [
        // Property-based testing library (QuickCheck-style for Swift)
        .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        // Core library target - platform-independent models and logic
        .target(
            name: "FaithQuestCore",
            dependencies: [],
            path: "Sources/FaithQuestCore"
        ),
        // Test target for the core library
        .testTarget(
            name: "FaithQuestCoreTests",
            dependencies: [
                "FaithQuestCore",
                .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "Tests/FaithQuestCoreTests"
        ),
    ]
)
