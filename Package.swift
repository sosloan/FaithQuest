// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaithQuest",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "FaithQuest",
            targets: ["FaithQuest"]),
    ],
    dependencies: [
        // No external dependencies - pure Apple ecosystem
    ],
    targets: [
        .target(
            name: "FaithQuest",
            dependencies: [],
            path: "FaithQuest"
        ),
        .testTarget(
            name: "FaithQuestTests",
            dependencies: ["FaithQuest"],
            path: "FaithQuestTests"
        ),
    ]
)
