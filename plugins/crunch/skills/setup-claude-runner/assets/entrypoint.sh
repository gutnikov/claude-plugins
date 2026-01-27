#!/bin/bash
set -e

# Claude Runner Entrypoint
# Clones a git repository and runs Claude Code agent with a prompt

# Parse arguments or use environment variables
GIT_REPO="${1:-$GIT_REPO}"
GIT_BRANCH="${2:-$GIT_BRANCH}"
PROMPT="${3:-$PROMPT}"

# Validate required parameters
if [ -z "$GIT_REPO" ]; then
    echo "Error: GIT_REPO is required"
    echo "Usage: docker run claude-runner <git-repo> [branch] [prompt]"
    echo "   or: docker run -e GIT_REPO=<repo> -e GIT_BRANCH=<branch> -e PROMPT=<prompt> claude-runner"
    exit 1
fi

if [ -z "$PROMPT" ]; then
    echo "Error: PROMPT is required"
    echo "Usage: docker run claude-runner <git-repo> [branch] [prompt]"
    echo "   or: docker run -e GIT_REPO=<repo> -e GIT_BRANCH=<branch> -e PROMPT=<prompt> claude-runner"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is required"
    exit 1
fi

# Default branch
GIT_BRANCH="${GIT_BRANCH:-main}"

echo "=== Claude Runner ==="
echo "Repository: $GIT_REPO"
echo "Branch: $GIT_BRANCH"
echo "Prompt: $PROMPT"
echo "===================="

# Clone repository with shallow depth
echo "Cloning repository..."
git clone --depth=1 --branch "$GIT_BRANCH" "$GIT_REPO" /workspace/repo

# Change to repo directory
cd /workspace/repo

echo "Repository cloned. Running Claude Code agent..."

# Run Claude Code in non-interactive mode with the prompt
# --print: Output result to stdout
# --dangerously-skip-permissions: Skip permission prompts for automation
claude --print --dangerously-skip-permissions "$PROMPT"

echo "=== Claude Runner Complete ==="
