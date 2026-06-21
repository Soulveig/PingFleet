// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "PingFleet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PingFleet", targets: ["PingFleet"])
    ],
    targets: [
        .executableTarget(name: "PingFleet")
    ]
)
