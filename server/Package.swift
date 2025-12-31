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
    name: "server",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(path: "shared", traits: ["GRPCClient", "OpenAPIServer"]),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-valkey.git", .upToNextMinor(from: "0.2.0")),
        .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "2.1.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.6.0"),
        .package(url: "https://github.com/swift-otel/swift-otel.git", from: "1.0.0", traits: ["OTLPHTTP"]),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-profile-recorder.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "5.3.0"),
        .package(url: "https://github.com/orlandos-nl/SSEKit.git", from: "1.1.0"),
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "3.0.0"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.2.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.4.0"),
        .package(url: "https://github.com/grpc/grpc-swift-extras.git", from: "2.0.0"), // https://github.com/grpc/grpc-swift-2/blob/main/Examples/service-lifecycle/Package.swift
        .package(url: "https://github.com/swift-server/swift-openapi-hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "6.3.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .target(name: "API"),
                .product(name: "GRPCClient", package: "shared"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCOTelTracingInterceptors", package: "grpc-swift-extras"),
                .product(name: "GRPCServiceLifecycle", package: "grpc-swift-extras"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdValkey", package: "hummingbird-valkey"),
                .product(name: "ProfileRecorderServer", package: "swift-profile-recorder"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OpenAPIHummingbird", package: "swift-openapi-hummingbird"),
                .product(name: "SystemPackage", package: "swift-system")
            ],
            swiftSettings: swiftSettings + [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
            ]
        ),
        .target(
            name: "API",
            dependencies: [
                .product(name: "OpenAPIServer", package: "shared"),
                .product(name: "GRPCClient", package: "shared"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
                .product(name: "HummingbirdWSCompression", package: "hummingbird-websocket"),
                .product(name: "HummingbirdValkey", package: "hummingbird-valkey"),
                .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
                .product(name: "HummingbirdBasicAuth", package: "hummingbird-auth"),
                .product(name: "SSEKit", package: "SSEKit"),
                .product(name: "Graphiti", package: "Graphiti"),
                .product(name: "JWTKit", package: "jwt-kit"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)
