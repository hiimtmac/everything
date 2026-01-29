# Everything - Family Coffee Ordering System

A learning playground for modern Swift backend development, microservices architecture, and distributed systems.

## What is Everything?

Everything is a family coffee ordering system that runs on a local k3s cluster. Family members order coffee drinks via iOS app, the barista gets notified, prepares the drink, and sends notifications when ready. This project explores:

- Modern Swift backend services (Swift 6.2, strict concurrency)
- Microservices architecture with gRPC
- Distributed tracing and observability
- Temporal workflows for orchestration
- Event-driven architecture with Kafka
- iOS extensions (Live Activities, Widgets, App Intents)

## Architecture

```
Family Members (iOS apps - iOS 26)
    ↓ REST/OpenAPI (JSON)
┌─────────────────┐
│  Hummingbird    │  (API Gateway - Swift 6.2)
│  - JWT auth     │
│  - Rate limiting│
│  - Valkey cache │  (auth tokens, rate limits)
└────────┬────────┘
         ↓ gRPC/Protobuf
    ┌────┴──────────┐
    ↓               ↓
┌────────────┐  ┌────────────┐
│  Order     │←→│ Customer   │  (gRPC both ways)
│  Service   │  │ Service    │
│            │  │            │
│ - Temporal │  │ - Stats    │
│ - Menu     │  │ - Favorites│
│ - Queue    │  │ - Loyalty  │
└─────┬──────┘  └──────┬─────┘
      ↓                ↓
   OrderDB         CustomerDB
   (Postgres)      (Postgres)
      ↓                ↓
   Valkey ←→ Kafka ←→ Valkey
   (cache)  (events)  (cache)
```

### Protocol Boundaries

- **External (Mobile ↔ Hummingbird):** REST/OpenAPI with JSON - Standard for mobile apps
- **Internal (Hummingbird ↔ Services):** gRPC with Protobuf - Efficient server-to-server
- **Internal (Service ↔ Service):** gRPC with Protobuf
- **Events:** Kafka for asynchronous event streaming

### Services

**Hummingbird (API Gateway)**

- Thin HTTP layer handling auth, rate limiting, protocol translation
- No business logic or database access
- Forwards requests to backend services via gRPC

**Order Service**

- Coffee shop operations: menu, orders, preparation workflow
- Orchestrates order lifecycle via Temporal (long-running workflows)
- Publishes order events to Kafka
- Database: OrderDB (orders, menu items, customizations)

**Customer Service**

- Family member profiles, favorites, statistics
- Loyalty/rewards system
- Consumes order events from Kafka to update stats
- Database: CustomerDB (customers, favorites, stats)

## Technology Stack

**Backend:** Swift 6.2 with strict concurrency
**HTTP Server:** Hummingbird
**Databases:** PostgreSQL (one per service)
**Cache/Queue:** Valkey with namespaced keys
**Event Streaming:** Kafka
**Workflows:** Temporal SDK
**Observability:** OpenTelemetry → Prometheus → Grafana
**Deployment:** k3s (local cluster)

## Example Flow

1. Family member opens iOS app → Shows coffee menu
2. Taps "Order My Usual" → Hummingbird validates JWT → Customer Service returns favorite drink
3. Places order → Order Service starts Temporal workflow → Publishes OrderPlaced event
4. Barista gets push notification → Accepts order
5. Barista makes coffee → Marks "Ready" → Customer gets push notification + Live Activity update
6. Customer picks up → Workflow completes → Kafka event updates customer stats
7. Full distributed trace: App → Hummingbird → Order Service → Customer Service → Temporal

See [CLAUDE.md](CLAUDE.md) for detailed architectural decisions and development guidelines.

## Getting Started

### Prerequisites

- Swift 6.2 toolchain
- Docker and Docker Compose
- Homebrew (for code generation tools)

```bash
brew install protobuf
```

### Development with DevContainers

Each service has a `.devcontainer` configuration.

Open any service directory in VS Code and select "Reopen in Container" to get a complete development environment.

### Observability

The project uses OpenTelemetry for distributed tracing with OTLP/gRPC:

**Architecture:**

- All services export traces to OTEL Collector via OTLP/gRPC (port 4317)
- OTEL Collector processes traces and exports to Prometheus
- Grafana visualizes metrics and traces

## Learning Resources

### GRPC

https://www.youtube.com/watch?v=yo-7ipiQwNs @17

### OTEL

https://www.youtube.com/watch?v=HSxIFLsoODc @12

**Internal Communication (ClusterIP):**

TODO

### External Access (Tailscale)

TODO/TBD

### Resource Management

**Pod Resource Requests:**

- Hummingbird: 256Mi memory, 250m CPU (lightweight, stateless)
- Order Service: 512Mi memory, 500m CPU (Temporal client, workflows)
- Customer Service: 512Mi memory, 500m CPU (Kafka consumers)
- Postgres: 512Mi memory, 500m CPU (per instance)
- Valkey: 256Mi memory, 250m CPU
- Kafka: 512Mi memory, 500m CPU

**Total Cluster Capacity (4 nodes x 6GB):** ~24GB usable memory

**Scaling Strategy:**

- Start with 2-3 replicas per service
- Use Horizontal Pod Autoscaler (HPA) for dynamic scaling
- Monitor with Prometheus, scale based on CPU/memory metrics

**Example Trace Flow:**

```
iOS App → Hummingbird → Order Service → Customer Service → Temporal Workflow
   ↓          ↓              ↓                ↓                    ↓
  OTel → OTel Collector ← OTel ← ────────── OTel ← ──────────── OTel
                ↓
         Prometheus + Tempo
                ↓
             Grafana
```

**ClusterIP Services act as internal load balancers:**

```
Hummingbird Pod → http://order-service:50051
                        ↓ (round-robin)
                    ┌─────┴─────┐
                    ↓           ↓
            order-pod-1   order-pod-2
```
