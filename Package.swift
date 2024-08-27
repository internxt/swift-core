// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InternxtSwiftCore",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "InternxtSwiftCore",
            targets: ["InternxtSwiftCore"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/iosdevzone/IDZSwiftCommonCrypto.git", .upToNextMajor(from: "0.13.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "InternxtSwiftCore",
            dependencies: [
                .product(name: "IDZSwiftCommonCrypto", package: "IDZSwiftCommonCrypto")
            ]),
        .testTarget(
            name: "InternxtSwiftCoreTests",
            dependencies: ["InternxtSwiftCore"]),
    ]
)
