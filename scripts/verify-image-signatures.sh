#!/bin/bash

# Script para verificar firmas de imágenes DevContainer
# Uso: ./verify-image-signatures.sh [imagen] [tag]

set -euo pipefail

# Configuración
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY="${REPOSITORY:-ironwolphern/devcontainer-images}"
CERTIFICATE_IDENTITY_REGEXP="${CERTIFICATE_IDENTITY_REGEXP:-^https://github.com/${REPOSITORY}}"
CERTIFICATE_OIDC_ISSUER="${CERTIFICATE_OIDC_ISSUER:-https://token.actions.githubusercontent.com}"

# Imágenes disponibles
AVAILABLE_IMAGES=("ansible" "python" "terraform" "go")

# Función para mostrar ayuda
show_help() {
    cat << EOF
Verificador de Firmas de Imágenes DevContainer

USAGE:
    $(basename "$0") [OPTIONS] [IMAGE] [TAG]

ARGUMENTS:
    IMAGE       Imagen a verificar (ansible, python, terraform, go, all)
    TAG         Tag específico a verificar (opcional, por defecto: latest)

OPTIONS:
    -h, --help              Mostrar esta ayuda
    -v, --verbose           Modo verbose
    -r, --registry URL      Registry URL (por defecto: ghcr.io)
    --repo REPO             Repository (por defecto: ironwolphern/devcontainer-images)
    --sbom                  También verificar SBOM
    --list-tags             Listar tags disponibles para la imagen

EXAMPLES:
    # Verificar imagen ansible con tag latest
    $(basename "$0") ansible

    # Verificar imagen específica con tag específico
    $(basename "$0") python v1.0.0

    # Verificar todas las imágenes
    $(basename "$0") all

    # Verificar con SBOM
    $(basename "$0") --sbom terraform latest

    # Listar tags disponibles
    $(basename "$0") --list-tags python

ENVIRONMENT VARIABLES:
    REGISTRY                    Registry URL
    REPOSITORY                  Repository name
    CERTIFICATE_IDENTITY_REGEXP Regexp para identidad del certificado
    CERTIFICATE_OIDC_ISSUER     OIDC issuer para verificación

EOF
}

# Función para logging
log() {
    local level="$1"
    shift
    case "$level" in
        INFO)  echo "ℹ️  $*" ;;
        WARN)  echo "⚠️  $*" ;;
        ERROR) echo "❌ $*" >&2 ;;
        SUCCESS) echo "✅ $*" ;;
        DEBUG) [[ "${VERBOSE:-false}" == "true" ]] && echo "🔍 $*" ;;
    esac
}

# Función para verificar prerrequisitos
check_prerequisites() {
    log DEBUG "Verificando prerrequisitos..."
    
    if ! command -v cosign &> /dev/null; then
        log ERROR "cosign no está instalado. Instálalo desde: https://docs.sigstore.dev/cosign/installation/"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log ERROR "docker no está disponible"
        exit 1
    fi
    
    log DEBUG "Prerrequisitos verificados"
}

# Función para listar tags disponibles
list_tags() {
    local image="$1"
    local image_url="${REGISTRY}/${REPOSITORY}/devcontainer-${image}"
    
    log INFO "Listando tags disponibles para ${image}..."
    
    # Usar docker CLI para listar tags
    if command -v skopeo &> /dev/null; then
        skopeo list-tags "docker://${image_url}" | jq -r '.Tags[]' | sort -V
    else
        log WARN "skopeo no disponible, usando API de registro..."
        # Fallback a API REST si skopeo no está disponible
        curl -s "https://ghcr.io/v2/${REPOSITORY}/devcontainer-${image}/tags/list" | \
            jq -r '.tags[]?' 2>/dev/null | sort -V || \
            log ERROR "No se pudieron obtener los tags"
    fi
}

