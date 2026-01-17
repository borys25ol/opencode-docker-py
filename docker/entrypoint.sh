#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Initialize or refresh the virtual environment
# uv venv is idempotent and extremely fast if the venv already exists
uv venv -q /home/opencode/.venv

# 2. Conditional dependency installation
# Check for requirements.txt first
if [ -f "requirements.txt" ]; then
    echo "📦 [Entrypoint] Found requirements.txt. Installing dependencies..."
    uv pip install -q -r requirements.txt
# If not found, check for pyproject.toml
elif [ -f "pyproject.toml" ]; then
    echo "📦 [Entrypoint] Found pyproject.toml. Syncing dependencies..."
    uv sync -q
# If neither exists, just skip and proceed
else
    echo "ℹ️ [Entrypoint] No dependency files found. Skipping installation step."
fi

# 3. Launch the main application
# Use 'exec' to replace the shell process with the application process.
# This ensures signals like SIGTERM (Ctrl+C) are handled correctly by the app.
echo "🚀 [Entrypoint] Starting OpenCode..."

opencode