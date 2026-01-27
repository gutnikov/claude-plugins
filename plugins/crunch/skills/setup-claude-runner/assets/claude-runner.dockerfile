# Claude Runner Dockerfile
# Containerized Claude Code agent for running prompts against git repositories

FROM ubuntu:22.04

LABEL maintainer="claude-plugins"
LABEL description="Claude Code agent runner container"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (LTS)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY assets/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables (can be overridden at runtime)
ENV GIT_REPO=""
ENV GIT_BRANCH="main"
ENV PROMPT=""
ENV ANTHROPIC_API_KEY=""

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
