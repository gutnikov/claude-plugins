---
name: setup-project
description: Project setup wizard. Auto-detects configured domains, shows setup status for required/optional domains, and guides through domain configuration.
---

# Setup Project

This skill provides a unified project setup dashboard that auto-detects existing domain configurations, displays setup status for all required and optional domains, and guides users through configuring any domain.

## Definition of Done

The setup is complete when:

1. All required domains are configured (or user explicitly defers)
2. User has reviewed optional domains
3. CLAUDE.md contains sections for all configured domains
4. Each configured domain passes its verification test

## Domain Classifications

### Required Domains (7)

Essential domains for a well-configured project:

| Domain                     | Key                       | Purpose                                     | Detection                                          |
|----------------------------|---------------------------|---------------------------------------------|----------------------------------------------------|
| **Tech Stack**             | `tech-stack`              | Auto-detect and configure project stack     | `## Tech Stack` in CLAUDE.md                       |
| **Configuration**          | `configuration`           | Manage env variables per environment        | `## Configuration` in CLAUDE.md                    |
| **Secrets**                | `secrets`                 | Store and retrieve secrets securely         | `## Secrets` in CLAUDE.md or secrets MCP in .mcp.json |
| **Pipelines**              | `pipelines`               | Define project pipelines (local, CI, deploy)| `## Pipelines` in CLAUDE.md                        |
| **Environments**           | `deploy-environments`     | Manage dev/staging/prod environments        | `## Environments` in CLAUDE.md                     |
| **Task Management**        | `task-management`         | Track and manage work items                 | `## Task Management` in CLAUDE.md or task MCP      |
| **Agents & Orchestration** | `agents-and-orchestration`| Configure Claude Code agents                | `## Agents` in CLAUDE.md                           |

### Optional Domains (7)

Enhance your project with additional capabilities:

| Domain                     | Key                      | Purpose                               | Detection                                     |
|----------------------------|--------------------------|---------------------------------------|-----------------------------------------------|
| **Memory Management**      | `memory-management`      | Persistent AI context across sessions | `## Memory` in CLAUDE.md or memory MCP        |
| **User Communication Bot** | `user-communication-bot` | Slack app/bot for project development | `## Communication` in CLAUDE.md or slack MCP  |
| **CI/CD**                  | `ci-cd`                  | Continuous integration and deployment | `## CI/CD` in CLAUDE.md                       |
| **Observability**          | `observability`          | Metrics, logs, traces, and alerting   | `## Observability` in CLAUDE.md               |
| **Problem Remediation**    | `problem-remediation`    | Runbook automation and self-healing   | `## Problem Remediation` in CLAUDE.md         |
| **Documentation**          | `documentation`          | Doc site generation and publishing    | `## Documentation` in CLAUDE.md               |
| **Localization**           | `localization`           | Internationalization and translation  | `## Localization` in CLAUDE.md                |

---

## Domain Detection Rules

### Detection Priority

For each domain, check in this order:

1. **CLAUDE.md section** - Primary indicator of configuration
2. **MCP configuration** - Check .mcp.json for relevant MCP servers
3. **Config files** - Domain-specific configuration files

### Detection Patterns by Domain

#### Tech Stack
```bash
# CLAUDE.md detection
grep -q "## Tech Stack" CLAUDE.md 2>/dev/null

# Additional: Check for package.json, requirements.txt, go.mod, etc.
ls package.json pyproject.toml requirements.txt go.mod Cargo.toml 2>/dev/null
```

#### Configuration
```bash
# CLAUDE.md detection
grep -q "## Configuration" CLAUDE.md 2>/dev/null

# Additional: Check for .env files, config directories
ls .env .env.* config/ 2>/dev/null
```

#### Secrets
```bash
# CLAUDE.md detection
grep -q "## Secrets" CLAUDE.md 2>/dev/null

# MCP detection - check for vault, 1password, or secrets MCPs
grep -E '"(vault|1password|secrets)"' .mcp.json 2>/dev/null

# File detection - check for SOPS config
ls .sops.yaml 2>/dev/null
```

#### Pipelines
```bash
# CLAUDE.md detection
grep -q "## Pipelines" CLAUDE.md 2>/dev/null

# Additional: Check for common pipeline files
ls Makefile justfile .github/workflows/*.yml 2>/dev/null
```

#### Environments (Deploy Environments)
```bash
# CLAUDE.md detection
grep -q "## Environments" CLAUDE.md 2>/dev/null

# Additional: Check for environment-specific configs
ls .env.development .env.staging .env.production 2>/dev/null
```

#### Task Management
```bash
# CLAUDE.md detection
grep -q "## Task Management" CLAUDE.md 2>/dev/null

# MCP detection - check for task management MCPs
grep -E '"(jira|trello|linear|asana|github-issues)"' .mcp.json 2>/dev/null
```

#### Agents & Orchestration
```bash
# CLAUDE.md detection
grep -q "## Agents" CLAUDE.md 2>/dev/null

# Additional: Check for agent config files
ls agents.json .claude/agents.json 2>/dev/null
```

