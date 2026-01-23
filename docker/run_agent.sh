#!/bin/bash

set -e

# This works even if the script is a symlink
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
# Since the script is in ./docker/run_agent.sh, the repo root is two levels up
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_PATH")")"

export INSTALL_DEPS="${INSTALL_DEPS:-false}"
export ENABLE_CACHE="${ENABLE_CACHE:-false}"
export SELECTED_ENV_FILE="${ENV_FILE:-$REPO_ROOT/.env}"

# Default exclusion lists (you can add your own default ones)
DEFAULT_DIRS_TO_EXCLUDE="${DEFAULT_DIRS_TO_EXCLUDE:-.git __pycache__}"
DEFAULT_FILES_TO_EXCLUDE="${DEFAULT_FILES_TO_EXCLUDE:-.DS_Store}"

# Check if the directory path argument is provided
if [ -z "$1" ]; then
    echo "Usage: opencode /path/to/project"
    exit 1
fi

export HOST_DIR=$(realpath "$1")
if [ ! -d "$HOST_DIR" ]; then
    echo "Error: Directory '$HOST_DIR' does not exist."
    exit 1
fi

echo "Starting OpenCode container for: $HOST_DIR"
export PROJECT_NAME=$(basename "$HOST_DIR")

# --- Dynamic Flags Processing ---

EXCLUDE_FLAGS=""

# Process directories to exclude (anonymous volumes)
ALL_DIRS_TO_EXCLUDE="${DEFAULT_DIRS_TO_EXCLUDE} ${EXCLUDE}"
for dir in $ALL_DIRS_TO_EXCLUDE; do
    if [ -n "$dir" ] && [ -d "$HOST_DIR/$dir" ]; then
        EXCLUDE_FLAGS+="-v /workspace/$dir "
    fi
done

# Process files to exclude (mapping to /dev/null)
ALL_FILES_TO_EXCLUDE="${DEFAULT_FILES_TO_EXCLUDE} ${EXCLUDE}"
for file in $ALL_FILES_TO_EXCLUDE; do
    if [ -n "$file" ] && [ -f "$HOST_DIR/$file" ]; then
        EXCLUDE_FLAGS+="-v /dev/null:/workspace/$file "
    fi
done

# Process ports
ALL_PORTS="${DEFAULT_PORTS} ${PORTS}"
PORTS_FLAGS=""
for port in $ALL_PORTS; do
    if [ -n "$port" ]; then
        PORTS_FLAGS+="-p $port:$port "
    fi
done

# --- Environment Configuration (Dynamic & Optional) ---

ENV_FLAG=""
if [ -f "$SELECTED_ENV_FILE" ]; then
    ENV_FLAG="--env-file $(realpath "$SELECTED_ENV_FILE")"
    echo "Env info: loaded $SELECTED_ENV_FILE"
else
    echo "Env info: no env file found, skipping."
fi

# --- Cache Configuration ---

CACHE_FLAG=""
if [ "$ENABLE_CACHE" = "true" ]; then
    CACHE_FLAG="-v ${PROJECT_NAME}_uv_cache:/home/opencode/.cache/uv"
    echo "Cache info: uv cache is ENABLED"
else
    echo "Cache info: uv cache is DISABLED (default)"
fi

# --- Run Docker Container ---

docker run -it --rm \
  --name "opencode-agent-$PROJECT_NAME" \
  $PORTS_FLAGS \
  -e INSTALL_DEPS="$INSTALL_DEPS" \
  -v "${REPO_ROOT}/config/:/home/opencode/.config/opencode/" \
  -v "${REPO_ROOT}/data/:/home/opencode/.local/share/opencode/" \
  -v "${HOST_DIR}:/workspace" \
  $CACHE_FLAG \
  $EXCLUDE_FLAGS \
  $ENV_FLAG \
  opencode-docker-py-agent
