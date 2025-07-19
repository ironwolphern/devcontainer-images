#!/bin/bash
# Este script verifica las firmas Cosign de las imágenes de DevContainer

set -euo pipefail

# Configuración
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY="${REPOSITORY:-ironwolphern/devcontainer-images}"
IMAGES=("ansible" "python" "terraform" "go")
DEFAULT_TAG="${DEFAULT_TAG:-latest}"
CERTIFICATE_IDENTITY_REGEXP="${CERTIFICATE_IDENTITY_REGEXP:-^https://github.com/${REPOSITORY}}"
CERTIFICATE_OIDC_ISSUER="${CERTIFICATE_OIDC_ISSUER:-https://token.actions.githubusercontent.com}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de utilidad
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
DevContainer Images - Verificador de Firmas

USO:
    $0 [OPCIONES] [IMAGEN] [TAG]

OPCIONES:
    -h, --help              Mostrar esta ayuda
    -v, --verbose           Modo verbose
    -a, --all               Verificar todas las imágenes
    -s, --sbom              También verificar SBOM
    --policy FILE           Usar archivo de política específico
    --list-tags IMAGEN      Listar tags disponibles para una imagen
    --check-available       Solo verificar disponibilidad de imágenes

ARGUMENTOS:
    IMAGEN                  Imagen a verificar (ansible, python, terraform, go)
                           Si no se especifica, se verifican todas
    TAG                     Tag de la imagen (default: latest)

EJEMPLOS:
    $0                      # Verificar todas las imágenes con tag 'latest'
    $0 ansible              # Verificar imagen ansible con tag 'latest'
    $0 python v1.0.0        # Verificar imagen python con tag 'v1.0.0'
    $0 --sbom terraform     # Verificar firma y SBOM de terraform
    $0 --list-tags python   # Listar tags disponibles para python
    $0 --check-available    # Solo verificar que las imágenes están disponibles

ENVIRONMENT VARIABLES:
    REGISTRY                Registry URL (default: ghcr.io)
    REPOSITORY              Repository name (default: ironwolphern/devcontainer-images)
    CERTIFICATE_IDENTITY_REGEXP
    CERTIFICATE_OIDC_ISSUER

REQUISITOS:
    - cosign (v2.0+)
    - docker o podman
    - jq (opcional, para análisis de SBOM)

EOF
}

check_dependencies() {
    log_info "Verificando dependencias..."

    if ! command -v cosign >/dev/null 2>&1; then
        log_error "Cosign no está instalado. Instálalo desde: https://docs.sigstore.dev/cosign/installation/"
        exit 1
    fi

    if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
        log_error "Docker o Podman requerido para verificar que las imágenes existen"
        exit 1
    fi

    if command -v docker >/dev/null 2>&1; then
        CONTAINER_CMD="docker"
    else
        CONTAINER_CMD="podman"
    fi

    log_success "Dependencias verificadas"
}

