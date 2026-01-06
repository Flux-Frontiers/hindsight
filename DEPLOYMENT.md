# Hindsight Deployment Configuration

## Current Architecture

**Hybrid Setup: Native API + Docker Control Plane**

```
┌─────────────────────────────────────────┐
│  macOS Host                             │
│                                         │
│  ┌────────────────────────────────┐    │
│  │ Native API (Metal GPU)         │    │
│  │ • Ollama (qwen2.5:3b-q8)       │    │
│  │ • Embeddings (MPS/Metal)       │    │
│  │ • PostgreSQL (embedded pg0)    │    │
│  │ • Port: 8888                   │    │
│  └────────────────────────────────┘    │
│            ▲                            │
│            │ HTTP                       │
│  ┌─────────┴──────────────────────┐    │
│  │ Docker: Control Plane          │    │
│  │ • Next.js UI                   │    │
│  │ • Port: 9999                   │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

## Why This Configuration?

1. **Metal GPU Acceleration**: Native API runs directly on macOS, using Apple Silicon's Metal Performance Shaders (MPS) for embeddings and reranking
2. **Data Persistence**: Connected to existing PostgreSQL database with all memory banks
3. **Ollama Integration**: LLM running on host with Metal GPU acceleration
4. **Simple UI Deployment**: Control Plane in Docker for easy management and restarts

## Components

### 1. Native API (hindsight-api)
- **Runtime**: Native Python on macOS
- **LLM**: Ollama (qwen2.5:3b-instruct-q8_0) via Metal
- **Embeddings**: BAAI/bge-small-en-v1.5 (MPS device)
- **Reranker**: cross-encoder/ms-marco-MiniLM-L-6-v2 (MPS device)
- **Database**: Embedded PostgreSQL (pg0) at port 5432
- **Data Location**: `~/.pg0/instances/hindsight/data`
- **Port**: 8888

### 2. Docker Control Plane (hindsight-cp)
- **Runtime**: Docker container (Alpine Linux + Node.js)
- **Framework**: Next.js 16
- **Port**: 9999
- **API Connection**: http://host.docker.internal:8888

### 3. Ollama (System Service)
- **Models**: qwen2.5:3b-instruct-q8_0, plus others
- **Port**: 11434
- **API**: http://localhost:11434/v1

## Running the System

### Start All Services

```bash
# 1. Ensure Ollama is running
ollama serve  # Usually already running as a service

# 2. Start the Native API
cd ~/repos/hindsight/hindsight-api
HINDSIGHT_API_LLM_PROVIDER=ollama \
HINDSIGHT_API_LLM_MODEL=qwen2.5:3b-instruct-q8_0 \
HINDSIGHT_API_LLM_BASE_URL=http://localhost:11434/v1 \
HINDSIGHT_API_LLM_MAX_CONCURRENT=1 \
uv run hindsight-api &

# 3. Start the Docker Control Plane
docker run -d -p 9999:9999 \
  -e HINDSIGHT_CP_DATAPLANE_API_URL=http://host.docker.internal:8888 \
  --name hindsight-cp \
  hindsight-cp
```

### Access Points

- **Control Plane UI**: http://localhost:9999
- **API**: http://localhost:8888
- **API Documentation**: http://localhost:8888/docs
- **API Health**: http://localhost:8888/health
- **Ollama**: http://localhost:11434

### Stop Services

```bash
# Stop API
pkill -f hindsight-api

# Stop Control Plane
docker stop hindsight-cp && docker rm hindsight-cp

# Stop PostgreSQL (if needed)
pkill -f "postgres.*hindsight"
```

## Configuration Details

### Environment Variables (API)

```bash
# LLM Configuration
HINDSIGHT_API_LLM_PROVIDER=ollama
HINDSIGHT_API_LLM_MODEL=qwen2.5:3b-instruct-q8_0
HINDSIGHT_API_LLM_BASE_URL=http://localhost:11434/v1
HINDSIGHT_API_LLM_MAX_CONCURRENT=1

# Database (default: embedded pg0)
HINDSIGHT_API_DATABASE_URL=pg0

# Server
HINDSIGHT_API_HOST=0.0.0.0
HINDSIGHT_API_PORT=8888
HINDSIGHT_API_LOG_LEVEL=info

