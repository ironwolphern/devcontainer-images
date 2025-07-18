---
applyTo: "**/*.yml,**/*.yaml"
---
# Buenas Prácticas de GitHub Actions

## 1. **Estructura y Organización de Workflows**

### 1.1 Nomenclatura y Organización
- Usa nombres descriptivos y claros para los workflows
- Organiza workflows por función: CI, CD, testing, security
- Estructura recomendada:
  ```
  .github/
  ├── workflows/
  │   ├── ci.yml                    # Integración continua
  │   ├── cd-staging.yml           # Deploy a staging
  │   ├── cd-production.yml        # Deploy a producción
  │   ├── security-scan.yml        # Análisis de seguridad
  │   ├── dependency-update.yml    # Actualización de dependencias
  │   └── cleanup.yml              # Limpieza de recursos
  ├── actions/                     # Actions customizadas
  │   ├── setup-node/
  │   └── deploy-app/
  └── ISSUE_TEMPLATE/              # Templates de issues
  ```

### 1.2 Configuración de Triggers
- Usa triggers específicos para cada workflow
- Evita triggers demasiado amplios que ejecuten workflows innecesariamente
- Ejemplos de triggers optimizados:
  ```yaml
  # CI para pull requests y push a main
  on:
    push:
      branches: [ main, develop ]
      paths:
        - 'src/**'
        - 'tests/**'
        - 'package.json'
        - '.github/workflows/ci.yml'
    pull_request:
      branches: [ main ]
      paths:
        - 'src/**'
        - 'tests/**'
        - 'package.json'

  # Deploy solo en tags
  on:
    push:
      tags:
        - 'v*.*.*'

  # Workflow manual con parámetros
  on:
    workflow_dispatch:
      inputs:
        environment:
          description: 'Deployment environment'
          required: true
          default: 'staging'
          type: choice
          options:
            - staging
            - production
        version:
          description: 'Version to deploy'
          required: false
          type: string
  ```

### 1.3 Documentación en Workflows
- Incluye descripciones claras en cada workflow
- Documenta parámetros de entrada y salida
- Usa comentarios para explicar lógica compleja
- Ejemplo:
  ```yaml
  name: 'CI Pipeline'

  on:
    push:
      branches: [ main ]
    pull_request:
      branches: [ main ]

  env:
    NODE_VERSION: '18'
    CACHE_KEY: 'node-modules-v1'

  jobs:
    test:
      name: 'Run Tests'
      runs-on: ubuntu-latest

      steps:
        # Checkout del código fuente
        - name: 'Checkout code'
          uses: actions/checkout@v4
          with:
            fetch-depth: 0  # Necesario para análisis de calidad

        # Configuración de Node.js con cache
        - name: 'Setup Node.js'
          uses: actions/setup-node@v4
          with:
            node-version: ${{ env.NODE_VERSION }}
            cache: 'npm'
            cache-dependency-path: 'package-lock.json'
  ```

## 2. **Seguridad y Gestión de Secretos**

### 2.1 Manejo Seguro de Secretos
- **NUNCA** hardcodees credenciales en workflows
- Usa GitHub Secrets para información sensible
- Implementa el principio de menor privilegio
- Ejemplos de gestión de secretos:
  ```yaml
  jobs:
    deploy:
      runs-on: ubuntu-latest
      environment: production  # Requiere aprobación manual

      steps:
        - name: 'Deploy to AWS'
          env:
            AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
            AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            AWS_REGION: ${{ secrets.AWS_REGION }}
            DATABASE_URL: ${{ secrets.DATABASE_URL }}
          run: |
            # Deploy script aquí
            echo "Deploying to production..."
  ```

### 2.2 Permisos y Tokens
- Usa tokens con permisos mínimos necesarios
- Configura permisos explícitos en workflows
- Usa GitHub App tokens para mejor seguridad
- Ejemplo:
  ```yaml
  permissions:
    contents: read      # Leer código fuente
    pull-requests: write # Escribir comentarios en PRs
    checks: write       # Escribir check results
    security-events: write # Para security scanning

  jobs:
    security-scan:
      runs-on: ubuntu-latest
      permissions:
        security-events: write
        actions: read
        contents: read

      steps:
        - uses: actions/checkout@v4
        - name: 'Run CodeQL Analysis'
          uses: github/codeql-action/analyze@v2
          with:
            languages: javascript
  ```

