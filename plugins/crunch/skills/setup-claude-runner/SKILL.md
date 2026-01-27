---
name: setup-claude-runner
description: Set up Claude Code runner container with Docker support (local or remote)
arguments:
  - name: action
    required: false
    description: |
      Action to perform:
      - 'setup': Full setup (check docker, copy dockerfile, build)
      - 'setup-remote': Setup on a remote machine via SSH (verify, install, build)
      - 'verify-remote': Verify remote machine prerequisites only
      - 'check': Check Docker availability only
      - 'test': Test the dockerfile with a sample repo
      - 'run': Run the container locally
      - 'run-remote': Run the container on a remote machine
      Default: setup
  - name: remote_host
    required: false
    description: Remote machine hostname or IP (for remote actions)
  - name: git_repo
    required: false
    description: Git repository URL to clone
  - name: git_branch
    required: false
    description: Git branch to checkout (default: main)
  - name: prompt
    required: false
    description: Prompt to send to Claude Code agent
---

# Setup Claude Runner Skill

This skill sets up a Docker-based Claude Code runner that can clone a git repository
and execute Claude Code agent prompts against it. Supports both local and remote execution.

## Assets

```
plugins/crunch/skills/setup-claude-runner/
├── SKILL.md
└── assets/
    ├── claude-runner.dockerfile      # Main dockerfile
    ├── entrypoint.sh                 # Container entrypoint script
    ├── remote-setup.sh               # Remote machine setup script
    ├── remote-config.yaml.template   # Remote configuration template
    ├── run-remote.sh                 # Run on remote machine script
    └── verify-remote.sh              # Verify remote prerequisites
```

## Arguments

| Argument      | Required | Default | Description                           |
|---------------|----------|---------|---------------------------------------|
| `action`      | No       | `setup` | Action to perform (see above)         |
| `remote_host` | No       | -       | Remote hostname (for remote actions)  |
| `git_repo`    | No       | -       | Git repository URL                    |
| `git_branch`  | No       | `main`  | Git branch to checkout                |
| `prompt`      | No       | -       | Prompt for Claude Code agent          |

## Definition of Done

1. Docker is installed and running (local or remote)
2. Dockerfile and scripts are in place
3. Docker image is built
4. Container can clone a repo and run Claude Code agent

---

# Local Setup

## Quick Start (Local)

```bash
# 1. Copy files to project root
cp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile ./
cp plugins/crunch/skills/setup-claude-runner/assets/entrypoint.sh ./assets/

# 2. Build image
docker build -f claude-runner.dockerfile -t claude-runner:latest .

# 3. Run
docker run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="https://github.com/user/repo.git" \
  -e PROMPT="Explain the project structure" \
  claude-runner:latest
```

---

# Remote Setup

## Action: setup-remote

Full remote setup workflow with verification.

**Steps:**

1. Verify remote prerequisites (`verify-remote.sh`)
2. Install Docker if missing (`remote-setup.sh`)
3. Copy dockerfile and entrypoint to remote
4. Build Docker image on remote
5. Run test to verify

**Commands:**

```bash
# Step 1: Verify remote (required before setup)
./assets/verify-remote.sh remote-host

# Step 2-5: Run full setup
REMOTE_USER=deploy ./assets/remote-setup.sh remote-host
```

---

## Action: verify-remote

Verify remote machine prerequisites without making changes.

**Checks performed:**

| Check                    | What it verifies                              |
|--------------------------|-----------------------------------------------|
| SSH connectivity         | Can connect to remote via SSH                 |
| Docker installed         | `docker --version` succeeds                   |
| Docker daemon running    | `docker info` succeeds                        |
| Docker permissions       | User can run `docker ps`                      |
| Internet connectivity    | Can reach api.anthropic.com                   |
| GitHub access            | Can reach github.com                          |
| Working directory        | ~/claude-runner exists                        |
| Dockerfile present       | claude-runner.dockerfile is in place          |
| Entrypoint present       | entrypoint.sh is in place                     |
| Docker image built       | claude-runner:latest image exists             |
| Disk space               | At least 5GB free                             |
| Memory                   | At least 2GB available                        |

**Commands:**

```bash
# Run verification
chmod +x plugins/crunch/skills/setup-claude-runner/assets/verify-remote.sh
./assets/verify-remote.sh remote-host

# With custom user and key
REMOTE_USER=deploy REMOTE_KEY=~/.ssh/mykey ./assets/verify-remote.sh remote-host
```

**Example output:**

