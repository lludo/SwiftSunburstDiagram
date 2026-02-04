// swift-tools-version:6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SunburstDiagram",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
    ],
    products: [
        .library(
            name: "SunburstDiagram",
            targets: ["SunburstDiagram"]),
    ],
    targets: [
        .target(
            name: "SunburstDiagram",
            dependencies: []),
        .testTarget(
            name: "SunburstDiagramTests",
            dependencies: ["SunburstDiagram"]),
    ]
)