#### Memory Management
```bash
# CLAUDE.md detection
grep -q "## Memory" CLAUDE.md 2>/dev/null

# MCP detection
grep -E '"(memory|pinecone|chroma|weaviate)"' .mcp.json 2>/dev/null
```

#### User Communication Bot
```bash
# CLAUDE.md detection
grep -q "## Communication" CLAUDE.md 2>/dev/null

# MCP detection
grep -E '"(slack|discord)"' .mcp.json 2>/dev/null
```

#### CI/CD
```bash
# CLAUDE.md detection
grep -q "## CI/CD" CLAUDE.md 2>/dev/null

# File detection
ls .github/workflows/*.yml .gitlab-ci.yml .circleci/config.yml Jenkinsfile 2>/dev/null
```

#### Observability
```bash
# CLAUDE.md detection
grep -q "## Observability" CLAUDE.md 2>/dev/null

# MCP detection
grep -E '"(datadog|grafana|prometheus)"' .mcp.json 2>/dev/null
```

#### Problem Remediation
```bash
# CLAUDE.md detection
grep -q "## Problem Remediation" CLAUDE.md 2>/dev/null

# File detection - runbooks directory
ls runbooks/ .runbooks/ 2>/dev/null
```

#### Documentation
```bash
# CLAUDE.md detection
grep -q "## Documentation" CLAUDE.md 2>/dev/null

# File detection - docs directory or config
ls docs/ docusaurus.config.js mkdocs.yml 2>/dev/null
```

#### Localization
```bash
# CLAUDE.md detection
grep -q "## Localization" CLAUDE.md 2>/dev/null

# File detection - i18n directories
ls locales/ i18n/ translations/ 2>/dev/null
```

---

## Domain Templates

This skill includes individual template files for each domain. When configuring a domain, use the corresponding template to generate the CLAUDE.md section.

**Templates Location**: `plugins/crunch/skills/setup-project/templates/`

### Available Templates

| Domain                 | Template File                          |
|------------------------|----------------------------------------|
| Tech Stack             | `tech-stack.template.md`               |
| Configuration          | `configuration.template.md`            |
| Secrets                | `secrets.template.md`                  |
| Pipelines              | `pipelines.template.md`                |
| Environments           | `deploy-environments.template.md`      |
| Task Management        | `task-management.template.md`          |
| Agents & Orchestration | `agents-and-orchestration.template.md` |
| Memory Management      | `memory-management.template.md`        |
| User Communication Bot | `user-communication-bot.template.md`   |
| CI/CD                  | `ci-cd.template.md`                    |
| Observability          | `observability.template.md`            |
| Problem Remediation    | `problem-remediation.template.md`      |
| Documentation          | `documentation.template.md`            |
| Localization           | `localization.template.md`             |

### Template Usage

When setting up a domain:

1. Read the domain template from `templates/{domain-key}.template.md`
2. Collect values for all `{placeholder}` variables during setup
3. Replace placeholders with actual values
4. Append or update the section in CLAUDE.md

**Example:**
```bash
# Read template
cat plugins/crunch/skills/setup-project/templates/secrets.template.md

# After collecting values, the placeholders like {secrets_backend}, {integration_type}, etc.
# are replaced with actual values (e.g., "SOPS + age", "File-based")
```

---

## Workflow

### Phase 0: Auto-Detection

**ALWAYS start here.** Scan the project to build the current status map.

#### Step 1: Read CLAUDE.md

```bash
cat CLAUDE.md 2>/dev/null
```

**If CLAUDE.md doesn't exist**, offer to create it:

```typescript
AskUserQuestion({
  questions: [{
    question: "No CLAUDE.md found. Would you like to create one?",
    header: "Initialize",
    options: [
      { label: "Yes, create CLAUDE.md (Recommended)", description: "Create CLAUDE.md to document project configuration" },
      { label: "Skip", description: "Continue without CLAUDE.md" }
    ],
    multiSelect: false
  }]
})
```

**If "Yes" selected:**

```bash
cat > CLAUDE.md << 'EOF'
# Project Configuration

This file documents the project setup for Claude Code.

<!-- Domain sections are added as they are configured via /setup-project -->
EOF
```

#### Step 2: Read .mcp.json

```bash
cat .mcp.json 2>/dev/null
```

Extract configured MCP servers for domain detection.

#### Step 3: Build Status Map

For each domain, determine status:

| Status           | Meaning                                   | Visual |
|------------------|-------------------------------------------|--------|
| `configured`     | Domain section exists and appears complete| `[x]`  |
| `partial`        | Some indicators present but incomplete    | `[~]`  |
| `not configured` | No indicators found                       | `[ ]`  |

#### Step 4: Extract Configuration Details

For configured domains, extract key details to display:

