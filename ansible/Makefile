.PHONY: help deps ping setup install reset check

help:
	@echo "Raspberry Pi k3s Cluster Management"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  deps     Install required Ansible collections"
	@echo "  ping     Test connectivity to all Pis"
	@echo "  check    Dry-run full setup (no changes)"
	@echo "  setup    Full setup: prepare nodes + install k3s"
	@echo "  install  Install k3s only (nodes already prepared)"
	@echo "  reset    Tear down cluster (DESTRUCTIVE)"
	@echo ""

deps:
	ansible-galaxy collection install -r requirements.yml --upgrade

ping:
	ansible all -m ping

check:
	ansible-playbook playbooks/site.yaml --check --diff

setup:
	ansible-playbook playbooks/site.yaml

install:
	ansible-playbook playbooks/k3s-install.yaml

reset:
	ansible-playbook playbooks/k3s-reset.yaml
