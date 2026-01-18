# opencode-docker-py

> Fast, isolated Python environment with automatic dependency management that just works

## Features

- Dockerized environment with OpenCode CLI
- Automatic venv setup and dependency installation
- Volume masking (.venv, .git, etc.)
- Context7 MCP integration
- Persistent UV cache

## How It Works

### Directory Masking Technique

**Problem:** When mounting a project directory into a Docker container, the entire directory structure is shared. However, you often want to exclude certain directories from the container's view—particularly virtual environments (`.venv`, `.ve`), version control (`.git`), and other project-specific directories.

**Solution:** Docker volume masking works by mounting empty anonymous volumes over specific paths within the container. When you mount an anonymous volume at `/workspace/.venv`, it overlays the host's `.venv` directory with an empty container volume, effectively "masking" it from view.

**Why this matters:**

- **Isolation:** The container uses its own virtual environment at `/home/opencode/.venv`, completely separate from your host's venv
- **Performance:** Prevents Docker from syncing large `.venv` or `.git` directories
- **Clean State:** Container always starts with a fresh, predictable environment
- **No Conflicts:** Host dependencies won't interfere with container dependencies

**How to customize:**
```bash
# Edit Makefile to add more directories
DIRS_TO_EXCLUDE := ".venv .ve .git node_modules dist build"
```

### Automatic Dependency Installation

The container automatically detects and installs Python dependencies every time it starts. No manual setup required—it just works.

**Detection order:**
1. Checks for `requirements.txt` → Uses `uv pip install -r requirements.txt`
2. Checks for `pyproject.toml` → Uses `uv sync` (respects `[project]` dependencies)
3. No dependency files found → Skips installation, proceeds directly to OpenCode

**Benefits:**
- **Zero Configuration:** Works with any standard Python project
- **Fast:** UV is 10-100x faster than pip
- **Automatic venv:** Creates `/home/opencode/.venv` on first run, refreshes on subsequent runs
- **Smart Refresh:** Only installs missing or updated packages

**Example scenarios:**

*Scenario 1: pip project*
```bash
# Your project has requirements.txt
requirements.txt  # Automatically installed on container start
```

*Scenario 2: pyproject project*
```bash
# Your project uses pyproject.toml
pyproject.toml   # uv sync installs all dependencies
```

*Scenario 3: Simple script*
```bash
# No dependency files
script.py        # OpenCode starts directly, no installation step
```

### UV Cache for Performance

The container uses a persistent Docker volume to cache all UV-related artifacts, dramatically improving startup times and reducing network usage.

**What gets cached:**

- **Downloaded packages:** All Python wheels and source distributions
- **Multiple Python versions:** Any Python versions installed by uv (e.g., 3.11, 3.12, 3.13)
- **Build artifacts:** Compiled extensions and build caches
- **Package metadata:** Resolution results for faster future installs

**Performance impact:**

| Scenario | First Run | Subsequent Runs |
|----------|-----------|-----------------|
| Install 10 packages | ~15s | <1s |
| Install 50 packages | ~45s | <2s |
| Install 100+ packages | ~90s | <5s |

**Cache location:** `/home/opencode/.cache/uv` (mapped to Docker volume `uv_cache`)

**Cross-project sharing:** The cache is persistent across container restarts and can be shared across different projects on the same machine (when using the same cache volume name).

**Environment configuration** (from Dockerfile):
```dockerfile
UV_CACHE_DIR=/home/opencode/.cache/uv          # Cache directory
UV_PYTHON_INSTALL_DIR=/home/opencode/.cache/uv/python  # Python versions
UV_LINK_MODE=copy                                # Safe across filesystems
```

**Cache management:**
```bash
# View cache size
docker volume inspect PROJECT_NAME_uv_cache

# Clear cache if needed
docker volume rm PROJECT_NAME_uv_cache
```

### Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│ Docker Container                                         │
│                                                         │
│  /workspace/           (mounted from HOST_DIR)          │
│  ├── your_code.py                                        │
│  ├── requirements.txt    ──────→ [Auto-detected]        │
│  ├── .venv/             (MASKED - empty volume)         │
│  └── .git/              (MASKED - empty volume)         │
│                                                         │
│  /home/opencode/                                         │
│  ├── .venv/            (Container's Python environment) │
│  │   └── bin/python    (UV-installed packages)          │
│  │                                                     │
│  └── .cache/uv/        (PERSISTENT CACHE VOLUME)        │
│      ├── python/       (Downloaded Python versions)     │
│      ├── venv/         (Virtual environment cache)       │
│      └── packages/     (Downloaded wheels & sources)    │
│                                                         │
│  Entry Point: Automatically installs dependencies      │
│                and starts OpenCode                      │
└─────────────────────────────────────────────────────────┘
```

**Key benefits for developers:**
- 🚀 **Fast startup** with intelligent caching
- 🔒 **Clean isolation** between host and container
- 📦 **Zero setup**—just run and it works
- 💾 **Persistent cache** saves time across sessions
- 🎯 **Project-agnostic**—works with any Python project

## Prerequisites

- Docker 20.10+


Available commands:
- `make config` - Copy config files
- `make build` - Build Docker image
- `make agent DIR=/path/to/your/project` - Run coding agent

## Quick Start

```bash
# Clone and setup
git clone https://github.com/borys25ol/opencode-docker-py opencode-docker-py
cd opencode-docker-py

# Configure
make config

# Copy .env.example to .env
cp .env.example .env
# Add CONTEXT7_API_KEY to .env

# Build
make build

# Run
make agent DIR=/path/to/your/project
```

## Configuration

**.env:**
```env
CONTEXT7_API_KEY=your_key_here
```

**config/opencode.json:**
```json
{
  "model": "opencode/glm-4.7-free",
  "theme": "tokyonight",
  "mcp": {
    "context7": {
      "enabled": true,
      "headers": {
        "CONTEXT7_API_KEY": "{env:CONTEXT7_API_KEY}"
      }
    }
  }
}
```

**config/AGENT_RULES.md:** - Custom agent behavior rules

## Ports

- `4096` - OpenCode UI
- `8080` - Local API servers

## Customization

Edit `Makefile` to configure:
- Tools to install in container: `LOCAL_TOOLS := "curl ca-certificates git vim make"`
- Directories to mask from container: `DIRS_TO_EXCLUDE := ".venv .git"`
- Ports to expose: `PORTS := "4096 8080"`
