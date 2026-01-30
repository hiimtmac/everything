# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Everything** is a family coffee ordering system running on a local k3s cluster. This is a learning playground for modern Swift backend development, microservices architecture, and distributed systems.

**Use Case:** Family members order coffee drinks via iOS app, the barista gets notified, prepares the drink, and sends notifications when ready.

This monorepo contains multiple interconnected Swift projects designed to explore a variety of technologies and patterns. All components are written in the latest Swift version with strict concurrency enabled.

## Swift Requirements

### Strict Concurrency

All code MUST enable strict concurrency checking:

- Use `async`/`await` for all asynchronous operations
- NO legacy frameworks (DispatchQueue, OperationQueue, Combine for async operations unless absolutely necessary)
- Proper actor isolation and Sendable conformance
- Swift 6.2 language features and tooling
- Must be linux compatible API

### Concurrency Patterns

- Prefer structured concurrency (`async let`, `TaskGroup`)
- Use actors for shared mutable state
- Leverage `@Observable` macro for SwiftUI state (iOS app)
- All network calls should be `async` functions

## Technology Stack

### Infrastructure

- **Database:** PostgreSQL (k8s StatefulSet)
- **Cache/Queue:** Valkey (single instance, key prefix isolation: `server:*`, `order:*`, `customer:*`)
- **Event Streaming:** Kafka (k8s StatefulSet)
- **Workflow Engine:** Temporal
- **Observability:** OpenTelemetry → Prometheus + Grafana
- **Container Orchestration:** k3s (local cluster)

## Observability Stack

All services are instrumented with comprehensive observability:

- **OpenTelemetry**: Distributed tracing and metrics collection
- **Prometheus**: Metrics storage and querying
- **Grafana**: Visualization and dashboards

Ensure all new endpoints and workflows emit appropriate traces and metrics.

## Temporal Workflows

The Order Service (`/service-order`) integrates Temporal SDK for orchestrating order workflows:

**Why Temporal:**

- Order workflows can span 30+ minutes (too long for HTTP request)
- Needs to handle failures at any step (barista doesn't accept, customer doesn't pick up)
- State must survive service restarts
- Supports compensation (refund if order cancelled mid-workflow)

## Deployment

This system is deployed on a 4-node Raspberry Pi 4 cluster running k3s. All Swift services, infrastructure components, and observability tools run within the cluster.

### Hardware

- **4x Raspberry Pi 4**
- **Networking:** Gigabit Ethernet
- **Storage:** MicroSD cards + PersistentVolumes for stateful workloads
- **k3s:** Lightweight Kubernetes distribution optimized for ARM/edge devices

**Cluster Topology:**

- 1 control plane node
- 3 worker nodes
- All workloads (including Postgres/Kafka) run as k8s resources

### Workload Types

**StatefulSets (persistent data):**
- Postgres (with PVC)
- Kafka (with PVC)

**Deployments (stateless/ephemeral):**
- Swift services (server, order-service, customer-service)
- Valkey (ephemeral cache)
- Temporal server + UI
- Observability stack (OTEL collector, Prometheus, Grafana)

### Containerization

All Swift services are containerized with multi-stage builds

### Infrastructure Deployment

All workloads are deployed via kubectl/kustomize:

```bash
kubectl apply -k k8s/
```

#### PostgreSQL

**Database-per-Service Pattern:**

- Single PostgreSQL StatefulSet with separate databases (`order_db`, `customer_db`)
- Each service connects to its own database with its own user
- No cross-database joins (use gRPC or Kafka for cross-service data)
- Coordinate connection pool sizes across services to stay under `max_connections`
- Simulates having separate RDS instances in production

#### Kafka

Event streaming for asynchronous communication between services. Runs as a StatefulSet in k8s. In production: would use managed service (MSK, Confluent Cloud) or dedicated cluster with Strimzi operator.

#### Temporal

Workflow orchestration engine for Order Service. Runs as a Deployment in k8s. In production: would use Temporal Cloud.

#### Service Discovery

All services communicate via in-cluster DNS:

- `postgres:5432` - PostgreSQL service
- `kafka:9092` - Kafka bootstrap server
- `order-service:50051` - Order Service gRPC
- `customer-service:50051` - Customer Service gRPC

**Postgres credentials** (defined in k8s Secrets):
- `order_service` user → `order_db` database
- `customer_service` user → `customer_db` database
- `temporal` user → `temporal` + `temporal_visibility` databases

See README.md for full architecture details.