### 2.3 Validación de Acciones de Terceros
- Usa versiones específicas de acciones (no `@main`)
- Verifica el hash SHA de acciones críticas
- Mantén un registro de acciones aprobadas
- Ejemplo:
  ```yaml
  steps:
    # ✅ Buena práctica - versión específica
    - uses: actions/checkout@v4.1.1

    # ✅ Mejor práctica - hash SHA específico
    - uses: actions/setup-node@64ed1c7eab4cce3362f8c340dee64e5eaeef8f7c # v4.0.6

    # ❌ Evitar - versión flotante
    # - uses: actions/checkout@main
  ```

## 3. **Performance y Optimización**

### 3.1 Paralelización de Jobs
- Ejecuta jobs independientes en paralelo
- Usa matrices para testing en múltiples configuraciones
- Implementa dependencias entre jobs cuando sea necesario
- Ejemplo:
  ```yaml
  jobs:
    test:
      strategy:
        matrix:
          node-version: [16, 18, 20]
          os: [ubuntu-latest, windows-latest, macos-latest]
        fail-fast: false  # No cancela otros jobs si uno falla

      runs-on: ${{ matrix.os }}

      steps:
        - uses: actions/checkout@v4
        - name: 'Setup Node.js ${{ matrix.node-version }}'
          uses: actions/setup-node@v4
          with:
            node-version: ${{ matrix.node-version }}
            cache: 'npm'

        - name: 'Install dependencies'
          run: npm ci

        - name: 'Run tests'
          run: npm test

    deploy:
      needs: test  # Solo ejecuta después de que test sea exitoso
      if: github.ref == 'refs/heads/main'
      runs-on: ubuntu-latest

      steps:
        - name: 'Deploy application'
          run: echo "Deploying..."
  ```

### 3.2 Cache Estratégico
- Implementa cache para dependencias y build artifacts
- Usa claves de cache específicas y descriptivas
- Configura fallback keys para mejor eficiencia
- Ejemplo:
  ```yaml
  steps:
    - uses: actions/checkout@v4

    # Cache de dependencias de Node.js
    - name: 'Cache Node.js modules'
      uses: actions/cache@v3
      with:
        path: ~/.npm
        key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
        restore-keys: |
          ${{ runner.os }}-node-

    # Cache de build artifacts
    - name: 'Cache build output'
      uses: actions/cache@v3
      with:
        path: |
          dist/
          .next/cache/
        key: ${{ runner.os }}-build-${{ github.sha }}
        restore-keys: |
          ${{ runner.os }}-build-

    # Cache de Docker layers
    - name: 'Setup Docker Buildx'
      uses: docker/setup-buildx-action@v3
      with:
        driver-opts: |
          image=moby/buildkit:buildx-stable-1

    - name: 'Build and push Docker image'
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: myapp:latest
        cache-from: type=gha
        cache-to: type=gha,mode=max
  ```

### 3.3 Optimización de Runners
- Usa runners apropiados para cada task
- Considera self-hosted runners para casos específicos
- Optimiza el uso de recursos
- Ejemplo:
  ```yaml
  jobs:
    lint:
      runs-on: ubuntu-latest  # Rápido y económico para linting

    test-unit:
      runs-on: ubuntu-latest

    test-integration:
      runs-on: ubuntu-latest
      services:
        postgres:
          image: postgres:13
          env:
            POSTGRES_PASSWORD: postgres
          options: >-
            --health-cmd pg_isready
            --health-interval 10s
            --health-timeout 5s
            --health-retries 5

    build-windows:
      runs-on: windows-latest  # Solo cuando sea necesario

    performance-test:
      runs-on: self-hosted  # Runner dedicado para tests de performance
      labels: [performance, high-memory]
  ```

