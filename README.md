# opencode-docker-py

> Fast, isolated Python environment with automatic dependency management that just works

## Features

- Dockerized environment with OpenCode CLI
- Automatic venv setup with optional dependency installation
- Volume masking (.venv, .git, etc.)
- Optional, persistent UV cache

## Project Structure

```
.
├── Makefile                 # Build/run helpers and install/uninstall
├── README.md                # Docs
├── docker/                  # Image, entrypoint, and run script
├── config/                  # OpenCode config + rules
├── data/                    # Persistent OpenCode storage (sessions/logs)
├── .env.example             # Env template
└── .env                     # Local env (not committed)
```

## How It Works

### Directory Masking Technique

Docker mounts can expose everything in your project, including `.venv` and `.git`. This setup masks those paths by mounting empty volumes over them (for example `/workspace/.venv`), so the container sees a clean workspace.

**Why this matters:**

- **Isolation:** Container venv at `/home/opencode/.venv`
- **Performance:** Avoids syncing large directories
- **Clean State:** Predictable environment on each run

**How to customize:**
```bash
# Add extra excludes at runtime
EXCLUDE=".venv .ve dist build" dockercode /path/to/your/project
```

### File Masking Technique

Files can be hidden by bind-mounting them to `/dev/null` inside the container. This is useful for local secrets like `.env.local` that should not be visible to the container.

**Example:**
```bash
EXCLUDE=".env.local secrets.json" dockercode /path/to/your/project
```

### Automatic Dependency Installation

When `INSTALL_DEPS=true`, the container detects and installs Python dependencies on startup.

**Detection order:**
1. Checks for `requirements.txt` → Uses `uv pip install -r requirements.txt`
2. Checks for `pyproject.toml` → Uses `uv sync` (respects `[project]` dependencies)
3. No dependency files found → Skips installation, proceeds directly to OpenCode

**Benefits:**
- **Zero configuration:** Works with any standard Python project
- **Fast:** uv is 10-100x faster than pip
- **Automatic venv:** Creates `/home/opencode/.venv` on first run, refreshes on subsequent runs
- **Smart refresh:** Only installs missing or updated packages

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

### UV Cache

When `ENABLE_CACHE=true`, the container mounts a Docker volume at `/home/opencode/.cache/uv` to store uv downloads and build artifacts. This speeds up subsequent runs and reduces network usage. Clear it anytime with `make clean-cache`.

### Persistent OpenCode Data

The `data/` directory is mounted into the container at `/home/opencode/.local/share/opencode` and keeps your OpenCode state between runs.

**What it contains:**

- **Sessions and diffs:** conversation history, run state, and deltas
- **Logs:** runtime logs for troubleshooting
- **Snapshots:** periodic state snapshots and metadata

You can delete `data/` to reset OpenCode to a clean state, but you'll lose session history.

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


## Commands

Available commands:
- `make build` - Build Docker image
- `make agent DIR=/path/to/your/project` - Run coding agent
- `make clean-cache` - Remove uv cache Docker volumes
- `make install` - Install `dockercode` CLI globally
- `make uninstall` - Remove `dockercode` CLI

**About `make install`:**
Makes `docker/run_agent.sh` executable and creates a symlink at `/usr/local/bin/dockercode` (requires `sudo`). The `dockercode` command simply calls that script, so updates to the script take effect immediately.

**About `make uninstall`:**
Removes the `/usr/local/bin/dockercode` symlink (requires `sudo`).

## Quick Start

```bash
# Clone and setup
git clone https://github.com/borys25ol/opencode-docker-py opencode-docker-py
cd opencode-docker-py

# Copy .env.example to .env
cp .env.example .env

# Build
make build

# Install CLI (optional)
make install

# Run
dockercode /path/to/your/project

# Alternative (no install)
./docker/run_agent.sh /path/to/your/project
```

## Configuration

**Optional `config/opencode.json`:**
OpenCode runs without this file. Create it only if you want custom settings.
```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {},
  "instructions": [
    "/home/opencode/.config/opencode/AGENT_RULES.md"
  ],
  "theme": "tokyonight",
  "model": "opencode/glm-4.7-free"
}
```

**Environment variables (run-time):**
- `INSTALL_DEPS=true|false` - Install Python dependencies on start (default: false)
- `ENABLE_CACHE=true|false` - Enable uv cache volume (default: false)
- `ENV_FILE=/path/to/.env` - Select env file (default: repo `.env`)
- `EXCLUDE="dir1 dir2 file1"` - Extra dirs/files to mask
- `PORTS="3000 5173"` - Forward one or more ports into the container

**Defaults (run_agent.sh):**
- `DEFAULT_DIRS_TO_EXCLUDE=".git __pycache__"`
- `DEFAULT_FILES_TO_EXCLUDE=".DS_Store"`
- `DEFAULT_PORTS=""`

## Customization

Edit `Makefile` to configure:
- Tools to install in container: `LOCAL_TOOLS := "curl ca-certificates git vim make"`
- Installed CLI name: `BIN_NAME := dockercode`

Adjust runtime behavior with environment variables when running `dockercode`.

## Usage Examples

```bash
# Enable uv cache and dependency install
ENABLE_CACHE=true INSTALL_DEPS=true dockercode /path/to/your/project

# Exclude extra dirs/files from the container
EXCLUDE=".idea .vscode .env.local" dockercode /path/to/your/project

# Use a specific env file
ENV_FILE=/path/to/custom.env dockercode /path/to/your/project

# Forward ports to the container (space-separated list)
PORTS="3000 5173" dockercode /path/to/your/project
```

## Tips

- The default exclusions are `.git` and `__pycache__` plus `.DS_Store` files.
- To clear cached uv artifacts, run `make clean-cache`.

## Troubleshooting

- Docker permission errors: ensure your user can run Docker (or use `sudo`).
- Env file not found: set `ENV_FILE=/path/to/.env` or create `.env` from `.env.example`.
- Cache not appearing: run with `ENABLE_CACHE=true` and re-check Docker volumes.

## FAQ

**Why is caching disabled by default?**
Caching is opt-in so the container behaves predictably on first run and avoids creating Docker volumes unless you want them.

**How do I exclude more paths from the container?**
Add them via `EXCLUDE="dir1 dir2 file1"` when you run `dockercode`.
