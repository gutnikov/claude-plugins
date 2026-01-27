#!/bin/bash
set -e

# Verify Remote Environment for Claude Runner
# This script checks all prerequisites on a remote machine

REMOTE_HOST="$1"
REMOTE_USER="${REMOTE_USER:-$USER}"
REMOTE_KEY="${REMOTE_KEY:-$HOME/.ssh/id_rsa}"

if [ -z "$REMOTE_HOST" ]; then
    echo "Usage: ./verify-remote.sh <remote-host>"
    echo ""
    echo "Environment variables:"
    echo "  REMOTE_USER - SSH username (default: \$USER)"
    echo "  REMOTE_KEY  - SSH key path (default: ~/.ssh/id_rsa)"
    exit 1
fi

echo "=== Claude Runner Remote Verification ==="
echo "Target: $REMOTE_USER@$REMOTE_HOST"
echo "=========================================="
echo ""

# Track failures
FAILURES=0

# SSH options
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o BatchMode=yes -o ConnectTimeout=10"
if [ -f "$REMOTE_KEY" ]; then
    SSH_OPTS="$SSH_OPTS -i $REMOTE_KEY"
fi

# Helper function for checks
check() {
    local name="$1"
    local cmd="$2"
    printf "%-40s" "Checking $name..."

    if OUTPUT=$(ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" "$cmd" 2>&1); then
        echo "[OK]"
        if [ -n "$OUTPUT" ] && [ "$3" = "show" ]; then
            echo "  └─ $OUTPUT"
        fi
        return 0
    else
        echo "[FAILED]"
        if [ -n "$OUTPUT" ]; then
            echo "  └─ $OUTPUT"
        fi
        ((FAILURES++))
        return 1
    fi
}

# Phase 1: SSH Connectivity
echo "== Phase 1: SSH Connectivity =="
check "SSH connection" "echo 'connected'" || {
    echo ""
    echo "FATAL: Cannot connect to remote host via SSH."
    echo ""
    echo "To fix:"
    echo "  1. Ensure SSH key is set up: ssh-copy-id $REMOTE_USER@$REMOTE_HOST"
    echo "  2. Test manually: ssh $REMOTE_USER@$REMOTE_HOST"
    echo "  3. Check firewall allows port 22"
    exit 1
}
echo ""

# Phase 2: Docker Installation
echo "== Phase 2: Docker Installation =="
check "Docker installed" "docker --version" "show"
check "Docker daemon running" "docker info > /dev/null 2>&1"
check "Docker permissions" "docker ps > /dev/null 2>&1" || {
    echo "  └─ Hint: Run 'sudo usermod -aG docker $REMOTE_USER' on remote"
}
echo ""

# Phase 3: Network Access
echo "== Phase 3: Network Access =="
check "Internet connectivity" "curl -s --max-time 5 https://api.anthropic.com > /dev/null"
check "GitHub access" "curl -s --max-time 5 https://github.com > /dev/null"
echo ""

# Phase 4: Working Directory
echo "== Phase 4: Working Directory =="
check "Working dir exists" "test -d ~/claude-runner" || {
    echo "  └─ Will be created during setup"
}
check "Dockerfile present" "test -f ~/claude-runner/claude-runner.dockerfile" || {
    echo "  └─ Will be copied during setup"
}
check "Entrypoint present" "test -f ~/claude-runner/assets/entrypoint.sh" || {
    echo "  └─ Will be copied during setup"
}
echo ""

# Phase 5: Docker Image
echo "== Phase 5: Docker Image =="
check "claude-runner image" "docker image inspect claude-runner:latest > /dev/null 2>&1" || {
    echo "  └─ Will be built during setup"
}
echo ""

# Phase 6: System Resources
echo "== Phase 6: System Resources =="
check "Disk space (>5GB free)" "[ \$(df -BG ~ | tail -1 | awk '{print \$4}' | tr -d 'G') -gt 5 ]" || {
    echo "  └─ Consider cleaning up: docker system prune"
}
check "Memory (>2GB)" "[ \$(free -g | awk '/^Mem:/{print \$7}') -gt 1 ]" "show" || {
    echo "  └─ Low memory may cause build failures"
}
echo ""

# Summary
echo "=========================================="
if [ $FAILURES -eq 0 ]; then
    echo "All checks passed! Remote is ready for Claude Runner."
    echo ""
    echo "Next steps:"
    echo "  1. Run setup: ./run-remote.sh setup $REMOTE_HOST"
    echo "  2. Or manually:"
    echo "     scp assets/* $REMOTE_USER@$REMOTE_HOST:~/claude-runner/"
    echo "     ssh $REMOTE_USER@$REMOTE_HOST 'cd ~/claude-runner && docker build -t claude-runner:latest .'"
else
    echo "Found $FAILURES issue(s). Please fix before proceeding."
    echo ""
    echo "Quick fixes:"
    echo "  - Docker not installed: ssh $REMOTE_USER@$REMOTE_HOST 'curl -fsSL https://get.docker.com | sudo sh'"
    echo "  - Permission denied: ssh $REMOTE_USER@$REMOTE_HOST 'sudo usermod -aG docker \$USER'"
    echo "  - Working dir missing: ssh $REMOTE_USER@$REMOTE_HOST 'mkdir -p ~/claude-runner/assets'"
fi
echo "=========================================="

exit $FAILURES
