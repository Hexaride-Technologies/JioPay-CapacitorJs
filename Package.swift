// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JiopayCapacitorjs",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "JiopayCapacitorjs",
            targets: ["JioPayCapacitorJsPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "JioPayCapacitorJsPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/JioPayCapacitorJsPlugin"),
        .testTarget(
            name: "JioPayCapacitorJsPluginTests",
            dependencies: ["JioPayCapacitorJsPlugin"],
            path: "ios/Tests/JioPayCapacitorJsPluginTests")
    ]
)