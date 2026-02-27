SHELL := /bin/bash

REPO_URL ?= $(shell git remote get-url origin 2>/dev/null)
REPO_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)

INVENTORY ?= ansible/inventory/hosts.ini
PLAYBOOK ?= ansible/playbooks/site.yml

.PHONY: all bootstrap check argocd-password

check-prereqs:
	@test "$$(uname -s)" = "Linux" || (echo "ERROR: this playbook must run on a Linux host. k3s does not support macOS."; exit 1)
	@command -v ansible-playbook > /dev/null 2>&1 || (echo "ERROR: ansible-playbook not found. Install it with: pip3 install ansible"; exit 1)
	@test -n "$(REPO_URL)" || (echo "ERROR: no git remote 'origin' found. Run: git remote add origin <your-repo-url>"; exit 1)

all: bootstrap check

bootstrap: check-prereqs
	@echo "Using repo: $(REPO_URL) (branch: $(REPO_BRANCH))"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) -K -e repo_url=$(REPO_URL) -e repo_branch=$(REPO_BRANCH)

check:
	@echo ""
	@echo "=== Cluster Nodes ==="
	@k3s kubectl get nodes -o wide
	@echo ""
	@echo "=== ArgoCD Sync Status ==="
	@k3s kubectl -n argocd get applications.argoproj.io web-nginx -o jsonpath='{.status.sync.status} / health: {.status.health.status}' && echo
	@echo ""
	@echo "=== Web App Resources ==="
	@k3s kubectl -n web get pods,svc
	@echo ""
	@echo "=== Application Reachability ==="
	@NODE_IP=$$(k3s kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}'); \
	 echo "Checking http://$$NODE_IP:30080 ..."; \
	 curl -sf --max-time 5 http://$$NODE_IP:30080 > /dev/null && echo "OK - application responded" || echo "FAIL - application did not respond"

argocd-password:
	@echo "ArgoCD admin password:"
	@k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
