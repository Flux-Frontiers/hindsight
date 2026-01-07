#!/bin/bash
# Check status of Hindsight packages on GHCR
# Usage: ./scripts/check-ghcr-status.sh

set -e

ORG="flux-frontiers"
PACKAGES=("hindsight-persagent" "hindsight-api-persagent" "hindsight-control-plane-persagent")

echo "Checking GHCR package status for $ORG..."
echo ""

for package in "${PACKAGES[@]}"; do
    echo "Checking: ghcr.io/$ORG/$package"
    
    # Try to pull without auth (tests if public)
    if docker pull "ghcr.io/$ORG/$package:latest" 2>&1 | grep -q "unauthorized\|denied"; then
        echo "  ❌ PRIVATE - Requires authentication"
    else
        echo "  ✅ PUBLIC - Accessible without auth"
    fi
    echo ""
done

echo "To check package settings manually:"
echo "  https://github.com/orgs/$ORG/packages"
echo ""
echo "To check organization settings:"
echo "  https://github.com/organizations/$ORG/settings/packages"