image_exists() {
    local image="$1"
    log_info "Verificando que la imagen existe: $image"

    if $CONTAINER_CMD manifest inspect "$image" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

verify_signature() {
    local image="$1"
    local verbose="${2:-false}"

    log_info "🔍 Verificando firma para: $image"

    # Primero verificar que la imagen existe
    if ! image_exists "$image"; then
        log_error "❌ La imagen no existe o no es accesible: $image"
        return 1
    fi

    # Configurar variables de entorno para Cosign
    export COSIGN_EXPERIMENTAL=1

    local cmd="cosign verify \
        --certificate-identity-regexp='$CERTIFICATE_IDENTITY_REGEXP' \
        --certificate-oidc-issuer='$CERTIFICATE_OIDC_ISSUER' \
        '$image'"

    if [[ "$verbose" == "true" ]]; then
        log_info "Ejecutando: $cmd"
    fi

    if eval "$cmd" >/dev/null 2>&1; then
        log_success "✅ Firma verificada para: $image"
        return 0
    else
        log_error "❌ Verificación de firma fallida para: $image"
        return 1
    fi
}

verify_sbom() {
    local image="$1"
    local verbose="${2:-false}"

    log_info "📋 Verificando SBOM para: $image"

    export COSIGN_EXPERIMENTAL=1

    local cmd="cosign verify-attestation \
        --certificate-identity-regexp='$CERTIFICATE_IDENTITY_REGEXP' \
        --certificate-oidc-issuer='$CERTIFICATE_OIDC_ISSUER' \
        --type spdxjson \
        '$image'"

    if [[ "$verbose" == "true" ]]; then
        log_info "Ejecutando: $cmd"
    fi

    if eval "$cmd" >/dev/null 2>&1; then
        log_success "✅ SBOM verificado para: $image"

        # Si jq está disponible, mostrar estadísticas del SBOM
        if command -v jq >/dev/null 2>&1; then
            log_info "📊 Analizando SBOM..."
            local sbom_file="/tmp/sbom_${image//[:\/]/_}.json"

            cosign download attestation \
                --certificate-identity-regexp="^https://github.com/$REPOSITORY" \
                --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
                "$image" > "$sbom_file" 2>/dev/null || true

            if [[ -f "$sbom_file" ]]; then
                local package_count
                package_count=$(jq -r '.payload' "$sbom_file" 2>/dev/null | base64 -d 2>/dev/null | jq -r '.predicate.packages | length' 2>/dev/null || echo "0")
                log_info "📦 Paquetes en SBOM: $package_count"
                rm -f "$sbom_file"
            fi
        fi

        return 0
    else
        log_error "❌ Verificación de SBOM fallida para: $image"
        return 1
    fi
}

list_available_tags() {
    local image_name="$1"
    local image_url="${REGISTRY}/${REPOSITORY}/devcontainer-${image_name}"

    log_info "📋 Listando tags disponibles para devcontainer-${image_name}..."

    # Usar skopeo si está disponible, sino usar API REST
    if command -v skopeo >/dev/null 2>&1; then
        log_info "Usando skopeo para listar tags..."
        if skopeo list-tags "docker://${image_url}" 2>/dev/null | jq -r '.Tags[]?' | sort -V; then
            return 0
        else
            log_warn "Error con skopeo, intentando con API REST..."
        fi
    fi

    # Fallback a API REST
    log_info "Usando API REST para listar tags..."
    local api_url="https://ghcr.io/v2/${REPOSITORY}/devcontainer-${image_name}/tags/list"

    if command -v curl >/dev/null 2>&1; then
        if curl -s "$api_url" | jq -r '.tags[]?' 2>/dev/null | sort -V; then
            return 0
        fi
    fi
    log_error "No se pudieron obtener los tags para devcontainer-${image_name}"
    log_info "Puedes verificar manualmente en: https://github.com/${REPOSITORY}/pkgs/container/devcontainer-${image_name}"
    return 1
}

check_image_availability() {
    local image_name="$1"
    local tag="$2"
    local image_url="${REGISTRY}/${REPOSITORY}/devcontainer-${image_name}:${tag}"

    log_info "🔍 Verificando disponibilidad de: devcontainer-${image_name}:${tag}"

    if image_exists "$image_url"; then
        log_success "✅ Imagen disponible: devcontainer-${image_name}:${tag}"
        return 0
    else
        log_error "❌ Imagen no disponible: devcontainer-${image_name}:${tag}"
        log_info "Tags disponibles para devcontainer-${image_name}:"
        list_available_tags "$image_name" || true
        return 1
    fi
}

main() {
    local images_to_verify=()
    local tag="$DEFAULT_TAG"
    local verify_all=false
    local verify_sbom=false
    local verbose=false
    local policy_file=""
    local list_tags_only=false
    local check_available_only=false
    local target_image_for_tags=""

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -a|--all)
                verify_all=true
                shift
                ;;
            -s|--sbom)
                verify_sbom=true
                shift
                ;;
            --policy)
                policy_file="$2"
                shift 2
                ;;
            --list-tags)
                list_tags_only=true
                target_image_for_tags="$2"
                shift 2
                ;;
            --check-available)
                check_available_only=true
                shift
                ;;
            -*)
                log_error "Opción desconocida: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ ${#images_to_verify[@]} -eq 0 ]]; then
                    images_to_verify=("$1")
                elif [[ ${#images_to_verify[@]} -eq 1 && "$tag" == "$DEFAULT_TAG" ]]; then
                    tag="$1"
                else
                    log_error "Demasiados argumentos posicionales"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Manejar operaciones especiales
    if [[ "$list_tags_only" == "true" ]]; then
        if [[ -z "$target_image_for_tags" ]]; then
            log_error "Debes especificar una imagen para listar tags"
            show_help
            exit 1
        fi
        if [[ ! " ${IMAGES[*]} " =~ " $target_image_for_tags " ]]; then
            log_error "Imagen desconocida: $target_image_for_tags"
            log_info "Imágenes disponibles: ${IMAGES[*]}"
            exit 1
        fi
        list_available_tags "$target_image_for_tags"
        exit $?
    fi

    # Si se especifica --all o no se especifica imagen, verificar todas
    if [[ "$verify_all" == "true" || ${#images_to_verify[@]} -eq 0 ]]; then
        images_to_verify=("${IMAGES[@]}")
    fi

    # Verificar que la imagen especificada es válida
    for img in "${images_to_verify[@]}"; do
        if [[ ! " ${IMAGES[*]} " =~ " $img " ]]; then
            log_error "Imagen desconocida: $img"
            log_info "Imágenes disponibles: ${IMAGES[*]}"
            exit 1
        fi
    done

    check_dependencies

    # Si solo se quiere verificar disponibilidad, hacerlo y salir
    if [[ "$check_available_only" == "true" ]]; then
        log_info "🔍 Verificando solo disponibilidad de imágenes..."
        local available_count=0
        for image_name in "${images_to_verify[@]}"; do
            if check_image_availability "$image_name" "$tag"; then
                ((available_count++))
            fi
        done

        log_info "📊 Resultado: $available_count/${#images_to_verify[@]} imágenes disponibles"

        if [[ $available_count -eq ${#images_to_verify[@]} ]]; then
            log_success "✅ Todas las imágenes están disponibles"
            exit 0
        else
            log_error "❌ Algunas imágenes no están disponibles"
            exit 1
        fi
    fi

    log_info "🚀 Iniciando verificación de firmas"
    log_info "Registry: $REGISTRY"
    log_info "Repository: $REPOSITORY"
    log_info "Images: ${images_to_verify[*]}"
    log_info "Tag: $tag"

    local success_count=0
    local total_count=${#images_to_verify[@]}
    local failed_images=()

    for image_name in "${images_to_verify[@]}"; do
        local full_image="$REGISTRY/$REPOSITORY/devcontainer-$image_name:$tag"

        echo ""
        log_info "🔄 Procesando: $image_name"

        # Verificar que la imagen existe y está disponible
        if ! check_image_availability "$image_name" "$tag"; then
            failed_images+=("$image_name")
            continue
        fi

        # Verificar firma
        if verify_signature "$full_image" "$verbose"; then
            ((success_count++))

            # Verificar SBOM si se solicita
            if [[ "$verify_sbom" == "true" ]]; then
                if ! verify_sbom "$full_image" "$verbose"; then
                    failed_images+=("$image_name (SBOM)")
                    ((success_count--))
                fi
            fi
        else
            failed_images+=("$image_name (firma)")
        fi
    done

    echo ""
    echo "=========================================="
    log_info "📊 RESUMEN DE VERIFICACIÓN"
    echo "=========================================="
    log_info "Imágenes procesadas: $total_count"
    log_success "Verificaciones exitosas: $success_count"

    if [[ ${#failed_images[@]} -gt 0 ]]; then
        log_error "Verificaciones fallidas: ${#failed_images[@]}"
        for failed in "${failed_images[@]}"; do
            log_error "  - $failed"
        done
        echo ""
        log_error "❌ Algunas verificaciones fallaron"
        exit 1
    else
        echo ""
        log_success "✅ Todas las verificaciones completadas exitosamente"
        exit 0
    fi
}

# Ejecutar función principal con todos los argumentos
main "$@"