```
=== Claude Runner Remote Verification ===
Target: deploy@remote-host
==========================================

== Phase 1: SSH Connectivity ==
Checking SSH connection...                  [OK]

== Phase 2: Docker Installation ==
Checking Docker installed...                [OK]
  └─ Docker version 24.0.7, build afdd53b
Checking Docker daemon running...           [OK]
Checking Docker permissions...              [OK]

== Phase 3: Network Access ==
Checking Internet connectivity...           [OK]
Checking GitHub access...                   [OK]

== Phase 4: Working Directory ==
Checking Working dir exists...              [FAILED]
  └─ Will be created during setup
Checking Dockerfile present...              [FAILED]
  └─ Will be copied during setup
Checking Entrypoint present...              [FAILED]
  └─ Will be copied during setup

== Phase 5: Docker Image ==
Checking claude-runner image...             [FAILED]
  └─ Will be built during setup

== Phase 6: System Resources ==
Checking Disk space (>5GB free)...          [OK]
Checking Memory (>2GB)...                   [OK]

==========================================
Found 4 issue(s). Please fix before proceeding.
```

---

## Prerequisites for Remote Execution

Before running on a remote machine, you need:

| Requirement          | Description                                    |
|----------------------|------------------------------------------------|
| SSH access           | SSH key-based authentication to remote machine |
| Remote user          | User with sudo or docker group membership      |
| Network              | Remote can access git repos and Anthropic API  |

## Phase 1: Configure SSH Access

**1. Generate SSH key (if needed):**

```bash
ssh-keygen -t ed25519 -C "claude-runner"
```

**2. Copy public key to remote:**

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@remote-host
```

**3. Test SSH connection:**

```bash
ssh user@remote-host "echo 'SSH connection successful'"
```

**4. (Optional) Add to SSH config:**

```bash
# ~/.ssh/config
Host claude-runner-host
    HostName 192.168.1.100
    User deploy
    IdentityFile ~/.ssh/id_ed25519
```

---

## Phase 2: Setup Remote Machine

**Option A: Automated setup**

```bash
# Copy and run setup script on remote
scp plugins/crunch/skills/setup-claude-runner/assets/remote-setup.sh user@remote-host:~
ssh user@remote-host "chmod +x remote-setup.sh && ./remote-setup.sh"
```

**Option B: Manual setup**

```bash
# SSH to remote
ssh user@remote-host

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Log out and back in for group changes
exit
ssh user@remote-host

# Verify Docker
docker --version
docker run hello-world
```

---

## Phase 3: Build Image on Remote

**Option A: Build on remote (recommended)**

```bash
# Create working directory on remote
ssh user@remote-host "mkdir -p ~/claude-runner/assets"

# Copy dockerfile and entrypoint
scp plugins/crunch/skills/setup-claude-runner/assets/claude-runner.dockerfile user@remote-host:~/claude-runner/
scp plugins/crunch/skills/setup-claude-runner/assets/entrypoint.sh user@remote-host:~/claude-runner/assets/

# Build on remote
ssh user@remote-host "cd ~/claude-runner && docker build -f claude-runner.dockerfile -t claude-runner:latest ."
```

**Option B: Use Docker registry**

```bash
# Build locally
docker build -f claude-runner.dockerfile -t claude-runner:latest .

# Tag for registry
docker tag claude-runner:latest ghcr.io/your-org/claude-runner:latest

# Push to registry
docker push ghcr.io/your-org/claude-runner:latest

# Pull on remote
ssh user@remote-host "docker pull ghcr.io/your-org/claude-runner:latest"
ssh user@remote-host "docker tag ghcr.io/your-org/claude-runner:latest claude-runner:latest"
```

---

## Phase 4: Configure API Key on Remote

**IMPORTANT:** Never store API keys in plain text files or pass them as command arguments.

**Option A: Pass via SSH (recommended for one-off runs)**

The API key is passed through the SSH session, not stored on remote:

```bash
ssh user@remote-host "ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' docker run --rm \
  -e ANTHROPIC_API_KEY \
  -e GIT_REPO='https://github.com/user/repo.git' \
  -e PROMPT='Your prompt' \
  claude-runner:latest"
```

**Option B: Secrets file on remote (for persistent setup)**

```bash
# On remote machine, create secrets file with restricted permissions
ssh user@remote-host "echo 'export ANTHROPIC_API_KEY=your-key-here' > ~/.claude-runner-secrets && chmod 600 ~/.claude-runner-secrets"

# Source before running
ssh user@remote-host "source ~/.claude-runner-secrets && docker run --rm \
  -e ANTHROPIC_API_KEY \
  -e GIT_REPO='...' \
  -e PROMPT='...' \
  claude-runner:latest"
```

**Option C: Docker secrets (for Docker Swarm)**

```bash
# Create secret
echo "$ANTHROPIC_API_KEY" | docker secret create anthropic_api_key -

