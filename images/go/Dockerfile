# syntax=docker/dockerfile:1

# Multi-stage build for Go development environment
ARG GO_VERSION=1.23
ARG ALPINE_VERSION=3.20
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    gcc \
    musl-dev

WORKDIR /tmp

# Install Go tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest && \
    go install github.com/onsi/ginkgo/v2/ginkgo@latest && \
    go install gotest.tools/gotestsum@latest

# Production stage
ARG GO_VERSION=1.23
ARG ALPINE_VERSION=3.20
FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS production

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    curl \
    ca-certificates \
    bash \
    make \
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
