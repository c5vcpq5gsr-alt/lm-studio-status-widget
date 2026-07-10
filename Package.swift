// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LMStudioStatusWidget",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "LMStudioStatusWidget",
            targets: ["LMStudioStatusWidget"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LMStudioStatusWidget",
            path: "Sources/LMStudioStatusWidget"
        )
    ]
)
