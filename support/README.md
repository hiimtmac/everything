# Everything - Shared Development Infrastructure

This directory contains the shared infrastructure for all services in the Everything monorepo.

## Overview

The infrastructure setup provides all dependencies required by the three services:
- **Server** (API Gateway)
- **Service-Order** (Order microservice)
- **Service-Customer** (Customer microservice)

## Infrastructure Components

### Databases (PostgreSQL 16)
- `postgres-order` - Order service database (port 5432)
- `postgres-customer` - Customer service database (port 5532)
- `postgres-temporal` - Temporal persistence (port 5433)

### Cache (Valkey 8)
- `valkey-server` - Server API cache (port 6379)
- `valkey-order` - Order service cache + job queue (port 6479)
- `valkey-customer` - Customer service cache + job queue (port 6579)

### Event Streaming
- `zookeeper` - Kafka coordination
- `kafka` - Event streaming broker (port 9092)

### Workflow Orchestration
- `temporal` - Temporal server (port 7233)
- `temporal-ui` - Temporal Web UI (port 8081)

### Observability
- `otel-collector` - OpenTelemetry collector (port 4317)
- `prometheus` - Metrics storage (port 9090)
- `jaeger` - Distributed tracing UI (port 16686)

## Getting Started

### 1. Create Docker Network

Before starting the infrastructure, create the shared network:

```bash
docker network create everything-network
```

### 2. Start Infrastructure

From the `/support` directory:

```bash
docker compose up -d
```

### 3. Verify Services

Check that all services are healthy:

```bash
docker compose ps
```

You should see all services in a "healthy" state.

### 4. Test Connectivity

```bash
# PostgreSQL
docker exec postgres-order pg_isready -U order
docker exec postgres-customer pg_isready -U customer
docker exec postgres-temporal pg_isready -U temporal

# Valkey
docker exec valkey-server valkey-cli ping
docker exec valkey-order valkey-cli ping
docker exec valkey-customer valkey-cli ping

# Kafka (from within container)
docker exec kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

### 5. Access UIs

- **Temporal UI**: http://localhost:8081
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

### 6. Open Devcontainers

With infrastructure running, open any service in VS Code:
- `/server` - API Gateway devcontainer
- `/service-order` - Order service devcontainer
- `/service-customer` - Customer service devcontainer

The devcontainers will automatically connect to the shared infrastructure via the `everything-network`.

## Stopping Infrastructure

To stop all infrastructure:

```bash
docker compose down
```

To stop and remove all data volumes:

```bash
docker compose down -v
```

## Resource Usage

Expected resource consumption:
- **RAM**: ~4-5GB
- **CPU**: Moderate (varies with load)
- **Disk**: ~2-3GB for volumes

## Troubleshooting

### Port Conflicts

If you get port binding errors, check for conflicting services:

```bash
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Valkey
lsof -i :9092  # Kafka
lsof -i :7233  # Temporal
```

### Network Issues

If services can't communicate, verify the network exists:

```bash
docker network ls | grep everything-network
```

If missing, create it:

```bash
docker network create everything-network
```

### View Logs

To see logs from a specific service:

```bash
docker compose logs -f <service-name>
```

Examples:
```bash
docker compose logs -f postgres-order
docker compose logs -f kafka
docker compose logs -f temporal
docker compose logs -f otel-collector
```

### Reset Everything

To completely reset all infrastructure and data:

```bash
docker compose down -v
docker volume prune -f
docker compose up -d
```

## Connection Details

### From Devcontainers

Services connect using container names on the `everything-network`:

**Databases:**
- Order DB: `postgres-order:5432` (database: `order`, user: `order`)
- Customer DB: `postgres-customer:5432` (database: `customer`, user: `customer`)
- Temporal DB: `postgres-temporal:5432` (database: `temporal`, user: `temporal`)

**Cache:**
- Server: `valkey-server:6379`
- Order: `valkey-order:6379`
- Customer: `valkey-customer:6379`

**Event Streaming:**
- Kafka: `kafka:9092`

**Workflows:**
- Temporal: `temporal:7233`

**Observability:**
- OTEL Collector: `otel-collector:4317`

### From Host Machine

Use published ports to access from your local machine:

| Service | Port | Credentials |
|---------|------|-------------|
| postgres-order | 5432 | user: order, password: order_password |
| postgres-customer | 5532 | user: customer, password: customer_password |
| postgres-temporal | 5433 | user: temporal, password: temporal_password |
| valkey-server | 6379 | - |
| valkey-order | 6479 | - |
| valkey-customer | 6579 | - |
| kafka | 9092 | - |
| temporal | 7233 | - |
| temporal-ui | 8081 | - |
| otel-collector | 4317 | - |
| prometheus | 9090 | - |
| jaeger | 16686 | - |

## Data Persistence

All data is persisted in Docker volumes:
- `postgres-order-data`
- `postgres-customer-data`
- `postgres-temporal-data`
- `valkey-server-data`
- `valkey-order-data`
- `valkey-customer-data`
- `kafka-data`
- `zookeeper-data`
- `temporal-data`
- `prometheus-data`
- `otel-logs`

Data persists across container restarts but can be removed with `docker compose down -v`.
