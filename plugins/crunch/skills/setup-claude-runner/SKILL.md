---
name: setup-claude-runner
description: Set up Claude Code runner container with Docker support
arguments:
  - name: action
    required: false
    description: |
      Action to perform:
      - 'setup': Install Docker (if needed), copy files, build image
      - 'verify': Check all prerequisites
      - 'run': Execute container with prompt
      - 'build': Build Docker image only
      - 'test': Run test workflow
      Default: setup
  - name: host
    required: false
    description: |
      Target host. Use 'localhost' for local execution or hostname/IP for remote.
      Default: localhost
  - name: git_repo
    required: false
    description: Git repository URL to clone - any provider (GitHub, GitLab, Gitea, etc.)
  - name: git_branch
    required: false
    description: Git branch to checkout (default: main)
  - name: prompt
    required: false
    description: Prompt to send to Claude Code agent
---

# Setup Claude Runner Skill

This skill sets up a Docker-based Claude Code runner that can clone a git repository
and execute Claude Code agent prompts against it. Works on local machine or remote hosts.

## Assets

```
plugins/crunch/skills/setup-claude-runner/
├── SKILL.md
└── assets/
    ├── claude-runner.sh              # Main CLI (unified local/remote)
    ├── claude-runner.dockerfile      # Docker image definition
    └── entrypoint.sh                 # Container entrypoint
```

## Arguments

| Argument     | Required | Default     | Description                       |
|--------------|----------|-------------|-----------------------------------|
| `action`     | No       | `setup`     | Action to perform                 |
| `host`       | No       | `localhost` | Target host (local or remote)     |
| `git_repo`   | No       | -           | Git repository URL                |
| `git_branch` | No       | `main`      | Git branch to checkout            |
| `prompt`     | No       | -           | Prompt for Claude Code agent      |

## Definition of Done

1. Docker is installed and running on target host
2. Dockerfile and entrypoint are in place
3. Docker image is built
4. Container can clone a repo and run Claude Code agent

---

## Quick Start

```bash
# Make script executable
chmod +x plugins/crunch/skills/setup-claude-runner/assets/claude-runner.sh
cd plugins/crunch/skills/setup-claude-runner/assets

# Setup (local)
./claude-runner.sh setup

# Setup (remote)
HOST=server.example.com ./claude-runner.sh setup

# Run
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
GIT_REPO="https://github.com/user/repo.git" \
PROMPT="Explain the project structure" \
./claude-runner.sh run

# Run on remote
HOST=server.example.com \
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
GIT_REPO="https://github.com/user/repo.git" \
PROMPT="Explain the project structure" \
./claude-runner.sh run
```

---

## Environment Variables

| Variable            | Required | Default         | Description                     |
|---------------------|----------|-----------------|---------------------------------|
| `HOST`              | No       | `localhost`     | Target host                     |
| `REMOTE_USER`       | No       | `$USER`         | SSH user (for remote)           |
| `REMOTE_KEY`        | No       | `~/.ssh/id_rsa` | SSH key path (for remote)       |
| `WORK_DIR`          | No       | `claude-runner` | Working directory on host       |
| `GIT_REPO`          | Yes*     | -               | Repository to clone             |
| `GIT_BRANCH`        | No       | `main`          | Branch to checkout              |
| `PROMPT`            | Yes*     | -               | Prompt for Claude Code          |
| `ANTHROPIC_API_KEY` | Yes*     | -               | Anthropic API key               |

*Required for `run` action

---

## Actions

### verify

Check all prerequisites on target host.

```bash
./claude-runner.sh verify
HOST=remote-server ./claude-runner.sh verify
```

**Checks performed:**

| Check              | Description                           |
|--------------------|---------------------------------------|
| SSH connectivity   | Can connect (remote only)             |
| Docker installed   | `docker --version` works              |
| Docker daemon      | `docker info` works                   |
| Docker permissions | User can run `docker ps`              |
| Internet access    | Can reach api.anthropic.com           |
| Working directory  | ~/claude-runner exists                |
| Dockerfile         | claude-runner.dockerfile present      |
| Entrypoint         | entrypoint.sh present                 |
| Docker image       | claude-runner:latest exists           |

---

### setup

Full setup: install Docker (if needed), copy files, build image.

```bash
# Local
./claude-runner.sh setup

# Remote
HOST=remote-server REMOTE_USER=deploy ./claude-runner.sh setup
```

