# DevContainer Images

[![CI/CD Pipeline](https://github.com/ironwolphern/devcontainer-images/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/ci-cd.yml)
[![Security Scan](https://github.com/ironwolphern/devcontainer-images/actions/workflows/security-scan.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/security-scan.yml)
[![Dependency Update](https://github.com/ironwolphern/devcontainer-images/actions/workflows/dependency-update.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/dependency-update.yml)

This repository contains optimized Docker images that are automatically updated for development with different technologies and programming languages.

## 📦 Available Images

| Technology | Current Version | Description | Included Tools |
|------------|----------------|-------------|----------------|
| [Ansible](./images/ansible/) | Ansible 11.7 | Automation development environment | Ansible, ansible-dev-tools, ansible-lint, molecule, pytest |
| [Python](./images/python/) | Python 3.13 | Complete Python development environment | pytest, black, flake8, bandit, fastapi, django |
| [Terraform](./images/terraform/) | Terraform 1.12.2 | IaC development environment | Terraform, Terragrunt, TFLint, Checkov |
| [Go](./images/go/) | Go 1.23 | Go development environment | gopls, golangci-lint, gosec, delve |

## 🚀 Quick Start

### With Make (Recommended)

```bash
# View current versions
make versions

# Build all images
make build-all

# Build specific image
make build-python

# Test all images
make test-all

# Run specific image
make run-python
```

### Custom Versions

```bash
# Build with specific versions
make build-python PYTHON_VERSION=3.13
make build-go GO_VERSION=1.23
make build-terraform TERRAFORM_VERSION=1.12.2
```

### Docker Compose

```yaml
version: '3.8'

services:
  python-dev:
    image: ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest
    volumes:
      - .:/workspace
    working_dir: /workspace
```

## 🔄 CI/CD and Automation

### Automated Workflows

- **🔨 CI/CD Pipeline**: Automatic build, test and push on changes
- **🛡️ Security Scan**: Daily security analysis with Trivy and Hadolint
- **📦 Dependency Update**: Weekly automatic dependency updates
- **🚀 Release**: Automatic release creation with versioned tags

### Automatic Updates

Images are automatically updated:
- **Weekly**: Tool and dependency versions
- **Daily**: Security analysis
- **On each commit**: Build and integration tests

## Common Features

All images follow security and optimization best practices:

- ✅ **Multi-stage builds** to reduce final size
- ✅ **Non-root users** for enhanced security
- ✅ **Health checks** included
- ✅ **Testing and security tools**
- ✅ **Docker cache optimization**
- ✅ **Official base images** and specific versions

## ⚙️ Version Configuration

Versions are parameterized and can be configured:

### Makefile Environment Variables

```bash
export PYTHON_VERSION=3.13
export GO_VERSION=1.23
export TERRAFORM_VERSION=1.12.2
export ALPINE_VERSION=3.20
```

### Docker Build Args

```bash
docker build --build-arg PYTHON_VERSION=3.13 -t my-python ./images/python
docker build --build-arg GO_VERSION=1.23 -t my-go ./images/go
```

## 🛡️ Security and Quality

### Automated Analysis

- **Trivy**: Vulnerability scanning in images
- **Grype**: Additional security analysis  
- **Hadolint**: Dockerfile linting
- **Safety**: Python dependency verification
- **TruffleHog**: Secret detection

### Implemented Best Practices

- ✅ **Non-root users** in all images
- ✅ **Multi-stage builds** for optimization
- ✅ **Health checks** included
- ✅ **Automated security analysis**
- ✅ **Fixed dependency versions**
- ✅ **Verified official base images**

## 📚 DevContainer Support

All images are optimized for VS Code DevContainers:

```json
{
  "name": "Python DevContainer",
  "image": "ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-functionality`
3. Follow the best practices defined in `.github/instructions/`
4. Run tests: `make test-all`
5. Run linting: `hadolint images/*/Dockerfile`
6. Create a Pull Request

### Local Development

```bash
# Open in DevContainer (VS Code)
code .

# Or use directly
make build-all
make test-all
```

## 📋 Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR**: Incompatible API changes
- **MINOR**: New backwards-compatible functionality
- **PATCH**: Bug fixes and security updates

## 🔗 Useful Links

- [Docker Hub](https://hub.docker.com/u/ironwolphern)
- [GitHub Container Registry](https://github.com/ironwolphern/devcontainer-images/pkgs/container)
- [DevContainers Specification](https://containers.dev/)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)

## 📄 License

See [LICENSE](LICENSE) for more details.

---

**Maintained by**: [@ironwolphern](https://github.com/ironwolphern)  
**Last updated**: July 2025
