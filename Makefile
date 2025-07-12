# DevContainer Images Makefile

# Variables
REGISTRY ?= localhost
TAG ?= latest
IMAGES = ansible python terraform go

# Version variables (can be overridden)
PYTHON_VERSION ?= 3.12
ANSIBLE_VERSION ?= 11.7
GO_VERSION ?= 1.23
ALPINE_VERSION ?= 3.20
TERRAFORM_VERSION ?= 1.12.2
TERRAGRUNT_VERSION ?= 0.67.16
TFLINT_VERSION ?= 0.53.0
CHECKOV_VERSION ?= 3.2.255
TERRASCAN_VERSION ?= 0.2.3

# Build arguments for each image
ANSIBLE_BUILD_ARGS = --build-arg PYTHON_VERSION=$(PYTHON_VERSION)
PYTHON_BUILD_ARGS = --build-arg PYTHON_VERSION=$(PYTHON_VERSION)
TERRAFORM_BUILD_ARGS = --build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
                       --build-arg TERRAFORM_VERSION=$(TERRAFORM_VERSION) \
                       --build-arg TERRAGRUNT_VERSION=$(TERRAGRUNT_VERSION) \
                       --build-arg TFLINT_VERSION=$(TFLINT_VERSION) \
                       --build-arg CHECKOV_VERSION=$(CHECKOV_VERSION)
GO_BUILD_ARGS = --build-arg GO_VERSION=$(GO_VERSION) \
                --build-arg ALPINE_VERSION=$(ALPINE_VERSION)

# Default target
.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: versions
versions: ## Show current versions
	@echo "📦 Current Versions:"
	@echo "  Python:     $(PYTHON_VERSION)"
	@echo "  Ansible:    $(ANSIBLE_VERSION)"
	@echo "  Go:         $(GO_VERSION)"
	@echo "  Alpine:     $(ALPINE_VERSION)"
	@echo "  Terraform:  $(TERRAFORM_VERSION)"
	@echo "  Terragrunt: $(TERRAGRUNT_VERSION)"
	@echo "  TFLint:     $(TFLINT_VERSION)"
	@echo "  Checkov:    $(CHECKOV_VERSION)"

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

.PHONY: test-terraform
test-terraform: build-terraform ## Test Terraform image
	@echo "Testing Terraform image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terraform version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) terragrunt --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-terraform:$(TAG) tflint --version

.PHONY: test-go
test-go: build-go ## Test Go image
	@echo "Testing Go image..."
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) go version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) golangci-lint --version
	export DOCKER_HOST=unix:///var/run/docker.sock && docker run --rm $(REGISTRY)/devcontainer-go:$(TAG) gopls version

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
