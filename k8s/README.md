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

## Quick Start

```bash
# 1. Install dependencies
make deps

# 2. Create Kubernetes secrets (interactive)
make secrets

# 3. Build Docker images
make build-all

# 4. Deploy everything (infrastructure + monitoring + staging)
make deploy-all

# 5. Verify deployment
make verify

# 6. Check status
make status
```

## Cluster Architecture

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

- Single deployment system (Helmfile + Helm)
- Consistent networking (all services in-cluster)
- Simplified service discovery (DNS-based)
- Unified resource management and monitoring

**In production**, Postgres and Kafka would typically be:

- Managed services (AWS RDS, MSK, Confluent Cloud, Temporal Cloud)
- Or run in dedicated k8s clusters with operators (CloudNativePG, Strimzi)

## Deployment Order

The order of deployment matters - infrastructure must be deployed before applications that depend on it.

```bash
# 1. Infrastructure (postgres, kafka, valkey, temporal)
make deploy-infra

# 2. Monitoring (otel, prometheus, grafana)
make deploy-monitoring

# 3. Applications - staging
make deploy-staging

# 4. Applications - production
make deploy-prod

# Or deploy everything at once:
make deploy-all  # infra + monitoring + staging
```

## Secret Management

Before deploying, you must create Kubernetes secrets for database credentials:

```bash
# Interactive secret creation
make secrets
```

This creates secrets in multiple namespaces:

**Infrastructure (`infra` namespace):**
- `postgres-credentials` - Master postgres password
- `temporal-credentials` - Temporal database user password

**Application namespaces (`staging`, `prod`):**
- `order-db-credentials` - Order service database password
- `customer-db-credentials` - Customer service database password

**Manual secret creation:**

```bash
# Generate secure passwords
openssl rand -base64 32

# Create secrets manually
kubectl create secret generic postgres-credentials \
  --from-literal=postgres-password=<password> \
  -n infra

kubectl create secret generic order-db-credentials \
  --from-literal=password=<password> \
  -n staging
```

**Production Best Practices:**
- Use external-secrets-operator or sealed-secrets
- Store passwords in HashiCorp Vault or AWS Secrets Manager
- Rotate credentials regularly
- Never commit secrets to git

## Resource Management

**k8s Pod Resource Requests (distributed across nodes):**

| Component        | Memory  | CPU   | Type        |
| ---------------- | ------- | ----- | ----------- |
| postgres         | 192Mi   | 500m  | StatefulSet |
| kafka            | 192Mi   | 500m  | StatefulSet |
| server           | 64Mi    | 100m  | Deployment  |
| order-service    | 64Mi    | 100m  | Deployment  |
| customer-service | 64Mi    | 100m  | Deployment  |
| valkey           | 128Mi   | 100m  | Deployment  |
| temporal         | 256Mi   | 250m  | Deployment  |
| otel-collector   | 64Mi    | 100m  | Deployment  |
| prometheus       | 256Mi   | 250m  | Deployment  |
| grafana          | 128Mi   | 100m  | Deployment  |

**Total Cluster Capacity:** 4 nodes × ~906MB RAM = ~3.5GB total memory

**Postgres Connection Pool Coordination:**

With a shared Postgres instance, coordinate pool sizes across services to stay under `max_connections=100`:

| Service          | Pool Size | Reason                          |
| ---------------- | --------- | ------------------------------- |
| Order Service    | 10        | Temporal workflows, main writes |
| Customer Service | 10        | Kafka consumer, stats updates   |
| Temporal         | 30        | 20 default + 10 visibility      |
| Reserve          | ~50       | Headroom, admin, migrations     |

Each service connects to its own database using database-per-service pattern:

```yaml
env:
  - name: DB_HOST
    value: "postgresql.infra.svc.cluster.local"
  - name: DB_NAME
    value: "order_db"  # Separate database per service
  - name: DB_USER
    value: "order_service"
  - name: DB_POOL_SIZE
    value: "10"
```

## Service Discovery

All services use in-cluster DNS for service discovery:

```
postgresql.infra.svc.cluster.local:5432
kafka.infra.svc.cluster.local:9092
valkey.infra.svc.cluster.local:6379
temporal.infra.svc.cluster.local:7233
otel-collector.monitoring.svc.cluster.local:4317
order.staging.svc.cluster.local:50051
customer.staging.svc.cluster.local:50051
```

