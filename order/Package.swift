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
    name: "service",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .executable(name: "App", targets: ["App"])
    ],
    dependencies: [
        .package(path: "shared", traits: ["GRPCServer", "GRPCClient"]),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.30.0"),
        .package(url: "https://github.com/hummingbird-project/postgres-migrations.git", from: "1.1.0"),
        .package(url: "https://github.com/hummingbird-project/swift-jobs-valkey.git", from: "1.0.0-rc.3"),
        .package(url: "https://github.com/valkey-io/valkey-swift.git", .upToNextMinor(from: "0.5.0")),
        .package(url: "https://github.com/swift-server/swift-kafka-client.git", from: "1.0.0-alpha.9"),
        .package(url: "https://github.com/swift-otel/swift-otel.git", from: "1.0.0", traits: ["OTLPHTTP"]),
        .package(url: "https://github.com/apple/swift-configuration.git", from: "1.0.0", traits: [.defaults, "CommandLineArguments"]),
        .package(url: "https://github.com/apple/swift-system.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-profile-recorder.git", .upToNextMinor(from: "0.3.0")),
        .package(url: "https://github.com/apple/swift-temporal-sdk.git", from: "0.5.0"),
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.2.0"),
        .package(url: "https://github.com/grpc/grpc-swift-nio-transport.git", from: "2.4.0"),
        .package(url: "https://github.com/grpc/grpc-swift-extras.git", from: "2.0.0"), // https://github.com/grpc/grpc-swift-2/blob/main/Examples/service-lifecycle/Package.swift
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .target(name: "Domain"),
                .product(name: "Configuration", package: "swift-configuration"),
                .product(name: "GRPCServer", package: "shared"),
                .product(name: "GRPCClient", package: "shared"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "GRPCNIOTransportHTTP2", package: "grpc-swift-nio-transport"),
                .product(name: "GRPCOTelTracingInterceptors", package: "grpc-swift-extras"),
                .product(name: "GRPCReflectionService", package: "grpc-swift-extras"),
                .product(name: "GRPCHealthService", package: "grpc-swift-extras"),
                .product(name: "GRPCServiceLifecycle", package: "grpc-swift-extras"),
                // .product(name: "Jobs", package: "swift-jobs"),
                .product(name: "JobsValkey", package: "swift-jobs-valkey"),
                .product(name: "Kafka", package: "swift-kafka-client"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "ProfileRecorderServer", package: "swift-profile-recorder"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "Temporal", package: "swift-temporal-sdk"),
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
            name: "Domain",
            dependencies: [
                .product(name: "GRPCServer", package: "shared"),
                .product(name: "GRPCClient", package: "shared"),
                .product(name: "GRPCCore", package: "grpc-swift-2"),
                .product(name: "PostgresNIO", package: "postgres-nio"),
                .product(name: "PostgresMigrations", package: "postgres-migrations"),
                .product(name: "Valkey", package: "valkey-swift"),
                .product(name: "JobsValkey", package: "swift-jobs-valkey"),
                .product(name: "Kafka", package: "swift-kafka-client"),
                .product(name: "Temporal", package: "swift-temporal-sdk"),
            ],
            swiftSettings: swiftSettings
        ),
        // .testTarget(
        //     name: "OrderServiceTests",
        //     dependencies: ["OrderService"]
        // ),
    ]
)
