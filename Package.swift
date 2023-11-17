// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "CorePersistence",
    platforms: [
        .iOS(.v14),
        .macOS(.v12),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CorePersistence",
            targets: [
                "CorePersistence",
                "Proquint",
                "UUIDv6"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax", from: "509.0.0"),
        .package(url: "https://github.com/vmanot/Expansions.git", branch: "main"),
        .package(url: "https://github.com/vmanot/Merge.git", branch: "master"),
        .package(url: "https://github.com/vmanot/Swallow.git", branch: "master")
    ],
    targets: [
        .macro(
            name: "CorePersistenceMacros",
            dependencies: [
                "Expansions",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Sources/CorePersistenceMacros"
        ),
        .target(
            name: "CorePersistence",
            dependencies: [
                "CorePersistenceMacros",
                "Expansions",
                "Merge",
                "Proquint",
                "Swallow"
            ]
        ),
        .target(
            name: "Proquint",
            dependencies: [
                "Swallow"
            ]
        ),
        .target(
            name: "UUIDv6",
            dependencies: [
                "CorePersistence"
            ]
        ),
        .target(
            name: "_XMLCoder",
            dependencies: [
                "CorePersistence",
                "Swallow"
            ],
            path: "Sources/_XMLCoder",
            swiftSettings: []
        ),
        .testTarget(
            name: "CorePersistenceTests",
            dependencies: [
                "CorePersistence"
            ]
        ),
    ]
)
