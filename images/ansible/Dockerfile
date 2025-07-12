# syntax=docker/dockerfile:1

# Multi-stage build for Ansible development environment
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential=12.9 \
    gcc=4:12.2.0-3 \
    libffi-dev=3.4.4-1 \
    libssl-dev=3.0.16-1~deb12u1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install Ansible and testing tools
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
ARG PYTHON_VERSION=3.12
FROM python:${PYTHON_VERSION}-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client=1:9.2p1-2+deb12u6 \
    sshpass=1.09-1+b1 \
    git=1:2.39.5-0+deb12u2 \
    curl=7.88.1-10+deb12u12 \
    ca-certificates=20230311+deb12u1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash --uid 1001 ansible

# Copy installed packages from builder
COPY --from=builder /root/.local /home/ansible/.local

# Set PATH to include user local binaries
ENV PATH=/home/ansible/.local/bin:$PATH

# Set Ansible configuration
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_STDOUT_CALLBACK=yaml
ENV ANSIBLE_INVENTORY_UNPARSED_WARNING=False

WORKDIR /workspace

# Change ownership and switch to non-root user
RUN chown -R ansible:ansible /workspace
USER ansible

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ansible --version || exit 1

# Default command
CMD ["/bin/bash"]
