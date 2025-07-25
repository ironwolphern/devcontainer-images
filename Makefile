# DevContainer Images Makefile

# Variables
REGISTRY ?= localhost
TAG ?= latest
IMAGES = ansible python terraform go

# Version variables (can be overridden)
PYTHON_VERSION ?= 3.13
ANSIBLE_VERSION ?= 11.7
GO_VERSION ?= 1.24
ALPINE_VERSION ?= 3.22
TERRAFORM_VERSION ?= 1.12.2
TERRAGRUNT_VERSION ?= 0.83.2
TFLINT_VERSION ?= 0.58.1
CHECKOV_VERSION ?= 3.2.451
TERRASCAN_VERSION ?= 0.2.3
TERRAFORM_DOCS_VERSION ?= 0.20.0
TFSEC_VERSION ?= 1.28.14
COSIGN_VERSION ?= 2.5.3

# Build arguments for each image
ANSIBLE_BUILD_ARGS = --build-arg PYTHON_VERSION=$(PYTHON_VERSION)
PYTHON_BUILD_ARGS = --build-arg PYTHON_VERSION=$(PYTHON_VERSION)
TERRAFORM_BUILD_ARGS = --build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
                       --build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
                       --build-arg TERRAGRUNT_VERSION=$(TERRAGRUNT_VERSION) \
                       --build-arg TFLINT_VERSION=$(TFLINT_VERSION) \
                       --build-arg CHECKOV_VERSION=$(CHECKOV_VERSION) \
					   --build-arg TERRASCAN_VERSION=$(TERRASCAN_VERSION) \
					   --build-arg TERRAFORM_DOCS_VERSION=$(TERRAFORM_DOCS_VERSION) \
					   --build-arg TFSEC_VERSION=$(TFSEC_VERSION)
GO_BUILD_ARGS = --build-arg GO_VERSION=$(GO_VERSION) \
                --build-arg ALPINE_VERSION=$(ALPINE_VERSION)

# Default target
.PHONY: help
help: ## Show this help message
	@echo "DevContainer Images - Makefile Help"
	@echo ""
	@echo "📦 BUILD TARGETS:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(build|push|pull)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧪 TEST TARGETS:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(test|scan|verify)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🔧 TROUBLESHOOTING:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(check|diagnose|troubleshoot|fix|debug|trigger)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🛠️  UTILITIES:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v -E "(build|push|pull|test|scan|verify|check|diagnose|troubleshoot|fix|debug|trigger)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🔄 IMAGE MANAGEMENT:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "(clean|remove|prune|list|images|tags)" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: versions
versions: ## Show current versions
	@echo "📦 Current Versions:"
	@echo "  Python:         $(PYTHON_VERSION)"
	@echo "  Ansible:        $(ANSIBLE_VERSION)"
	@echo "  Go:             $(GO_VERSION)"
	@echo "  Terraform:      $(TERRAFORM_VERSION)"
	@echo "  Cosign:         $(COSIGN_VERSION)"

# Build targets
.PHONY: build-all
build-all: $(addprefix build-,$(IMAGES)) ## Build all images

.PHONY: build-ansible
build-ansible: ## Build Ansible image
	@echo "Building Ansible image with Python $(PYTHON_VERSION)..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker build $(ANSIBLE_BUILD_ARGS) -t $(REGISTRY)/devcontainer-ansible:$(TAG) images/ansible/

.PHONY: build-python
build-python: ## Build Python image
	@echo "Building Python image with Python $(PYTHON_VERSION)..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker build $(PYTHON_BUILD_ARGS) -t $(REGISTRY)/devcontainer-python:$(TAG) images/python/

.PHONY: build-terraform
build-terraform: ## Build Terraform image
	@echo "Building Terraform image with Terraform $(TERRAFORM_VERSION)..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker build $(TERRAFORM_BUILD_ARGS) -t $(REGISTRY)/devcontainer-terraform:$(TAG) images/terraform/

.PHONY: build-go
build-go: ## Build Go image
	@echo "Building Go image with Go $(GO_VERSION)..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker build $(GO_BUILD_ARGS) -t $(REGISTRY)/devcontainer-go:$(TAG) images/go/

# Test targets
.PHONY: test-all
test-all: $(addprefix test-,$(IMAGES)) ## Test all images

.PHONY: test-ansible
test-ansible: build-ansible ## Test Ansible image
	@echo "Testing Ansible image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-ansible:$(TAG) ansible --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-ansible:$(TAG) ansible-lint --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-ansible:$(TAG) molecule --version

.PHONY: test-python
test-python: build-python ## Test Python image
	@echo "Testing Python image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-python:$(TAG) python --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-python:$(TAG) pytest --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-python:$(TAG) black --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-python:$(TAG) bandit --version

