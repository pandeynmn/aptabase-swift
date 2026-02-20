// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AptabaseNomad",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AptabaseNomad",
            targets: ["Aptabase"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Aptabase",
            resources: [
                .copy("PrivacyInfo.xcprivacy"),
            ],
        ),
        .testTarget(
            name: "AptabaseTests",
            dependencies: ["Aptabase"],
        ),
    ],
)
