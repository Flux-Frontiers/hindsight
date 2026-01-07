#!/bin/bash
# Push Hindsight Docker images to GitHub Container Registry (GHCR)
# Usage: ./scripts/push-to-ghcr.sh [variant] [tag]
#   variant: standalone, api, cp, or all (default: all)
#   tag: image tag (default: latest)

set -e

VARIANT="${1:-all}"
TAG="${2:-latest}"
ORG="flux-frontiers"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Building and pushing Hindsight Docker images to GHCR${NC}"
echo "Organization: $ORG"
echo "Tag: $TAG"
echo ""

# Function to build and push an image
build_and_push() {
    local target=$1
    local image_name=$2
    local full_name="ghcr.io/$ORG/$image_name-persagent:$TAG"
    
    echo -e "${GREEN}Building $image_name...${NC}"
    docker build -f docker/standalone/Dockerfile --target "$target" -t "$full_name" .
    
    echo -e "${GREEN}Pushing $full_name...${NC}"
    docker push "$full_name"
    
    echo -e "${GREEN}✓ Successfully pushed $full_name${NC}"
    echo ""
}

# Check if logged in to GHCR
if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
    echo "Not logged in to GHCR. Attempting login..."
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "Error: GITHUB_TOKEN environment variable not set"
        echo "Please run: export GITHUB_TOKEN=your_token"
        echo "Or login manually: echo \$GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin"
        exit 1
    fi
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$USER" --password-stdin
fi

# Build and push based on variant
case "$VARIANT" in
    standalone)
        build_and_push "standalone" "hindsight"
        ;;
    api)
        build_and_push "api-only" "hindsight-api"
        ;;
    cp)
        build_and_push "cp-only" "hindsight-control-plane"
        ;;
    all)
        build_and_push "standalone" "hindsight"
        build_and_push "api-only" "hindsight-api"
        build_and_push "cp-only" "hindsight-control-plane"
        ;;
    *)
        echo "Error: Unknown variant '$VARIANT'"
        echo "Usage: $0 [standalone|api|cp|all] [tag]"
        exit 1
        ;;
esac

echo -e "${GREEN}All done! 🎉${NC}"
echo ""
echo "Your images are now available at:"
if [ "$VARIANT" = "all" ] || [ "$VARIANT" = "standalone" ]; then
    echo "  ghcr.io/$ORG/hindsight-persagent:$TAG"
fi
if [ "$VARIANT" = "all" ] || [ "$VARIANT" = "api" ]; then
    echo "  ghcr.io/$ORG/hindsight-api-persagent:$TAG"
fi
if [ "$VARIANT" = "all" ] || [ "$VARIANT" = "cp" ]; then
    echo "  ghcr.io/$ORG/hindsight-control-plane-persagent:$TAG"
fi
echo ""
echo "To make them public, visit: https://github.com/orgs/$ORG/packages"