**What it does:**

1. Checks if Docker is installed
   - Local: prompts user to install if missing
   - Remote: installs via `get.docker.com`
2. Creates working directory (`~/claude-runner`)
3. Copies `claude-runner.dockerfile` and `entrypoint.sh`
4. Builds Docker image `claude-runner:latest`

---

### build

Build (or rebuild) the Docker image.

```bash
./claude-runner.sh build
HOST=remote-server ./claude-runner.sh build
```

---

### run

Execute the container with a prompt against a git repository.

```bash
ANTHROPIC_API_KEY="sk-..." \
GIT_REPO="https://github.com/user/repo.git" \
GIT_BRANCH="main" \
PROMPT="Explain the architecture" \
./claude-runner.sh run

# Remote
HOST=remote-server \
ANTHROPIC_API_KEY="sk-..." \
GIT_REPO="https://github.com/user/repo.git" \
PROMPT="List all API endpoints" \
./claude-runner.sh run
```

**Output:**

```
[localhost] === Claude Runner ===
[localhost] Repository: https://github.com/user/repo.git
[localhost] Branch: main
[localhost] Prompt: Explain the architecture
[localhost] ====================
Cloning into '/workspace/repo'...
Repository cloned. Running Claude Code agent...

[Claude Code output here]

=== Claude Runner Complete ===
```

---

### test

Test container startup (doesn't require API key).

```bash
./claude-runner.sh test
```

---

## Remote Host Configuration

For remote hosts, configure SSH access first:

```bash
# Generate SSH key (if needed)
ssh-keygen -t ed25519 -C "claude-runner"

# Copy to remote
ssh-copy-id user@remote-host

# Test connection
ssh user@remote-host "echo OK"

# (Optional) Add to ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host claude-runner
    HostName 192.168.1.100
    User deploy
    IdentityFile ~/.ssh/id_ed25519
EOF

# Now use the alias
HOST=claude-runner ./claude-runner.sh setup
```

---

## Dockerfile Reference

### claude-runner.dockerfile

```dockerfile
FROM ubuntu:22.04

# Install Node.js 20.x and Claude Code CLI
RUN apt-get update && apt-get install -y curl git ca-certificates gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
    gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] \
    https://deb.nodesource.com/node_20.x nodistro main" | \
    tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /workspace
COPY assets/entrypoint.sh /entrypoint.sh

ENV GIT_REPO="" GIT_BRANCH="main" PROMPT="" ANTHROPIC_API_KEY=""
ENTRYPOINT ["/entrypoint.sh"]
```

### entrypoint.sh

```bash
#!/bin/bash
set -e

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

## Security Notes

| Concern              | Recommendation                                   |
|----------------------|--------------------------------------------------|
| API key exposure     | Pass via environment, never in commands          |
| SSH security         | Use key-based auth, disable password             |
| Remote Docker        | Don't expose daemon over TCP without TLS         |
| Network isolation    | Use firewall on Docker host                      |
| Secrets in images    | Never bake secrets into Docker images            |

---

## Troubleshooting

| Error                           | Cause                    | Solution                              |
|---------------------------------|--------------------------|---------------------------------------|
| `Docker not found`              | Not installed            | Install Docker Desktop or use setup   |
| `Permission denied`             | User not in docker group | `sudo usermod -aG docker $USER`       |
| `Cannot connect to Docker`      | Daemon not running       | Start Docker Desktop / daemon         |
| `SSH permission denied`         | Key not configured       | `ssh-copy-id user@host`               |
| `Repository not found`          | Invalid URL or private   | Check URL, use token for private      |
| `ANTHROPIC_API_KEY required`    | Key not set              | Export the environment variable       |

---

## Examples

```bash
# Verify local Docker setup
./claude-runner.sh verify

# Setup on remote server
HOST=prod-server.example.com REMOTE_USER=deploy ./claude-runner.sh setup

# Run analysis on a GitHub repo
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
GIT_REPO="https://github.com/anthropics/anthropic-cookbook.git" \
PROMPT="What examples are included in this cookbook?" \
./claude-runner.sh run

# Run on remote with different branch
HOST=worker-1 \
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
GIT_REPO="https://github.com/user/project.git" \
GIT_BRANCH="feature-branch" \
PROMPT="Review the changes in this branch" \
./claude-runner.sh run
```
