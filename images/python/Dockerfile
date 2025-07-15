# syntax=docker/dockerfile:1

# Multi-stage build for Python development environment
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-slim AS builder

# Install build dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential=12.* \
    gcc=4:12.* \
    g++=4:12.* \
    libffi-dev=3.* \
    libssl-dev=3.* \
    libpq-dev=15.* \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Install Python packages
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
ARG PYTHON_VERSION=3.13
FROM python:${PYTHON_VERSION}-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.* \
    curl=7.* \
    jq=1.* \
    ca-certificates=20230311+deb12u1 \
    libpq5=15.* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash --uid 1001 developer

# Copy installed packages from builder
COPY --from=builder /root/.local /home/developer/.local

# Set PATH to include user local binaries
ENV PATH=/home/developer/.local/bin:$PATH
ENV PYTHONPATH=/workspace
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /workspace

# Change ownership and switch to non-root user
RUN chown -R developer:developer /workspace
USER developer

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python --version || exit 1

# Default command
CMD ["/bin/bash"]
