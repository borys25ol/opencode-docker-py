#!/bin/bash

# 1. Check if the directory path argument is provided
if [ -z "$1" ]; then
    echo "Error: No directory path provided."
    echo "Usage: $0 /path/to/your/project"
    exit 1
fi

# 2. Convert to absolute path (Docker requires absolute paths for volumes)
export HOST_DIR=$(realpath "$1")

# 3. Verify if the directory actually exists on the host
if [ ! -d "$HOST_DIR" ]; then
    echo "Error: Directory '$HOST_DIR' does not exist."
    exit 1
fi

echo "Starting OpenCode container for: $HOST_DIR"

# Get project name from HOST_DIR.
export PROJECT_NAME=$(basename "$HOST_DIR")

# Convert space-separated string DIRS_TO_EXCLUDE into docker volume flags
EXCLUDE_FLAGS=""
for dir in $DIRS_TO_EXCLUDE; do
    EXCLUDE_FLAGS+="-v /workspace/$dir "
done

# Convert space-separated string PORTS into docker port flags
PORTS_FLAGS=""
for port in $PORTS; do
    PORTS_FLAGS+="-p $port:$port "
done

# Check if .env file exists
ENV_FLAG=""
if [ -f ".env" ]; then
    ENV_FLAG="--env-file .env"
else
    echo "Warning: .env file not found. Running without env-file."
fi

# 4. Run the container using Docker Compose
# --rm: automatically remove the container when you exit
docker run -it --rm \
  --name opencode-agent-$PROJECT_NAME \
  $PORTS_FLAGS \
  -v "$(pwd)/config/AGENT_RULES.md:/home/opencode/.config/opencode/AGENT_RULES.md:ro" \
  -v "$(pwd)/config/opencode.json:/home/opencode/.config/opencode/opencode.json:ro" \
  -v "${HOST_DIR}:/workspace" \
  $EXCLUDE_FLAGS \
  -v "${PROJECT_NAME}_uv_cache:/home/opencode/.cache/uv" \
  $ENV_FLAG \
  opencode-docker-py-agent
