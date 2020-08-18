// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RIBTools",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "RIBDebugHost",
            targets: ["RIBDebugHost"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", .branch("master")),
        .package(url: "https://github.com/apple/swift-nio-transport-services.git", .branch("master")),
        .package(url: "https://github.com/uber/RIBs.git", .branch("master")),
        .package(url: "https://github.com/RxSwiftCommunity/RxOptional", .branch("master")),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .branch("master")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "RIBDebugHost",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .byName(name: "RIBs"),
                .byName(name: "RxOptional"),
                .byName(name: "RxSwift"),
            ],
            path: "./Sources/RIBDebugHost"),
        .testTarget(
            name: "RIBDebugHostTests",
            dependencies: ["RIBDebugHost"]),
    ]
)
