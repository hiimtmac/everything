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
      └────────┬───────┘
               ↓
        ┌─────────────┐
        │  Postgres   │
        │ ┌─────────┐ │
        │ │order_db │ │  (database-per-service)
        │ ├─────────┤ │
        │ │customer_│ │
        │ │   db    │ │
        │ └─────────┘ │
        └──────┬──────┘
               ↓
        Valkey ←→ Kafka
        (cache)   (events)
           │
    ┌──────┴──────┐
    │ Key Prefixes│
    │ server:*    │  (rate limits, sessions)
    │ order:*     │  (menu cache, queues)
    │ customer:*  │  (favorites cache)
    └─────────────┘
```

### Cluster Architecture

All workloads run in k8s on the Raspberry Pi cluster. Stateful services (Postgres, Kafka) run as StatefulSets with persistent storage, while stateless application services run as Deployments.

```
pi-control + pi-worker-1/2/3 (k8s cluster)
┌──────────────────────────────────────────┐
│ StatefulSets:                            │
│   postgres (PVC-backed)                  │
│   kafka (PVC-backed)                     │
│                                          │
│ Deployments:                             │
│   server                                 │
│   order-service                          │
│   customer-service                       │
│   valkey                                 │
│   temporal + temporal-ui                 │
│   otel-collector                         │
│   prometheus                             │
│   grafana                                │
└──────────────────────────────────────────┘
```

**Benefits of unified k8s deployment:**

- Single deployment system (kubectl/kustomize)
- Consistent networking (all services in-cluster)
- Simplified service discovery (DNS-based)
- Unified resource management and monitoring

**In production**, Postgres and Kafka would typically be:

- Managed services (AWS RDS, MSK, Confluent Cloud, Temporal Cloud)
- Or run in dedicated k8s clusters with operators (CloudNativePG, Strimzi)

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
- Database: `order_db` (orders, menu items, customizations)

**Customer Service**

- Family member profiles, favorites, statistics
- Loyalty/rewards system
- Consumes order events from Kafka to update stats
- Database: `customer_db` (customers, favorites, stats)

## Technology Stack

**Backend:** Swift 6.2 with strict concurrency
**HTTP Server:** Hummingbird
**Database:** PostgreSQL (StatefulSet, database-per-service isolation)
**Cache/Queue:** Valkey (single instance, key prefix isolation: `server:*`, `order:*`, `customer:*`)
**Event Streaming:** Kafka (StatefulSet)
**Workflows:** Temporal SDK
**Observability:** OpenTelemetry → Prometheus → Grafana
**Deployment:** k3s cluster managed via Ansible + kubectl/kustomize

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
- Docker (for local development)
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

### Deployment Workflow

All deployments are managed via kubectl/kustomize:

```bash
# Deploy all k8s workloads
kubectl apply -k k8s/
```

**Ansible manages the cluster nodes:**

- Installs k3s on control plane and worker nodes
- Configures node preparation (packages, settings)

**kubectl/kustomize manages all workloads:**

- StatefulSets: Postgres, Kafka
- Deployments: Swift services, Valkey, Temporal, observability stack
- ConfigMaps, Secrets, Services, PersistentVolumeClaims

### Resource Management

**k8s Pod Resource Requests (distributed across nodes):**

| Component        | Memory  | CPU   | Type        |
| ---------------- | ------- | ----- | ----------- |
| postgres         | 192Mi   | 0.5   | StatefulSet |
| kafka            | 192Mi   | 0.5   | StatefulSet |
| server           | 64Mi    | 100m  | Deployment  |
| order-service    | 64Mi    | 100m  | Deployment  |
| customer-service | 64Mi    | 100m  | Deployment  |
| valkey           | 128Mi   | 100m  | Deployment  |
| temporal         | 256Mi   | 250m  | Deployment  |
| otel-collector   | 64Mi    | 100m  | Deployment  |
| prometheus       | 256Mi   | 250m  | Deployment  |
| grafana          | 128Mi   | 100m  | Deployment  |

**Total Cluster Capacity (4 nodes x 4 CPU, ~906MB each):** 16 CPU cores, ~3.5GB usable memory

**Postgres Connection Pool Configuration:**

With a shared Postgres instance, coordinate pool sizes across services to stay under `max_connections` (default 100):

| Service          | Pool Size | Reason                          |
| ---------------- | --------- | ------------------------------- |
| Order Service    | 5-10      | Temporal workflows, main writes |
| Customer Service | 5-10      | Kafka consumer, stats updates   |
| Temporal         | 10-20     | Workflow state persistence      |
| Reserve          | ~60       | Headroom, admin connections     |

Each service connects to its own database:

```swift
let pool = PostgresClient(
    configuration: .init(
        host: "postgres",
        username: "order_service",
        password: "...",
        database: "order_db"  // each service has its own database
    ),
    connectionPoolConfiguration: .init(
        minimumConnections: 1,
        maximumConnections: 10  // coordinate across services
    )
)
```

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
