// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "KeyGeneratorCC",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KeyGeneratorCC", targets: ["KeyGeneratorCC"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1")
    ],
    targets: [
        .executableTarget(
            name: "KeyGeneratorCC",
            dependencies: [
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "KeyGeneratorCCTests",
            dependencies: ["KeyGeneratorCC"]
        )
    ]
)
