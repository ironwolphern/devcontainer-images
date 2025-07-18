# syntax=docker/dockerfile:1

# Multi-stage build for Go development environment
ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.22
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

# Install build dependencies and tools
RUN apk add --no-cache \
    git=2.49.1-r0 \
    ca-certificates=20250619-r0 \
    gcc=14.2.0-r6 \
    musl-dev=1.2.5-r10 \
    binutils=2.44-r2 \
    binutils-gold=2.44-r2

WORKDIR /tmp

# Install Go tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install github.com/onsi/ginkgo/v2/ginkgo@latest && \
    go install gotest.tools/gotestsum@latest && \
    go install github.com/securego/gosec/v2/cmd/gosec@latest

# Production stage
ARG GO_VERSION=1.24
ARG ALPINE_VERSION=3.22
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS production

# Install runtime dependencies and tools
RUN apk add --no-cache \
    git=2.49.1-r0 \
    curl=8.14.1-r1 \
    ca-certificates=20250619-r0 \
    bash=5.2.37-r0 \
    make=4.4.1-r3 \
    && update-ca-certificates

# Create non-root user
RUN addgroup -S gopher && adduser -S gopher -G gopher -u 1001

# Copy Go tools from builder
COPY --from=builder /go/bin/* /usr/local/bin/

# Set Go environment variables
ENV CGO_ENABLED=0
ENV GOOS=linux
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
ENV GO111MODULE=on
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org

# Create Go workspace
RUN mkdir -p /go/src /go/bin /go/pkg /workspace && \
    chown -R gopher:gopher /go /workspace

WORKDIR /workspace

# Switch to non-root user
USER gopher

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD go version || exit 1

# Default command
CMD ["/bin/bash"]

# Configure GPG for the gopher user in runtime
RUN echo "export GPG_TTY=$(tty)" >> /home/gopher/.bashrc
