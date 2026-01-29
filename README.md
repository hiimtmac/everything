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

### Infrastructure Split

Stateful data stores run outside k8s on the control node via Docker Compose. Application workloads run in k8s on worker nodes. This mirrors production patterns where databases would be managed services (RDS, MSK, etc.) or run in dedicated clusters.

```
pi-control (Docker Compose)           pi-worker-1/2/3 (k8s cluster)
┌──────────────────────────┐          ┌──────────────────────────┐
│ postgres:5432            │          │ server                   │
│ kafka:9092               │◄────────►│ order-service            │
│                          │          │ customer-service         │
│                          │          │ valkey                   │
│ Managed via Ansible      │          │ temporal + temporal-ui   │
│                          │          │ otel-collector           │
│                          │          │ prometheus               │
│                          │          │ grafana                  │
└──────────────────────────┘          └──────────────────────────┘
```

**Why this split:**

| Outside k8s (Docker Compose) | Inside k8s | Reason |
|------------------------------|------------|--------|
| Postgres | | Persistent data, complex to manage in k8s |
| Kafka | | Persistent message log, complex clustering |
| | Valkey | Ephemeral cache, can lose data on restart |
| | Temporal | Stateless - its state lives in Postgres |
| | Swift services | Stateless apps |
| | Observability | Semi-stateful, acceptable to lose on restart |

**In production**, Postgres and Kafka would typically be:
- Managed services (AWS RDS, MSK, Confluent Cloud, Temporal Cloud)
- Or run in dedicated k8s clusters with operators (CloudNativePG, Strimzi)

Running stateful workloads in k8s is complex (PersistentVolumes, StatefulSets, operators for failover/backups). For learning application-layer k8s patterns, keeping data stores outside simplifies things.

**Note on data durability:** Docker Compose on the control node still requires backups for real durability. If the node's SD card dies, data is lost. Use `pg_dump` to external storage for backups.

### Connecting k8s to Infrastructure

k8s pods connect to Postgres/Kafka on the control node using ExternalName services or direct IP. The control node hostname is `pi-control` (or use the IP from `ansible/inventory/hosts.local.yaml`).

**Infrastructure Endpoints:**

| Service | Port | Usage |
|---------|------|-------|
| Postgres | 5432 | `pi-control:5432` |
| Kafka | 9094 | `pi-control:9094` (external listener) |

**Option 1: ExternalName Service (recommended)**

```yaml
# k8s/base/external-services.yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: everything
spec:
  type: ExternalName
  externalName: pi-control  # or IP: 192.168.x.x
---
apiVersion: v1
kind: Service
metadata:
  name: kafka
  namespace: everything
spec:
  type: ExternalName
  externalName: pi-control
```

Pods then connect via `postgres:5432` and `kafka:9094` as if they were in-cluster services.

**Option 2: Environment Variables**

```yaml
# In deployment spec
env:
  - name: DATABASE_HOST
    value: "pi-control"  # or ConfigMap reference
  - name: DATABASE_PORT
    value: "5432"
  - name: KAFKA_BOOTSTRAP_SERVERS
    value: "pi-control:9094"
```

**Postgres Connection (per-service credentials):**

| Service | Database | User | Password |
|---------|----------|------|----------|
| order-service | `order_db` | `order_service` | `order_service` |
| customer-service | `customer_db` | `customer_service` | `customer_service` |
| temporal | `temporal` | `temporal` | `temporal` |
| temporal (visibility) | `temporal_visibility` | `temporal` | `temporal` |

Credentials are set in `ansible/roles/docker-infra/files/init-db.sql`.

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
**Database:** PostgreSQL (single instance, database-per-service isolation - simulates separate RDS instances)
**Cache/Queue:** Valkey (single instance, key prefix isolation: `server:*`, `order:*`, `customer:*`)
**Event Streaming:** Kafka
**Workflows:** Temporal SDK
**Observability:** OpenTelemetry → Prometheus → Grafana
**Deployment:** k3s cluster + Docker Compose (managed via Ansible)

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

### Deployment Workflow

Infrastructure and application deployments are managed separately:

```bash
# Infrastructure changes (Postgres, Kafka on control node)
ansible-playbook ansible/playbooks/infrastructure.yml

# Application changes (k8s workloads)
kubectl apply -k k8s/
```

**Ansible manages the control node:**
- Installs Docker
- Deploys docker-compose.yml for Postgres/Kafka
- Handles infrastructure updates

**kubectl/kustomize manages k8s:**
- Swift services, Valkey, Temporal, observability stack
- ConfigMaps, Secrets, Services, Deployments

This separation mirrors production where infrastructure teams manage data stores and application teams deploy via CI/CD to k8s.

### Resource Management

**Control Node (~906MB total):**

| Component | Memory Limit | CPU Limit |
|-----------|--------------|-----------|
| Postgres | 192MB | 0.5 |
| Kafka (KRaft) | 192MB | 0.5 |
| k3s control plane | ~300MB | - |
| System/OS | ~100MB | - |
| **Headroom** | **~120MB** | - |

**k8s Pod Resource Requests (worker nodes):**

- server: 64Mi memory, 100m CPU (lightweight, stateless)
- order-service: 64Mi memory, 100m CPU (Temporal client, workflows)
- customer-service: 64Mi memory, 100m CPU (Kafka consumers)
- valkey: 128Mi memory, 100m CPU
- temporal: 256Mi memory, 250m CPU
- otel-collector: 64Mi memory, 100m CPU
- prometheus: 256Mi memory, 250m CPU
- grafana: 128Mi memory, 100m CPU

**Total Cluster Capacity (4 nodes x 4 CPU, ~906MB each):** 16 CPU cores, ~3.5GB usable memory

With Postgres/Kafka on control node (~384MB), all 3 worker nodes (~2.7GB total) are available for application workloads.

**Postgres Connection Pool Configuration:**

With a shared Postgres instance, coordinate pool sizes across services to stay under `max_connections` (default 100):

| Service | Pool Size | Reason |
|---------|-----------|--------|
| Order Service | 5-10 | Temporal workflows, main writes |
| Customer Service | 5-10 | Kafka consumer, stats updates |
| Temporal | 10-20 | Workflow state persistence |
| Reserve | ~60 | Headroom, admin connections |

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
