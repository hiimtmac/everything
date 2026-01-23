# API Specifications

This directory contains all API specifications for the project.

## Structure

### OpenAPI (`/openapi`)

Contains OpenAPI 3.1 specifications for the HTTP REST API used by the mobile app to communicate with the server.

- **Main spec**: `api.yaml`
- **Naming convention**: Use lowercase with hyphens (e.g., `user-service.yaml`)
- **Versioning**: Append version when maintaining multiple versions (e.g., `api-v1.yaml`, `api-v2.yaml`)

### gRPC (`/proto`)

Contains Protocol Buffer definitions for gRPC services used for server-to-service communication.

- **Main service**: `service.proto`
- **Naming convention**: Use lowercase with underscores (e.g., `user_service.proto`)
- **Package naming**: Use dotted notation (e.g., `myapp.service.v1`)

## Code Generation

Generated code is committed to the repository in `/shared/Sources/*/Generated/` directories.

To regenerate code after modifying specifications:

```bash
make generate-all
```

Or generate specific targets:

```bash
make generate-openapi-client   # iOS client
make generate-openapi-server   # HTTP server
make generate-grpc-client      # gRPC client (server uses this)
make generate-grpc-server      # gRPC server (service uses this)
```

## Tools Required

- `swift-openapi-generator` - For OpenAPI code generation
- `protoc` - Protocol Buffer compiler
- `grpc-swift` - Swift gRPC plugin

Install via Homebrew:

```bash
brew install swift-openapi-generator protobuf grpc-swift
```
