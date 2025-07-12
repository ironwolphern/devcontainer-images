# Go DevContainer Image

Imagen Docker optimizada para desarrollo con Go, incluyendo herramientas de testing, linting y análisis de seguridad.

## Características

- **Base**: Go 1.23 Alpine
- **Usuario**: `gopher` (UID 1001, no-root)
- **Directorio de trabajo**: `/workspace`

## Herramientas Incluidas

### Core
- Go 1.23
- Git, make, bash

### Development Tools
- gopls (Language Server)
- delve (debugger)

### Linting y Quality
- golangci-lint (meta-linter)
- staticcheck (static analysis)

### Security
- gosec (security scanner)

### Testing
- Ginkgo (BDD testing framework)
- gotestsum (enhanced test output)

## Uso

### Build
```bash
docker build -t go-dev .
```

### Ejecutar
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  go-dev
```

### Con Docker Compose
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

## Variables de Entorno

- `CGO_ENABLED=0`
- `GOOS=linux`
- `GOPATH=/go`
- `GO111MODULE=on`
- `GOPROXY=https://proxy.golang.org,direct`
- `GOSUMDB=sum.golang.org`

## Comandos Útiles

```bash
# Inicializar módulo
go mod init myproject

# Build y test
go build ./...
go test ./...

# Con gotestsum
gotestsum ./...

# Linting
golangci-lint run

# Security scan
gosec ./...

# Testing con Ginkgo
ginkgo generate
ginkgo
```

## Estructura de Proyecto Recomendada

```
/workspace/
├── cmd/                 # Aplicaciones principales
├── internal/            # Código privado de la aplicación
├── pkg/                # Librerías públicas
├── api/                # Definiciones de API
├── web/                # Assets web
├── configs/            # Archivos de configuración
├── scripts/            # Scripts de build y deploy
├── test/               # Tests adicionales
├── go.mod
└── go.sum
```

## Seguridad

- Ejecuta como usuario no-root (`gopher`)
- Análisis de seguridad con gosec
- Go modules con checksum verification
- Health check incluido
- CGO deshabilitado por defecto para binarios estáticos
