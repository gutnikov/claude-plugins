---
name: setup-claude-runner
description: Set up Claude Code runner container with Docker support
arguments:
  - name: action
    required: false
    description: |
      Action to perform:
      - 'setup': Full setup (check docker, copy dockerfile, build)
      - 'check': Check Docker availability only
      - 'test': Test the dockerfile with a sample repo
      - 'run': Run the container with specified repo and prompt
      Default: setup
  - name: git_repo
    required: false
    description: Git repository URL to clone (for 'run' action)
  - name: git_branch
    required: false
    description: Git branch to checkout (default: main)
  - name: prompt
    required: false
    description: Prompt to send to Claude Code agent
---

# Setup Claude Runner Skill

This skill sets up a Docker-based Claude Code runner that can clone a git repository
and execute Claude Code agent prompts against it. The container runs in non-interactive
mode and returns the prompt result.

## Assets

```
plugins/crunch/skills/setup-claude-runner/
├── SKILL.md
└── assets/
    ├── claude-runner.dockerfile    # Main dockerfile
    └── entrypoint.sh               # Container entrypoint script
```

## Arguments

| Argument     | Required | Default | Description                          |
|--------------|----------|---------|--------------------------------------|
| `action`     | No       | `setup` | `setup`, `check`, `test`, or `run`   |
| `git_repo`   | No       | -       | Git repository URL (for run action)  |
| `git_branch` | No       | `main`  | Git branch to checkout               |
| `prompt`     | No       | -       | Prompt for Claude Code agent         |

## Definition of Done

1. Docker is installed and running
2. `claude-runner.dockerfile` and `entrypoint.sh` exist in project root
3. Docker build succeeds
4. Container can clone a repo and run Claude Code agent

---

## Container Usage

### Environment Variables

| Variable           | Required | Default | Description                    |
|--------------------|----------|---------|--------------------------------|
| `GIT_REPO`         | Yes      | -       | Git repository URL to clone    |
| `GIT_BRANCH`       | No       | `main`  | Branch to checkout             |
| `PROMPT`           | Yes      | -       | Prompt for Claude Code agent   |
| `ANTHROPIC_API_KEY`| Yes      | -       | Anthropic API key              |

### Run with Arguments

```bash
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  claude-runner:latest \
  "https://github.com/user/repo.git" \
  "main" \
  "Explain the project structure"
```

### Run with Environment Variables

```bash
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="https://github.com/user/repo.git" \
  -e GIT_BRANCH="main" \
  -e PROMPT="Explain the project structure" \
  claude-runner:latest
```

### Expected Output

```
=== Claude Runner ===
Repository: https://github.com/user/repo.git
Branch: main
Prompt: Explain the project structure
====================
Cloning repository...
Cloning into '/workspace/repo'...
Repository cloned. Running Claude Code agent...

[Claude Code agent output here]

=== Claude Runner Complete ===
```

---

## Actions

### Action: setup

Full setup workflow.

**Steps:**

1. Check Docker availability
2. Copy dockerfile and entrypoint to project root
3. Build Docker image

**Commands:**

```bash
# Copy files to project root
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./
cp plugins/crunch/skills/setup-claude-runner/assets/entrypoint.sh ./assets/

# Build image
docker build -f claude-runner.dockerfile -t claude-runner:latest .
```

---

### Action: check

Check Docker availability only.

**Commands:**

```bash
docker --version
docker info
```

---

### Action: test

Test the dockerfile with a sample public repository.

**Commands:**

```bash
# Build if not already built
docker build -f claude-runner.dockerfile -t claude-runner:latest .

# Test with a simple prompt (requires ANTHROPIC_API_KEY)
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="https://github.com/anthropics/anthropic-cookbook.git" \
  -e GIT_BRANCH="main" \
  -e PROMPT="List the top-level files in this repository" \
  claude-runner:latest
```

---

### Action: run

Run the container with specified parameters.

**Commands:**

```bash
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="<git_repo>" \
  -e GIT_BRANCH="<git_branch>" \
  -e PROMPT="<prompt>" \
  claude-runner:latest
```

---

## Workflow Phases

### Phase 1: Docker Check

Verify Docker is installed and running.

**Commands:**

```bash
docker --version
docker info
```

**If Docker not installed:**

