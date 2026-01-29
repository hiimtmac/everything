.PHONY: help deps ping k3s-setup k3s-install k3s-reset k3s-check update docker-setup infra infra-check

help:
	@echo "Raspberry Pi k3s Cluster Management"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "General:"
	@echo "  deps           Install required Ansible collections"
	@echo "  ping           Test connectivity to all Pis"
	@echo "  update         Update system packages (one node at a time)"
	@echo ""
	@echo "k3s Cluster:"
	@echo "  k3s-setup      Full setup: prepare nodes + install k3s"
	@echo "  k3s-install    Install k3s only (nodes already prepared)"
	@echo "  k3s-check      Dry-run k3s setup (no changes)"
	@echo "  k3s-reset      Tear down cluster (DESTRUCTIVE)"
	@echo ""
	@echo "Infrastructure (Postgres, Kafka on control node):"
	@echo "  docker-setup   Install Docker on control node (one-time)"
	@echo "  infra          Deploy/update infrastructure containers"
	@echo "  infra-check    Dry-run infrastructure deployment"
	@echo ""
	@echo "NOTE: Running Docker on control node simulates managed services."
	@echo "In production, use RDS/MSK or dedicated clusters instead."
	@echo ""

deps:
	ansible-galaxy collection install -r requirements.yml --upgrade

ping:
	ansible all -m ping

update:
	ansible-playbook playbooks/update.yaml

# k3s cluster targets
k3s-setup:
	ansible-playbook playbooks/site.yaml

k3s-install:
	ansible-playbook playbooks/k3s-install.yaml

k3s-check:
	ansible-playbook playbooks/site.yaml --check --diff

k3s-reset:
	ansible-playbook playbooks/k3s-reset.yaml

# Infrastructure targets (Docker on control node)
docker-setup:
	ansible-playbook playbooks/docker-setup.yaml

infra:
	ansible-playbook playbooks/infrastructure.yaml

infra-check:
	ansible-playbook playbooks/infrastructure.yaml --check --diff
