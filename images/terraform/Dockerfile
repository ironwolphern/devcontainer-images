# syntax=docker/dockerfile:1

# Multi-stage build for Terraform development environment
ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION} AS downloader

# Install download dependencies
RUN apk add --no-cache \
    curl=8.12.1-r0 \
    unzip=6.0-r14 \
    gnupg=2.4.5-r0

WORKDIR /tmp

# Download and verify Terraform
ARG TERRAFORM_VERSION=1.12.2
ARG TERRAGRUNT_VERSION=0.67.16
ARG TFLINT_VERSION=0.53.0
ARG CHECKOV_VERSION=3.2.255

# Download Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
    && unzip terraform.zip \
    && chmod +x terraform

# Download Terragrunt
RUN curl -fsSL https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o terragrunt \
    && chmod +x terragrunt

# Download TFLint
RUN curl -fsSL https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip -o tflint.zip \
    && unzip tflint.zip \
    && chmod +x tflint

# Production stage
ARG ALPINE_VERSION=3.20
FROM alpine:${ALPINE_VERSION} AS production

# Install runtime dependencies
RUN apk add --no-cache \
    bash=5.2.26-r0 \
    git=2.45.4-r0 \
    curl=8.12.1-r0 \
    ca-certificates=20241121-r1 \
    openssh-client=9.7_p1-r5 \
    python3=3.12.11-r0 \
    py3-pip=24.0-r2 \
    make=4.4.1-r2 \
    && ln -sf python3 /usr/bin/python

# Create non-root user
RUN addgroup -S terraform && adduser -S terraform -G terraform -u 1001

# Copy binaries from downloader stage
COPY --from=downloader /tmp/terraform /usr/local/bin/terraform
COPY --from=downloader /tmp/terragrunt /usr/local/bin/terragrunt
COPY --from=downloader /tmp/tflint /usr/local/bin/tflint

# Install Python-based tools
RUN pip3 install --no-cache-dir --break-system-packages \
    checkov==3.* \
    terrascan==0.2.* \
    pre-commit==3.*

# Set environment variables
ENV TF_IN_AUTOMATION=true
ENV TF_INPUT=false
ENV TF_CLI_ARGS_plan="-no-color"
ENV TF_CLI_ARGS_apply="-no-color"

WORKDIR /workspace

# Change ownership and switch to non-root user
RUN chown -R terraform:terraform /workspace
USER terraform

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD terraform version || exit 1

# Default command
CMD ["/bin/bash"]
