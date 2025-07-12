# Go DevContainer Image

Optimized Docker image for Go development, including testing, linting and security analysis tools.

## Features

- **Base**: Go 1.23 Alpine
- **User**: `gopher` (UID 1001, non-root)
- **Working directory**: `/workspace`

## Included Tools

### Core
- Go 1.23
- Git, make, bash

### Development Tools
- gopls (Language Server)
- delve (debugger)

### Linting and Quality
- golangci-lint (meta-linter)
- staticcheck (static analysis)

### Security
- gosec (security scanner)

### Testing
- Ginkgo (BDD testing framework)
- gotestsum (enhanced test output)

## Usage

### Build
```bash
docker build -t go-dev .
```

### Run
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  go-dev
```

### With Docker Compose
```yaml
version: '3.8'
services:
  go:
    build: .
    volumes:
      - .:/workspace
      - go-cache:/go/pkg/mod
    working_dir: /workspace
    ports:
      - "8080:8080"

volumes:
  go-cache:
```

## Environment Variables

- `CGO_ENABLED=0`
- `GOOS=linux`
- `GOPATH=/go`
- `GO111MODULE=on`
- `GOPROXY=https://proxy.golang.org,direct`
- `GOSUMDB=sum.golang.org`

## Useful Commands

```bash
# Initialize module
go mod init myproject

# Build and test
go build ./...
go test ./...

# With gotestsum
gotestsum ./...

# Linting
golangci-lint run

# Security scan
gosec ./...

# Testing with Ginkgo
ginkgo generate
ginkgo
```

## Recommended Project Structure

```
/workspace/
├── cmd/                 # Main applications
├── internal/            # Private application code
├── pkg/                # Public libraries
├── api/                # API definitions
├── web/                # Web assets
├── configs/            # Configuration files
├── scripts/            # Build and deploy scripts
├── test/               # Additional tests
├── go.mod
└── go.sum
```

## Security

- Runs as non-root user (`gopher`)
- Security analysis with gosec
- Go modules with checksum verification
- Health check included
- CGO disabled by default for static binaries
