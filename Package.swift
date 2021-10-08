// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SLRNetworkMonitor",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SLRNetworkMonitor", targets: ["SLRNetworkMonitor"]
        )
    ],
    targets: [
        .target(
            name: "SLRNetworkMonitor",
            path: ".",
            sources: ["Source"],
            publicHeadersPath: "Source",
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Network"),
                .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
                .linkedLibrary("resolv")
            ]
        ),
        .testTarget(
            name: "SLRNetworkMonitorTests",
            dependencies: ["SLRNetworkMonitor"],
            path: ".",
            sources: ["Tests"]
        )
    ]
)
