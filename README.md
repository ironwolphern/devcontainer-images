# DevContainer Images

[![CI/CD Pipeline](https://github.com/ironwolphern/devcontainer-images/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/ci-cd.yml)
[![Security Scan](https://github.com/ironwolphern/devcontainer-images/actions/workflows/security-scan.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/security-scan.yml)
[![Dependency Update](https://github.com/ironwolphern/devcontainer-images/actions/workflows/dependency-update.yml/badge.svg)](https://github.com/ironwolphern/devcontainer-images/actions/workflows/dependency-update.yml)

Este repositorio contiene imágenes Docker optimizadas y actualizadas automáticamente para desarrollo con diferentes tecnologías y lenguajes de programación.

## 📦 Imágenes Disponibles

| Tecnología | Versión Actual | Descripción | Herramientas Incluidas |
|------------|----------------|-------------|------------------------|
| [Ansible](./images/ansible/) | Ansible 11.7 | Entorno de desarrollo para automatización | Ansible 9.x, ansible-lint, molecule, pytest |
| [Python](./images/python/) | Python 3.12 | Entorno de desarrollo Python completo | pytest, black, flake8, bandit, fastapi, django |
| [Terraform](./images/terraform/) | Terraform 1.12.2 | Entorno de desarrollo IaC | Terraform, Terragrunt, TFLint, Checkov |
| [Go](./images/go/) | Go 1.23 | Entorno de desarrollo Go | gopls, golangci-lint, gosec, delve |

## 🚀 Uso Rápido

### Con Make (Recomendado)

```bash
# Ver versiones actuales
make versions

# Build todas las imágenes
make build-all

# Build imagen específica
make build-python

# Test todas las imágenes
make test-all

# Ejecutar imagen específica
make run-python
```

### Versiones Personalizadas

```bash
# Build con versiones específicas
make build-python PYTHON_VERSION=3.11
make build-go GO_VERSION=1.22
make build-terraform TERRAFORM_VERSION=1.11.0
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

## 🔄 CI/CD y Automatización

### Workflows Automatizados

- **🔨 CI/CD Pipeline**: Build, test y push automático en cambios
- **🛡️ Security Scan**: Análisis diario de seguridad con Trivy y Hadolint
- **📦 Dependency Update**: Actualización semanal automática de dependencias
- **🚀 Release**: Creación automática de releases con tags versionados

### Actualizaciones Automáticas

Las imágenes se actualizan automáticamente:
- **Semanalmente**: Versiones de herramientas y dependencias
- **Diariamente**: Análisis de seguridad
- **En cada commit**: Build y tests de integración

## Características Comunes

Todas las imágenes siguen las mejores prácticas de seguridad y optimización:

- ✅ **Multi-stage builds** para reducir el tamaño final
- ✅ **Usuarios no-root** para mayor seguridad
- ✅ **Health checks** incluidos
- ✅ **Herramientas de testing** y seguridad
- ✅ **Optimización de cache** de Docker
- ✅ **Imágenes base oficiales** y versiones específicas

## ⚙️ Configuración de Versiones

Las versiones están parametrizadas y pueden ser configuradas:

### Variables de Entorno del Makefile

```bash
export PYTHON_VERSION=3.12
export GO_VERSION=1.23
export TERRAFORM_VERSION=1.12.2
export ALPINE_VERSION=3.20
```

### Build Args de Docker

```bash
docker build --build-arg PYTHON_VERSION=3.12 -t my-python ./images/python
docker build --build-arg GO_VERSION=1.23 -t my-go ./images/go
```

## 🛡️ Seguridad y Calidad

### Análisis Automatizado

- **Trivy**: Escaneo de vulnerabilidades en imágenes
- **Grype**: Análisis adicional de seguridad  
- **Hadolint**: Linting de Dockerfiles
- **Safety**: Verificación de dependencias Python
- **TruffleHog**: Detección de secretos

### Mejores Prácticas Implementadas

- ✅ **Usuarios no-root** en todas las imágenes
- ✅ **Multi-stage builds** para optimización
- ✅ **Health checks** incluidos
- ✅ **Análisis de seguridad** automatizado
- ✅ **Versiones fijadas** de dependencias
- ✅ **Imágenes base oficiales** verificadas

## 📚 DevContainer Support

Todas las imágenes están optimizadas para VS Code DevContainers:

```json
{
  "name": "Python DevContainer",
  "image": "ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  }
}
```

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature: `git checkout -b feature/nueva-funcionalidad`
3. Sigue las mejores prácticas definidas en `.github/instructions/`
4. Ejecuta los tests: `make test-all`
5. Ejecuta el linting: `hadolint images/*/Dockerfile`
6. Crea un Pull Request

### Desarrollo Local

```bash
# Abrir en DevContainer (VS Code)
code .

# O usar directamente
make build-all
make test-all
```

## 📋 Versionado

Este proyecto sigue [Semantic Versioning](https://semver.org/):

- **MAJOR**: Cambios incompatibles en la API
- **MINOR**: Nuevas funcionalidades compatibles
- **PATCH**: Correcciones y actualizaciones de seguridad

## 🔗 Enlaces Útiles

- [Docker Hub](https://hub.docker.com/u/ironwolphern)
- [GitHub Container Registry](https://github.com/ironwolphern/devcontainer-images/pkgs/container)
- [DevContainers Specification](https://containers.dev/)
- [VS Code DevContainers](https://code.visualstudio.com/docs/devcontainers/containers)

## 📄 Licencia

Ver [LICENSE](LICENSE) para más detalles.

---

**Mantenido por**: [@ironwolphern](https://github.com/ironwolphern)  
**Última actualización**: Julio 2025
