---
applyTo: "**/*.dockerfile,**/*.docker-compose.yml,**/*.docker-compose.yaml"
---
# Buenas Prácticas de Dockerfile y Docker Compose

## 1. **Dockerfile - Mejores Prácticas Generales**

### 1.1 Estructura y Organización
- Usa `.dockerignore` para excluir archivos innecesarios
- Ordena las instrucciones de menos a más cambiantes para optimizar cache
- Agrupa comandos relacionados en una sola instrucción `RUN`
- Usa multi-stage builds para reducir el tamaño final

```dockerfile
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.nyc_output
coverage
.DS_Store
```

### 1.2 Imagen Base
- Usa imágenes oficiales cuando sea posible
- Especifica versiones exactas de imágenes base
- Prefiere imágenes `alpine` para menor tamaño
- Usa imágenes específicas para el runtime necesario

```dockerfile
# ❌ Malo - Sin versión específica
FROM node

# ✅ Bueno - Versión específica y alpine
FROM node:18-alpine

# ✅ Mejor - Hash específico para máxima seguridad
FROM node:18-alpine@sha256:a1e0b8c...
```

### 1.3 Orden de Instrucciones (Cache Optimization)
```dockerfile
# Optimizado para cache de Docker
FROM node:18-alpine

# 1. Instalar dependencias del sistema (raramente cambian)
RUN apk add --no-cache git curl

# 2. Copiar archivos de dependencias primero
COPY package*.json ./

# 3. Instalar dependencias (cambian ocasionalmente)
RUN npm ci --only=production && npm cache clean --force

# 4. Copiar código fuente al final (cambia frecuentemente)
COPY . .

# 5. Comando de ejecución
CMD ["npm", "start"]
```

## 2. **Instrucciones Dockerfile - Mejores Prácticas**

### 2.1 FROM
```dockerfile
# ✅ Especifica versión y usa imágenes slim/alpine
FROM python:3.11-slim

# ✅ Multi-stage build para optimización
FROM python:3.11-slim AS builder
# ... build steps ...

FROM python:3.11-slim AS runtime
COPY --from=builder /app /app
```

### 2.2 RUN
```dockerfile
# ❌ Malo - Múltiples layers innecesarios
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ Bueno - Una sola layer, limpieza incluida
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ✅ Alpine - Más eficiente
RUN apk add --no-cache curl git
```

### 2.3 COPY vs ADD
```dockerfile
# ✅ Usa COPY para archivos locales
COPY package*.json ./
COPY src/ ./src/

# ✅ ADD solo para URLs o archivos tar que necesitas extraer
ADD https://example.com/file.tar.gz /tmp/
ADD archive.tar.gz /opt/
```

### 2.4 WORKDIR
```dockerfile
# ✅ Usa WORKDIR en lugar de RUN cd
WORKDIR /app

# ❌ Evita esto
RUN cd /app && npm install
```

### 2.5 USER
```dockerfile
# ✅ No ejecutes como root en producción
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# ✅ Alternativa con UID específico
RUN adduser -D -s /bin/sh -u 1001 appuser
USER 1001
```

### 2.6 EXPOSE y Health Checks
```dockerfile
# ✅ Documenta puertos expuestos
EXPOSE 3000

# ✅ Incluye health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
```

## 3. **Dockerfile - Ejemplos por Tecnología**

### 3.1 Node.js Dockerfile Optimizado
```dockerfile
FROM node:18-alpine AS builder

# Instalar dependencias del sistema
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar todas las dependencias (incluidas dev)
RUN npm ci

# Copiar código fuente
COPY . .

# Build de la aplicación
RUN npm run build

# Etapa de producción
FROM node:18-alpine AS production

# Crear usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copiar archivos de dependencias
COPY package*.json ./

# Instalar solo dependencias de producción
RUN npm ci --only=production && npm cache clean --force

# Copiar build desde etapa anterior
COPY --from=builder /app/dist ./dist

# Cambiar ownership al usuario no-root
RUN chown -R appuser:appgroup /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

EXPOSE 3000

CMD ["node", "dist/server.js"]
```

