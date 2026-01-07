# ✅ Docker Setup Complete

Your Hindsight Docker images are now configured to build and publish to GitHub Container Registry with unique names!

## 📦 Your Fork's Images

Your images will use the `-persagent` suffix to avoid conflicts with upstream packages:

- **Standalone** (API + Control Plane): `ghcr.io/flux-frontiers/hindsight-persagent:latest`
- **API Only**: `ghcr.io/flux-frontiers/hindsight-api-persagent:latest`
- **Control Plane Only**: `ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest`

## Why `-persagent` Suffix?

The flux-frontiers organization already has packages from the upstream hindsight repo. The `-persagent` suffix ensures:
- ✅ No conflicts with upstream packages
- ✅ Clear distinction between upstream and your fork
- ✅ Independent version management

## Quick Start

### Build and Push Locally

```bash
# Build and push all variants
./scripts/push-to-ghcr.sh all latest

# Or build specific variant
./scripts/push-to-ghcr.sh standalone latest
```

### Use GitHub Actions

1. **Commit and push** these changes to main branch
2. **Workflow runs automatically** and pushes to GHCR
3. **Make packages public** at https://github.com/orgs/flux-frontiers/packages

## Usage Example

Once public, anyone can use your fork's images:

```bash
# Pull and run your fork's standalone image
docker pull ghcr.io/flux-frontiers/hindsight-persagent:latest

docker run -d -p 8888:8888 -p 9999:9999 \
  -e HINDSIGHT_API_LLM_API_KEY=your-openai-key \
  --name hindsight \
  ghcr.io/flux-frontiers/hindsight-persagent:latest

# Access UI at http://localhost:9999
# Access API at http://localhost:8888
```

## Check Status

```bash
# Verify your fork's packages are public
./scripts/check-ghcr-status.sh
```

## What Was Set Up

1. ✅ GitHub Actions workflow for automated builds
2. ✅ Removed hardcoded API key from Dockerfile (security fix)
3. ✅ Local build/push script with `-persagent` suffix
4. ✅ Status check script for your fork's packages
5. ✅ Comprehensive documentation
6. ✅ Unique package names to avoid upstream conflicts

## Files Created/Modified

- [`.github/workflows/docker-build-push.yml`](.github/workflows/docker-build-push.yml) - Automated build workflow
- [`docker/standalone/Dockerfile`](docker/standalone/Dockerfile) - Removed hardcoded API key
- [`scripts/push-to-ghcr.sh`](scripts/push-to-ghcr.sh) - Local build/push script
- [`scripts/check-ghcr-status.sh`](scripts/check-ghcr-status.sh) - Status verification script
- [`DOCKER_BUILD_GUIDE.md`](DOCKER_BUILD_GUIDE.md) - Comprehensive documentation

## Next Steps

1. **Commit and push** these changes to trigger the first automated build
2. **Monitor build** in Actions tab: https://github.com/flux-frontiers/hindsight/actions
3. **Make packages public** at: https://github.com/orgs/flux-frontiers/packages
   - Look for: `hindsight-persagent`, `hindsight-api-persagent`, `hindsight-control-plane-persagent`
4. **Share your fork's images** with your team

## Comparison: Upstream vs Fork

| Package | Upstream | Your Fork |
|---------|----------|-----------|
| Standalone | `ghcr.io/flux-frontiers/hindsight` | `ghcr.io/flux-frontiers/hindsight-persagent` |
| API Only | `ghcr.io/flux-frontiers/hindsight-api` | `ghcr.io/flux-frontiers/hindsight-api-persagent` |
| Control Plane | `ghcr.io/flux-frontiers/hindsight-control-plane` | `ghcr.io/flux-frontiers/hindsight-control-plane-persagent` |

## Resources

- **Your fork's packages**: https://github.com/orgs/flux-frontiers/packages (look for `-persagent` suffix)
- **Workflow runs**: https://github.com/flux-frontiers/hindsight/actions
- **Full guide**: [`DOCKER_BUILD_GUIDE.md`](DOCKER_BUILD_GUIDE.md)

---

**Status**: ✅ Ready to build and push your fork's Docker images!