.PHONY: test-terraform
test-terraform: build-terraform ## Test Terraform image
	@echo "Testing Terraform image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terraform version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terragrunt --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) tflint --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) checkov --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terrascan --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) tfsec --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terraform-docs --version

.PHONY: test-go
test-go: build-go ## Test Go image
	@echo "Testing Go image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) go version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) golangci-lint --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) gosec -version

# Push targets
.PHONY: push-all
push-all: $(addprefix push-,$(IMAGES)) ## Push all images

.PHONY: push-ansible
push-ansible: build-ansible ## Push Ansible image
	export DOCKER_HOST=unix:///var/run/docker.sock && docker push $(REGISTRY)/devcontainer-ansible:$(TAG)

.PHONY: push-python
push-python: build-python ## Push Python image
	export DOCKER_HOST=unix:///var/run/docker.sock && docker push $(REGISTRY)/devcontainer-python:$(TAG)

.PHONY: push-terraform
push-terraform: build-terraform ## Push Terraform image
	export DOCKER_HOST=unix:///var/run/docker.sock && docker push $(REGISTRY)/devcontainer-terraform:$(TAG)

.PHONY: push-go
push-go: build-go ## Push Go image
	export DOCKER_HOST=unix:///var/run/docker.sock && docker push $(REGISTRY)/devcontainer-go:$(TAG)

# Clean targets
.PHONY: clean
clean: ## Remove all built images
	@echo "Cleaning up images..."
	-export DOCKER_HOST=unix:///var/run/docker.sock && docker rmi $(REGISTRY)/devcontainer-ansible:$(TAG)
	-export DOCKER_HOST=unix:///var/run/docker.sock && docker rmi $(REGISTRY)/devcontainer-python:$(TAG)
	-export DOCKER_HOST=unix:///var/run/docker.sock && docker rmi $(REGISTRY)/devcontainer-terraform:$(TAG)
	-export DOCKER_HOST=unix:///var/run/docker.sock && docker rmi $(REGISTRY)/devcontainer-go:$(TAG)

.PHONY: prune
prune: ## Remove unused Docker resources
	export DOCKER_HOST=unix:///var/run/docker.sock && docker system prune -f

# Scan targets (security)
.PHONY: scan-all
scan-all: $(addprefix scan-,$(IMAGES)) ## Scan all images for vulnerabilities

.PHONY: scan-ansible
scan-ansible: build-ansible ## Scan Ansible image
	@echo "Scanning Ansible image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image $(REGISTRY)/devcontainer-ansible:$(TAG)

.PHONY: scan-python
scan-python: build-python ## Scan Python image
	@echo "Scanning Python image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image $(REGISTRY)/devcontainer-python:$(TAG)

.PHONY: scan-terraform
scan-terraform: build-terraform ## Scan Terraform image
	@echo "Scanning Terraform image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image $(REGISTRY)/devcontainer-terraform:$(TAG)

.PHONY: scan-go
scan-go: build-go ## Scan Go image
	@echo "Scanning Go image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy image $(REGISTRY)/devcontainer-go:$(TAG)

# Development targets
.PHONY: run-ansible
run-ansible: build-ansible ## Run Ansible container interactively
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run -it --rm -v $(PWD):/workspace $(REGISTRY)/devcontainer-ansible:$(TAG)

.PHONY: run-python
run-python: build-python ## Run Python container interactively
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run -it --rm -v $(PWD):/workspace $(REGISTRY)/devcontainer-python:$(TAG)

.PHONY: run-terraform
run-terraform: build-terraform ## Run Terraform container interactively
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run -it --rm -v $(PWD):/workspace $(REGISTRY)/devcontainer-terraform:$(TAG)

.PHONY: run-go
run-go: build-go ## Run Go container interactively
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run -it --rm -v $(PWD):/workspace $(REGISTRY)/devcontainer-go:$(TAG)

# Signature verification targets
.PHONY: verify-signatures
verify-signatures: ## Verify signatures of all images
	@echo "🔍 Verificando firmas de todas las imágenes..."
	@./scripts/verify-signatures.sh --all

.PHONY: verify-signatures-with-sbom
verify-signatures-with-sbom: ## Verify signatures and SBOM of all images
	@echo "🔍 Verificando firmas y SBOM de todas las imágenes..."
	@./scripts/verify-signatures.sh --all --sbom

.PHONY: verify-ansible
verify-ansible: ## Verify Ansible image signature
	@echo "🔍 Verificando firma de imagen Ansible..."
	@./scripts/verify-signatures.sh ansible

.PHONY: verify-python
verify-python: ## Verify Python image signature
	@echo "🔍 Verificando firma de imagen Python..."
	@./scripts/verify-signatures.sh python

