// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FZMetadata",
    platforms: [.macOS(.v10_15), .iOS(.v14), .macCatalyst(.v14), .tvOS(.v14), .watchOS(.v7)],
    products: [
        .library(
            name: "FZMetadata",
            targets: ["FZMetadata"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/flocked/FZSwiftUtils.git", branch: "main"),
    ],
    targets: [
        .target(name: "_MDQueryInterposer", path: "Sources/FZMetadata+ObjC/MDQueryInterposer"),
        .target(
            name: "FZMetadata",
            dependencies: ["FZSwiftUtils", .target(name: "_MDQueryInterposer", condition: .when(platforms: [.macOS]))]
        ),
    ]
)
