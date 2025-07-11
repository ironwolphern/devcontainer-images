# Terraform DevContainer Image

Imagen Docker optimizada para desarrollo con Terraform e Infrastructure as Code, incluyendo herramientas de testing y análisis de seguridad.

## Características

- **Base**: Alpine Linux 3.18
- **Usuario**: `terraform` (UID 1001, no-root)
- **Directorio de trabajo**: `/workspace`

## Herramientas Incluidas

### Core
- Terraform 1.5.7
- Terragrunt 0.50.17

### Linting y Testing
- TFLint
- Checkov (security scanning)
- Terrascan
- pre-commit

### Utilidades
- Git, SSH client, curl
- Python 3 + pip
- make, bash

## Uso

### Build
```bash
docker build -t terraform-dev .
```

### Ejecutar
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.aws:/home/terraform/.aws:ro \
  terraform-dev
```

### Con Docker Compose
```yaml
version: '3.8'
services:
  terraform:
    build: .
    volumes:
      - .:/workspace
      - ~/.aws:/home/terraform/.aws:ro
    working_dir: /workspace
    environment:
      - AWS_PROFILE=default
```

## Variables de Entorno

- `TF_IN_AUTOMATION=true`
- `TF_INPUT=false`
- `TF_CLI_ARGS_plan=-no-color`
- `TF_CLI_ARGS_apply=-no-color`

## Comandos Útiles

```bash
# Terraform básico
terraform init
terraform plan
terraform apply

# Con Terragrunt
terragrunt init
terragrunt plan
terragrunt apply

# Linting
tflint
checkov -d .

# Security scan
terrascan scan -t terraform
```

## Seguridad

- Ejecuta como usuario no-root (`terraform`)
- Análisis de seguridad con Checkov y Terrascan
- Binarios verificados desde fuentes oficiales
- Health check incluido

## Providers Soportados

Esta imagen funciona con todos los providers de Terraform. Para providers que requieren autenticación:

- **AWS**: Monta `~/.aws` o usa variables de entorno
- **Azure**: Usa `az login` o variables de entorno
- **GCP**: Monta service account key o usa variables de entorno
