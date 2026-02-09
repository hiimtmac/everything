#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Kubernetes Secrets Creation ===${NC}"
echo ""
echo "This script will create secrets for:"
echo "  - PostgreSQL master password (infra namespace)"
echo "  - PostgreSQL user passwords (per-env for order/customer, shared for temporal)"
echo "  - Application secrets (staging and prod namespaces)"
echo ""

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to create or update a single-key secret
create_secret() {
    local namespace=$1
    local secret_name=$2
    local key=$3
    local value=$4

    if ! kubectl get namespace "$namespace" &> /dev/null; then
        echo -e "${YELLOW}Creating namespace: $namespace${NC}"
        kubectl create namespace "$namespace"
    fi

    if kubectl get secret "$secret_name" -n "$namespace" &> /dev/null; then
        echo -e "${YELLOW}Secret $secret_name already exists in $namespace. Skipping...${NC}"
        return 0
    fi

    kubectl create secret generic "$secret_name" \
        --from-literal="$key=$value" \
        -n "$namespace"

    echo -e "${GREEN}✓ Created secret: $secret_name in namespace $namespace${NC}"
}

echo "=== Step 1: Infrastructure Secrets (infra namespace) ==="
echo ""

# PostgreSQL master password
echo "Enter PostgreSQL master password (leave empty to generate):"
read -s -p "postgres password: " POSTGRES_PASSWORD
echo ""
if [ -z "$POSTGRES_PASSWORD" ]; then
    POSTGRES_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for postgres${NC}"
fi
create_secret "infra" "postgres-credentials" "postgres-password" "$POSTGRES_PASSWORD"
echo ""

# Temporal database password (shared across envs)
echo "Enter temporal database password (leave empty to generate):"
read -s -p "temporal password: " TEMPORAL_PASSWORD
echo ""
if [ -z "$TEMPORAL_PASSWORD" ]; then
    TEMPORAL_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for temporal${NC}"
fi
create_secret "infra" "temporal-credentials" "password" "$TEMPORAL_PASSWORD"
echo ""

# Per-environment order service passwords
echo "Enter order_service_staging database password (leave empty to generate):"
read -s -p "order staging password: " ORDER_STAGING_PASSWORD
echo ""
if [ -z "$ORDER_STAGING_PASSWORD" ]; then
    ORDER_STAGING_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for order_service_staging${NC}"
fi

echo "Enter order_service_prod database password (leave empty to generate):"
read -s -p "order prod password: " ORDER_PROD_PASSWORD
echo ""
if [ -z "$ORDER_PROD_PASSWORD" ]; then
    ORDER_PROD_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for order_service_prod${NC}"
fi

# Per-environment customer service passwords
echo "Enter customer_service_staging database password (leave empty to generate):"
read -s -p "customer staging password: " CUSTOMER_STAGING_PASSWORD
echo ""
if [ -z "$CUSTOMER_STAGING_PASSWORD" ]; then
    CUSTOMER_STAGING_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for customer_service_staging${NC}"
fi

echo "Enter customer_service_prod database password (leave empty to generate):"
read -s -p "customer prod password: " CUSTOMER_PROD_PASSWORD
echo ""
if [ -z "$CUSTOMER_PROD_PASSWORD" ]; then
    CUSTOMER_PROD_PASSWORD=$(generate_password)
    echo -e "${GREEN}Generated password for customer_service_prod${NC}"
fi

# postgres-service-credentials — injected as env vars into the postgres init container
echo ""
echo "Creating postgres-service-credentials (used by DB init script)..."
if kubectl get secret "postgres-service-credentials" -n "infra" &> /dev/null; then
    echo -e "${YELLOW}Secret postgres-service-credentials already exists in infra. Skipping...${NC}"
else
    kubectl create secret generic postgres-service-credentials \
        --from-literal="ORDER_SERVICE_STAGING_PASSWORD=$ORDER_STAGING_PASSWORD" \
        --from-literal="ORDER_SERVICE_PROD_PASSWORD=$ORDER_PROD_PASSWORD" \
        --from-literal="CUSTOMER_SERVICE_STAGING_PASSWORD=$CUSTOMER_STAGING_PASSWORD" \
        --from-literal="CUSTOMER_SERVICE_PROD_PASSWORD=$CUSTOMER_PROD_PASSWORD" \
        --from-literal="TEMPORAL_PASSWORD=$TEMPORAL_PASSWORD" \
        -n "infra"
    echo -e "${GREEN}✓ Created secret: postgres-service-credentials in namespace infra${NC}"
fi

echo ""
echo "=== Step 2: Application Secrets (staging namespace) ==="
echo ""

create_secret "staging" "order-db-credentials" "password" "$ORDER_STAGING_PASSWORD"
create_secret "staging" "customer-db-credentials" "password" "$CUSTOMER_STAGING_PASSWORD"

echo ""
echo "=== Step 3: Application Secrets (prod namespace) ==="
echo ""

create_secret "prod" "order-db-credentials" "password" "$ORDER_PROD_PASSWORD"
create_secret "prod" "customer-db-credentials" "password" "$CUSTOMER_PROD_PASSWORD"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ All secrets created successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Summary:"
echo "  - infra namespace: postgres-credentials, temporal-credentials, postgres-service-credentials"
echo "  - staging namespace: order-db-credentials, customer-db-credentials"
echo "  - prod namespace: order-db-credentials, customer-db-credentials"
echo ""
echo "IMPORTANT: Save these credentials securely!"
echo ""
echo "To view secrets:"
echo "  kubectl get secrets -n infra"
echo "  kubectl get secret postgres-credentials -n infra -o jsonpath='{.data.postgres-password}' | base64 -d"
echo ""
echo "Next steps:"
echo "  1. Deploy infrastructure: make deploy-infra"
echo "  2. Verify postgres: kubectl logs -n infra postgresql-0"
echo "  3. Register Temporal namespaces (after Temporal is healthy):"
echo "       kubectl exec -n infra deployment/temporal-admintools -- tctl namespace register staging"
echo "       kubectl exec -n infra deployment/temporal-admintools -- tctl namespace register prod"
echo "     The order service TEMPORAL_CLIENT_NAMESPACE / TEMPORAL_WORKER_NAMESPACE env vars"
echo "     must match a registered namespace or the worker will fail to connect."
echo "  4. Deploy monitoring: make deploy-monitoring"
echo "  5. Build images: make build-all"
echo "  6. Deploy apps: make deploy-staging"
echo ""
