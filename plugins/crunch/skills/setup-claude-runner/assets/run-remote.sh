#!/bin/bash
set -e

# Run Claude Runner on Remote Machine
# Usage: ./run-remote.sh <remote-host> <git-repo> <prompt> [branch]

REMOTE_HOST="$1"
GIT_REPO="$2"
PROMPT="$3"
GIT_BRANCH="${4:-main}"
REMOTE_USER="${REMOTE_USER:-$USER}"
REMOTE_KEY="${REMOTE_KEY:-$HOME/.ssh/id_rsa}"
WORK_DIR="${REMOTE_WORK_DIR:-claude-runner}"

# Validate arguments
if [ -z "$REMOTE_HOST" ] || [ -z "$GIT_REPO" ] || [ -z "$PROMPT" ]; then
    echo "Usage: ./run-remote.sh <remote-host> <git-repo> <prompt> [branch]"
    echo ""
    echo "Environment variables:"
    echo "  REMOTE_USER       - SSH username (default: \$USER)"
    echo "  REMOTE_KEY        - SSH key path (default: ~/.ssh/id_rsa)"
    echo "  REMOTE_WORK_DIR   - Working directory on remote (default: claude-runner)"
    echo "  ANTHROPIC_API_KEY - API key (required)"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is required"
    exit 1
fi

echo "=== Claude Runner Remote Execution ==="
echo "Remote: $REMOTE_USER@$REMOTE_HOST"
echo "Repository: $GIT_REPO"
echo "Branch: $GIT_BRANCH"
echo "Prompt: $PROMPT"
echo "======================================="

# SSH options
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
if [ -f "$REMOTE_KEY" ]; then
    SSH_OPTS="$SSH_OPTS -i $REMOTE_KEY"
fi

# Run on remote
# Note: API key is passed via stdin to avoid appearing in process list
ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" bash -s << REMOTE_SCRIPT
set -e
cd ~/$WORK_DIR

# Read API key from environment (passed securely)
export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"

# Run container
docker run --rm \
    -e ANTHROPIC_API_KEY="\$ANTHROPIC_API_KEY" \
    -e GIT_REPO="$GIT_REPO" \
    -e GIT_BRANCH="$GIT_BRANCH" \
    -e PROMPT="$PROMPT" \
    claude-runner:latest

REMOTE_SCRIPT

echo "=== Remote Execution Complete ==="
