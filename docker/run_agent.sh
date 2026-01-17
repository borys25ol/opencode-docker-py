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

# 4. Run the container using Docker Compose
# --rm: automatically remove the container when you exit
docker compose run --service-ports --rm agent
