# Terraform DevContainer Image

Optimized Docker image for Terraform and Infrastructure as Code development, including testing and security analysis tools.

## Features

- **Base**: Alpine Linux 3.22
- **User**: `terraform` (UID 1001, non-root)
- **Working directory**: `/workspace`

## Included Tools

### Core
- Terraform 1.12.2
- Terragrunt 0.83.2

### Linting and Testing
- TFLint
- Checkov (security scanning)
- Terrascan
- pre-commit

### Security
- TFsec

### Documentation
- TerraformDocs

### Utilities
- Git, SSH client, curl
- Python 3 + pip
- make, bash

## Usage

### Build
```bash
docker build -t terraform-dev .
```

### Run
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  -v ~/.aws:/home/terraform/.aws:ro \
  terraform-dev
```

### With Docker Compose
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

## Environment Variables

- `TF_IN_AUTOMATION=true`
- `TF_INPUT=false`
- `TF_CLI_ARGS_plan=-no-color`
- `TF_CLI_ARGS_apply=-no-color`

## Useful Commands

```bash
# Basic Terraform
terraform init
terraform plan
terraform apply

# With Terragrunt
terragrunt init
terragrunt plan
terragrunt apply

# Linting
tflint
checkov -d .

# Security scan
terrascan scan -t terraform
```

## Security

- Runs as non-root user (`terraform`)
- Security analysis with Checkov and Terrascan
- Verified binaries from official sources
- Health check included

## Supported Providers

This image works with all Terraform providers. For providers requiring authentication:

- **AWS**: Mount `~/.aws` or use environment variables
- **Azure**: Use `az login` or environment variables
- **GCP**: Mount service account key or use environment variables
