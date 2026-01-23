#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# 1. Full Setup Logic (Venv + Installation)
if [ "$INSTALL_DEPS" = "true" ]; then
    echo "🛠️ [Entrypoint] Full setup mode enabled."

    # Initialize virtual environment only when we are going to install something
    uv venv -q /home/opencode/.venv

    if [ -f "requirements.txt" ]; then
        echo "📦 [Entrypoint] Installing from requirements.txt..."
        uv pip install -q -r requirements.txt
    elif [ -f "pyproject.toml" ]; then
        echo "📦 [Entrypoint] Syncing from pyproject.toml..."
        uv sync -q
    else
        echo "ℹ️ [Entrypoint] No dependency files found, but venv created."
    fi
else
    echo "⏭️ [Entrypoint] INSTALL_DEPS is false. Skipping venv and installation."
fi

# 3. Launch the main application
# Use 'exec' to replace the shell process with the application process.
# This ensures signals like SIGTERM (Ctrl+C) are handled correctly by the app.
echo "🚀 [Entrypoint] Starting OpenCode..."

opencode