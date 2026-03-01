// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Arabica",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Arabica",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "ArabicaTests",
            dependencies: ["Arabica"],
            path: "Tests"
        )
    ]
)