### 3.2 Python Dockerfile Optimizado
```dockerfile
FROM python:3.11-slim AS builder

# Instalar dependencias de build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias en un directorio específico
RUN pip install --user --no-cache-dir -r requirements.txt

# Etapa de producción
FROM python:3.11-slim AS production

# Crear usuario no-root
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copiar dependencias instaladas
COPY --from=builder /root/.local /home/appuser/.local

# Asegurar que el PATH incluya las dependencias del usuario
ENV PATH=/home/appuser/.local/bin:$PATH

# Copiar código de la aplicación
COPY --chown=appuser:appuser . .

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

EXPOSE 8000

CMD ["python", "app.py"]
```

### 3.3 Java Dockerfile Optimizado
```dockerfile
FROM openjdk:17-jdk-slim AS builder

WORKDIR /app

# Copiar archivos de build
COPY pom.xml .
COPY src ./src

# Build de la aplicación
RUN ./mvnw clean package -DskipTests

# Etapa de producción
FROM openjdk:17-jre-slim AS production

# Crear usuario no-root
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copiar JAR desde etapa de build
COPY --from=builder /app/target/*.jar app.jar

# Cambiar ownership
RUN chown appuser:appuser app.jar

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

# Usar exec form para mejor manejo de señales
CMD ["java", "-jar", "app.jar"]
```

## 4. **Docker Compose - Mejores Prácticas**

### 4.1 Estructura de Archivos
```yaml
# docker-compose.yml - Configuración base
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

```yaml
# docker-compose.override.yml - Desarrollo local
version: '3.8'

services:
  app:
    build:
      target: development
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
    command: npm run dev

  db:
    ports:
      - "5432:5432"  # Exponer DB en desarrollo
```

### 4.2 Variables de Entorno
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    image: myapp:latest
    environment:
      # ✅ Usar variables de entorno
      - DATABASE_URL=${DATABASE_URL}
      - API_KEY=${API_KEY}
      # ✅ Valores por defecto
      - LOG_LEVEL=${LOG_LEVEL:-info}
    env_file:
      - .env
      - .env.local
```

```bash
# .env
DATABASE_URL=postgresql://user:pass@db:5432/myapp
API_KEY=your-api-key-here
LOG_LEVEL=debug

# .env.production
DATABASE_URL=postgresql://prod-host:5432/myapp
LOG_LEVEL=warn
```

### 4.3 Redes y Servicios
```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    networks:
      - frontend-network
    depends_on:
      - backend

  backend:
    build: ./backend
    networks:
      - frontend-network
      - backend-network
    depends_on:
      - db
      - redis

  db:
    image: postgres:15-alpine
    networks:
      - backend-network
    volumes:
      - db_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    networks:
      - backend-network

networks:
  frontend-network:
  backend-network:

volumes:
  db_data:
```

### 4.4 Health Checks y Dependencias
```yaml
version: '3.8'

services:
  app:
    build: .
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
```

## 5. **Seguridad**

### 5.1 Dockerfile Security
```dockerfile
# ✅ Usar imágenes base de fuentes confiables
FROM node:18-alpine

# ✅ Actualizar paquetes y limpiar cache
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# ✅ Crear usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# ✅ Copiar archivos con ownership correcto
COPY --chown=appuser:appgroup . /app

# ✅ Cambiar a usuario no-root
USER appuser

# ✅ Usar dumb-init para mejor manejo de señales
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
```

### 5.2 Docker Compose Security
```yaml
version: '3.8'

services:
  app:
    build: .
    # ✅ No exponer puertos innecesarios en producción
    expose:
      - "3000"
    # ✅ Usar secrets para datos sensibles
    secrets:
      - db_password
      - api_key
    # ✅ Limitar recursos
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  db:
    image: postgres:15-alpine
    # ✅ Usar secrets en lugar de environment
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    # ✅ Volúmenes con permisos restrictivos
    volumes:
      - type: volume
        source: db_data
        target: /var/lib/postgresql/data
        volume:
          nocopy: true

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    external: true

volumes:
  db_data:
    driver: local
```

