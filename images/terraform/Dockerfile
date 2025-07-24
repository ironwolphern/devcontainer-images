# syntax=docker/dockerfile:1

# Multi-stage build for Terraform development environment
ARG ALPINE_VERSION=3.22
FROM alpine:${ALPINE_VERSION} AS downloader

# Install download dependencies
RUN apk add --no-cache \
    curl=8.14.1-r1 \
    unzip=6.0-r15 \
    gnupg=2.4.7-r0

WORKDIR /tmp

# Download and verify Terraform
ARG TERRAFORM_VERSION=1.12.2
ARG TERRAGRUNT_VERSION=0.83.2
ARG TFLINT_VERSION=0.58.1
ARG TFSEC_VERSION=1.28.14
ARG TERRAFORM_DOCS_VERSION=0.20.0

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

# Download TFsec
RUN curl -fsSL https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 -o tfsec \
    && chmod +x tfsec

# Download TerraformDocs
RUN curl -fsSL https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz -o terraform-docs.tar.gz \
    && tar -xzf terraform-docs.tar.gz \
    && chmod +x terraform-docs

# Production stage
ARG ALPINE_VERSION=3.22
FROM alpine:${ALPINE_VERSION} AS production

# Install runtime dependencies
RUN apk add --no-cache \
    bash=5.2.37-r0 \
    git=2.49.1-r0 \
    curl=8.14.1-r1 \
    ca-certificates=20250619-r0 \
    openssh=10.0_p1-r7 \
    python3=3.12.11-r0 \
    py3-pip=25.1.1-r0 \
    make=4.4.1-r3 \
    && ln -sf python3 /usr/bin/python

# Create non-root user
RUN addgroup -S terraform && adduser -S terraform -G terraform -u 1001

# Copy binaries from downloader stage
COPY --from=downloader /tmp/terraform /usr/local/bin/terraform
COPY --from=downloader /tmp/terragrunt /usr/local/bin/terragrunt
COPY --from=downloader /tmp/tflint /usr/local/bin/tflint

# Set environment variables
ENV TF_IN_AUTOMATION=true
ENV TF_INPUT=false
ENV TF_CLI_ARGS_plan="-no-color"
ENV TF_CLI_ARGS_apply="-no-color"

WORKDIR /workspace

# Create Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python packages in virtual environment
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && rm -rf requirements.txt

# Change ownership and switch to non-root user
RUN chown -R terraform:terraform /workspace /opt/venv
USER terraform

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD terraform version || exit 1

# Default command
CMD ["/bin/bash"]

# Configure GPG for the terraform user in runtime
RUN echo "export GPG_TTY=$(tty)" >> /home/terraform/.bashrc
