#!/bin/bash
#
# Build and push Hindsight Docker images to GitHub Container Registry (GHCR)
#
# Usage:
#   ./scripts/docker-push-ghcr.sh [standalone|api|cp] [tag]
#
# Examples:
#   ./scripts/docker-push-ghcr.sh                    # Build and push all images with 'latest' tag
#   ./scripts/docker-push-ghcr.sh standalone v0.2.1  # Build and push standalone image with version tag
#   ./scripts/docker-push-ghcr.sh api latest         # Build and push API-only image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GHCR_REGISTRY="ghcr.io"
GHCR_ORG="flux-frontiers"
IMAGE_NAME="hindsight"
BUILD_TYPE="${1:-all}"
TAG="${2:-latest}"

# GitHub Container Registry requires authentication
echo -e "${YELLOW}Checking GHCR authentication...${NC}"
if ! echo "$CR_PAT" | docker login $GHCR_REGISTRY -u USERNAME --password-stdin 2>/dev/null; then
    echo -e "${RED}ERROR: Not authenticated to GHCR${NC}"
    echo ""
    echo "To authenticate, you need a GitHub Personal Access Token (PAT) with 'write:packages' scope:"
    echo ""
    echo "  1. Go to: https://github.com/settings/tokens/new"
    echo "  2. Create token with 'write:packages' and 'read:packages' scopes"
    echo "  3. Export it: export CR_PAT=YOUR_TOKEN"
    echo "  4. Login: echo \$CR_PAT | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Authenticated to GHCR${NC}"
echo ""

# Function to build and push an image
build_and_push() {
    local target=$1
    local image_suffix=$2
    local full_image="${GHCR_REGISTRY}/${GHCR_ORG}/${IMAGE_NAME}${image_suffix}"

    echo -e "${YELLOW}Building $full_image:$TAG${NC}"
    echo "  Target: $target"
    echo ""

    docker build \
        -f docker/standalone/Dockerfile \
        --target "$target" \
        -t "$full_image:$TAG" \
        .

    echo ""
    echo -e "${YELLOW}Pushing $full_image:$TAG${NC}"
    docker push "$full_image:$TAG"

    echo -e "${GREEN}✓ Successfully pushed $full_image:$TAG${NC}"
    echo ""
}

# Build and push based on type
case "$BUILD_TYPE" in
    standalone)
        build_and_push "standalone" ""
        ;;
    api)
        build_and_push "api-only" "-api"
        ;;
    cp)
        build_and_push "cp-only" "-cp"
        ;;
    all)
        echo -e "${YELLOW}Building all image variants...${NC}"
        echo ""
        build_and_push "standalone" ""
        build_and_push "api-only" "-api"
        build_and_push "cp-only" "-cp"
        ;;
    *)
        echo -e "${RED}ERROR: Invalid build type '$BUILD_TYPE'${NC}"
        echo ""
        echo "Usage: $0 [standalone|api|cp|all] [tag]"
        exit 1
        ;;
esac

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}All images pushed successfully!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Published images:"
case "$BUILD_TYPE" in
    standalone)
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME:$TAG"
        ;;
    api)
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-api:$TAG"
        ;;
    cp)
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-cp:$TAG"
        ;;
    all)
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME:$TAG (standalone)"
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-api:$TAG"
        echo "  - $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-cp:$TAG"
        ;;
esac
echo ""
echo "To pull these images:"
case "$BUILD_TYPE" in
    standalone)
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME:$TAG"
        ;;
    api)
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-api:$TAG"
        ;;
    cp)
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-cp:$TAG"
        ;;
    all)
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME:$TAG"
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-api:$TAG"
        echo "  docker pull $GHCR_REGISTRY/$GHCR_ORG/$IMAGE_NAME-cp:$TAG"
        ;;
esac
echo ""
echo "To make images public, visit:"
echo "  https://github.com/orgs/$GHCR_ORG/packages?repo_name=$IMAGE_NAME"