## 6. **Optimización de Performance**

### 6.1 Multi-stage Builds
```dockerfile
# Etapa de desarrollo/build
FROM node:18-alpine AS development
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Etapa de testing
FROM development AS testing
RUN npm run test

# Etapa de producción - Solo lo necesario
FROM nginx:alpine AS production
COPY --from=development /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 6.2 Cache Optimization
```dockerfile
# ✅ Orden optimizado para cache
FROM python:3.11-slim

# Instalar dependencias del sistema (raramente cambian)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar requirements primero (cambian ocasionalmente)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código al final (cambia frecuentemente)
COPY . .

CMD ["python", "app.py"]
```

### 6.3 Minimizar Tamaño de Imagen
```dockerfile
FROM alpine:3.18 AS builder

# Instalar dependencias de build
RUN apk add --no-cache \
    build-base \
    python3-dev \
    py3-pip

WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Etapa final - Solo runtime
FROM alpine:3.18

# Instalar solo runtime dependencies
RUN apk add --no-cache python3

# Crear usuario no-root
RUN adduser -D -s /bin/sh appuser

# Copiar dependencias instaladas
COPY --from=builder /root/.local /home/appuser/.local

WORKDIR /app
COPY --chown=appuser:appuser . .

USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH

CMD ["python3", "app.py"]
```

## 7. **Desarrollo y Debugging**

### 7.1 Docker Compose para Desarrollo
```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      # Hot reload
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
      - "9229:9229"  # Debug port
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    ports:
      - "5432:5432"  # Acceso directo para debugging
    environment:
      - POSTGRES_DB=myapp_dev
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=devpass
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
      # Mounting init scripts
      - ./db/init:/docker-entrypoint-initdb.d

volumes:
  postgres_dev_data:
```

### 7.2 Dockerfile para Desarrollo
```dockerfile
# Dockerfile.dev
FROM node:18-alpine

# Instalar herramientas de desarrollo
RUN apk add --no-cache \
    git \
    curl \
    vim

WORKDIR /app

# Instalar nodemon globalmente para hot reload
RUN npm install -g nodemon

# Copiar package files
COPY package*.json ./
RUN npm install

# En desarrollo, el código se monta como volumen
# No copiamos el código aquí

EXPOSE 3000 9229

# Comando para desarrollo con hot reload
CMD ["npm", "run", "dev"]
```

## 8. **Monitoreo y Logging**

### 8.1 Health Checks Avanzados
```dockerfile
# Dockerfile con health check personalizado
FROM node:18-alpine

WORKDIR /app

# Instalar curl para health checks
RUN apk add --no-cache curl

COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Health check más robusto
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node health-check.js

EXPOSE 3000
CMD ["node", "server.js"]
```

```javascript
// health-check.js
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  method: 'GET',
  timeout: 5000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => {
  process.exit(1);
});

req.on('timeout', () => {
  req.destroy();
  process.exit(1);
});

req.end();
```

### 8.2 Logging en Docker Compose
```yaml
version: '3.8'

services:
  app:
    build: .
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    labels:
      - "logging=true"
      - "service=app"

  nginx:
    image: nginx:alpine
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://localhost:514"
        tag: "nginx"

  # Servicio de logging centralizado
  logstash:
    image: docker.elastic.co/logstash/logstash:8.8.0
    volumes:
      - ./logstash/config:/usr/share/logstash/pipeline
    ports:
      - "5044:5044"