| Platform | Installation                                      |
|----------|---------------------------------------------------|
| macOS    | `brew install --cask docker` or Docker Desktop    |
| Linux    | `curl -fsSL https://get.docker.com | sh`          |
| Windows  | Docker Desktop installer                          |

---

### Phase 2: Copy Files

Copy dockerfile and entrypoint to project root.

**Commands:**

```bash
# Create assets directory if needed
mkdir -p assets

# Copy files
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./claude-runner.dockerfile
cp plugins/crunch/skills/setup-claude-runner/assets/entrypoint.sh ./assets/entrypoint.sh

# Make entrypoint executable
chmod +x assets/entrypoint.sh
```

**Files copied:**

| Source                                    | Destination                    |
|-------------------------------------------|--------------------------------|
| `assets/claude-runner.dockerfile`         | `./claude-runner.dockerfile`   |
| `assets/entrypoint.sh`                    | `./assets/entrypoint.sh`       |

---

### Phase 3: Build Image

Build Docker image.

**Commands:**

```bash
docker build -f claude-runner.dockerfile -t claude-runner:latest .
```

**Expected Output:**

```
Successfully built <image_id>
Successfully tagged claude-runner:latest
```

---

### Phase 4: Verify

Run a test to verify the container works.

**Commands:**

```bash
# Quick verification (will fail without API key, but tests container startup)
docker run --rm claude-runner:latest || true
```

**Expected error (without API key):**

```
Error: ANTHROPIC_API_KEY environment variable is required
```

This confirms the container starts and the entrypoint script runs correctly.

---

## Dockerfile Reference

### assets/claude-runner.dockerfile

```dockerfile
FROM ubuntu:22.04

# Install Node.js 20.x and Claude Code CLI
RUN apt-get update && apt-get install -y curl git ca-certificates gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /workspace
COPY assets/entrypoint.sh /entrypoint.sh

ENV GIT_REPO="" GIT_BRANCH="main" PROMPT="" ANTHROPIC_API_KEY=""
ENTRYPOINT ["/entrypoint.sh"]
```

### assets/entrypoint.sh

```bash
#!/bin/bash
set -e

GIT_REPO="${1:-$GIT_REPO}"
GIT_BRANCH="${2:-$GIT_BRANCH}"
PROMPT="${3:-$PROMPT}"

# Validate required parameters
[ -z "$GIT_REPO" ] && echo "Error: GIT_REPO required" && exit 1
[ -z "$PROMPT" ] && echo "Error: PROMPT required" && exit 1
[ -z "$ANTHROPIC_API_KEY" ] && echo "Error: ANTHROPIC_API_KEY required" && exit 1

# Clone repository
git clone --depth=1 --branch "$GIT_BRANCH" "$GIT_REPO" /workspace/repo
cd /workspace/repo

# Run Claude Code agent
claude --print --dangerously-skip-permissions "$PROMPT"
```

---

## Error Handling

| Error                      | Detection                  | Recovery                              |
|----------------------------|----------------------------|---------------------------------------|
| Docker not installed       | `docker --version` fails   | Show installation instructions        |
| Docker daemon not running  | `docker info` fails        | Start Docker Desktop / daemon         |
| Build fails                | Non-zero exit code         | Check dockerfile syntax               |
| Clone fails                | Git error in output        | Check repo URL and branch             |
| API key missing            | Entrypoint error           | Set ANTHROPIC_API_KEY env var         |
| Prompt fails               | Claude Code error          | Check prompt and repo contents        |

---

## Troubleshooting

| Error                           | Cause                        | Solution                              |
|---------------------------------|------------------------------|---------------------------------------|
| `ANTHROPIC_API_KEY required`    | API key not set              | Pass `-e ANTHROPIC_API_KEY=...`       |
| `GIT_REPO required`             | Repo not specified           | Pass repo as arg or env var           |
| `Repository not found`          | Invalid repo URL             | Check URL and access permissions      |
| `Branch not found`              | Invalid branch name          | Check branch exists in repo           |
| `Permission denied`             | Private repo                 | Use SSH key or token in URL           |

---

## Quick Reference

```bash
# Setup
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./
cp plugins/crunch/skills/setup-claude-runner/assets/entrypoint.sh ./assets/
docker build -f claude-runner.dockerfile -t claude-runner:latest .

# Run
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="https://github.com/user/repo.git" \
  -e PROMPT="Your prompt here" \
  claude-runner:latest

# Clean up
docker rmi claude-runner:latest
```
