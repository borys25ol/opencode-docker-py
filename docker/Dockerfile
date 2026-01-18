# --- Stage 1: Extraction ---
# Use the official uv image to provide the binaries.
FROM ghcr.io/astral-sh/uv:latest AS uv_bin

# --- Stage 2: Runtime Environment ---
# Using debian:bookworm-slim instead of full Ubuntu to significantly reduce image size
# while maintaining full compatibility with Python wheels and C-extensions.
FROM ubuntu:24.04

ARG LOCAL_TOOLS="curl ca-certificates git"

# Consolidate environment variables to reduce layers.
# UV_PYTHON_INSTALL_DIR: Ensures Python toolchains are stored in the persistent cache volume.
# UV_LINK_MODE: Set to 'copy' to avoid performance warnings on different filesystems.
# UV_PYTHON_PREFERENCE: Ensures uv respects .python-version from your workspace.
ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/opencode \
    UV_PROJECT_ENVIRONMENT=/home/opencode/.venv \
    UV_CACHE_DIR=/home/opencode/.cache/uv \
    UV_PYTHON_INSTALL_DIR=/home/opencode/.cache/uv/python \
    UV_LINK_MODE=copy \
    UV_PYTHON_PREFERENCE=managed \
    PATH="/home/opencode/.opencode/bin:/home/opencode/.venv/bin:$PATH"

# Combine system update, dependency installation, user creation, and directory prep.
# This single RUN command reduces the number of intermediate image layers.
RUN apt-get update && apt-get install -y --no-install-recommends $LOCAL_TOOLS \
    && useradd -m -s /bin/bash opencode \
    && mkdir -p /home/opencode/.local/share/opencode \
                /home/opencode/.config/opencode \
                /home/opencode/.cache/uv \
                /home/opencode/.venv \
                /workspace \
    && chown -R opencode:opencode /home/opencode /workspace \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy uv binaries from the extraction stage.
COPY --from=uv_bin /uv /uvx /bin/

# Copy the entrypoint script and set correct permissions
COPY --chown=opencode:opencode ./entrypoint.sh /home/opencode/entrypoint.sh
RUN chmod +x /home/opencode/entrypoint.sh

# Switch to the non-root user for security and runtime operations.
USER opencode
WORKDIR /workspace

# Install the OpenCode CLI.
# The installer automatically places the binary into $HOME/.opencode/bin.
RUN curl -fsSL https://opencode.ai/install | bash

# Define the entrypoint script as the default execution path
ENTRYPOINT ["/home/opencode/entrypoint.sh"]