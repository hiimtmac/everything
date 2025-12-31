// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    .enableUpcomingFeature("ExistentialAny"),

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0444-member-import-visibility.md
    .enableUpcomingFeature("MemberImportVisibility"),

    // https://github.com/swiftlang/swift-evolution/blob/main/proposals/0409-access-level-on-imports.md
    .enableUpcomingFeature("InternalImportsByDefault"),
]

let package = Package(
    name: "shared-wrapper",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "OpenAPIClientWrapper", targets: ["OpenAPIClientWrapper"])
    ],
    dependencies: [
        .package(path: "../../shared", traits: ["OpenAPIClient"]),
        .package(url: "https://github.com/apple/swift-openapi-urlsession.git", from: "1.2.0"),
    ],
    targets: [
        .target(
            name: "OpenAPIClientWrapper",
            dependencies: [
                .product(name: "OpenAPIClient", package: "shared"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)
