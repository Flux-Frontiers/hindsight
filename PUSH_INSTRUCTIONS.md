# Push Instructions for Hindsight PersAgent Images

## Quick Push to GHCR

Your images will be named:
- `ghcr.io/flux-frontiers/hindsight-persagent:latest`
- `ghcr.io/flux-frontiers/hindsight-api-persagent:latest`
- `ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest`

### Option 1: Use the Script (Recommended)

```bash
# Login to GHCR first
export GITHUB_TOKEN=your_github_token
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Build and push all three images
./scripts/push-to-ghcr.sh all latest
```

### Option 2: Manual Build and Push

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Build all three variants
docker build -f docker/standalone/Dockerfile --target standalone \
  -t ghcr.io/flux-frontiers/hindsight-persagent:latest .

docker build -f docker/standalone/Dockerfile --target api-only \
  -t ghcr.io/flux-frontiers/hindsight-api-persagent:latest .

docker build -f docker/standalone/Dockerfile --target cp-only \
  -t ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest .

# Push all three
docker push ghcr.io/flux-frontiers/hindsight-persagent:latest
docker push ghcr.io/flux-frontiers/hindsight-api-persagent:latest
docker push ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest
```

### Option 3: Use GitHub Actions

1. Commit and push these changes to main branch
2. Go to https://github.com/flux-frontiers/hindsight/actions
3. Click "Build and Push Docker Images"
4. Click "Run workflow"
5. Wait for build to complete

## Make Images Public

After pushing, make the packages public:

1. Go to https://github.com/orgs/flux-frontiers/packages
2. Find each package:
   - `hindsight-persagent`
   - `hindsight-api-persagent`
   - `hindsight-control-plane-persagent`
3. For each package:
   - Click on the package name
   - Click "Package settings" (bottom right)
   - Scroll to "Danger Zone"
   - Click "Change visibility" → "Public"
   - Type the package name to confirm
   - Click "I understand, change package visibility"

## Verify Public Access

```bash
# Check if packages are public
./scripts/check-ghcr-status.sh

# Should show:
# ✅ PUBLIC - Accessible without auth
```

## Test Your Images

Once public, anyone can use them:

```bash
# Pull and run (no authentication needed!)
docker pull ghcr.io/flux-frontiers/hindsight-persagent:latest

docker run -d -p 8888:8888 -p 9999:9999 \
  -e HINDSIGHT_API_LLM_API_KEY=your-openai-key \
  --name hindsight-persagent \
  ghcr.io/flux-frontiers/hindsight-persagent:latest

# Access UI: http://localhost:9999
# Access API: http://localhost:8888
```

## Troubleshooting

### "unauthorized: unauthenticated"
- Make sure you're logged in: `docker login ghcr.io`
- Check your GITHUB_TOKEN has `write:packages` permission

### "denied: permission_denied"
- Ensure you have write access to the flux-frontiers organization
- Check organization package settings allow member uploads

### Build fails with disk space error
- Clean up Docker: `docker system prune -a -f`
- The GitHub Actions workflow includes automatic cleanup

## Next Steps

1. ✅ Push images using one of the methods above
2. ✅ Make packages public at https://github.com/orgs/flux-frontiers/packages
3. ✅ Verify with `./scripts/check-ghcr-status.sh`
4. ✅ Share the public images with your team!

Your images will be available at:
- `ghcr.io/flux-frontiers/hindsight-persagent:latest`
- `ghcr.io/flux-frontiers/hindsight-api-persagent:latest`
- `ghcr.io/flux-frontiers/hindsight-control-plane-persagent:latest`