## 4. **Testing y Validación**

### 4.1 Pipeline de Testing Completo
- Implementa múltiples niveles de testing
- Usa herramientas específicas para cada tipo de test
- Genera reportes y artefactos de testing
- Ejemplo:
  ```yaml
  name: 'Comprehensive Testing Pipeline'

  on:
    push:
      branches: [ main, develop ]
    pull_request:
      branches: [ main ]

  jobs:
    # Linting y formato
    lint:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with:
            node-version: '18'
            cache: 'npm'

        - run: npm ci
        - run: npm run lint
        - run: npm run format:check

    # Tests unitarios
    unit-tests:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with:
            node-version: '18'
            cache: 'npm'

        - run: npm ci
        - run: npm run test:unit -- --coverage

        - name: 'Upload coverage reports'
          uses: codecov/codecov-action@v3
          with:
            token: ${{ secrets.CODECOV_TOKEN }}
            files: ./coverage/lcov.info

    # Tests de integración
    integration-tests:
      runs-on: ubuntu-latest
      services:
        postgres:
          image: postgres:13
          env:
            POSTGRES_PASSWORD: postgres
            POSTGRES_DB: testdb
          options: >-
            --health-cmd pg_isready
            --health-interval 10s
            --health-timeout 5s
            --health-retries 5

        redis:
          image: redis:7
          options: >-
            --health-cmd "redis-cli ping"
            --health-interval 10s
            --health-timeout 5s
            --health-retries 5

      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with:
            node-version: '18'
            cache: 'npm'

        - run: npm ci
        - run: npm run test:integration
          env:
            DATABASE_URL: postgres://postgres:postgres@localhost:5432/testdb
            REDIS_URL: redis://localhost:6379

    # Tests end-to-end
    e2e-tests:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: actions/setup-node@v4
          with:
            node-version: '18'
            cache: 'npm'

        - run: npm ci
        - run: npm run build
        - run: npm run start &
        - run: npx wait-on http://localhost:3000
        - run: npm run test:e2e

        - name: 'Upload E2E test results'
          uses: actions/upload-artifact@v3
          if: always()
          with:
            name: e2e-test-results
            path: |
              tests/e2e/screenshots/
              tests/e2e/videos/
  ```

### 4.2 Quality Gates
- Implementa verificaciones de calidad obligatorias
- Usa branch protection rules
- Configura status checks requeridos
- Ejemplo:
  ```yaml
  jobs:
    quality-gate:
      runs-on: ubuntu-latest
      needs: [lint, unit-tests, integration-tests, security-scan]

      steps:
        - name: 'Check quality metrics'
          run: |
            # Verificar cobertura mínima
            if [ "${{ needs.unit-tests.outputs.coverage }}" -lt "80" ]; then
              echo "Coverage below 80%"
              exit 1
            fi

            # Verificar vulnerabilidades críticas
            if [ "${{ needs.security-scan.outputs.critical-vulns }}" -gt "0" ]; then
              echo "Critical vulnerabilities found"
              exit 1
            fi

            echo "Quality gate passed"

        - name: 'Update status'
          uses: actions/github-script@v6
          with:
            script: |
              github.rest.repos.createCommitStatus({
                owner: context.repo.owner,
                repo: context.repo.repo,
                sha: context.sha,
                state: 'success',
                context: 'Quality Gate',
                description: 'All quality checks passed'
              });
  ```

## 5. **CI/CD y Deployment**