- **Tech Stack**: Language, framework, runtime versions
- **Configuration**: Config management tool (dotenv, direnv, etc.)
- **Secrets**: Backend type (Vault, SOPS, 1Password, etc.)
- **Pipelines**: Defined pipelines (local, ci, deploy)
- **Environments**: Environment names (dev, staging, prod)
- **Task Management**: Tool name (Jira, Trello, Linear)
- **Agents**: Agent types configured
- **Memory Management**: Memory backend
- **User Communication Bot**: Bot platform (Slack, Discord)
- **CI/CD**: CI platform (GitHub Actions, GitLab CI)
- **Observability**: Observability platform
- **Problem Remediation**: Runbook system
- **Documentation**: Doc system (Docusaurus, MkDocs)
- **Localization**: i18n system

---

### Phase 1: Display Status Dashboard

Present the complete project setup status:

```
Project Setup Status
====================

REQUIRED DOMAINS (7):
  [x] Tech Stack           - Configured (Node.js 20, TypeScript, React)
  [x] Configuration        - Configured (dotenv)
  [ ] Secrets              - Not configured
  [x] Pipelines            - Configured (local, ci)
  [ ] Environments         - Not configured
  [x] Task Management      - Configured (Jira)
  [ ] Agents & Orchestration - Not configured

  Required: 4/7 complete

OPTIONAL DOMAINS (7):
  [ ] Memory Management      - Not configured
  [x] User Communication Bot - Configured (Slack)
  [x] CI/CD                  - Configured (GitHub Actions)
  [ ] Observability          - Not configured
  [ ] Problem Remediation    - Not configured
  [ ] Documentation          - Not configured
  [ ] Localization           - Not configured

  Optional: 2/7 complete

Overall Progress: 6/14 domains configured
```

---

### Phase 2: Action Selection

Use AskUserQuestion to present action options:

```typescript
AskUserQuestion({
  questions: [{
    question: "What would you like to do?",
    header: "Action",
    options: [
      { label: "Setup required domain", description: "Configure a required domain that's not set up" },
      { label: "Setup optional domain", description: "Configure an optional domain" },
      { label: "Update existing domain", description: "Modify a domain that's already configured" },
      { label: "View domain details", description: "See configuration details for a domain" }
    ],
    multiSelect: false
  }]
})
```

**Note:** User can select "Other" for additional actions like "Setup all required domains" or "Exit".

---

### Phase 3: Domain Selection

Based on the selected action, present relevant domains.

#### For "Setup required domain"

Show only unconfigured required domains:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which required domain would you like to set up?",
    header: "Domain",
    options: [
      // Only include domains with status "not configured"
      { label: "Secrets", description: "Store and retrieve secrets securely" },
      { label: "Environments", description: "Manage dev/staging/prod environments" },
      { label: "Agents & Orchestration", description: "Configure Claude Code agents" }
    ],
    multiSelect: false
  }]
})
```

#### For "Setup optional domain"

Show all optional domains:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which optional domain would you like to set up?",
    header: "Domain",
    options: [
      { label: "Memory Management", description: "Persistent AI context across sessions" },
      { label: "Observability", description: "Metrics, logs, traces, and alerting" },
      { label: "Problem Remediation", description: "Runbook automation and self-healing" },
      { label: "Documentation", description: "Doc site generation and publishing" }
    ],
    multiSelect: false
  }]
})
```

#### For "Update existing domain"

Show only configured domains:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which domain would you like to update?",
    header: "Domain",
    options: [
      // Only include domains with status "configured"
      { label: "Tech Stack", description: "Currently: Node.js 20, TypeScript, React" },
      { label: "Configuration", description: "Currently: dotenv" },
      { label: "Task Management", description: "Currently: Jira" }
    ],
    multiSelect: false
  }]
})
```

#### For "View domain details"

Show all configured domains:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which domain's details would you like to view?",
    header: "Domain",
    options: [
      { label: "Tech Stack", description: "View tech stack configuration" },
      { label: "Configuration", description: "View configuration setup" },
      { label: "Task Management", description: "View task management setup" }
    ],
    multiSelect: false
  }]
})
```

---

### Phase 4: Domain Setup/Update

Each domain has specific setup instructions. The setup flow follows this pattern:

1. **Domain Explanation** - Why this domain matters
2. **Vendor/Tool Selection** - Choose implementation
3. **Configuration** - Set up the chosen tool
4. **Verification** - Test the setup
5. **Documentation** - Update CLAUDE.md

---

## Domain Setup Guides

### Tech Stack

#### Purpose
Auto-detect and document the project's technology stack for consistent development.

#### Popular Options
- **Auto-detect** (Recommended) - Scan package files
- **Manual entry** - Specify stack manually

#### Setup Flow

**Step 1: Auto-detect**

