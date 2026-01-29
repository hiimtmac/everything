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

- **Database:** PostgreSQL
- **Cache/Queue:** Valkey (single instance, key prefix isolation: `server:*`, `order:*`, `customer:*`)
- **Event Streaming:** Kafka
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
- **Storage:** MicroSD cards
- **k3s:** Lightweight Kubernetes distribution optimized for ARM/edge devices

**Cluster Topology:**

- 1 control plane node (runs Postgres/Kafka via Docker Compose)
- 3 worker nodes (run k8s application workloads)

### Infrastructure Split

Stateful data stores run outside k8s to simplify operations and mirror production patterns (where these would be managed services like RDS, MSK, Temporal Cloud).

**Control node (Docker Compose via Ansible):**
- Postgres
- Kafka

**k8s cluster (worker nodes):**
- Swift services (server, order-service, customer-service)
- Valkey (ephemeral cache)
- Temporal server + UI
- Observability stack (OTEL collector, Prometheus, Grafana)

### Containerization

All Swift services are containerized with multi-stage builds

### Infrastructure Deployment

**Control node:** Ansible installs Docker and manages docker-compose.yml

**k8s workloads:** kubectl/kustomize for application deployments

#### PostgreSQL

**Database-per-Service Pattern:**

- Single PostgreSQL instance with separate databases (`order_db`, `customer_db`)
- Each service connects to its own database with its own user
- No cross-database joins (use gRPC or Kafka for cross-service data)
- Coordinate connection pool sizes across services to stay under `max_connections`
- Simulates having separate RDS instances in production

#### Kafka

Event streaming for asynchronous communication between services. In production: would use managed service (MSK, Confluent Cloud) or dedicated cluster with Strimzi operator.

#### Temporal

Workflow orchestration engine for Order Service. Runs in k8s, connects to Postgres on control node. In production: would use Temporal Cloud.

#### Connecting k8s to Infrastructure

Postgres and Kafka run on `pi-control` via Docker Compose. k8s pods connect using:

- **ExternalName Service**: Create k8s Service with `type: ExternalName` pointing to `pi-control`
- **Direct IP**: Use control node IP from `ansible/inventory/hosts.local.yaml`

**Endpoints:**
- Postgres: `pi-control:5432`
- Kafka: `pi-control:9094` (external listener)

**Postgres credentials** (defined in `ansible/roles/docker-infra/files/init-db.sql`):
- `order_service` user → `order_db` database
- `customer_service` user → `customer_db` database
- `temporal` user → `temporal` + `temporal_visibility` databases

See README.md "Connecting k8s to Infrastructure" section for full k8s manifest examples.