# Embeddings & Reranking (default: local)
HINDSIGHT_API_EMBEDDINGS_PROVIDER=local
HINDSIGHT_API_RERANKER_PROVIDER=local
```

### Environment Variables (Control Plane)

```bash
HINDSIGHT_CP_DATAPLANE_API_URL=http://host.docker.internal:8888
NODE_ENV=production
```

## Docker Images

### Available Images

1. **hindsight:latest** - Full standalone (API + Control Plane)
2. **hindsight-cp:latest** - Control Plane only (current deployment)
3. **hindsight-api** - API only (not built yet)

### Building Images

```bash
# Control Plane only
docker build -f docker/standalone/Dockerfile --target cp-only -t hindsight-cp .

# Full standalone
docker build -f docker/standalone/Dockerfile -t hindsight .

# API only
docker build -f docker/standalone/Dockerfile --target api-only -t hindsight-api .
```

## Data & Persistence

### Memory Banks
- **Location**: PostgreSQL database at `~/.pg0/instances/hindsight/data`
- **Current Banks**: 
  - `persagent-charlie.brown` - Personal Agent for Charlie Brown

### Database Access

```bash
# Connect to PostgreSQL
psql postgresql://hindsight:hindsight@localhost:5432/hindsight

# List all banks
curl http://localhost:8888/v1/default/banks | jq .

# Check database health
curl http://localhost:8888/health
```

## Performance

### GPU Acceleration Status
- **LLM (Ollama)**: ✅ Metal GPU (qwen2.5:3b-instruct-q8_0)
- **Embeddings**: ✅ Metal GPU (MPS device, BAAI/bge-small-en-v1.5)
- **Reranker**: ✅ Metal GPU (MPS device, cross-encoder)
- **Control Plane**: N/A (UI only)

### Typical Latencies
- **Health check**: <5ms
- **List banks**: <10ms
- **Embedding (single doc)**: ~10ms (Metal) vs ~50ms (CPU)
- **LLM call**: ~500ms-2s (model-dependent)

## Troubleshooting

### API Not Starting
```bash
# Check if PostgreSQL is already running
ps aux | grep postgres | grep hindsight

# Kill existing instance
pkill -f "postgres.*hindsight"

# Check port availability
lsof -i :8888
```

### Control Plane Can't Connect to API
```bash
# Verify API is running
curl http://localhost:8888/health

# Check Docker can reach host
docker exec hindsight-cp curl http://host.docker.internal:8888/health
```

### Ollama Connection Issues
```bash
# Check Ollama is running
curl http://localhost:11434/api/tags

# List available models
ollama list

# Test model
ollama run qwen2.5:3b-instruct-q8_0 "Hello"
```

## Alternative Configurations

### Full Docker (All-in-One)
- **Pros**: Single container, simple deployment
- **Cons**: No Metal GPU for embeddings, isolated data
- **Use case**: Production deployment on Linux servers

```bash
docker run -p 8888:8888 -p 9999:9999 \
  -e HINDSIGHT_API_LLM_PROVIDER=ollama \
  -e HINDSIGHT_API_LLM_MODEL=qwen2.5:3b-instruct-q8_0 \
  -e HINDSIGHT_API_LLM_BASE_URL=http://host.docker.internal:11434/v1 \
  hindsight
```

### All Native (No Docker)
- **Pros**: Full Metal GPU acceleration, simple debugging
- **Cons**: Requires Node.js/npm setup, manual dependency management
- **Use case**: Development

```bash
# Terminal 1: API
cd hindsight-api
uv run hindsight-api

# Terminal 2: Control Plane
cd hindsight-control-plane
npm run dev
```

## Maintenance

### Updating the System

```bash
# Update code
cd ~/repos/hindsight
git pull

# Rebuild TypeScript client (if API changed)
npm install -w @vectorize-io/hindsight-client
npm run build -w @vectorize-io/hindsight-client

# Rebuild Docker Control Plane
docker build -f docker/standalone/Dockerfile --target cp-only -t hindsight-cp .

# Restart services
docker stop hindsight-cp && docker rm hindsight-cp
pkill -f hindsight-api
# Then start again (see "Running the System" above)
```

### Viewing Logs

```bash
# API logs (if running in background)
tail -f ~/hindsight-api.log

# Control Plane logs
docker logs -f hindsight-cp

# PostgreSQL logs
tail -f ~/.pg0/instances/hindsight/data/log/postgresql-*.log
```

## Notes

- **Port Conflicts**: Ensure ports 8888, 9999, 5432, and 11434 are available
- **macOS Firewall**: May need to allow connections for hindsight-api and ollama
- **Resource Usage**: Ollama + embeddings use ~2-4GB RAM on Apple Silicon
- **Data Backup**: PostgreSQL data is in `~/.pg0/instances/hindsight/data` - back up regularly