```bash
# Detect language/runtime
ls package.json 2>/dev/null && echo "Node.js project detected"
ls pyproject.toml requirements.txt 2>/dev/null && echo "Python project detected"
ls go.mod 2>/dev/null && echo "Go project detected"
ls Cargo.toml 2>/dev/null && echo "Rust project detected"

# Extract version from package.json
cat package.json | grep -E '"node"|"engines"' 2>/dev/null

# Detect framework
cat package.json | grep -E '"react"|"vue"|"angular"|"next"|"express"' 2>/dev/null
```

**Step 2: Confirm Detection**

```
I detected the following tech stack:

Language: Node.js 20
Runtime: Node.js 20.x
Package Manager: npm 10.x
Framework: React 18, Next.js 14
Build Tool: Turbopack
Testing: Jest, React Testing Library

Is this correct?
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Tech Stack

- **Language**: Node.js 20
- **Package Manager**: npm 10.x
- **Framework**: React 18, Next.js 14
- **Build Tool**: Turbopack
- **Testing**: Jest, React Testing Library

### Development Commands

- `npm install` - Install dependencies
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm test` - Run tests
```

---

### Configuration

#### Purpose
Manage environment variables and configuration across environments.

#### Popular Options
| Tool          | Description               | Best For          |
|---------------|---------------------------|-------------------|
| **dotenv**    | Simple .env files         | Small projects    |
| **direnv**    | Directory-specific env    | Multiple projects |
| **Doppler**   | Cloud config management   | Teams, production |
| **Infisical** | Open-source secrets/config| Self-hosted needs |

#### Setup Flow

**Step 1: Select Tool**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which configuration management tool would you like to use?",
    header: "Config Tool",
    options: [
      { label: "dotenv (Recommended)", description: "Simple .env files, works everywhere" },
      { label: "direnv", description: "Directory-specific environment variables" },
      { label: "Doppler", description: "Cloud-based configuration management" },
      { label: "Infisical", description: "Open-source secrets and config management" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Setup (dotenv example)**

```bash
# Check if .env.example exists
ls .env.example 2>/dev/null

# Create .env.example if not exists
cat > .env.example << 'EOF'
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=

# API Keys
API_KEY=
EOF
```

**Step 3: Verify .gitignore**

```bash
grep -q "^\.env$" .gitignore 2>/dev/null || echo ".env" >> .gitignore
```

**Step 4: Document**

Add to CLAUDE.md:

```markdown
## Configuration

**Tool**: dotenv

### Environment Files

- `.env` - Local development (gitignored)
- `.env.example` - Template with all variables
- `.env.test` - Test environment

### Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_ENV` | Environment name | Yes |
| `PORT` | Server port | No (default: 3000) |
| `DATABASE_URL` | Database connection string | Yes |

### Usage

Copy `.env.example` to `.env` and fill in values:
```bash
cp .env.example .env
```
```

---

### Secrets

#### Purpose
Securely store and retrieve sensitive credentials.

#### Popular Options
| Tool                    | Integration | Description                  | Best For                 |
|-------------------------|-------------|------------------------------|--------------------------|
| **HashiCorp Vault**     | MCP / CLI   | Enterprise secrets management| Large teams, compliance  |
| **SOPS + age**          | File-based  | Git-encrypted secrets        | GitOps workflows         |
| **1Password**           | MCP         | Password manager integration | Small teams              |
| **AWS Secrets Manager** | CLI         | AWS-native secrets           | AWS projects             |

#### Setup Flow

**Step 1: Select Backend**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which secrets management tool would you like to use?",
    header: "Secrets",
    options: [
      { label: "SOPS + age (Recommended)", description: "Git-friendly encrypted secrets with age keys" },
      { label: "HashiCorp Vault", description: "Enterprise secrets management with API access" },
      { label: "1Password", description: "Password manager with CLI and MCP integration" },
      { label: "AWS Secrets Manager", description: "AWS-native secrets management" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Setup (SOPS + age example)**

```bash
# Check for tools
which sops age-keygen 2>/dev/null

# Generate age key if needed
if [ ! -f ~/.config/sops/age/keys.txt ]; then
  mkdir -p ~/.config/sops/age
  age-keygen -o ~/.config/sops/age/keys.txt
fi

# Get public key
AGE_PUBLIC_KEY=$(age-keygen -y ~/.config/sops/age/keys.txt)

# Create .sops.yaml
cat > .sops.yaml << EOF
creation_rules:
  - path_regex: secrets/.*\.ya?ml$
    age: $AGE_PUBLIC_KEY
EOF

# Create secrets directory
mkdir -p secrets
```

**Step 3: Create Test Secret**

```bash
# Create and encrypt a test secret
echo "test_secret: hello_world" > secrets/test.yaml
sops -e -i secrets/test.yaml
```

**Step 4: Verify**

```bash
# Decrypt and verify
sops -d secrets/test.yaml
```

**Step 5: Document**

Add to CLAUDE.md:

```markdown
## Secrets

**Backend**: SOPS + age

### Configuration

- **Config file**: `.sops.yaml`
- **Key location**: `~/.config/sops/age/keys.txt`
- **Secrets directory**: `secrets/`

### Usage