```

## 9. **CI/CD Integration**

### 9.1 GitHub Actions con Docker
```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout
      uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login to DockerHub
      if: github.event_name != 'pull_request'
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKERHUB_USERNAME }}
        password: ${{ secrets.DOCKERHUB_TOKEN }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: myorg/myapp
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=semver,pattern={{version}}
          type=semver,pattern={{major}}.{{minor}}

    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        platforms: linux/amd64,linux/arm64
        push: ${{ github.event_name != 'pull_request' }}
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: myorg/myapp:latest
        format: 'sarif'
        output: 'trivy-results.sarif'

    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
```

## 10. **Herramientas y Comandos Útiles**

### 10.1 Comandos Docker Útiles
```bash
# Build optimizado con cache
docker build --cache-from myapp:latest -t myapp:new .

# Análisis de layers
docker history myapp:latest

# Inspección de imagen
docker inspect myapp:latest

# Limpieza de sistema
docker system prune -a

# Análisis de tamaño
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Logs con timestamp
docker logs -f --timestamps container_name

# Stats en tiempo real
docker stats --no-stream
```

### 10.2 Docker Compose Útiles
```bash
# Build sin cache
docker-compose build --no-cache

# Up en background con logs
docker-compose up -d && docker-compose logs -f

# Escalar servicios
docker-compose up --scale web=3

# Validar configuración
docker-compose config

# Ver dependencias
docker-compose ps --services

# Ejecutar comandos en servicio
docker-compose exec app bash

# Override para diferentes entornos
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

### 10.3 Herramientas de Análisis
```bash
# Hadolint - Linter para Dockerfile
hadolint Dockerfile

# Dive - Análisis de layers
dive myimage:tag

# Trivy - Scanner de vulnerabilidades
trivy image myimage:tag

# Docker Scout - Análisis de seguridad
docker scout cves myimage:tag

# Container Structure Test
container-structure-test test --image myimage:tag --config test.yaml
```

## 11. **Mejores Prácticas por Entorno**

### 11.1 Desarrollo
```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/app:cached
      - node_modules:/app/node_modules
    environment:
      - NODE_ENV=development
    ports:
      - "3000:3000"
    command: npm run dev

volumes:
  node_modules:
```

### 11.2 Testing
```yaml
# docker-compose.test.yml
version: '3.8'

services:
  app-test:
    build:
      context: .
      target: testing
    environment:
      - NODE_ENV=test
    command: npm test

  integration-test:
    build: .
    depends_on:
      - db-test
    environment:
      - NODE_ENV=test
    command: npm run test:integration

  db-test:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=test_db
    tmpfs:
      - /var/lib/postgresql/data
```

### 11.3 Producción
```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    image: myorg/myapp:${TAG:-latest}
    restart: unless-stopped
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
    secrets:
      - app_secret
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

secrets:
  app_secret:
    external: true
```

---

## Checklist de Mejores Prácticas

### ✅ Dockerfile
- [ ] Usar imágenes base oficiales y específicas
- [ ] Implementar multi-stage builds
- [ ] Optimizar orden de instrucciones para cache
- [ ] Crear usuario no-root
- [ ] Incluir health checks
- [ ] Minimizar layers innecesarios
- [ ] Limpiar cache de paquetes
- [ ] Usar .dockerignore

### ✅ Docker Compose
- [ ] Usar variables de entorno
- [ ] Implementar health checks
- [ ] Configurar redes apropiadas
- [ ] Usar secrets para datos sensibles
- [ ] Configurar límites de recursos
- [ ] Separar archivos por entorno
- [ ] Implementar dependencias correctas

### ✅ Seguridad
- [ ] Escanear imágenes por vulnerabilidades
- [ ] No ejecutar como root
- [ ] Usar secrets management
- [ ] Validar imágenes base
- [ ] Implementar least privilege
- [ ] Configurar network policies

## Recursos Adicionales

- [Docker Best Practices](https://docs.docker.com/develop/best-practices/)
- [Docker Compose Specification](https://docs.docker.com/compose/compose-file/)
- [Hadolint - Dockerfile Linter](https://github.com/hadolint/hadolint)
- [Dive - Image Layer Explorer](https://github.com/wagoodman/dive)
- [Trivy - Vulnerability Scanner](https://github.com/aquasecurity/trivy)

---

*Última actualización: Junio 2025*
