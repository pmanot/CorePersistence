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
                "_CoreIdentity",
                "_CSV",
                "_JSON",
                "_ModularDecodingEncoding",
                "CorePersistence",
                "Proquint",
                "UUIDv6"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.1.0"),
        .package(url: "https://github.com/SwiftUIX/SwiftUIX.git", branch: "master"),
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
            name: "_ModularDecodingEncoding",
            dependencies: [
                "_CoreIdentity",
                "Merge",
                "Swallow"
            ],
            path: "Sources/_ModularDecodingEncoding",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
            ]
        ),
        .target(
            name: "_CoreIdentity",
            dependencies: [
                "CorePersistenceMacros",
                "Merge",
                "Proquint",
                "Swallow"
            ],
            path: "Sources/_CoreIdentity",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
            ]
        ),
        .target(
            name: "_CSV",
            dependencies: [
                "Swallow"
            ],
            path: "Sources/_CSV",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
            ]
        ),
        .target(
            name: "_JSON",
            dependencies: [
                "Swallow",
                "SwiftUIX"
            ],
            path: "Sources/_JSON",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
            ]
        ),
        .target(
            name: "_XMLCoder",
            dependencies: [
                "CorePersistence",
                "Swallow"
            ],
            path: "Sources/_XMLCoder",
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
            ]
        ),
        .target(
            name: "CorePersistence",
            dependencies: [
                "_CoreIdentity",
                "_JSON",
                "_ModularDecodingEncoding",
                "CorePersistenceMacros",
                "Expansions",
                "Merge",
                "Proquint",
                "Swallow"
            ],
            swiftSettings: [
                .unsafeFlags([
                    "-Xfrontend",
                    "-disable-typo-correction",
                    "-Xfrontend",
                    "-disable-verify-exclusivity",
                ])
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
        .testTarget(
            name: "CorePersistenceTests",
            dependencies: [
                "CorePersistence"
            ]
        ),
    ]
)
