// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TimelapseCreator",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "TimelapseCreator",
            targets: ["TimelapseCreator"]
        )
    ],
    dependencies: [
        // Add dependencies here if needed
    ],
    targets: [
        .executableTarget(
            name: "TimelapseCreator",
            dependencies: [],
            path: "TimelapseCreator",
            sources: [
                "App",
                "Views", 
                "Managers",
                "Models"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
) 