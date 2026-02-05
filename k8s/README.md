# Kubernetes Deployment

This directory contains Helm charts and Helmfile configurations for deploying the Everything coffee ordering system to a k3s cluster.

## Directory Structure

```
k8s/
├── helmfile-infra.yaml       # Infrastructure (Postgres, Kafka, Valkey)
├── helmfile-monitoring.yaml  # Observability (Prometheus, Grafana, OTEL)
├── helmfile-apps.yaml        # Application services
├── charts/
│   ├── server/               # HTTP server (Hummingbird) - custom chart
│   ├── order-service/        # Order gRPC service - custom chart (TODO)
│   └── customer-service/     # Customer gRPC service - custom chart (TODO)
└── values/
    ├── infra/
    │   ├── postgres.yaml     # Bitnami PostgreSQL config
    │   ├── kafka.yaml        # Bitnami Kafka config
    │   └── valkey.yaml       # Bitnami Valkey config
    ├── monitoring/
    │   ├── prometheus.yaml   # kube-prometheus-stack config
    │   └── otel.yaml         # OTEL collector config
    └── apps/
        ├── server/
        │   ├── common.yaml   # Shared across environments
        │   ├── staging.yaml
        │   └── prod.yaml
        ├── order-service/
        │   └── ...
        └── customer-service/
            └── ...
```

## Chart Strategy

| Component            | Chart Source                | Reason                                          |
| -------------------- | --------------------------- | ----------------------------------------------- |
| Postgres             | Bitnami                     | Community chart handles HA, backups, upgrades   |
| Kafka                | Bitnami                     | Community chart handles clustering, persistence |
| Valkey               | Bitnami                     | Community chart with Sentinel support           |
| Prometheus + Grafana | kube-prometheus-stack       | Industry standard, includes dashboards          |
| OTEL Collector       | opentelemetry-collector     | Official chart                                  |
| server               | Custom (`charts/server/`)   | Our app, our deployment model                   |
| order-service        | Custom (`charts/order/`)    | Our app, needs migration hooks                  |
| customer-service     | Custom (`charts/customer/`) | Our app, needs migration hooks                  |

## Environments

- **staging** - Single replicas, debug logging
- **prod** - Multiple replicas, info logging

Both environments share infrastructure (Postgres, Kafka, Valkey) deployed to the `infra` namespace.

## Namespaces

| Namespace    | Contents                              |
| ------------ | ------------------------------------- |
| `infra`      | Postgres, Kafka, Valkey               |
| `monitoring` | Prometheus, Grafana, OTEL Collector   |
| `staging`    | App services (staging environment)    |
| `prod`       | App services (production environment) |

## Deployment Order

```bash
# 1. Infrastructure (rarely changes)
helmfile -f helmfile-infra.yaml sync

# 2. Monitoring (independent of apps)
helmfile -f helmfile-monitoring.yaml sync

# 3. Apps - staging
helmfile -f helmfile-apps.yaml -e staging sync

# 4. Apps - prod
helmfile -f helmfile-apps.yaml -e prod sync
```

## Useful Commands

```bash
# Preview changes before applying
helmfile -f helmfile-apps.yaml -e staging diff

# Deploy single service
helmfile -f helmfile-apps.yaml -e staging -l name=server sync

# View rendered manifests
helmfile -f helmfile-apps.yaml -e staging template

# List releases
helmfile -f helmfile-apps.yaml -e staging list

# Rollback a release
helm rollback server 1 -n staging
```

## Database Migrations

The order-service and customer-service charts use Helm hooks for migrations:

- Migrations run as a Job with `helm.sh/hook: pre-install,pre-upgrade`
- The Job runs once before the Deployment updates
- Replicas start only after migration succeeds
- Failed migration Jobs are preserved for debugging

## TODO

- [ ] Create order-service chart (with migration hook)
- [ ] Create customer-service chart (with migration hook)
- [ ] Create helmfile-infra.yaml with Bitnami charts
- [ ] Create helmfile-monitoring.yaml
- [ ] Create helmfile-apps.yaml
- [ ] Create values files for each environment