### 5.1 Estrategias de Deployment
- Implementa diferentes estrategias según el entorno
- Usa environments para control de acceso
- Configura aprobaciones manuales para producción
- Ejemplo:
  ```yaml
  jobs:
    deploy-staging:
      runs-on: ubuntu-latest
      environment: staging
      if: github.ref == 'refs/heads/develop'

      steps:
        - uses: actions/checkout@v4
        - name: 'Deploy to staging'
          run: |
            echo "Deploying to staging environment"
            # Deploy script aquí

    deploy-production:
      runs-on: ubuntu-latest
      environment:
        name: production
        url: https://myapp.com
      if: startsWith(github.ref, 'refs/tags/v')
      needs: [test, security-scan, build]

      steps:
        - uses: actions/checkout@v4

        - name: 'Deploy to production'
          run: |
            echo "Deploying version ${{ github.ref_name }} to production"
            # Deploy script aquí

        - name: 'Health check'
          run: |
            sleep 30  # Esperar a que la aplicación se inicie
            curl -f https://myapp.com/health || exit 1

        - name: 'Notify deployment success'
          uses: 8398a7/action-slack@v3
          with:
            status: success
            channel: '#deployments'
            text: 'Production deployment successful! 🚀'
          env:
            SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  ```

### 5.2 Rollback Strategies
- Implementa rollback automático en caso de fallos
- Mantén versiones anteriores disponibles
- Configura monitoreo post-deployment
- Ejemplo:
  ```yaml
  jobs:
    deploy-with-rollback:
      runs-on: ubuntu-latest
      environment: production

      steps:
        - uses: actions/checkout@v4

        - name: 'Backup current version'
          id: backup
          run: |
            CURRENT_VERSION=$(curl -s https://api.myapp.com/version)
            echo "current_version=$CURRENT_VERSION" >> $GITHUB_OUTPUT
            echo "Backing up version: $CURRENT_VERSION"

        - name: 'Deploy new version'
          id: deploy
          run: |
            echo "Deploying new version..."
            # Deploy script aquí
            echo "deploy_success=true" >> $GITHUB_OUTPUT

        - name: 'Health check'
          id: health_check
          run: |
            sleep 30
            for i in {1..5}; do
              if curl -f https://myapp.com/health; then
                echo "health_check_passed=true" >> $GITHUB_OUTPUT
                exit 0
              fi
              sleep 10
            done
            echo "health_check_passed=false" >> $GITHUB_OUTPUT
            exit 1

        - name: 'Rollback on failure'
          if: failure() && steps.deploy.outputs.deploy_success == 'true'
          run: |
            echo "Rolling back to version: ${{ steps.backup.outputs.current_version }}"
            # Rollback script aquí

        - name: 'Notify deployment result'
          if: always()
          uses: 8398a7/action-slack@v3
          with:
            status: ${{ job.status }}
            channel: '#deployments'
            text: |
              Deployment ${{ job.status }}!
              Version: ${{ github.ref_name }}
              Health Check: ${{ steps.health_check.outputs.health_check_passed }}
          env:
            SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  ```

## 6. **Monitoreo y Observabilidad**

### 6.1 Logging y Debugging
- Usa logging estructurado en workflows
- Implementa debugging condicional
- Configura retención de logs apropiada
- Ejemplo:
  ```yaml
  env:
    DEBUG: ${{ secrets.ACTIONS_STEP_DEBUG || 'false' }}

  jobs:
    build:
      runs-on: ubuntu-latest

      steps:
        - name: 'Debug information'
          if: env.DEBUG == 'true'
          run: |
            echo "::group::Environment Information"
            echo "Runner OS: ${{ runner.os }}"
            echo "Runner Architecture: ${{ runner.arch }}"
            echo "GitHub Event: ${{ github.event_name }}"
            echo "Branch: ${{ github.ref_name }}"
            echo "Commit SHA: ${{ github.sha }}"
            echo "Actor: ${{ github.actor }}"
            echo "::endgroup::"

        - name: 'Build application'
          run: |
            echo "::group::Building Application"
            npm run build
            echo "::endgroup::"

            echo "::notice::Build completed successfully"

        - name: 'Error handling example'
          run: |
            if ! npm run test; then
              echo "::error::Tests failed"
              echo "::group::Test Output"
              npm run test --verbose
              echo "::endgroup::"
              exit 1
            fi
  ```