**Encrypt a file:**
```bash
sops -e secrets/prod.yaml > secrets/prod.enc.yaml
```

**Decrypt a file:**
```bash
sops -d secrets/prod.enc.yaml
```

**Edit encrypted file:**
```bash
sops secrets/prod.enc.yaml
```

### Security Notes

- Never commit unencrypted secrets
- Share the public key, never the private key
- Backup the private key securely
```

---

### Pipelines

#### Purpose
Define and document project pipelines for common operations.

#### Standard Pipelines
| Pipeline   | Description              | Common Commands          |
|------------|--------------------------|--------------------------|
| **local**  | Local development        | install, dev, test, lint |
| **ci**     | Continuous integration   | lint, test, build        |
| **deploy** | Deployment               | build, deploy, verify    |

#### Setup Flow

**Step 1: Detect Existing Pipelines**

```bash
# Check for Makefile
ls Makefile 2>/dev/null && cat Makefile | grep -E "^[a-z].*:" | head -10

# Check for justfile
ls justfile 2>/dev/null && just --list 2>/dev/null

# Check for npm scripts
cat package.json 2>/dev/null | grep -A 20 '"scripts"'

# Check for GitHub Actions
ls .github/workflows/*.yml 2>/dev/null
```

**Step 2: Define Pipelines**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which pipelines would you like to define?",
    header: "Pipelines",
    options: [
      { label: "local", description: "Local development commands (install, dev, test)" },
      { label: "ci", description: "CI pipeline (lint, test, build)" },
      { label: "deploy", description: "Deployment pipeline (build, deploy, verify)" },
      { label: "release", description: "Release pipeline (version, changelog, publish)" }
    ],
    multiSelect: true
  }]
})
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Pipelines

### local

Local development workflow:

| Step | Command | Description |
|------|---------|-------------|
| install | `npm install` | Install dependencies |
| dev | `npm run dev` | Start dev server |
| test | `npm test` | Run tests |
| lint | `npm run lint` | Check code style |

### ci

Continuous integration pipeline:

| Step | Command | Description |
|------|---------|-------------|
| lint | `npm run lint` | Check code style |
| test | `npm test -- --coverage` | Run tests with coverage |
| build | `npm run build` | Build for production |

### deploy

Deployment pipeline:

| Step | Command | Description |
|------|---------|-------------|
| build | `npm run build` | Build for production |
| deploy | `npm run deploy` | Deploy to environment |
| verify | `npm run smoke-test` | Run smoke tests |
```

---

### Environments (Deploy Environments)

#### Purpose
Manage configuration and behavior across dev/staging/prod environments.

#### Standard Environments
| Environment     | Purpose                | URL Pattern         |
|-----------------|------------------------|---------------------|
| **development** | Local development      | localhost:3000      |
| **staging**     | Pre-production testing | staging.example.com |
| **production**  | Live application       | example.com         |

#### Setup Flow

**Step 1: Define Environments**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which environments does your project have?",
    header: "Environments",
    options: [
      { label: "development", description: "Local development environment" },
      { label: "staging", description: "Pre-production testing environment" },
      { label: "production", description: "Live production environment" },
      { label: "preview", description: "PR preview environments" }
    ],
    multiSelect: true
  }]
})
```

**Step 2: Create Environment Files**

```bash
# Create environment-specific .env files
touch .env.development .env.staging .env.production

# Add to .gitignore (keep .env files gitignored)
echo ".env.*" >> .gitignore
echo "!.env.example" >> .gitignore
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Environments

| Environment | Purpose | Config File | URL |
|-------------|---------|-------------|-----|
| development | Local development | `.env.development` | http://localhost:3000 |
| staging | Pre-production | `.env.staging` | https://staging.example.com |
| production | Live application | `.env.production` | https://example.com |

### Environment-Specific Variables

| Variable | development | staging | production |
|----------|-------------|---------|------------|
| `API_URL` | localhost:4000 | api-staging.example.com | api.example.com |
| `LOG_LEVEL` | debug | info | warn |
| `ENABLE_DEBUG` | true | true | false |

### Switching Environments

```bash
# Load specific environment
cp .env.development .env
npm run dev

# Or use direnv with .envrc per directory
```
```

---

### Task Management

#### Purpose
Track and manage work items, bugs, and features.

#### Popular Options
| Tool              | Integration     | Description               | Best For          |
|-------------------|-----------------|---------------------------|-------------------|
| **Jira**          | MCP (Official)  | Enterprise issue tracking | Large teams       |
| **Linear**        | MCP (Official)  | Modern issue tracking     | Fast-moving teams |
| **Trello**        | MCP (Community) | Visual kanban boards      | Simple workflows  |
| **GitHub Issues** | MCP             | GitHub-native issues      | Open source       |

#### Setup Flow

**Step 1: Select Tool**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which task management tool do you use?",
    header: "Tasks",
    options: [
      { label: "Jira", description: "Enterprise issue tracking with workflows" },
      { label: "Linear", description: "Modern, fast issue tracking" },
      { label: "Trello", description: "Visual kanban boards" },
      { label: "GitHub Issues", description: "GitHub-native issue tracking" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Configure MCP (Jira example)**

```json
{
  "mcpServers": {
    "jira": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/jira/sse"]
    }
  }
}
```

**Step 3: Test Connection**

After Claude Code reload, test by listing projects or issues.

**Step 4: Document**

Add to CLAUDE.md:

```markdown
## Task Management

**Backend**: Jira
**Integration**: MCP (Official)

### Configuration

- **Project**: PROJ
- **Board**: Main Development Board
- **Workflow**: To Do → In Progress → Review → Done

### Available Operations

- Create issues
- Update issue status
- Add comments
- Link issues
- Search with JQL

### Usage Examples

"Create a bug ticket for the login issue"
"Move PROJ-123 to In Progress"
"What are my assigned tickets?"
```

---

### Agents & Orchestration

#### Purpose
Configure Claude Code agents for specialized tasks.

#### Agent Types
| Agent           | Purpose                   | Trigger            |
|-----------------|---------------------------|--------------------|
| **code-review** | Review PRs and code changes| On PR creation     |
| **test-runner** | Run and analyze tests     | After code changes |
| **deploy**      | Handle deployments        | On release         |
| **monitor**     | Monitor for issues        | Continuous         |

#### Setup Flow

**Step 1: Select Agent Types**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which agent types would you like to configure?",
    header: "Agents",
    options: [
      { label: "code-review", description: "Automated code review on PRs" },
      { label: "test-runner", description: "Run tests after code changes" },
      { label: "deploy", description: "Handle deployment workflows" },
      { label: "monitor", description: "Monitor for issues and alerts" }
    ],
    multiSelect: true
  }]
})
```

**Step 2: Document**

Add to CLAUDE.md:

```markdown
## Agents

### Configured Agents

| Agent | Purpose | Trigger | Status |
|-------|---------|---------|--------|
| code-review | Review code changes | PR creation | Active |
| test-runner | Run test suite | Code push | Active |

### Agent Configuration

Agents are configured via Claude Code hooks and workflows.

### code-review Agent

- **Trigger**: New PR opened
- **Actions**:
  - Check code style
  - Review for issues
  - Suggest improvements
- **Output**: PR comment with review

### test-runner Agent

- **Trigger**: Code pushed to branch
- **Actions**:
  - Run test suite
  - Report coverage
  - Flag failures
- **Output**: Test results summary
```

---

### Memory Management

#### Purpose
Persist AI context and learnings across sessions.

#### Popular Options
| Tool           | Integration    | Description           | Best For          |
|----------------|----------------|-----------------------|-------------------|
| **Memory MCP** | MCP (Official) | Simple key-value memory| Basic persistence |
| **Pinecone**   | API            | Vector database       | Semantic search   |
| **Chroma**     | Local          | Embedded vector DB    | Local development |

#### Setup Flow

**Step 1: Select Backend**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which memory backend would you like to use?",
    header: "Memory",
    options: [
      { label: "Memory MCP (Recommended)", description: "Simple built-in memory storage" },
      { label: "Pinecone", description: "Cloud vector database for semantic search" },
      { label: "Chroma", description: "Local embedded vector database" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Configure (Memory MCP example)**

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    }
  }
}
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Memory

**Backend**: Memory MCP

### Configuration

The Memory MCP provides persistent storage for AI context.

### Available Operations

- `store_memory` - Save information
- `retrieve_memory` - Get stored information
- `list_memories` - List all stored items
- `delete_memory` - Remove stored item

### Usage

Memories are automatically used to maintain context across sessions.
```

---

### User Communication Bot

#### Purpose
Enable Claude to communicate via Slack or Discord.

#### Popular Options
| Platform    | Integration     | Description             |
|-------------|-----------------|-------------------------|
| **Slack**   | MCP (Official)  | Team communication      |
| **Discord** | MCP (Community) | Community communication |

#### Setup Flow

**Step 1: Select Platform**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which communication platform would you like to integrate?",
    header: "Platform",
    options: [
      { label: "Slack (Recommended)", description: "Team communication with channels and DMs" },
      { label: "Discord", description: "Community communication with servers and channels" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Configure (Slack example)**

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "<your-bot-token>",
        "SLACK_TEAM_ID": "<your-team-id>"
      }
    }
  }
}
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Communication

**Platform**: Slack
**Integration**: MCP

### Configuration

- **Bot Name**: Claude Assistant
- **Channels**: #dev, #alerts

### Available Operations

- Send messages to channels
- Send direct messages
- Read channel history
- React to messages

### Usage Examples

"Post a message to #dev about the deployment"
"DM @user about the code review"
```

---

### CI/CD

#### Purpose
Automate testing, building, and deployment.

#### Popular Options
| Platform           | Description          | Best For          |
|--------------------|----------------------|-------------------|
| **GitHub Actions** | GitHub-native CI/CD  | GitHub repos      |
| **GitLab CI**      | GitLab-native CI/CD  | GitLab repos      |
| **CircleCI**       | Cloud CI/CD platform | Complex pipelines |
| **Jenkins**        | Self-hosted CI/CD    | Enterprise, on-prem|

#### Setup Flow

**Step 1: Detect Existing CI**

```bash
ls .github/workflows/*.yml 2>/dev/null && echo "GitHub Actions detected"
ls .gitlab-ci.yml 2>/dev/null && echo "GitLab CI detected"
ls .circleci/config.yml 2>/dev/null && echo "CircleCI detected"
ls Jenkinsfile 2>/dev/null && echo "Jenkins detected"
```

**Step 2: Document**

Add to CLAUDE.md:

```markdown
## CI/CD

**Platform**: GitHub Actions

### Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push, PR | Run tests and linting |
| `deploy.yml` | Release | Deploy to production |
| `preview.yml` | PR | Deploy preview environment |

### Pipeline Steps

**CI Pipeline** (`.github/workflows/ci.yml`):
1. Checkout code
2. Setup Node.js
3. Install dependencies
4. Run linting
5. Run tests
6. Build

**Deploy Pipeline** (`.github/workflows/deploy.yml`):
1. Checkout code
2. Build application
3. Deploy to environment
4. Run smoke tests
```

---

### Observability

#### Purpose
Monitor application health with metrics, logs, and traces.

#### Popular Options
| Platform       | Description              | Best For        |
|----------------|--------------------------|-----------------|
| **Datadog**    | Full-stack observability | Enterprise      |
| **Grafana**    | Open-source dashboards   | Self-hosted     |
| **Prometheus** | Metrics collection       | Kubernetes      |
| **Honeycomb**  | Distributed tracing      | Complex systems |

#### Setup Flow

**Step 1: Select Platform**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which observability platform do you use?",
    header: "Observability",
    options: [
      { label: "Datadog", description: "Full-stack observability with APM" },
      { label: "Grafana + Prometheus", description: "Open-source metrics and dashboards" },
      { label: "Honeycomb", description: "Distributed tracing and debugging" },
      { label: "None yet", description: "Set up basic logging" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Document**

Add to CLAUDE.md:

```markdown
## Observability

**Platform**: Datadog

### Configuration

- **Dashboard**: https://app.datadoghq.com/dashboard/xxx
- **APM Service**: my-service
- **Log Index**: main

### Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `request.latency` | API latency | > 500ms |
| `error.rate` | Error percentage | > 1% |
| `cpu.usage` | CPU utilization | > 80% |

### Alerts

- **High latency** - P50 > 500ms for 5 minutes
- **Error spike** - Error rate > 1% for 2 minutes
- **Service down** - No heartbeat for 1 minute
```

---

### Problem Remediation

#### Purpose
Automate runbook execution and self-healing.

#### Components
| Component        | Purpose                |
|------------------|------------------------|
| **Runbooks**     | Documented procedures  |
| **Automation**   | Executable remediation |
| **Verification** | Post-fix validation    |

#### Setup Flow

**Step 1: Create Runbooks Directory**

```bash
mkdir -p runbooks
```

**Step 2: Create Template Runbook**

```bash
cat > runbooks/template.md << 'EOF'
# Runbook: [Issue Name]

## Symptoms
- [What the user/system observes]

## Diagnosis
1. [Step to identify root cause]
2. [Additional diagnostic steps]

## Resolution
1. [Step to fix the issue]
2. [Additional fix steps]

## Verification
1. [How to confirm the fix worked]

## Prevention
- [How to prevent recurrence]
EOF
```

**Step 3: Document**

Add to CLAUDE.md:

```markdown
## Problem Remediation

**Runbooks Location**: `runbooks/`

### Available Runbooks

| Runbook | Issue | Auto-remediate |
|---------|-------|----------------|
| `high-memory.md` | Memory usage > 90% | Yes |
| `connection-pool.md` | DB connection exhaustion | Yes |
| `disk-full.md` | Disk space < 10% | No |

### Automation

Runbooks marked as auto-remediate can be executed automatically:

```bash
./scripts/remediate.sh <runbook-name>
```

### Creating New Runbooks

1. Copy `runbooks/template.md`
2. Fill in all sections
3. Add to this table
4. Test the remediation steps
```

---

### Documentation

#### Purpose
Generate and publish project documentation.

#### Popular Options
| Platform       | Description       | Best For           |
|----------------|-------------------|--------------------|
| **Docusaurus** | React-based docs  | Modern docs sites  |
| **MkDocs**     | Python-based docs | Simple docs        |
| **GitBook**    | Cloud-hosted docs | Team collaboration |
| **Mintlify**   | API documentation | Developer APIs     |

#### Setup Flow

**Step 1: Select Platform**

```typescript
AskUserQuestion({
  questions: [{
    question: "Which documentation platform would you like to use?",
    header: "Docs",
    options: [
      { label: "Docusaurus (Recommended)", description: "Modern React-based documentation" },
      { label: "MkDocs", description: "Simple Python-based documentation" },
      { label: "GitBook", description: "Cloud-hosted team documentation" },
      { label: "README only", description: "Just maintain README.md" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Document**

Add to CLAUDE.md:

```markdown
## Documentation

**Platform**: Docusaurus
**URL**: https://docs.example.com

### Structure

```
docs/
  intro.md
  getting-started/
    installation.md
    configuration.md
  guides/
    deployment.md
  api/
    reference.md
```

### Commands

- `npm run docs:dev` - Start docs dev server
- `npm run docs:build` - Build docs
- `npm run docs:deploy` - Deploy docs

### Writing Docs

1. Create/edit markdown files in `docs/`
2. Update `sidebars.js` for navigation
3. Preview with `npm run docs:dev`
4. Deploy with `npm run docs:deploy`
```

---

### Localization

#### Purpose
Support multiple languages in the application.

#### Popular Options
| Platform     | Description                  | Best For             |
|--------------|------------------------------|----------------------|
| **Lokalise** | Cloud translation management | Teams with translators|
| **Crowdin**  | Community translation        | Open source          |
| **i18next**  | JS i18n framework            | Frontend apps        |
| **Phrase**   | Enterprise TMS               | Large scale          |

#### Setup Flow

**Step 1: Select Approach**

```typescript
AskUserQuestion({
  questions: [{
    question: "How would you like to handle localization?",
    header: "i18n",
    options: [
      { label: "i18next (Recommended)", description: "JavaScript i18n framework" },
      { label: "Lokalise + i18next", description: "i18next with cloud translation management" },
      { label: "Crowdin", description: "Community-powered translation" },
      { label: "Manual JSON files", description: "Simple JSON translation files" }
    ],
    multiSelect: false
  }]
})
```

**Step 2: Document**

Add to CLAUDE.md:

```markdown
## Localization

**Framework**: i18next
**Management**: Lokalise

### Supported Languages

| Language | Code | Status |
|----------|------|--------|
| English | `en` | Complete (default) |
| Spanish | `es` | 95% |
| French | `fr` | 90% |
| German | `de` | 85% |

### File Structure

```
locales/
  en/
    common.json
    errors.json
  es/
    common.json
    errors.json
```

### Adding Translations

1. Add key to `locales/en/common.json`
2. Push to Lokalise: `npm run i18n:push`
3. Translators complete translations
4. Pull updates: `npm run i18n:pull`

### Usage

```typescript
import { useTranslation } from 'react-i18next';

const { t } = useTranslation();
return <h1>{t('welcome.title')}</h1>;
```
```

---

## Error Handling

### Common Issues

| Issue                           | Cause              | Solution                               |
|---------------------------------|--------------------|----------------------------------------|
| CLAUDE.md not found             | New project        | Create CLAUDE.md with initial structure|
| .mcp.json parse error           | Invalid JSON       | Validate and fix JSON syntax           |
| MCP not loading                 | Config error       | Check .mcp.json, restart Claude Code   |
| Domain detection false positive | Partial config     | Verify actual configuration            |
| Domain detection false negative | Non-standard setup | Add manual CLAUDE.md section           |

### Recovery Actions

**If CLAUDE.md doesn't exist:**

```bash
cat > CLAUDE.md << 'EOF'
# Project Configuration

This file documents the project setup for Claude Code.

<!-- Domain sections are added as they are configured via /setup-project -->
EOF
```

**If a domain section is missing:**

Use the domain template to generate the section:
```bash
# Read template for the domain
cat plugins/crunch/skills/setup-project/templates/{domain-key}.template.md

# Replace placeholders with values and append to CLAUDE.md
```

**If .mcp.json is invalid:**
```bash
# Validate JSON
cat .mcp.json | python -m json.tool
```

**If domain detection is incorrect:**
Manually add or update the appropriate section in CLAUDE.md.

---

## Interactive Checkpoints

### Phase 0 Checkpoints
- [ ] CLAUDE.md read (or created)
- [ ] .mcp.json read (if exists)
- [ ] All domains scanned

### Phase 1 Checkpoints
- [ ] Dashboard displayed
- [ ] User reviews status

### Phase 2 Checkpoints
- [ ] "What would you like to do?"

### Phase 3 Checkpoints
- [ ] Domain selected

### Phase 4 Checkpoints
- [ ] Domain explanation shown
- [ ] Vendor/tool selected
- [ ] Configuration completed
- [ ] Verification passed
- [ ] CLAUDE.md updated

### Post-Setup
- [ ] Return to dashboard
- [ ] Show updated status

---

## Related Skills

- `/setup-project-domain` - Meta-skill for creating domain setup skills
- `/setup-mcp` - Generic MCP setup wizard
- `/secrets` - Manage secrets in configured backend
- `/task-management` - Manage tasks in configured backend