# Función para verificar si una imagen existe
image_exists() {
    local image_ref="$1"
    
    log DEBUG "Verificando existencia de: $image_ref"
    
    if docker manifest inspect "$image_ref" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para verificar firma de imagen
verify_signature() {
    local image_ref="$1"
    local verify_sbom="${2:-false}"
    
    log INFO "Verificando firma para: $image_ref"
    
    # Verificar que la imagen existe
    if ! image_exists "$image_ref"; then
        log ERROR "La imagen $image_ref no existe o no es accesible"
        return 1
    fi
    
    # Verificar firma
    log DEBUG "Ejecutando verificación de firma..."
    if cosign verify \
        --certificate-identity-regexp="$CERTIFICATE_IDENTITY_REGEXP" \
        --certificate-oidc-issuer="$CERTIFICATE_OIDC_ISSUER" \
        "$image_ref" > /dev/null 2>&1; then
        log SUCCESS "Firma verificada para: $image_ref"
    else
        log ERROR "Verificación de firma fallida para: $image_ref"
        return 1
    fi
    
    # Verificar SBOM si se solicitó
    if [[ "$verify_sbom" == "true" ]]; then
        log INFO "Verificando SBOM para: $image_ref"
        if cosign verify-attestation \
            --certificate-identity-regexp="$CERTIFICATE_IDENTITY_REGEXP" \
            --certificate-oidc-issuer="$CERTIFICATE_OIDC_ISSUER" \
            --type spdxjson \
            "$image_ref" > /dev/null 2>&1; then
            log SUCCESS "SBOM verificado para: $image_ref"
        else
            log WARN "SBOM no disponible o verificación fallida para: $image_ref"
        fi
    fi
    
    return 0
}

# Función para verificar múltiples imágenes
verify_images() {
    local images=("$@")
    local tag="${TAG:-latest}"
    local failed=0
    
    for image in "${images[@]}"; do
        local image_ref="${REGISTRY}/${REPOSITORY}/devcontainer-${image}:${tag}"
        
        log INFO "Procesando imagen: $image"
        
        if verify_signature "$image_ref" "$VERIFY_SBOM"; then
            log SUCCESS "Verificación exitosa para devcontainer-${image}:${tag}"
        else
            log ERROR "Verificación fallida para devcontainer-${image}:${tag}"
            ((failed++))
        fi
        
        echo ""
    done
    
    if [[ $failed -eq 0 ]]; then
        log SUCCESS "Todas las verificaciones completadas exitosamente"
        return 0
    else
        log ERROR "$failed verificación(es) fallaron"
        return 1
    fi
}

# Parsear argumentos
VERBOSE=false
VERIFY_SBOM=false
LIST_TAGS=false
TAG="latest"
IMAGE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --repo)
            REPOSITORY="$2"
            shift 2
            ;;
        --sbom)
            VERIFY_SBOM=true
            shift
            ;;
        --list-tags)
            LIST_TAGS=true
            shift
            ;;
        -*)
            log ERROR "Opción desconocida: $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$IMAGE" ]]; then
                IMAGE="$1"
            elif [[ -z "$TAG" || "$TAG" == "latest" ]]; then
                TAG="$1"
            else
                log ERROR "Demasiados argumentos"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Verificar prerrequisitos
check_prerequisites

# Procesar solicitud de listar tags
if [[ "$LIST_TAGS" == "true" ]]; then
    if [[ -z "$IMAGE" ]]; then
        log ERROR "Debes especificar una imagen para listar tags"
        exit 1
    fi
    
    if [[ "$IMAGE" == "all" ]]; then
        for img in "${AVAILABLE_IMAGES[@]}"; do
            echo "=== devcontainer-${img} ==="
            list_tags "$img"
            echo ""
        done
    else
        list_tags "$IMAGE"
    fi
    exit 0
fi

# Validar imagen
if [[ -z "$IMAGE" ]]; then
    log ERROR "Debes especificar una imagen para verificar"
    show_help
    exit 1
fi

# Configurar experimento de Cosign
export COSIGN_EXPERIMENTAL=1

log INFO "Iniciando verificación de firmas..."
log INFO "Registry: $REGISTRY"
log INFO "Repository: $REPOSITORY"
log INFO "Verificar SBOM: $VERIFY_SBOM"
log INFO "Tag: $TAG"
echo ""

# Procesar verificación
if [[ "$IMAGE" == "all" ]]; then
    verify_images "${AVAILABLE_IMAGES[@]}"
else
    # Validar que la imagen está en la lista de disponibles
    if [[ ! " ${AVAILABLE_IMAGES[*]} " =~ " ${IMAGE} " ]]; then
        log ERROR "Imagen '$IMAGE' no está disponible. Imágenes disponibles: ${AVAILABLE_IMAGES[*]}"
        exit 1
    fi
    
    verify_images "$IMAGE"
fi
