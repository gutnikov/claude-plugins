---
name: setup-claude-runner
description: Set up Claude Code runner container with Docker support
arguments:
  - name: action
    required: false
    description: |
      Action to perform:
      - 'setup': Full setup (check docker, copy dockerfile, test)
      - 'check': Check Docker availability only
      - 'test': Test the dockerfile
      Default: setup
---

# Setup Claude Runner Skill

This skill sets up a Docker-based Claude Code runner environment. It copies the
dockerfile to the project root and verifies Docker is working correctly.

## Assets

```
plugins/crunch/skills/setup-claude-runner/
├── SKILL.md
└── assets/
    └── claude-runner.dockerfile    # Dockerfile to copy to project root
```

## Arguments

| Argument | Required | Default | Description                        |
|----------|----------|---------|------------------------------------|
| `action` | No       | `setup` | `setup`, `check`, or `test`        |

## Definition of Done

1. Docker is installed and running
2. `claude-runner.dockerfile` exists in project root
3. Docker build succeeds
4. Container runs and outputs verification message

---

## Actions

### Action: setup

Full setup workflow.

**Steps:**

1. Check Docker availability
2. Copy dockerfile to project root
3. Build Docker image
4. Run container to verify

---

### Action: check

Check Docker availability only.

---

### Action: test

Test existing dockerfile (build and run).

---

## Workflow

### Phase 1: Docker Check

Verify Docker is installed and running.

**Check Commands:**

```bash
# Check Docker CLI is available
docker --version

# Check Docker daemon is running
docker info
```

**If Docker not installed:**

Present installation options based on platform:

| Platform | Installation                                      |
|----------|---------------------------------------------------|
| macOS    | `brew install --cask docker` or Docker Desktop    |
| Linux    | `curl -fsSL https://get.docker.com | sh`          |
| Windows  | Docker Desktop installer                          |

**Interactive Checkpoint:**

If Docker not available:
- Offer to show installation instructions
- Retry after installation
- Abort setup

---

### Phase 2: Copy Dockerfile

Copy dockerfile from assets to project root.

**Commands:**

```bash
# Copy dockerfile to project root
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./claude-runner.dockerfile

# Verify file exists
ls -la claude-runner.dockerfile
```

**Source file:** `plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile`

**Destination:** `{project_root}/claude-runner.dockerfile`

---

### Phase 3: Build Image

Build Docker image from dockerfile.

**Commands:**

```bash
# Build image with tag
docker build -f claude-runner.dockerfile -t claude-runner:latest .
```

**Expected Output:**

```
Successfully built <image_id>
Successfully tagged claude-runner:latest
```

**On failure:**
- Show build error output
- Offer to retry or abort

---

### Phase 4: Test Container

Run container in non-interactive mode to verify.

**Commands:**

```bash
# Run container (non-interactive, auto-remove)
docker run --rm claude-runner:latest
```

**Expected Output:**

```
Claude runner container is working
```

**Verification:**
- Exit code is 0
- Output contains expected message

---

## Dockerfile Reference

### assets/claude-runner.dockerfile

```dockerfile
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
```

---

## Error Handling

| Error                      | Detection                  | Recovery                              |
|----------------------------|----------------------------|---------------------------------------|
| Docker not installed       | `docker --version` fails   | Show installation instructions        |
| Docker daemon not running  | `docker info` fails        | Start Docker Desktop / daemon         |
| Build fails                | Non-zero exit code         | Show error, check dockerfile syntax   |
| Container fails to run     | Non-zero exit code         | Check image, rebuild                  |
| Permission denied          | Docker socket error        | Add user to docker group or use sudo  |

---

## Troubleshooting

| Error                           | Cause                        | Solution                              |
|---------------------------------|------------------------------|---------------------------------------|
| `Cannot connect to Docker`      | Daemon not running           | Start Docker Desktop or `systemctl start docker` |
| `permission denied`             | User not in docker group     | `sudo usermod -aG docker $USER` then re-login |
| `no space left on device`       | Disk full                    | `docker system prune` to clean up     |
| `image not found`               | Build failed                 | Check build output, rebuild           |

---

## Quick Reference

```bash
# Check Docker
docker --version
docker info

# Copy dockerfile
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./

# Build image
docker build -f claude-runner.dockerfile -t claude-runner:latest .

# Test container
docker run --rm claude-runner:latest

# Clean up
docker rmi claude-runner:latest
```
