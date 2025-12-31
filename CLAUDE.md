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
- **Cache/Queue:** Valkey
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

- 1 control plane node (also runs workloads)
- 3 worker nodes
- All 4 nodes participate in running pods (k3s default behavior)

### Containerization

All Swift services are containerized with multi-stage builds

### Infrastructure Deployment

Infrastructure components use Helm charts for simplified deployment and lifecycle management.

#### PostgreSQL

**Database-per-Service Pattern:**

- Deploy separate PostgreSQL instances for Order Service and Customer Service
- Each service owns its database schema
- No cross-database joins (use gRPC or Kafka for cross-service data)

#### Kafka

Event streaming for asynchronous communication between services

#### Temporal

Workflow orchestration engine for Order Service