# Use in service (Swarm mode only)
docker service create --secret anthropic_api_key claude-runner:latest
```

---

## Phase 5: Run on Remote

**Using run-remote.sh script:**

```bash
# Make script executable
chmod +x plugins/crunch/skills/setup-claude-runner/assets/run-remote.sh

# Run
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
REMOTE_USER="deploy" \
./plugins/crunch/skills/setup-claude-runner/assets/run-remote.sh \
  "remote-host" \
  "https://github.com/user/repo.git" \
  "Explain the architecture"
```

**Direct SSH command:**

```bash
ssh user@remote-host "
  cd ~/claude-runner && \
  docker run --rm \
    -e ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' \
    -e GIT_REPO='https://github.com/user/repo.git' \
    -e GIT_BRANCH='main' \
    -e PROMPT='Explain the project structure' \
    claude-runner:latest
"
```

---

## Remote Configuration File

Create `remote-config.yaml` from template for persistent configuration:

```bash
cp plugins/crunch/skills/setup-claude-runner/assets/remote-config.yaml.template ./remote-config.yaml
```

**Example configuration:**

```yaml
remote:
  host: "192.168.1.100"
  user: "deploy"
  port: 22
  key_file: "~/.ssh/claude-runner"

docker:
  image_strategy: "build"

api_key:
  method: "env"

work_dir: "~/claude-runner"
```

---

## Docker Context (Alternative Approach)

Instead of SSH commands, you can use Docker contexts to control remote Docker:

**1. Create context:**

```bash
docker context create remote-runner \
  --docker "host=ssh://user@remote-host"
```

**2. Use context:**

```bash
# Switch to remote context
docker context use remote-runner

# Now all docker commands run on remote
docker build -f claude-runner.dockerfile -t claude-runner:latest .
docker run --rm -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" ...

# Switch back to local
docker context use default
```

**3. One-off command with context:**

```bash
docker --context remote-runner run --rm \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  -e GIT_REPO="https://github.com/user/repo.git" \
  -e PROMPT="Your prompt" \
  claude-runner:latest
```

---

## Security Considerations

| Concern                | Recommendation                                      |
|------------------------|-----------------------------------------------------|
| API key exposure       | Never log or echo API keys; use env vars            |
| SSH security           | Use key-based auth, disable password auth           |
| Docker socket          | Don't expose Docker daemon over TCP without TLS     |
| Network isolation      | Use firewall to restrict access to Docker host      |
| Image provenance       | Use signed images if using registry                 |
| Secrets in images      | Never bake secrets into Docker images               |

---

## Troubleshooting Remote

| Error                           | Cause                         | Solution                              |
|---------------------------------|-------------------------------|---------------------------------------|
| `Permission denied (publickey)` | SSH key not configured        | Run `ssh-copy-id user@host`           |
| `Cannot connect to Docker`      | User not in docker group      | `sudo usermod -aG docker $USER`       |
| `Connection refused`            | Docker daemon not running     | `sudo systemctl start docker`         |
| `Network unreachable`           | Firewall blocking             | Check firewall rules                  |
| `Image not found`               | Image not built on remote     | Build or pull image on remote         |

---

## Complete Remote Setup Checklist

```markdown
- [ ] SSH key generated and copied to remote
- [ ] SSH connection tested successfully
- [ ] Docker installed on remote machine
- [ ] User added to docker group on remote
- [ ] Working directory created on remote
- [ ] Dockerfile and entrypoint.sh copied to remote
- [ ] Docker image built on remote
- [ ] API key handling method chosen and configured
- [ ] Test run completed successfully
```

---

## Quick Reference

```bash
# === Local ===
docker build -f claude-runner.dockerfile -t claude-runner:latest .
docker run --rm -e ANTHROPIC_API_KEY -e GIT_REPO="..." -e PROMPT="..." claude-runner:latest

# === Remote Setup ===
ssh-copy-id user@remote-host
scp assets/claude-runner.dockerfile assets/entrypoint.sh user@remote-host:~/claude-runner/
ssh user@remote-host "cd ~/claude-runner && docker build -f claude-runner.dockerfile -t claude-runner:latest ."

# === Remote Run ===
ssh user@remote-host "ANTHROPIC_API_KEY='$ANTHROPIC_API_KEY' docker run --rm \
  -e ANTHROPIC_API_KEY -e GIT_REPO='...' -e PROMPT='...' claude-runner:latest"

# === Docker Context ===
docker context create remote --docker "host=ssh://user@remote-host"
docker --context remote run --rm -e ANTHROPIC_API_KEY -e GIT_REPO="..." -e PROMPT="..." claude-runner:latest
```
