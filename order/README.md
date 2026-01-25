# Order Service

gRPC service for coffee shop operations, order management, and workflow orchestration.

## Responsibilities

- **Menu Management**: Coffee menu items, customizations, pricing
- **Order Processing**: Order creation, validation, status tracking
- **Workflow Orchestration**: Long-running order workflows via Temporal
- **Event Publishing**: Publishes order events to Kafka for other services

## Technology Stack

- **Language**: Swift 6.2 with strict concurrency
- **gRPC**: Server-side gRPC with bidirectional streaming support
- **Database**: PostgreSQL (OrderDB) via `hummingbird-postgres`
- **Cache**: Valkey via `swift-valkey`
- **Queue**: Background jobs via `swift-jobs-valkey`
- **Workflows**: Temporal SDK for long-running processes
- **Events**: Kafka for publishing order events
- **Observability**: OpenTelemetry for distributed tracing

## gRPC API

Defined in `/specs/proto/order.proto`

### Service Methods

- `HealthCheck` - Service health status (unary)
- More methods to be added...

### Streaming Support

This service implements all gRPC streaming patterns:
- **Unary**: Simple request-response
- **Server streaming**: Real-time order status updates
- **Client streaming**: Batch order operations
- **Bidirectional streaming**: Real-time order tracking

## Database Schema

**OrderDB** contains:
- `orders` - Order records with status, customer_id, timestamps
- `order_items` - Individual items in an order (drink, customizations)
- `menu_items` - Coffee menu with prices
- `customizations` - Available drink modifications

## Environment Variables

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=orderdb
DB_USER=orderuser
DB_PASSWORD=orderpass

# Cache
VALKEY_HOST=localhost
VALKEY_PORT=6379

# Events
KAFKA_BROKERS=localhost:9092

# Workflows
TEMPORAL_HOST=localhost
TEMPORAL_PORT=7233

# Server
GRPC_PORT=50051
```

## Development

### Prerequisites

- Swift 6.2 toolchain
- Docker (for running dependencies)

### Running in DevContainer

The devcontainer includes all necessary dependencies:
- PostgreSQL (OrderDB)
- Valkey (cache + queue)
- Kafka (event streaming)
- Temporal (workflow engine)
- Prometheus + Grafana (observability)

```bash
# Open in VS Code
code services/order

# Reopen in Container (Command Palette: "Dev Containers: Reopen in Container")

# Build and run
swift run
```

### Running Locally

```bash
# Start dependencies
docker-compose -f .devcontainer/docker-compose.yml up -d

# Build
swift build

# Run
swift run

# Test
swift test
```

## Temporal Workflows

The Order Service uses Temporal for orchestrating multi-step order processes:

- **Order Fulfillment Workflow**: Order placement → Barista acceptance → Preparation → Ready → Pickup
- **Payment Processing**: Payment authorization → Capture → Refund handling
- **Notification Workflow**: Customer notifications at each order stage

Temporal provides:
- Reliable execution (survives service restarts)
- Retry logic with exponential backoff
- Workflow versioning for updates
- Activity timeouts and compensation logic

## Kafka Events

**Published Events:**
- `order.placed` - New order created
- `order.accepted` - Barista accepted order
- `order.ready` - Drink is ready for pickup
- `order.completed` - Order picked up
- `order.cancelled` - Order cancelled

Other services (Customer Service) consume these events to update statistics and loyalty points.

## Observability

All operations are instrumented with OpenTelemetry:
- **Traces**: End-to-end request tracing (gRPC → Database → Temporal → Kafka)
- **Metrics**: Order volume, latency, error rates
- **Logs**: Structured logging with correlation IDs

View in Grafana: http://localhost:3000
