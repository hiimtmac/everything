# Customer Service

gRPC service for family member profiles, favorites, statistics, and loyalty management.

## Responsibilities

- **Customer Profiles**: Family member information, preferences, dietary restrictions
- **Favorites**: Stored favorite drinks for quick ordering
- **Statistics**: Order history, favorite drinks, peak ordering times
- **Loyalty/Rewards**: Points accumulation, rewards redemption
- **Event Consumption**: Listens to Kafka events to update customer stats

## Technology Stack

- **Language**: Swift 6.2 with strict concurrency
- **gRPC**: Server-side gRPC with bidirectional streaming support
- **Database**: PostgreSQL (CustomerDB) via `hummingbird-postgres`
- **Cache**: Valkey via `swift-valkey`
- **Queue**: Background jobs via `swift-jobs-valkey`
- **Events**: Kafka for consuming order events
- **Observability**: OpenTelemetry for distributed tracing

## gRPC API

Defined in `/specs/proto/customer.proto`

### Service Methods

- `HealthCheck` - Service health status (unary)
- More methods to be added...

### Streaming Support

This service implements all gRPC streaming patterns:
- **Unary**: Simple request-response for profile queries
- **Server streaming**: Real-time customer stats updates
- **Client streaming**: Batch customer imports
- **Bidirectional streaming**: Live customer activity feeds

## Database Schema

**CustomerDB** contains:
- `customers` - Customer profiles (username, display name, preferences)
- `favorites` - Saved favorite drinks per customer
- `order_stats` - Aggregated order statistics
- `loyalty_points` - Points balance and transaction history
- `rewards` - Available rewards and redemption records

## Environment Variables

```bash
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=customerdb
DB_USER=customeruser
DB_PASSWORD=customerpass

# Cache
VALKEY_HOST=localhost
VALKEY_PORT=6379

# Events
KAFKA_BROKERS=localhost:9092

# Server
GRPC_PORT=50052
```

## Development

### Prerequisites

- Swift 6.2 toolchain
- Docker (for running dependencies)

### Running in DevContainer

The devcontainer includes all necessary dependencies:
- PostgreSQL (CustomerDB)
- Valkey (cache + queue)
- Kafka (event streaming)
- Prometheus + Grafana (observability)

```bash
# Open in VS Code
code services/customer

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

## Kafka Event Consumers

**Subscribed Events:**
- `order.placed` - Increment customer order count
- `order.completed` - Add loyalty points
- `order.cancelled` - Update stats
- `payment.processed` - Update spending totals

Background workers consume these events and update customer statistics asynchronously.

## Background Jobs

Uses `swift-jobs-valkey` for:
- **Stats Aggregation**: Periodic rollup of customer statistics
- **Reward Notifications**: Check for rewards eligibility
- **Loyalty Point Expiry**: Expire points after inactivity period
- **Data Cleanup**: Archive old order history

## Observability

All operations are instrumented with OpenTelemetry:
- **Traces**: End-to-end request tracing (gRPC → Database → Kafka)
- **Metrics**: Query latency, cache hit rates, Kafka consumer lag
- **Logs**: Structured logging with correlation IDs

View in Grafana: http://localhost:3001

## Integration with Order Service

The Customer Service is called by the Order Service when:
- Validating customer ID during order placement
- Retrieving favorite drinks for "Order My Usual"
- Checking loyalty points for discounts
- Applying rewards to orders

Both services communicate via gRPC for low-latency synchronous operations.
