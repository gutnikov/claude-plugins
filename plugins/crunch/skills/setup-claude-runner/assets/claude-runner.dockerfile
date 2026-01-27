# Claude Runner Dockerfile
# Base image for running Claude Code in containerized environments

FROM ubuntu:22.04

LABEL maintainer="claude-plugins"
LABEL description="Claude Code runner container"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Default command - simple verification
CMD ["echo", "Claude runner container is working"]