Format: `<service>.<namespace>.svc.cluster.local:<port>`

## Database Migrations

The order-service and customer-service charts use Helm hooks for migrations:

- Migrations run as a Job with `helm.sh/hook: pre-install,pre-upgrade`
- The Job runs once before the Deployment updates
- Replicas start only after migration succeeds
- Failed migration Jobs are preserved for debugging

**Migration Job Configuration:**

```yaml
migration:
  enabled: true
  command: ["migrate"]
  args: ["-y"]  # Auto-confirm migrations
  backoffLimit: 3
```

**Debugging Failed Migrations:**

```bash
# Check migration job status
kubectl get jobs -n staging

# View migration logs
kubectl logs -n staging job/order-migration

# Delete failed job to retry
kubectl delete job order-migration -n staging

# Re-run migration
helm upgrade order ./charts/order -n staging
```

## Useful Commands

### Helmfile Commands

```bash
# Preview changes before applying
make diff-staging

# Deploy single release
helmfile -f helmfile-apps.yaml -e staging -l name=server sync

# View rendered manifests
helmfile -f helmfile-apps.yaml -e staging template

# List releases
helmfile -f helmfile-apps.yaml -e staging list
```

### Helm Commands

```bash
# Rollback a release
helm rollback server 1 -n staging

# View release history
helm history server -n staging

# Get release values
helm get values server -n staging
```

### kubectl Commands

```bash
# View all resources
make status

# Check pod logs
kubectl logs -n staging deployment/order -f

# Port forward to service
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Execute command in pod
kubectl exec -n infra postgresql-0 -- psql -U postgres -c '\l'

# Debug DNS resolution
kubectl run -it --rm debug --image=nicolaka/netshoot -- \
  nslookup postgresql.infra.svc.cluster.local
```

## Troubleshooting

### Pods Not Starting

**Check pod status:**
```bash
kubectl get pods -n staging
kubectl describe pod <pod-name> -n staging
```

**Common issues:**
- ImagePullBackOff: Image doesn't exist or registry not accessible
- CrashLoopBackOff: Application crashing on startup, check logs
- Pending: Insufficient resources, check `kubectl describe node`

### Database Connection Failures

**Verify database is running:**
```bash
kubectl get pods -n infra | grep postgres
kubectl logs -n infra postgresql-0
```

**Test connection from pod:**
```bash
kubectl run -it --rm psql --image=postgres:17 -- \
  psql -h postgresql.infra.svc.cluster.local -U postgres
```

**Check credentials:**
```bash
kubectl get secret postgres-credentials -n infra -o yaml
```

### Migration Job Failures

**View migration logs:**
```bash
kubectl logs -n staging job/order-migration
```

**Common issues:**
- Database not ready: Wait for postgres pod to be Running
- Wrong credentials: Check secret exists and has correct password
- Migration conflicts: Previous migration failed mid-transaction

### Service Discovery Issues

**Test DNS resolution:**
```bash
kubectl run -it --rm debug --image=nicolaka/netshoot -- \
  nslookup order.staging.svc.cluster.local
```

**Check service endpoints:**
```bash
kubectl get endpoints -n staging order
```

**Verify service is running:**
```bash
kubectl get pods -n staging -l app=order
```

### Insufficient Resources

**Check node resources:**
```bash
kubectl describe nodes
kubectl top nodes
kubectl top pods --all-namespaces
```

**Solutions:**
- Reduce replica counts in staging
- Lower resource requests/limits
- Add more cluster nodes

### Grafana Access

**Port forward to Grafana:**
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

**Default credentials:**
- Username: `admin`
- Password: `admin` (change in production!)

**Visit:** http://localhost:3000

### Persistent Volume Issues

**Check PVs and PVCs:**
```bash
kubectl get pv,pvc --all-namespaces
```

**If PVC stuck in Pending:**
- Check storage class exists: `kubectl get storageclass`
- For k3s, local-path provisioner should auto-create PVs
- Check provisioner logs: `kubectl logs -n kube-system -l app=local-path-provisioner`
