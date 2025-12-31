# Full Observability Stack

Complete LGTM (Loki, Grafana, Tempo, Mimir/Prometheus) stack for learning observability.

## Components

1. **Swift App** - Your application (needs Dockerfile)
2. **OTEL Collector** - Routes telemetry to backends
3. **Prometheus** - Stores metrics
4. **Loki** - Stores logs
5. **Tempo** - Stores traces
6. **Grafana** - Visualizes everything

## Usage

### 1. Start the stack

```bash
docker-compose up -d
```

### 2. Access UIs

- **Grafana**: http://localhost:3000 (auto-login enabled)
- **Prometheus**: http://localhost:9090
- **Tempo**: http://localhost:3200

### 3. Your Swift app needs

In your Swift code using swift-otel:

```swift
let observability = try OTel.bootstrap(
    serviceName: "my-swift-app",
    endpoint: "http://otel-collector:4317"
)
```

### 4. View data in Grafana

- **Explore → Loki**: Query logs
- **Explore → Prometheus**: Query metrics
- **Explore → Tempo**: Search traces

## Data Flow

```
Swift App → OTLP → OTEL Collector → splits to:
                                    ├─ Prometheus (metrics)
                                    ├─ Loki (logs)
                                    └─ Tempo (traces)
                                           ↓
                                      Grafana (correlates all 3)
```

## Files Explained

- **docker-compose.yml** - Defines all services
- **otel-collector-config.yaml** - Routes telemetry (THE KEY FILE)
- **prometheus.yml** - Prometheus scrape config
- **loki-config.yaml** - Loki storage and OTLP ingestion config
- **tempo.yaml** - Tempo storage config
- **grafana-datasources.yml** - Auto-configure Grafana datasources

## Next Steps

1. Create your Swift app Dockerfile
2. Instrument with swift-otel
3. Generate traffic
4. Explore in Grafana

## Troubleshooting

**No data showing up?**

- Check OTEL Collector logs: `docker-compose logs otel-collector`
- Verify your app is sending to port 4317/4318
- Check the debug exporter in collector logs

**Grafana can't connect?**

- Wait 30 seconds for all services to start
- Check datasource health in Grafana → Connections → Data sources
