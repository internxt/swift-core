// swift-tools-version: 5.7.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InternxtSwiftCore",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
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
        // Official BLAKE3 C implementation (BLAKE3-team), minimal portable build.
        // Only the portable backend is vendored, so every SIMD backend must be
        // disabled explicitly — on AArch64 NEON is autodetected and would reference
        // blake3_neon.c, which we do not ship.
        .target(
            name: "CBlake3",
            cSettings: [
                .define("BLAKE3_NO_AVX512"),
                .define("BLAKE3_NO_AVX2"),
                .define("BLAKE3_NO_SSE41"),
                .define("BLAKE3_NO_SSE2"),
                .define("BLAKE3_USE_NEON", to: "0"),
            ]),
        .target(
            name: "InternxtSwiftCore",
            dependencies: [
                "CBlake3",
                .product(name: "IDZSwiftCommonCrypto", package: "IDZSwiftCommonCrypto")
            ]),
        .testTarget(
            name: "InternxtSwiftCoreTests",
            dependencies: ["InternxtSwiftCore"]),
    ]
)
