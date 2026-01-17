# opencode-docker-py

Docker container for [OpenCode](https://opencode.ai) AI coding agent.

## Features

- Dockerized environment with OpenCode CLI
- Automatic venv setup and dependency installation
- Volume masking (.venv, .git, etc.)
- Context7 MCP integration
- Persistent UV cache

## Quick Start

```bash
# Clone and setup
git clone <https://github.com/borys25ol/opencode-docker-py> opencode-docker-py
cd opencode-docker-py

# Configure
make config

# Copy .env.example to .env
cp .env.example .env
# Add CONTEXT7_API_KEY to .env

# Generate docker-compose.yml file
make generate

# Build
make build

# Run
make agent DIR=/path/to/your/project
```

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+


Available commands:
- `make sync` - Sync Python dependencies
- `make config` - Copy config files
- `make generate` - Regenerate docker-compose.yml file
- `make build` - Build Docker image
- `make agent DIR=/path/to/your/project` - Run coding agent

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

Edit `Makefile` to:
- Mask directories: `DIRS_TO_EXCLUDE := ".venv .git .ve node_modules"`

Then run `make generate`

Edit `docker-compose.yml` for port mappings.
