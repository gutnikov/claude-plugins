#!/bin/bash
set -e

# Claude Runner - Unified Local/Remote Execution
# Usage: ./claude-runner.sh <action> [options]
#
# Actions:
#   setup     - Install Docker, copy files, build image
#   verify    - Check prerequisites
#   run       - Execute container with prompt
#   build     - Build Docker image only
#   test      - Run test workflow
#
# Environment:
#   HOST              - Target host (localhost or remote, default: localhost)
#   REMOTE_USER       - SSH user for remote host (default: $USER)
#   REMOTE_KEY        - SSH key for remote host (default: ~/.ssh/id_rsa)
#   GIT_REPO          - Repository to clone
#   GIT_BRANCH        - Branch to checkout (default: main)
#   PROMPT            - Prompt for Claude Code
#   ANTHROPIC_API_KEY - API key (required for run)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ACTION="${1:-help}"
shift || true

# Configuration
HOST="${HOST:-localhost}"
REMOTE_USER="${REMOTE_USER:-$USER}"
REMOTE_KEY="${REMOTE_KEY:-$HOME/.ssh/id_rsa}"
WORK_DIR="${WORK_DIR:-claude-runner}"
GIT_BRANCH="${GIT_BRANCH:-main}"

# Determine if running locally or remotely
is_local() {
    [ "$HOST" = "localhost" ] || [ "$HOST" = "127.0.0.1" ] || [ -z "$HOST" ]
}

# Execute command on target host
run_on_host() {
    if is_local; then
        eval "$@"
    else
        local SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
        [ -f "$REMOTE_KEY" ] && SSH_OPTS="$SSH_OPTS -i $REMOTE_KEY"
        ssh $SSH_OPTS "$REMOTE_USER@$HOST" "$@"
    fi
}

# Copy file to target host
copy_to_host() {
    local src="$1"
    local dst="$2"
    if is_local; then
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    else
        local SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes"
        [ -f "$REMOTE_KEY" ] && SSH_OPTS="$SSH_OPTS -i $REMOTE_KEY"
        ssh $SSH_OPTS "$REMOTE_USER@$HOST" "mkdir -p $(dirname "$dst")"
        scp $SSH_OPTS "$src" "$REMOTE_USER@$HOST:$dst"
    fi
}

# Print with host prefix
log() {
    echo "[$HOST] $*"
}

# Check helper
check() {
    local name="$1"
    local cmd="$2"
    printf "%-40s" "  $name..."
    if run_on_host "$cmd" > /dev/null 2>&1; then
        echo "[OK]"
        return 0
    else
        echo "[FAILED]"
        return 1
    fi
}

#
# ACTIONS
#

action_help() {
    cat << 'EOF'
Claude Runner - Unified Local/Remote Execution

Usage: ./claude-runner.sh <action> [options]

Actions:
  setup     Install Docker (if needed), copy files, build image
  verify    Check all prerequisites
  run       Execute container with prompt
  build     Build Docker image only
  test      Run test workflow

Environment Variables:
  HOST              Target host (default: localhost)
  REMOTE_USER       SSH user for remote (default: $USER)
  REMOTE_KEY        SSH key path (default: ~/.ssh/id_rsa)
  GIT_REPO          Repository to clone
  GIT_BRANCH        Branch (default: main)
  PROMPT            Prompt for Claude Code
  ANTHROPIC_API_KEY API key (required for run)
  WORK_DIR          Working directory (default: claude-runner)

Examples:
  # Local setup and run
  ./claude-runner.sh setup
  ANTHROPIC_API_KEY=... GIT_REPO=https://github.com/user/repo PROMPT="Explain this" ./claude-runner.sh run

  # Remote setup and run
  HOST=server.example.com ./claude-runner.sh setup
  HOST=server.example.com ANTHROPIC_API_KEY=... GIT_REPO=... PROMPT="..." ./claude-runner.sh run
EOF
}

