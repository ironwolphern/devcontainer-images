# 🔐 Firma de Imágenes con Cosign

Este repositorio implementa firma automática de imágenes de contenedor usando [Cosign](https://docs.sigstore.dev/cosign/overview/) con keyless signing para garantizar la integridad y autenticidad de las imágenes DevContainer.

## 🎯 ¿Por qué Firmar Imágenes?

La firma de imágenes de contenedor es una práctica de seguridad crítica que:

- ✅ **Garantiza la integridad**: Verifica que las imágenes no han sido modificadas
- ✅ **Establece proveniencia**: Confirma el origen y proceso de construcción
- ✅ **Previene ataques de supply chain**: Protege contra imágenes maliciosas
- ✅ **Cumple con políticas de seguridad**: Satisface requisitos de compliance
- ✅ **Proporciona transparencia**: Incluye SBOM (Software Bill of Materials)

## 🔧 Implementación

### Keyless Signing

Utilizamos **keyless signing** con OIDC (OpenID Connect) que elimina la necesidad de gestionar claves privadas:

- 🔑 **Sin claves privadas**: No hay claves que gestionar o rotar
- 🆔 **Identidad basada en OIDC**: Usa tokens de GitHub Actions
- 🔄 **Automático**: Se ejecuta en cada build y release
- 🌐 **Transparente**: Registros públicos en Rekor

### Proceso Automático

1. **Build**: Las imágenes se construyen con Docker Buildx
2. **Push**: Se suben al registry (ghcr.io)
3. **Sign**: Cosign firma automáticamente usando OIDC
4. **SBOM**: Se genera y atesta un Software Bill of Materials
5. **Verify**: Se verifica la firma antes de completar el workflow

## 🛡️ Verificación de Firmas

### Verificación Manual

```bash
# Instalar Cosign
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# Verificar firma de imagen
export COSIGN_EXPERIMENTAL=1
cosign verify \
  --certificate-identity-regexp="^https://github.com/ironwolphern/devcontainer-images" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest
```

### Script Automatizado

Usamos el script incluido para verificaciones más fáciles:

```bash
# Verificar todas las imágenes
./scripts/verify-signatures.sh --all

# Verificar imagen específica
./scripts/verify-signatures.sh python

# Verificar con SBOM
./scripts/verify-signatures.sh --all --sbom

# Modo verbose
./scripts/verify-signatures.sh --verbose terraform

# Verificar tag específico
./scripts/verify-signatures.sh ansible v1.0.0
```

### Verificación de SBOM

```bash
# Verificar SBOM
cosign verify-attestation \
  --certificate-identity-regexp="^https://github.com/ironwolphern/devcontainer-images" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  --type spdxjson --output-file sbom-attestation-python.json\
  ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest

# Descargar SBOM para análisis
cosign download attestation \
  ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest
```

## 🏗️ Integración en CI/CD

### GitHub Actions

Las firmas se implementan automáticamente en:

- **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`): Firma imágenes en push a main
- **Release** (`.github/workflows/release.yml`): Firma imágenes de release
- **Verification** (`.github/workflows/verify-signatures.yml`): Verificación programada

### Configuración de Permisos

```yaml
permissions:
  contents: read
  packages: write
  id-token: write  # Requerido para keyless signing
```

### Pasos de Firma

```yaml
- name: 'Install Cosign'
  uses: sigstore/cosign-installer@v3

- name: 'Sign image'
  env:
    COSIGN_EXPERIMENTAL: 1
  run: |
    cosign sign --yes ${{ env.REGISTRY }}/image:tag
```

## 📋 Software Bill of Materials (SBOM)

### Generación Automática

Cada imagen incluye un SBOM en formato SPDX que contiene:

- 📦 **Lista completa de paquetes**: Todas las dependencias instaladas
- 🔢 **Versiones exactas**: Información detallada de versiones
- 📝 **Metadatos**: Información sobre el proceso de build
- 🔗 **Referencias**: Enlaces a repositorios y documentación

### Análisis de SBOM

```bash
# Descargar y analizar SBOM
cosign download attestation \
  ghcr.io/ironwolphern/devcontainer-images/devcontainer-python:latest | \
  jq -r '.payload' | base64 -d | jq -r '.predicate' > sbom.json

# Contar paquetes
jq '.packages | length' sbom.json

# Listar paquetes
jq -r '.packages[] | select(.name != null) | .name' sbom.json
```

## 🔒 Políticas de Seguridad

### Política de Verificación

Ejemplo de política para Kubernetes con Gatekeeper o Kyverno:

```yaml
apiVersion: v1alpha1
kind: ClusterImagePolicy
metadata:
  name: require-signed-devcontainer-images
spec:
  images:
  - glob: "ghcr.io/ironwolphern/devcontainer-images/*"
  authorities:
  - keyless:
      url: "https://fulcio.sigstore.dev"
      identities:
      - issuer: "https://token.actions.githubusercontent.com"
        subject: "https://github.com/ironwolphern/devcontainer-images/*"
```

### Pre-deployment Verification

```bash
#!/bin/bash
# Script para verificar antes de deployment

IMAGE="$1"
if ! cosign verify \
  --certificate-identity-regexp="^https://github.com/ironwolphern/devcontainer-images" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  "$IMAGE"; then
  echo "❌ Imagen no firmada o firma inválida"
  exit 1
fi

echo "✅ Imagen verificada, proceder con deployment"
```

## 🔄 Verificación Continua

### Verificación Programada

El workflow `verify-signatures.yml` ejecuta verificaciones automáticas:

- 📅 **Diariamente**: A las 6:00 AM UTC
- 🔄 **Manual**: Via workflow_dispatch
- 📊 **Reporte**: Resumen en GitHub Actions

### Monitoreo de Integridad

```bash
# Script para monitoreo continuo
#!/bin/bash
IMAGES=("ansible" "python" "terraform" "go")

for image in "${IMAGES[@]}"; do
  if ! ./scripts/verify-signatures.sh "$image"; then
    # Alertar al equipo de seguridad
    echo "ALERT: Signature verification failed for $image"
    # Integración con sistemas de alertas (Slack, PagerDuty, etc.)
  fi
done
```

## 🛠️ Herramientas y Recursos

### Instalación de Cosign

```bash
# Linux
curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
sudo mv cosign-linux-amd64 /usr/local/bin/cosign
sudo chmod +x /usr/local/bin/cosign

# macOS
brew install cosign

# Windows
choco install cosign
```

### Herramientas Complementarias

- **[Syft](https://github.com/anchore/syft)**: Generación de SBOM
- **[Grype](https://github.com/anchore/grype)**: Escáner de vulnerabilidades
- **[Rekor](https://docs.sigstore.dev/rekor/overview/)**: Transparency log
- **[Fulcio](https://docs.sigstore.dev/fulcio/overview/)**: CA para certificados

## 📚 Recursos Adicionales

- 📖 [Documentación oficial de Cosign](https://docs.sigstore.dev/cosign/overview/)
- 🎓 [Tutorial de Sigstore](https://docs.sigstore.dev/cosign/working_with_containers/)
- 🔐 [Mejores prácticas de seguridad](https://slsa.dev/)
- 📋 [Especificación SPDX](https://spdx.dev/)

## 🤝 Contribución

Para contribuir mejoras a la implementación de firmas:

1. 🔀 Fork el repositorio
2. 🌿 Crear branch para la funcionalidad
3. ✅ Asegurar que las firmas funcionen correctamente
4. 🧪 Probar el script de verificación
5. 📝 Actualizar documentación si es necesario
6. 🔄 Crear Pull Request

## ❓ Preguntas Frecuentes

### ¿Por qué keyless signing?

El keyless signing elimina la complejidad de gestionar claves privadas mientras proporciona la misma seguridad usando identidades OIDC verificables.

### ¿Qué pasa si GitHub Actions está comprometido?

Las firmas están vinculadas a identidades específicas del repositorio. Cualquier compromiso sería visible en los logs de transparencia de Rekor.

### ¿Puedo usar estas imágenes en entornos air-gapped?

Sí, pero necesitarás configurar verificación offline usando los certificados descargados previamente.

### ¿Cómo verifico imágenes anteriores?

Todas las firmas están almacenadas permanentemente en Rekor y pueden verificarse usando los mismos comandos con tags específicos.

---

*Para más información sobre seguridad de contenedores, consulta nuestras [guías de seguridad](SECURITY.md).*
