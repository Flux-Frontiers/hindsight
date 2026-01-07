# Docker Build & Push Guide

This guide explains how to build and push Hindsight Docker images to your own GitHub Container Registry (GHCR).

**Note**: These images use the `-persagent` suffix to avoid conflicts with the upstream hindsight packages in the flux-frontiers organization.

## Quick Start

### Automated Build (Recommended)

The easiest way is to use GitHub Actions:

1. **Push to your main branch** - The workflow will automatically build and push all three images
2. **Manual trigger** - Go to Actions → "Build and Push Docker Images" → "Run workflow"

Images will be pushed to:
- `ghcr.io/flux-frontiers/hindsight-persagent:latest` (standalone - API + Control Plane)
- `ghcr.io/flux-frontiers/hindsight-api-persagent:latest` (API only)
- `ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest` (Control Plane only)

### Manual Build (Local)

If you need to build locally:

```bash
# Build all three variants
docker build -f docker/standalone/Dockerfile --target standalone -t ghcr.io/flux-frontiers/hindsight-persagent:latest .
docker build -f docker/standalone/Dockerfile --target api-only -t ghcr.io/flux-frontiers/hindsight-api-persagent:latest .
docker build -f docker/standalone/Dockerfile --target cp-only -t ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest .

# Login to GHCR (one-time setup)
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Push images
docker push ghcr.io/flux-frontiers/hindsight-persagent:latest
docker push ghcr.io/flux-frontiers/hindsight-api-persagent:latest
docker push ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest
```

## Making Images Public

After pushing, your images will be private by default. To make them public:

### If You're an Organization Owner/Admin

1. **Enable public packages in organization settings** (one-time setup):
   - Go to https://github.com/organizations/flux-frontiers/settings/packages
   - Under "Package creation", ensure "Public" is enabled
   - Under "Package visibility", allow members to change visibility

2. **Make each package public**:
   - Go to https://github.com/orgs/flux-frontiers/packages
   - Click on each package (hindsight-persagent, hindsight-api-persagent, hindsight-control-plane-persagent)
   - Click "Package settings" (bottom right)
   - Scroll to "Danger Zone"
   - Click "Change visibility" → "Public"
   - Confirm the change

### If You're Not an Admin

Ask an organization owner to:
1. Go to https://github.com/organizations/flux-frontiers/settings/packages
2. Enable "Public" package creation
3. Allow members to change package visibility

Or ask them to make the packages public for you.

## GitHub Actions Workflow

The workflow file [`.github/workflows/docker-build-push.yml`](.github/workflows/docker-build-push.yml) is configured to:

- **Trigger on**: 
  - Every push to `main` branch
  - Manual workflow dispatch (Actions tab)
- **Build**: All three image variants (standalone, api-only, cp-only)
- **Platforms**: linux/amd64 and linux/arm64
- **Push to**: `ghcr.io/flux-frontiers/IMAGE_NAME-persagent`
- **Tags**: 
  - `latest` (for main branch)
  - `main-<sha>` (commit-specific)
  - `main` (branch name)

## Image Variants

### 1. Standalone (`hindsight-persagent:latest`)
- **Contains**: API + Control Plane
- **Ports**: 8888 (API), 9999 (Control Plane)
- **Use case**: All-in-one deployment
- **Size**: ~2.5GB

```bash
docker run -p 8888:8888 -p 9999:9999 \
  -e HINDSIGHT_API_LLM_API_KEY=your-key \
  ghcr.io/flux-frontiers/hindsight-persagent:latest
```

### 2. API Only (`hindsight-api-persagent:latest`)
- **Contains**: API only
- **Port**: 8888
- **Use case**: Separate API deployment, connect external UI
- **Size**: ~2GB

```bash
docker run -p 8888:8888 \
  -e HINDSIGHT_API_LLM_API_KEY=your-key \
  ghcr.io/flux-frontiers/hindsight-api-persagent:latest
```

### 3. Control Plane Only (`hindsight-control-plane-persagent:latest`)
- **Contains**: Control Plane UI only
- **Port**: 9999
- **Use case**: Connect to external API
- **Size**: ~200MB

```bash
docker run -p 9999:9999 \
  -e HINDSIGHT_CP_DATAPLANE_API_URL=http://your-api:8888 \
  ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest
```

## Build Options

The Dockerfile supports several build arguments:

