# Technology Stack Checklist

This is a "try all the things" learning project. Its over engineered on purpose. The project is a local drink ordering app in my house.

## Core Components

- iOS App:

  - Dual purpose app for customers/baristas (user can be both)

- watchOS App:

  - Small subset of iOS App

- ipadOS App:

  - POS terminal for taking orders in person

- macOS App:

  - Reporting and viewing history,
  - Managing inventory & updating menu

- tvOS App:

  - showing menu
  - brief orders status
  - Leaderboard

- Server:

  - Thin HTTP layer for protocol translation and edge concerns
  - uses OpenAPI contract between clients (\*OS apps)
  - uses GRPC to talk to other services

- Order Service:

  - Order business logic
  - Menu & inventory management

- Customer Service:

  - Sign(in|up) / Authentication
  - Profile management
  - Loyalty/reward system & Achievments

> Two services arbitrarily to have "more than one" service, services can talk to each other through grpc

- Shared:

  - OpenAPI codegen
  - GRPC codgen

- k3s
  - Deploy services on raspberri pi cluster accessible only on local network

## Technology wishlist

Would like to use all the following features:

- Websockets
- GraphQL
- SSE (https://github.com/hummingbird-project/hummingbird-examples/tree/main/server-sent-events)
- HTTP Streaming
- APNS (https://github.com/swift-server-community/APNSwift/blob/main/Package.swift)
- QUIC
- Unary RPC
- Server Stream RPC
- Client Strem RPC
- Bidirection RPC
- Distributed tracing (https://github.com/hummingbird-project/hummingbird-examples/tree/main/open-telemetry)
- End-to-end request tracking
- Service dependency mapping
- Latency breakdown & error tracing
- Log Aggregation with search/filtering
- Visualization (Grafana/Promethues)
- WebAuthn/Passkeys
- JWT Auth (https://github.com/hummingbird-project/hummingbird-examples/tree/main/auth-jwt)
- OAuth2/OIDC - SIWA (not sure if this is feasible for a local project)
- TOTP/OTP generation (https://github.com/hummingbird-project/hummingbird-examples/tree/main/auth-otp)
- SRP Auth
- Basic Auth
- Session Management (https://github.com/hummingbird-project/hummingbird-examples/tree/main/sessions)
- PSQL with connection pooling
- Read replicas
- Query Performance monitoring
- FTS (elasticsearch/meilisearch/psql FTS)
- Caching (Valkey) - cache-aside/write-through/invalidation/warming/hit-miss metrics
- Kafka
- Background jobs/queues
- Scheduled jobs/queues
- TemporalSDK (Order Placed → Notify Barista → Wait for Acceptance → Preparation → Mark Ready → Notify Customer → Wait for Pickup → Complete → Record Stats)
- Server profiling (https://github.com/apple/swift-profile-recorder)
- Live Activities
- Home/Lockscreen Widget
- Dynamic Island Support
- Siri Shortcuts/App Intents
- App Clips
- Watch complication
- Any other extension/target that could add functionality
- Kubernetes
- CI/CD
- Analytics collection & querying
- DocC & documentation hosting
- Foundation models

### Future wishlist

- Distributed Actors
- Embedded Swift
- Wasm Swift
- Swift 4 Android (shared client library to use in future android app)
- CoreML with background tasks to update model
- Web app