### 6.2 Métricas y Reporting
- Genera reportes de build y deployment
- Implementa métricas de performance
- Configura alertas para fallos críticos
- Ejemplo:
  ```yaml
  jobs:
    metrics:
      runs-on: ubuntu-latest

      steps:
        - name: 'Collect build metrics'
          id: metrics
          run: |
            BUILD_START=$(date +%s)

            # Build process
            npm run build

            BUILD_END=$(date +%s)
            BUILD_DURATION=$((BUILD_END - BUILD_START))

            echo "build_duration=$BUILD_DURATION" >> $GITHUB_OUTPUT
            echo "build_timestamp=$(date -Iseconds)" >> $GITHUB_OUTPUT

        - name: 'Send metrics to monitoring system'
          run: |
            curl -X POST "https://monitoring.myapp.com/metrics" \
              -H "Authorization: Bearer ${{ secrets.MONITORING_TOKEN }}" \
              -H "Content-Type: application/json" \
              -d '{
                "metric": "github_actions_build_duration",
                "value": "${{ steps.metrics.outputs.build_duration }}",
                "timestamp": "${{ steps.metrics.outputs.build_timestamp }}",
                "tags": {
                  "repository": "${{ github.repository }}",
                  "branch": "${{ github.ref_name }}",
                  "workflow": "${{ github.workflow }}"
                }
              }'

        - name: 'Generate build report'
          run: |
            cat << EOF > build-report.md
            # Build Report

            - **Repository**: ${{ github.repository }}
            - **Branch**: ${{ github.ref_name }}
            - **Commit**: ${{ github.sha }}
            - **Build Duration**: ${{ steps.metrics.outputs.build_duration }}s
            - **Timestamp**: ${{ steps.metrics.outputs.build_timestamp }}

            ## Artifacts
            - Build artifacts uploaded to: \${{ steps.upload.outputs.artifact-url }}
            EOF

        - name: 'Upload build report'
          uses: actions/upload-artifact@v3
          with:
            name: build-report
            path: build-report.md
  ```

## 7. **Reutilización y Mantenibilidad**

### 7.1 Composite Actions
- Crea acciones reutilizables para tareas comunes
- Parametriza acciones para mayor flexibilidad
- Mantén acciones en repositorios separados
- Ejemplo:
  ```yaml
  # .github/actions/setup-app/action.yml
  name: 'Setup Application Environment'
  description: 'Setup Node.js, install dependencies, and configure environment'

  inputs:
    node-version:
      description: 'Node.js version'
      required: false
      default: '18'
    cache-key:
      description: 'Cache key suffix'
      required: false
      default: 'default'
    install-dependencies:
      description: 'Whether to install dependencies'
      required: false
      default: 'true'

  outputs:
    cache-hit:
      description: 'Whether cache was hit'
      value: ${{ steps.cache.outputs.cache-hit }}

  runs:
    using: 'composite'
    steps:
      - name: 'Setup Node.js'
        uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'

      - name: 'Cache dependencies'
        id: cache
        uses: actions/cache@v3
        with:
          path: node_modules
          key: ${{ runner.os }}-node-${{ inputs.node-version }}-${{ inputs.cache-key }}-${{ hashFiles('**/package-lock.json') }}

      - name: 'Install dependencies'
        if: inputs.install-dependencies == 'true' && steps.cache.outputs.cache-hit != 'true'
        shell: bash
        run: npm ci

  # Uso de la composite action
  jobs:
    test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: ./.github/actions/setup-app
          with:
            node-version: '18'
            cache-key: 'test'
        - run: npm test
  ```

