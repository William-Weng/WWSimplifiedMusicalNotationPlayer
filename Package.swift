// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWSimplifiedMusicalNotationPlayer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "WWSimplifiedMusicalNotationPlayer", targets: ["WWSimplifiedMusicalNotationPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWTwelveEqualTemperament", from: "1.0.2")
    ],
    targets: [
        .target(name: "WWSimplifiedMusicalNotationPlayer", dependencies: ["WWTwelveEqualTemperament"]),

    ],swiftLanguageVersions: [
        .v5
    ]
)