```bash
# Skip ML model preload (faster build, models download at runtime)
docker build --build-arg PRELOAD_ML_MODELS=false -f docker/standalone/Dockerfile -t hindsight-persagent .

# Build specific variant
docker build --target api-only -f docker/standalone/Dockerfile -t hindsight-api-persagent .
docker build --target cp-only -f docker/standalone/Dockerfile -t hindsight-cp-persagent .
docker build --target standalone -f docker/standalone/Dockerfile -t hindsight-persagent .
```

## Environment Variables

### API Configuration

```bash
# LLM Provider (required)
HINDSIGHT_API_LLM_PROVIDER=openai          # or: anthropic, groq, ollama
HINDSIGHT_API_LLM_API_KEY=your-key         # Required for most providers
HINDSIGHT_API_LLM_MODEL=gpt-4o-mini        # Model name
HINDSIGHT_API_LLM_BASE_URL=http://...      # Optional: custom endpoint

# Database
HINDSIGHT_API_DATABASE_URL=pg0             # Default: embedded PostgreSQL
# Or: postgresql://user:pass@host:5432/db

# Server
HINDSIGHT_API_HOST=0.0.0.0
HINDSIGHT_API_PORT=8888
HINDSIGHT_API_LOG_LEVEL=info

# Embeddings & Reranking
HINDSIGHT_API_EMBEDDINGS_PROVIDER=local    # or: openai, voyage
HINDSIGHT_API_RERANKER_PROVIDER=local      # or: cohere, voyage
```

### Control Plane Configuration

```bash
# API Connection (required)
HINDSIGHT_CP_DATAPLANE_API_URL=http://localhost:8888

# Node.js
NODE_ENV=production
```

## Troubleshooting

### Build Fails with "No space left on device"

The workflow includes disk space cleanup, but if building locally:

```bash
# Clean up Docker
docker system prune -a -f

# Or use the free-disk-space action in CI
```

### Images are too large

```bash
# Skip ML model preload (saves ~1GB)
docker build --build-arg PRELOAD_ML_MODELS=false ...

# Models will download on first use instead
```

### Can't push to GHCR

```bash
# Ensure you're logged in
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Check token has write:packages permission
# Create token at: https://github.com/settings/tokens/new
```

### Multi-platform build fails locally

```bash
# Install QEMU for cross-platform builds
docker run --privileged --rm tonistiigi/binfmt --install all

# Or build single platform
docker build --platform linux/amd64 ...
```

## Using Your Images

Once pushed and made public, anyone can use your images:

```bash
# Pull and run standalone
docker pull ghcr.io/flux-frontiers/hindsight-persagent:latest
docker run -p 8888:8888 -p 9999:9999 \
  -e HINDSIGHT_API_LLM_API_KEY=your-key \
  ghcr.io/flux-frontiers/hindsight-persagent:latest

# Access UI at http://localhost:9999
# Access API at http://localhost:8888
```

## Updating Images

To update your images with new changes:

1. **Commit and push** your changes to main branch
2. **GitHub Actions** will automatically build and push new images
3. **Pull latest** on deployment machines:
   ```bash
   docker pull ghcr.io/flux-frontiers/hindsight-persagent:latest
   docker stop hindsight && docker rm hindsight
   docker run -d -p 8888:8888 -p 9999:9999 \
     -e HINDSIGHT_API_LLM_API_KEY=your-key \
     --name hindsight \
     ghcr.io/flux-frontiers/hindsight-persagent:latest
   ```

## Advanced: Custom Tags

To create custom tags (e.g., version numbers):

```bash
# Build with custom tag
docker build -f docker/standalone/Dockerfile -t ghcr.io/flux-frontiers/hindsight-persagent:v1.0.0 .

# Push custom tag
docker push ghcr.io/flux-frontiers/hindsight-persagent:v1.0.0

# Also tag as latest
docker tag ghcr.io/flux-frontiers/hindsight-persagent:v1.0.0 ghcr.io/flux-frontiers/hindsight-persagent:latest
docker push ghcr.io/flux-frontiers/hindsight-persagent:latest
```

## Why the `-persagent` Suffix?

The flux-frontiers organization already has packages named `hindsight`, `hindsight-api`, and `hindsight-control-plane` from the upstream repository. To avoid conflicts and allow your fork to publish its own images, we use the `-persagent` suffix. This ensures:

- No conflicts with upstream packages
- Clear distinction between upstream and fork images
- Ability to maintain your own versions independently

## Resources

- **Dockerfile**: [`docker/standalone/Dockerfile`](docker/standalone/Dockerfile)
- **Workflow**: [`.github/workflows/docker-build-push.yml`](.github/workflows/docker-build-push.yml)
- **Deployment Guide**: [`DEPLOYMENT.md`](DEPLOYMENT.md)
- **GHCR Docs**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