### 7.2 Reusable Workflows
- Crea workflows reutilizables para procesos comunes
- Usa inputs y secrets para parametrización
- Mantén workflows centralizados para la organización
- Ejemplo:
  ```yaml
  # .github/workflows/reusable-ci.yml
  name: 'Reusable CI Workflow'

  on:
    workflow_call:
      inputs:
        node-version:
          required: false
          type: string
          default: '18'
        run-e2e-tests:
          required: false
          type: boolean
          default: false
        environment:
          required: true
          type: string
      secrets:
        NPM_TOKEN:
          required: true
        CODECOV_TOKEN:
          required: false

  jobs:
    ci:
      runs-on: ubuntu-latest
      environment: ${{ inputs.environment }}

      steps:
        - uses: actions/checkout@v4

        - name: 'Setup Node.js'
          uses: actions/setup-node@v4
          with:
            node-version: ${{ inputs.node-version }}
            cache: 'npm'
            registry-url: 'https://registry.npmjs.org'

        - run: npm ci
          env:
            NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}

        - run: npm run lint
        - run: npm run test

        - name: 'Upload coverage'
          if: secrets.CODECOV_TOKEN != ''
          uses: codecov/codecov-action@v3
          with:
            token: ${{ secrets.CODECOV_TOKEN }}

        - name: 'E2E Tests'
          if: inputs.run-e2e-tests
          run: npm run test:e2e

  # .github/workflows/main.yml - Uso del workflow reutilizable
  name: 'Main CI/CD Pipeline'

  on:
    push:
      branches: [ main ]
    pull_request:
      branches: [ main ]

  jobs:
    ci:
      uses: ./.github/workflows/reusable-ci.yml
      with:
        node-version: '18'
        run-e2e-tests: true
        environment: 'staging'
      secrets:
        NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
        CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
  ```

## 8. **Troubleshooting y Debugging**

### 8.1 Debugging Strategies
- Usa debug mode para información detallada
- Implementa conditional debugging
- Configura step debugging específico
- Ejemplo:
  ```yaml
  jobs:
    debug-build:
      runs-on: ubuntu-latest
      env:
        ACTIONS_STEP_DEBUG: ${{ secrets.ACTIONS_STEP_DEBUG }}
        ACTIONS_RUNNER_DEBUG: ${{ secrets.ACTIONS_RUNNER_DEBUG }}

      steps:
        - name: 'Debug context'
          run: |
            echo "::group::GitHub Context"
            echo "Event: ${{ github.event_name }}"
            echo "Ref: ${{ github.ref }}"
            echo "SHA: ${{ github.sha }}"
            echo "Actor: ${{ github.actor }}"
            echo "Repository: ${{ github.repository }}"
            echo "::endgroup::"

            echo "::group::Runner Context"
            echo "OS: ${{ runner.os }}"
            echo "Architecture: ${{ runner.arch }}"
            echo "Name: ${{ runner.name }}"
            echo "::endgroup::"

        - name: 'Conditional debugging'
          if: ${{ github.event_name == 'workflow_dispatch' }}
          run: |
            echo "::debug::This is a debug message"
            echo "::notice::This is a notice message"
            echo "::warning::This is a warning message"

        - name: 'Error handling with debugging'
          run: |
            set -x  # Enable bash debugging

            if ! npm run build; then
              echo "::group::Debug Information"
              echo "Node version: $(node --version)"
              echo "NPM version: $(npm --version)"
              echo "Package.json:"
              cat package.json
              echo "Current directory:"
              pwd
              echo "Directory contents:"
              ls -la
              echo "::endgroup::"

              echo "::error::Build failed with detailed debug info above"
              exit 1
            fi
  ```

### 8.2 Common Issues y Solutions
- Documentar problemas comunes y sus soluciones
- Implementar checks preventivos
- Configurar alertas para fallos recurrentes
- Ejemplo:
  ```yaml
  jobs:
    troubleshoot:
      runs-on: ubuntu-latest

      steps:
        - name: 'Check for common issues'
          run: |
            # Check disk space
            echo "::group::Disk Space Check"
            df -h
            available_space=$(df / | tail -1 | awk '{print $4}' | sed 's/G//')
            if [ "$available_space" -lt "2" ]; then
              echo "::warning::Low disk space detected: ${available_space}GB"
              echo "::group::Large files"
              find . -type f -size +100M -exec ls -lh {} \;
              echo "::endgroup::"
            fi
            echo "::endgroup::"

            # Check memory usage
            echo "::group::Memory Check"
            free -h
            echo "::endgroup::"

            # Check network connectivity
            echo "::group::Network Check"
            if ! ping -c 1 google.com > /dev/null 2>&1; then
              echo "::error::Network connectivity issue detected"
            else
              echo "Network connectivity OK"
            fi
            echo "::endgroup::"

        - name: 'Verify environment setup'
          run: |
            echo "::group::Environment Verification"
            echo "PATH: $PATH"
            echo "Node.js: $(which node || echo 'not found')"
            echo "NPM: $(which npm || echo 'not found')"
            echo "Git: $(which git || echo 'not found')"
            echo "Docker: $(which docker || echo 'not found')"
            echo "::endgroup::"

        - name: 'Check dependencies'
          run: |
            if [ -f "package.json" ]; then
              echo "::group::Package.json Analysis"
              jq '.dependencies // {}' package.json
              echo "::endgroup::"

              if [ ! -f "package-lock.json" ]; then
                echo "::warning::package-lock.json not found, this may cause dependency issues"
              fi
            fi
  ```