.PHONY: verify-terraform
verify-terraform: ## Verify Terraform image signature
	@echo "🔍 Verificando firma de imagen Terraform..."
	@./scripts/verify-signatures.sh terraform

.PHONY: verify-go
verify-go: ## Verify Go image signature
	@echo "🔍 Verificando firma de imagen Go..."
	@./scripts/verify-signatures.sh go

# Security audit targets
.PHONY: security-audit
security-audit: scan-all verify-signatures ## Complete security audit (scan + verify)
	@echo "✅ Auditoría de seguridad completada"

.PHONY: install-cosign
install-cosign: ## Install Cosign (requires sudo)
	@echo "📦 Instalando Cosign..."
	@curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
	@sudo mv cosign-linux-amd64 /usr/local/bin/cosign
	@sudo chmod +x /usr/local/bin/cosign
	@cosign version
	@echo "✅ Cosign instalado exitosamente"

# Troubleshooting targets
.PHONY: check-images
check-images: ## Check availability of all images in registry
	@echo "🔍 Verificando disponibilidad de imágenes..."
	@./scripts/verify-signatures.sh --check-available

.PHONY: list-tags
list-tags: ## List available tags for all images
	@echo "📋 Listando tags disponibles..."
	@for img in $(IMAGES); do \
		echo "=== devcontainer-$$img ==="; \
		./scripts/verify-signatures.sh --list-tags $$img || true; \
		echo ""; \
	done

.PHONY: check-registry-access
check-registry-access: ## Check access to container registry
	@echo "🔐 Verificando acceso al registro..."
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "❌ GITHUB_TOKEN no está configurado"; \
		exit 1; \
	fi
	@echo "$$GITHUB_TOKEN" | docker login ghcr.io -u $$GITHUB_USERNAME --password-stdin
	@echo "✅ Acceso al registro verificado"

.PHONY: trigger-build
trigger-build: ## Trigger manual build via GitHub CLI (requires gh CLI)
	@echo "🚀 Triggering manual build..."
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "❌ GitHub CLI (gh) no está instalado"; \
		exit 1; \
	fi
	@gh workflow run ci-cd.yml -f image=all -f push_images=true
	@echo "✅ Build triggeado. Verifica el progreso con: gh run list"

.PHONY: debug-workflow
debug-workflow: ## Show recent workflow runs
	@echo "📊 Workflows recientes:"
	@if command -v gh >/dev/null 2>&1; then \
		gh run list --limit 10; \
	else \
		echo "❌ GitHub CLI (gh) no está instalado"; \
	fi

.PHONY: quick-diagnose
quick-diagnose: ## Quick diagnosis of the current state
	@echo "🩺 Diagnóstico rápido del estado actual"
	@echo ""
	@echo "1. Verificando herramientas..."
	@echo -n "   Docker: "; command -v docker >/dev/null && echo "✅" || echo "❌"
	@echo -n "   Cosign: "; command -v cosign >/dev/null && echo "✅" || echo "❌"
	@echo -n "   GitHub CLI: "; command -v gh >/dev/null && echo "✅" || echo "❌"
	@echo ""
	@echo "2. Verificando variables de entorno..."
	@echo -n "   GITHUB_TOKEN: "; [ -n "$$GITHUB_TOKEN" ] && echo "✅" || echo "❌"
	@echo -n "   GITHUB_USERNAME: "; [ -n "$$GITHUB_USERNAME" ] && echo "✅" || echo "❌"
	@echo ""
	@echo "3. Verificando disponibilidad de imágenes..."
	@./scripts/verify-signatures.sh --check-available || true
	@echo ""
	@echo "4. Workflows recientes (si gh CLI está disponible):"
	@if command -v gh >/dev/null 2>&1; then \
		gh run list --limit 5 || true; \
	else \
		echo "   GitHub CLI no disponible"; \
	fi

.PHONY: fix-missing-images
fix-missing-images: ## Attempt to fix missing images by triggering build
	@echo "🔧 Intentando reparar imágenes faltantes..."
	@echo "1. Verificando estado actual..."
	@./scripts/verify-signatures.sh --check-available || echo "❌ Algunas imágenes no están disponibles"
	@echo ""
	@echo "2. Triggering build..."
	@$(MAKE) trigger-build
	@echo ""
	@echo "3. Esperando build (esto puede tomar varios minutos)..."
	@echo "   Puedes monitorear el progreso con: gh run list"
	@echo "   O visitar: https://github.com/ironwolphern/devcontainer-images/actions"

.PHONY: troubleshoot
troubleshoot: quick-diagnose ## Alias for quick-diagnose

.PHONY: health-check
health-check: ## Quick health check of tools, environment, and images
	@./scripts/health-check.sh

.PHONY: health-check-quiet
health-check-quiet: ## Health check with quiet output (exit code only)
	@./scripts/health-check.sh --quiet
