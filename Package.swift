// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KickApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "KickApp",
            path: "KickApp",
            exclude: ["Resources"]
        ),
    ]
)