## 9. **Compliance y Auditoria**

### 9.1 Auditoría de Workflows
- Implementa logging de auditoría completo
- Mantén trazabilidad de cambios
- Configura reportes de compliance
- Ejemplo:
  ```yaml
  jobs:
    audit:
      runs-on: ubuntu-latest

      steps:
        - name: 'Audit log entry'
          run: |
            AUDIT_LOG=$(cat << EOF
            {
              "timestamp": "$(date -Iseconds)",
              "event": "${{ github.event_name }}",
              "repository": "${{ github.repository }}",
              "actor": "${{ github.actor }}",
              "ref": "${{ github.ref }}",
              "sha": "${{ github.sha }}",
              "workflow": "${{ github.workflow }}",
              "run_id": "${{ github.run_id }}",
              "run_number": "${{ github.run_number }}"
            }
            EOF
            )

            echo "::notice::Audit log: $AUDIT_LOG"

            # Send to audit system
            curl -X POST "https://audit.company.com/logs" \
              -H "Authorization: Bearer ${{ secrets.AUDIT_TOKEN }}" \
              -H "Content-Type: application/json" \
              -d "$AUDIT_LOG"

        - name: 'Compliance checks'
          run: |
            # Check for required approvals
            if [[ "${{ github.event_name }}" == "push" && "${{ github.ref }}" == "refs/heads/main" ]]; then
              PR_NUMBER=$(gh pr list --state merged --limit 1 --json number --jq '.[0].number')
              APPROVALS=$(gh pr view $PR_NUMBER --json reviews --jq '[.reviews[] | select(.state == "APPROVED")] | length')

              if [ "$APPROVALS" -lt "2" ]; then
                echo "::error::Insufficient approvals for main branch push"
                exit 1
              fi
            fi
          env:
            GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}

        - name: 'Generate compliance report'
          run: |
            cat << EOF > compliance-report.json
            {
              "workflow_run": {
                "id": "${{ github.run_id }}",
                "number": "${{ github.run_number }}",
                "started_at": "${{ github.event.workflow_run.created_at }}",
                "repository": "${{ github.repository }}",
                "branch": "${{ github.ref_name }}",
                "actor": "${{ github.actor }}"
              },
              "compliance_checks": {
                "required_approvals": true,
                "security_scan_passed": true,
                "tests_passed": true,
                "deployment_approved": true
              },
              "artifacts": {
                "logs_retained": true,
                "audit_trail_complete": true
              }
            }
            EOF

        - name: 'Upload compliance report'
          uses: actions/upload-artifact@v3
          with:
            name: compliance-report
            path: compliance-report.json
            retention-days: 90
  ```

