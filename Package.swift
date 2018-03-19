// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftBncsLib",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "SwiftBncsClient",
            targets: ["SwiftBncsClient"]),
        .executable(
            name: "SwiftBnls",
            targets: ["SwiftBnls"]),
        .library(
            name: "SwiftBncsNIO",
            targets: ["SwiftBncsNIO"]),
        .library(
            name: "SwiftBncsLib",
            targets: ["SwiftBncsLib"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "0.8.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftBncsLib",
            dependencies: ["CryptoSwift"]),
        .target(name: "SwiftBncsNIO",
            dependencies: ["SwiftBncsLib", "NIO"]),
        .target(
            name: "SwiftBncsClient",
            dependencies: ["SwiftBncsLib", "SwiftBncsNIO", "NIO"]),
        .target(
            name: "SwiftBnls",
            dependencies: ["SwiftBncsLib", "SwiftBncsNIO", "NIO"]),
        .testTarget(
            name: "SwiftBncsLibTests",
            dependencies: ["SwiftBncsLib"]),
    ]
)
