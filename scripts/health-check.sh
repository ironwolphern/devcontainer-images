#!/bin/bash

# Quick health check script for DevContainer Images
# Returns 0 if all is OK, 1 if there are issues

set -eo pipefail

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
REPOSITORY="${REPOSITORY:-ironwolphern/devcontainer-images}"
IMAGES=("ansible" "python" "terraform" "go")
TAG="${TAG:-latest}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Quick checks
check_tool() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        echo -e "✅ $tool"
        return 0
    else
        echo -e "❌ $tool"
        return 1
    fi
}

check_env_var() {
    local var="$1"
    if [ -n "${!var}" ]; then
        echo -e "✅ $var"
        return 0
    else
        echo -e "❌ $var"
        return 1
    fi
}

check_image() {
    local image="$1"
    local full_image="$REGISTRY/$REPOSITORY/devcontainer-$image:$TAG"
    
    if docker manifest inspect "$full_image" >/dev/null 2>&1; then
        echo -e "✅ devcontainer-$image:$TAG"
        return 0
    else
        echo -e "❌ devcontainer-$image:$TAG"
        return 1
    fi
}

# Main health check
main() {
    local issues=0
    
    echo "🩺 DevContainer Images Health Check"
    echo "=================================="
    echo ""
    
    # Check tools
    echo "🔧 Tools:"
    check_tool "docker" || ((issues++))
    check_tool "cosign" || ((issues++))
    check_tool "gh" || ((issues++))
    echo ""
    
    # Check environment
    echo "🌍 Environment:"
    check_env_var "GITHUB_TOKEN" || ((issues++))
    check_env_var "GITHUB_USERNAME" || ((issues++))
    echo ""
    
    # Check images
    echo "🐳 Images ($REGISTRY/$REPOSITORY):"
    for image in "${IMAGES[@]}"; do
        check_image "$image" || ((issues++))
    done
    echo ""
    
    # Summary
    if [ $issues -eq 0 ]; then
        echo -e "${GREEN}✅ All checks passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Found $issues issue(s)${NC}"
        echo ""
        echo "🔧 Quick fixes:"
        echo "  - Missing tools: see TROUBLESHOOTING.md"
        echo "  - Missing env vars: set GITHUB_TOKEN and GITHUB_USERNAME"
        echo "  - Missing images: run 'make trigger-build' or 'make fix-missing-images'"
        echo ""
        echo "📚 For detailed troubleshooting: see TROUBLESHOOTING.md"
        return 1
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "DevContainer Images Health Check"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help"
        echo "  --quiet, -q   Quiet mode (exit code only)"
        echo ""
        echo "Environment variables:"
        echo "  REGISTRY      Registry URL (default: ghcr.io)"
        echo "  REPOSITORY    Repository name (default: ironwolphern/devcontainer-images)"
        echo "  TAG           Tag to check (default: latest)"
        exit 0
        ;;
    --quiet|-q)
        main >/dev/null 2>&1
        exit $?
        ;;
    *)
        main
        exit $?
        ;;
esac
