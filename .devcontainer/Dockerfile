# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install development dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl=8.* \
    git=1:2.* \
    make=4.* \
    build-essential=12.* \
    ca-certificates=20240203 \
    gnupg=2.* \
    lsb-release=12.* \
    jq=1.* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set shell options for better error handling
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Hadolint for Dockerfile linting
RUN curl -L -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 \
    && chmod +x /usr/local/bin/hadolint

# Add vscode user to docker group (user already exists in base image)
RUN usermod -aG docker vscode || true

USER vscode

# Configure GPG for the vscode user in runtime
RUN echo 'export GPG_TTY=$(tty)' >> /home/vscode/.zshrc
