// swift-tools-version: 6.2
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // https://github.com/apple/swift-evolution/blob/main/proposals/0335-existential-any.md
    .enableUpcomingFeature("ExistentialAny")
]

let package = Package(
    name: "shared",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "OpenAPIClient", targets: ["OpenAPIClient", "OpenAPIShared"]),
        .library(name: "OpenAPIServer", targets: ["OpenAPIServer", "OpenAPIShared"]),
        .library(name: "GRPCClient", targets: ["GRPCClient", "GRPCShared"]),
        .library(name: "GRPCServer", targets: ["GRPCServer", "GRPCShared"]),
    ],
    traits: [
        .trait(name: "GRPC"),
        .trait(name: "GRPCClient", enabledTraits: ["GRPC"]),
        .trait(name: "GRPCServer", enabledTraits: ["GRPC"]),
        .trait(name: "OpenAPI"),
        .trait(name: "OpenAPIClient", enabledTraits: ["OpenAPI"]),
        .trait(name: "OpenAPIServer", enabledTraits: ["OpenAPI"]),
        .default(enabledTraits: ["GRPCClient", "GRPCServer", "OpenAPIClient", "OpenAPIServer"]),
    ],
    dependencies: [
        // OpenAPI
        .package(url: "https://github.com/apple/swift-openapi-generator.git", from: "1.10.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime.git", from: "1.9.0"),
        // gRPC
        .package(url: "https://github.com/grpc/grpc-swift-2.git", from: "2.2.0"),
        .package(url: "https://github.com/grpc/grpc-swift-protobuf.git", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.33.0"),
    ],
    targets: [
        // OpenAPI
        .target(
            name: "OpenAPIShared",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime", condition: .when(traits: ["OpenAPI"])),
            ],
            resources: [
                .copy("openapi.yml"),
                .copy("openapi-generator-config.yaml")
            ],
            swiftSettings: swiftSettings,
        ),
        .target(
            name: "OpenAPIClient",
            dependencies: [
                .target(name: "OpenAPIShared", condition: .when(traits: ["OpenAPIClient"])),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime", condition: .when(traits: ["OpenAPIClient"])),
            ],
            resources: [
                .copy("openapi.yml"),
                .copy("openapi-generator-config.yaml")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "OpenAPIServer",
            dependencies: [
                .target(name: "OpenAPIShared", condition: .when(traits: ["OpenAPIServer"])),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime", condition: .when(traits: ["OpenAPIServer"])),
            ],
            resources: [
                .copy("openapi.yml"),
                .copy("openapi-generator-config.yaml")
            ],
            swiftSettings: swiftSettings
        ),
        // gRPC
        .target(
            name: "GRPCShared",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf", condition: .when(traits: ["GRPC"])),  
            ],
            exclude: [
                "proto/",
                "grpc-swift-proto-generator-config.json",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "GRPCClient",
            dependencies: [
                .target(name: "GRPCShared", condition: .when(traits: ["GRPCClient"])),
                .product(name: "GRPCCore", package: "grpc-swift-2", condition: .when(traits: ["GRPCClient"])),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf", condition: .when(traits: ["GRPCClient"])),
            ],
            exclude: [
                "proto/",
                "grpc-swift-proto-generator-config.json",
                "module_mappings.txt",
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "GRPCServer",
            dependencies: [
                .target(name: "GRPCShared", condition: .when(traits: ["GRPCServer"])),
                .product(name: "GRPCCore", package: "grpc-swift-2", condition: .when(traits: ["GRPCServer"])),
                .product(name: "GRPCProtobuf", package: "grpc-swift-protobuf", condition: .when(traits: ["GRPCServer"])),
            ],
            exclude: [
                "proto/",
                "grpc-swift-proto-generator-config.json",
                "module_mappings.txt",
            ],
            swiftSettings: swiftSettings
        ),
        //
        //        // Tests
        //        .testTarget(
        //            name: "SharedTests",
        //            dependencies: [
        //                "OpenAPIClient",
        //                "OpenAPIServer",
        //                "GRPCClient",
        //                "GRPCServer",
        //            ]
        //        ),
    ]
)