action_verify() {
    echo "=== Claude Runner Verification ==="
    echo "Host: $HOST"
    is_local && echo "Mode: Local" || echo "Mode: Remote ($REMOTE_USER@$HOST)"
    echo "=================================="
    echo ""

    local failures=0

    # SSH (remote only)
    if ! is_local; then
        echo "== SSH Connectivity =="
        check "SSH connection" "echo connected" || ((failures++))
        echo ""
    fi

    echo "== Docker =="
    check "Docker installed" "docker --version" || ((failures++))
    check "Docker daemon" "docker info > /dev/null 2>&1" || ((failures++))
    check "Docker permissions" "docker ps > /dev/null 2>&1" || ((failures++))
    echo ""

    echo "== Network =="
    check "Internet access" "curl -s --max-time 5 https://api.anthropic.com > /dev/null" || ((failures++))
    echo ""

    echo "== Working Directory =="
    check "Work dir exists" "test -d ~/$WORK_DIR" || log "  Will be created during setup"
    check "Dockerfile" "test -f ~/$WORK_DIR/claude-runner.dockerfile" || log "  Will be copied during setup"
    check "Entrypoint" "test -f ~/$WORK_DIR/assets/entrypoint.sh" || log "  Will be copied during setup"
    echo ""

    echo "== Docker Image =="
    check "claude-runner:latest" "docker image inspect claude-runner:latest > /dev/null 2>&1" || log "  Will be built during setup"
    echo ""

    echo "=================================="
    if [ $failures -eq 0 ]; then
        echo "Core checks passed. Run 'setup' to complete installation."
    else
        echo "Found $failures critical issue(s)."
    fi
    return $failures
}

action_setup() {
    log "=== Claude Runner Setup ==="

    # Check/install Docker
    if ! run_on_host "docker --version" > /dev/null 2>&1; then
        log "Installing Docker..."
        if is_local; then
            echo "Docker not found. Please install Docker Desktop or run:"
            echo "  curl -fsSL https://get.docker.com | sh"
            exit 1
        else
            run_on_host "curl -fsSL https://get.docker.com | sudo sh"
            run_on_host "sudo usermod -aG docker \$USER"
            log "Docker installed. You may need to reconnect for group changes."
        fi
    fi

    # Create working directory
    log "Creating working directory..."
    run_on_host "mkdir -p ~/$WORK_DIR/assets"

    # Copy files
    log "Copying files..."
    copy_to_host "$SCRIPT_DIR/claude-runner.dockerfile" "~/$WORK_DIR/claude-runner.dockerfile"
    copy_to_host "$SCRIPT_DIR/entrypoint.sh" "~/$WORK_DIR/assets/entrypoint.sh"
    run_on_host "chmod +x ~/$WORK_DIR/assets/entrypoint.sh"

    # Build image
    log "Building Docker image..."
    run_on_host "cd ~/$WORK_DIR && docker build -f claude-runner.dockerfile -t claude-runner:latest ."

    log "=== Setup Complete ==="
}

action_build() {
    log "Building Docker image..."
    run_on_host "cd ~/$WORK_DIR && docker build -f claude-runner.dockerfile -t claude-runner:latest ."
    log "Build complete."
}

action_run() {
    # Validate
    if [ -z "$GIT_REPO" ]; then
        echo "Error: GIT_REPO is required"
        exit 1
    fi
    if [ -z "$PROMPT" ]; then
        echo "Error: PROMPT is required"
        exit 1
    fi
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "Error: ANTHROPIC_API_KEY is required"
        exit 1
    fi

    log "=== Claude Runner ==="
    log "Repository: $GIT_REPO"
    log "Branch: $GIT_BRANCH"
    log "Prompt: $PROMPT"
    log "===================="

    # Run container
    run_on_host "docker run --rm \
        -e ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' \
        -e GIT_REPO='$GIT_REPO' \
        -e GIT_BRANCH='$GIT_BRANCH' \
        -e PROMPT='$PROMPT' \
        claude-runner:latest"
}

action_test() {
    log "=== Claude Runner Test ==="

    # Test without API key - should fail gracefully
    log "Testing container startup..."
    if run_on_host "docker run --rm claude-runner:latest" 2>&1 | grep -q "GIT_REPO"; then
        log "Container starts correctly (validation working)"
    else
        log "ERROR: Container test failed"
        exit 1
    fi

    log "=== Test Complete ==="
    log "To run a full test, set ANTHROPIC_API_KEY, GIT_REPO, and PROMPT"
}

#
# MAIN
#

case "$ACTION" in
    help|--help|-h)
        action_help
        ;;
    verify|check)
        action_verify
        ;;
    setup|install)
        action_setup
        ;;
    build)
        action_build
        ;;
    run)
        action_run
        ;;
    test)
        action_test
        ;;
    *)
        echo "Unknown action: $ACTION"
        echo "Run './claude-runner.sh help' for usage"
        exit 1
        ;;
esac
