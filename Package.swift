// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FCKOnboarding",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FCKOnboarding",
            targets: ["FCKOnboarding"]),
    ],
    targets: [
        .target(
            name: "FCKOnboarding",
            dependencies: []),
        .testTarget(
            name: "FCKOnboardingTests",
            dependencies: ["FCKOnboarding"]),
    ]
)
