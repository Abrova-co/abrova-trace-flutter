// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "abrova_trace_flutter_sdk",
    platforms: [.iOS("12.0")],
    products: [
        .library(name: "abrova-trace-flutter-sdk", targets: ["abrova_trace_flutter_sdk"])
    ],
    dependencies: [
        .package(url: "https://center.abrova.ir/abrova/abrova-trace-ios-sdk.git", from: "0.2.5")
    ],
    targets: [
        .target(
            name: "abrova_trace_flutter_sdk",
            dependencies: [.product(name: "AbrovaTrace", package: "abrova-trace-ios-sdk")]
        )
    ]
)