### 9.2 Security Scanning
- Implementa scanning automático de vulnerabilidades
- Usa herramientas de análisis estático
- Configura políticas de seguridad
- Ejemplo:
  ```yaml
  jobs:
    security:
      runs-on: ubuntu-latest
      permissions:
        security-events: write
        actions: read
        contents: read

      steps:
        - uses: actions/checkout@v4

        - name: 'Dependency vulnerability scan'
          run: |
            npm audit --audit-level=high
            npm audit fix --dry-run

        - name: 'SAST with CodeQL'
          uses: github/codeql-action/init@v2
          with:
            languages: javascript
            queries: security-and-quality

        - name: 'Build for analysis'
          run: npm run build

        - name: 'Perform CodeQL Analysis'
          uses: github/codeql-action/analyze@v2

        - name: 'Container image scanning'
          uses: anchore/scan-action@v3
          with:
            image: "myapp:${{ github.sha }}"
            fail-build: true
            severity-cutoff: high

        - name: 'Upload Anchore scan SARIF report'
          uses: github/codeql-action/upload-sarif@v2
          with:
            sarif_file: results.sarif

        - name: 'Secret scanning'
          uses: trufflesecurity/trufflehog@v3.63.2-beta
          with:
            path: ./
            base: main
            head: HEAD

### 9.3 Image Signing with Cosign
- Implementa firma automática de imágenes de contenedor
- Usa keyless signing con OIDC para mayor seguridad
- Verifica firmas antes del deployment
- Ejemplo:
  ```yaml
  jobs:
    build-and-sign:
      runs-on: ubuntu-latest
      permissions:
        contents: read
        packages: write
        id-token: write  # Necesario para keyless signing

      steps:
        - name: 'Checkout code'
          uses: actions/checkout@v4

        - name: 'Set up Docker Buildx'
          uses: docker/setup-buildx-action@v3

        - name: 'Login to registry'
          uses: docker/login-action@v3
          with:
            registry: ghcr.io
            username: ${{ github.actor }}
            password: ${{ secrets.GITHUB_TOKEN }}

        - name: 'Install Cosign'
          uses: sigstore/cosign-installer@v3
          with:
            cosign-release: 'v2.4.0'

        - name: 'Build image'
          uses: docker/build-push-action@v6
          id: build
          with:
            push: true
            tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
            cache-from: type=gha
            cache-to: type=gha,mode=max

        - name: 'Sign image with keyless'
          env:
            COSIGN_EXPERIMENTAL: 1
          run: |
            cosign sign --yes ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}

        - name: 'Generate SBOM'
          run: |
            cosign download sbom ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }} || \
            syft ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }} -o spdx-json=sbom.spdx.json

        - name: 'Attest SBOM'
          env:
            COSIGN_EXPERIMENTAL: 1
          run: |
            cosign attest --yes --predicate sbom.spdx.json --type spdxjson \
              ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}

        - name: 'Verify signature'
          env:
            COSIGN_EXPERIMENTAL: 1
          run: |
            cosign verify \
              --certificate-identity-regexp="^https://github.com/${{ github.repository }}" \
              --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
              ghcr.io/${{ github.repository }}@${{ steps.build.outputs.digest }}
  ```

### 9.4 Policy Enforcement
- Configura políticas de verificación para deployment
- Ejemplo de política para Kubernetes:
  ```yaml
  # cosign-policy.yaml
  apiVersion: v1alpha1
  kind: ClusterImagePolicy
  metadata:
    name: require-signed-images
  spec:
    images:
    - glob: "ghcr.io/${{ github.repository }}/*"
    authorities:
    - keyless:
        url: "https://fulcio.sigstore.dev"
        identities:
        - issuer: "https://token.actions.githubusercontent.com"
          subject: "https://github.com/${{ github.repository }}/*"
  ```

  ```yaml
  # Deployment workflow con verificación
  deploy:
    runs-on: ubuntu-latest
    needs: build-and-sign

    steps:
      - name: 'Install Cosign'
        uses: sigstore/cosign-installer@v3

      - name: 'Verify image signature before deploy'
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          cosign verify \
            --certificate-identity-regexp="^https://github.com/${{ github.repository }}" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            ghcr.io/${{ github.repository }}:${{ github.sha }} || {
              echo "❌ Image signature verification failed"
              exit 1
            }
          echo "✅ Image signature verified successfully"

      - name: 'Deploy verified image'
        run: |
          kubectl set image deployment/myapp \
            container=ghcr.io/${{ github.repository }}:${{ github.sha }}
  ```
