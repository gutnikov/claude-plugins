#!/bin/bash
set -e

# Remote Setup Script for Claude Runner
# This script is copied to and executed on the remote machine

echo "=== Claude Runner Remote Setup ==="

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | $SUDO sh

    # Add current user to docker group
    $SUDO usermod -aG docker "$USER"

    echo "Docker installed. You may need to log out and back in for group changes to take effect."
fi

# Start Docker daemon if not running
if ! $SUDO docker info &> /dev/null; then
    echo "Starting Docker daemon..."
    $SUDO systemctl start docker
    $SUDO systemctl enable docker
fi

# Verify Docker is working
echo "Verifying Docker..."
docker --version
docker info > /dev/null

echo "=== Docker Ready ==="

# Create working directory
WORK_DIR="${CLAUDE_RUNNER_DIR:-$HOME/claude-runner}"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Working directory: $WORK_DIR"
echo "=== Remote Setup Complete ==="
