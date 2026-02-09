.PHONY: help deps secrets build-all build-server build-order build-customer \
        deploy-infra deploy-monitoring deploy-staging deploy-prod deploy-all \
        diff-infra diff-monitoring diff-staging diff-prod \
        destroy-infra destroy-monitoring destroy-staging destroy-prod \
        status verify clean

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Prerequisites

deps: ## Install helmfile and required helm plugins
	@echo "Installing helmfile..."
	@if ! command -v helmfile &> /dev/null; then \
		echo "helmfile not found. Installing via brew..."; \
		brew install helmfile; \
	else \
		echo "helmfile already installed: $$(helmfile --version)"; \
	fi
	@echo ""
	@echo "Installing helm plugins..."
	@helm plugin install https://github.com/databus23/helm-diff || echo "helm-diff already installed"
	@helm plugin install https://github.com/jkroepke/helm-secrets || echo "helm-secrets already installed"
	@echo ""
	@echo "✓ All dependencies installed"

secrets: ## Create Kubernetes secrets interactively
	@echo "=== Creating Kubernetes Secrets ==="
	@echo ""
	@echo "This will create secrets for:"
	@echo "  - PostgreSQL master credentials (infra namespace)"
	@echo "  - PostgreSQL user credentials for order/customer services"
	@echo "  - Temporal database credentials"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		./scripts/create-secrets.sh; \
	else \
		echo "Cancelled."; \
	fi

##@ Docker Images

build-all: build-server build-order build-customer ## Build all service Docker images

build-server: ## Build server service Docker image
	@echo "Building server image..."
	cd ../service-server && $(MAKE) docker-build

build-order: ## Build order service Docker image
	@echo "Building order service image..."
	cd ../service-order && $(MAKE) docker-build

build-customer: ## Build customer service Docker image
	@echo "Building customer service image..."
	cd ../service-customer && $(MAKE) docker-build

##@ Deployment

deploy-infra: ## Deploy infrastructure (postgres, kafka, valkey, temporal)
	@echo "Deploying infrastructure..."
	helmfile -f helmfile-infra.yaml sync
	@echo ""
	@echo "✓ Infrastructure deployed"
	@echo "  Run 'make verify' to check status"

deploy-monitoring: ## Deploy monitoring stack (otel, prometheus, grafana)
	@echo "Deploying monitoring stack..."
	helmfile -f helmfile-monitoring.yaml sync
	@echo ""
	@echo "✓ Monitoring deployed"
	@echo "  Access Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
	@echo "  Default credentials: admin / admin"

deploy-staging: ## Deploy applications to staging environment
	@echo "Deploying applications to staging..."
	helmfile -f helmfile-apps.yaml -e staging sync
	@echo ""
	@echo "✓ Staging deployed"
	@echo "  Namespace: staging"

deploy-prod: ## Deploy applications to production environment
	@echo "Deploying applications to production..."
	helmfile -f helmfile-apps.yaml -e prod sync
	@echo ""
	@echo "✓ Production deployed"
	@echo "  Namespace: prod"

deploy-all: deploy-infra deploy-monitoring deploy-staging ## Deploy everything (infra + monitoring + staging)
	@echo ""
	@echo "========================================="
	@echo "✓ Full deployment complete!"
	@echo "========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  1. Verify deployment: make verify"
	@echo "  2. Check logs: kubectl logs -n staging deployment/order -f"
	@echo "  3. Access Grafana: kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80"
	@echo ""

##@ Preview Changes

diff-infra: ## Preview infrastructure changes
	helmfile -f helmfile-infra.yaml diff

diff-monitoring: ## Preview monitoring stack changes
	helmfile -f helmfile-monitoring.yaml diff

diff-staging: ## Preview staging application changes
	helmfile -f helmfile-apps.yaml -e staging diff

diff-prod: ## Preview production application changes
	helmfile -f helmfile-apps.yaml -e prod diff

##@ Teardown

destroy-infra: ## Destroy infrastructure (WARNING: deletes persistent data)
	@echo "========================================="
	@echo "WARNING: This will delete ALL infrastructure"
	@echo "including persistent data (databases, kafka topics)"
	@echo "========================================="
	@echo ""
	@read -p "Are you absolutely sure? Type 'yes' to confirm: " -r; \
	echo; \
	if [ "$$REPLY" = "yes" ]; then \
		helmfile -f helmfile-infra.yaml destroy; \
		echo "✓ Infrastructure destroyed"; \
	else \
		echo "Cancelled."; \
	fi

destroy-monitoring: ## Destroy monitoring stack
	@echo "Destroying monitoring stack..."
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		helmfile -f helmfile-monitoring.yaml destroy; \
		echo "✓ Monitoring destroyed"; \
	else \
		echo "Cancelled."; \
	fi

destroy-staging: ## Destroy staging applications
	@echo "Destroying staging applications..."
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		helmfile -f helmfile-apps.yaml -e staging destroy; \
		echo "✓ Staging destroyed"; \
	else \
		echo "Cancelled."; \
	fi

destroy-prod: ## Destroy production applications
	@echo "Destroying production applications..."
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		helmfile -f helmfile-apps.yaml -e prod destroy; \
		echo "✓ Production destroyed"; \
	else \
		echo "Cancelled."; \
	fi

##@ Utilities

status: ## Show all k8s resources across namespaces
	@echo "=== Infrastructure (infra namespace) ==="
	@kubectl get all,pvc,secrets -n infra 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Monitoring (monitoring namespace) ==="
	@kubectl get all,pvc -n monitoring 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Staging (staging namespace) ==="
	@kubectl get all,jobs -n staging 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Production (prod namespace) ==="
	@kubectl get all,jobs -n prod 2>/dev/null || echo "Namespace not found"

verify: ## Verify cluster health and pod status
	@echo "=== Cluster Nodes ==="
	@kubectl get nodes -o wide
	@echo ""
	@echo "=== Infrastructure Pods ==="
	@kubectl get pods -n infra -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Monitoring Pods ==="
	@kubectl get pods -n monitoring -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Staging Pods ==="
	@kubectl get pods -n staging -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Production Pods ==="
	@kubectl get pods -n prod -o wide 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Persistent Volumes ==="
	@kubectl get pv,pvc --all-namespaces
	@echo ""
	@echo "=== Failed Pods (if any) ==="
	@kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null || echo "No failed pods"

clean: ## Remove helmfile lock files
	@echo "Removing helmfile lock files..."
	@rm -f helmfile-*.lock
	@echo "✓ Lock files removed"
