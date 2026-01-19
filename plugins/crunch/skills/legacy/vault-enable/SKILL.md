---
name: vault-enable
description: Interactive setup wizard for HashiCorp Vault integration. Guides user through enabling Vault, configuring authentication, and verifying access by reading/writing a test secret.
---

# Enable HashiCorp Vault

This skill guides users through the complete end-to-end process of setting up HashiCorp Vault for secrets management in their project.

## Definition of Done

The setup is complete when:

1. Vault is accessible (either local or remote)
2. Authentication is configured
3. User successfully writes and reads back a test secret via Vault

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                   | Use When                             |
| ---------------- | --------------------------------------------- | ------------------------------------ |
| **Full Setup**   | Install Vault + run local dev server          | Starting fresh, local development    |
| **Connect Only** | Configure client to connect to existing Vault | Production Vault, shared team server |

## Progress Tracking

Since Vault setup may require session restarts (e.g., after environment changes), progress is tracked in a file.

### Progress File: `vault-setup-progress.md`

Location: Project root (`./vault-setup-progress.md`)

**Format:**

```markdown
# Vault Setup Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 4A - Configure Project
- **Setup Mode**: Full Setup (Path A)

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [x] Phase 2A: Install Vault
- [x] Phase 3A: Start Dev Server
- [ ] Phase 4A: Configure Project ← CURRENT
- [ ] Phase 5: Connection Test
- [ ] Phase 6: Completion

## Collected Information

- **Setup Mode**: Full Setup (Local Dev Server)
- **Vault Address**: http://127.0.0.1:8200
- **Auth Method**: Root Token
- **Config Location**: .env

## Notes

- Dev server started, root token collected
- Resume from Phase 5 after environment reload if needed
```

### Progress Tracking Rules

1. **Create progress file** at the start of Phase 1
2. **Update after each phase** completion
3. **Store collected information** (non-sensitive) for resumption
4. **Delete progress file** only after successful DOD verification
5. **On session start**, check for existing progress file and resume

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: Check for Existing Installation & Progress

**ALWAYS start here.** Before anything else:

#### Step 1: Check for Existing Vault Configuration

First, detect if Vault is already set up in this project:

```bash
# Check CLAUDE.md for Vault configuration
grep -A 5 "### HashiCorp Vault" CLAUDE.md 2>/dev/null

# Check for environment variables
echo "VAULT_ADDR: $VAULT_ADDR"
echo "VAULT_TOKEN: ${VAULT_TOKEN:+set}"

# Check .env file
grep "^VAULT_" .env 2>/dev/null

# Check if Vault is accessible
vault status 2>/dev/null
```

**If Vault is already configured and accessible:**

Display status and offer options:

```
Vault is already configured in this project!

Current Configuration:
  Address: http://127.0.0.1:8200
  Status: Connected (unsealed)
  Auth: Token authentication
  Documented in: CLAUDE.md

What would you like to do?
1. Keep current setup (exit - you can use /vault-use for secrets operations)
2. Reconfigure (update CLAUDE.md and .env settings)
3. Start fresh (run /vault-disable first, then set up again)
```

- Option 1 → Exit setup mode, suggest using vault-use skill for secrets
- Option 2 → Skip to Phase 4A/3B (Configure Project) with existing values
- Option 3 → Suggest running vault-uninstall first, then re-running setup

**If Vault is partially configured (some components missing):**

```
Vault is partially configured:

Found:
  ✓ VAULT_ADDR in .env
  ✗ VAULT_TOKEN not set
  ✗ Cannot connect to Vault server

Would you like to:
1. Fix the current setup (resume from connection configuration)
2. Start fresh (clear existing config and begin setup)
```

- Option 1 → Resume from the appropriate phase based on what's missing
- Option 2 → Clear existing config and start from Phase 1

#### Step 2: Check for Progress File

1. **Check for progress file**

   ```bash
   cat vault-setup-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing Vault setup in progress!

     Current Phase: Phase 4A - Configure Project
     Setup Mode: Full Setup (Local Dev Server)
     Vault Address: http://127.0.0.1:8200

     Would you like to:
     1. Resume from where you left off
     2. Start over (will delete progress)
     ```

   - If resuming, skip to the indicated phase with collected information
   - If starting over, delete progress file and begin Phase 1

3. **If no progress file and no existing configuration:**
   - Proceed to Phase 1

### Phase 1: Prerequisites & Mode Selection

First, determine what kind of setup the user needs:

1. **Check for existing Vault configuration**
   - Check for `VAULT_ADDR` environment variable
   - Look for `~/.vault-token` file
   - Check for `.vault` config files in project

2. **Ask the user about setup mode**:

   "How would you like to set up Vault?"

   **Option A: Full Setup (Local Dev Server)**
   - "I need to install Vault and run it locally for development"
   - Requires: Ability to install software (brew/apt/binary)
   - Result: Local Vault dev server running, root token available

   **Option B: Connect to Existing Vault Server**
   - "There's already a Vault server I need to connect to"
   - Requires: Vault address, authentication credentials
   - Result: CLI/SDK configured to use remote Vault

   **Option C: Not Sure**
   - Help user determine which option fits their situation
   - Ask: "Is there an ops/infrastructure team managing Vault for you?"
   - Ask: "Do you have a Vault address (URL) and credentials?"

3. **Based on selection, proceed to appropriate phase:**
   - Option A → Continue to Phase 2A (Full Setup)
   - Option B → Skip to Phase 2B (Connect Only)

4. **Create progress file**
   Create `vault-setup-progress.md` with initial status:

   ```markdown
   # Vault Setup Progress

   ## Status

   - **Started**: [timestamp]
   - **Current Phase**: Phase 2A/2B
   - **Setup Mode**: [Full Setup / Connect Only]

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [ ] Phase 2: [Install Vault / Gather Connection Details]
   - [ ] Phase 3: [Start Dev Server / Configure Client]
   - [ ] Phase 4: Configure Project
   - [ ] Phase 5: Connection Test
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: [selected mode]
   ```

---

## Path A: Full Setup (Local Dev Server)

### Phase 2A: Install Vault

1. **Check if Vault is already installed**

   ```bash
   vault version
   ```

   If installed, skip to Phase 3A.

2. **Install Vault based on OS**

   **macOS (Homebrew):**

   ```bash
   brew tap hashicorp/tap
   brew install hashicorp/tap/vault
   ```

   **Ubuntu/Debian:**

   ```bash
   wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update && sudo apt install vault
   ```

   **Binary download:**
   - Direct user to https://releases.hashicorp.com/vault/
   - Download appropriate binary for their OS/arch
   - Extract and add to PATH

3. **Verify installation**
   ```bash
   vault version
   ```

### Phase 3A: Start Dev Server

1. **Explain dev server mode**
   - Dev server is for local development only
   - Data is stored in-memory (lost on restart)
   - Automatically unsealed and root token provided
   - NOT for production use

2. **Start the dev server**

   ```bash
   vault server -dev
   ```

   This outputs:
   - Root Token (save this!)
   - Unseal Key (not needed in dev mode)
   - API Address (usually http://127.0.0.1:8200)

3. **Ask user to provide from the output:**
   - Root Token
   - Vault Address (default: http://127.0.0.1:8200)

4. **Configure environment**
   ```bash
   export VAULT_ADDR='http://127.0.0.1:8200'
   export VAULT_TOKEN='<root-token>'
   ```

### Phase 4A: Configure Project

1. **Ask about configuration approach**
   - Environment variables only (recommended for dev)
   - `.env` file (gitignored)
   - Shell profile (`~/.bashrc`, `~/.zshrc`)

2. **Write configuration based on choice**

   **Option: .env file**

   ```
   VAULT_ADDR=http://127.0.0.1:8200
   VAULT_TOKEN=<root-token>
   ```

   **Option: Shell profile**

   ```bash
   export VAULT_ADDR='http://127.0.0.1:8200'
   export VAULT_TOKEN='<root-token>'
   ```

3. **Verify .gitignore**
   - Ensure `.env` is in `.gitignore`
   - NEVER commit Vault tokens

→ Proceed to Phase 5: Connection Test

---

## Path B: Connect to Existing Vault Server

### Phase 2B: Gather Connection Details

Ask the user for existing Vault server information:

1. **Vault address**
   - Ask: "What is the Vault server address?"
   - Example: `https://vault.company.internal:8200`

2. **Authentication method** - Ask: "How do you authenticate with Vault?"

   **Option 1: Token Authentication**
   - User provides a Vault token directly
   - Simplest method, common for CI/CD

   ```bash
   export VAULT_TOKEN='s.xxxxxxxxxxxxxxxx'
   ```

   **Option 2: AppRole Authentication**
   - For applications/automation
   - Requires Role ID and Secret ID

   ```bash
   vault write auth/approle/login \
     role_id="<role-id>" \
     secret_id="<secret-id>"
   ```

   **Option 3: LDAP/OIDC/GitHub Authentication**
   - Enterprise SSO methods
   - User authenticates with their identity

   ```bash
   vault login -method=ldap username=<user>
   vault login -method=oidc
   vault login -method=github token=<github-token>
   ```

   **Option 4: Kubernetes Authentication**
   - For pods running in Kubernetes
   - Uses service account token

   ```bash
   vault write auth/kubernetes/login \
     role="<role>" \
     jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
   ```

3. **Collect credentials based on auth method:**
   - Token: The token value
   - AppRole: Role ID and Secret ID
   - LDAP: Username (password prompted)
   - OIDC: Just initiate login flow
   - GitHub: Personal access token
   - Kubernetes: Role name

4. **TLS configuration (if HTTPS):**
   - "Does the server use a custom CA certificate?"
   - If yes, get path to CA cert file
   ```bash
   export VAULT_CACERT='/path/to/ca.crt'
   ```

### Phase 3B: Configure Client Connection

1. **Set Vault address**

   ```bash
   export VAULT_ADDR='https://vault.company.internal:8200'
   ```

2. **Authenticate based on method chosen**

3. **Ask about configuration persistence**
   - Environment variables only
   - `.env` file (gitignored)
   - Shell profile

4. **Write configuration**

   **Example .env file:**

   ```
   VAULT_ADDR=https://vault.company.internal:8200
   VAULT_TOKEN=s.xxxxxxxxxxxxxxxx
   # Or for AppRole:
   # VAULT_ROLE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   # VAULT_SECRET_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

5. **Verify .gitignore**
   - Ensure credentials are not committed

→ Proceed to Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths):

1. **Inform user about testing**
   "I'll now verify Vault access by writing and reading a test secret."

2. **Check Vault status**

   ```bash
   vault status
   ```

   - Verify Vault is reachable
   - Check seal status (should be unsealed)

3. **Write test secret**

   ```bash
   vault kv put secret/claude-test \
     message="Vault setup successful" \
     timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```

   Note: Path may vary based on secrets engine configuration:
   - KV v2: `secret/data/claude-test`
   - KV v1: `secret/claude-test`
   - Ask user for correct path if default fails

4. **Read test secret back**

   ```bash
   vault kv get secret/claude-test
   ```

5. **Confirm with user**
   "I was able to write and read a test secret. Did the operation complete successfully?"

### Phase 6: Completion

Once test is confirmed:

1. **Document in CLAUDE.md**
   - Check if `CLAUDE.md` exists in project root
   - If not, create it with basic project structure
   - Add or update the "Secrets Management" section:

   ```markdown
   ## Secrets Management

   ### HashiCorp Vault

   - **Status**: Configured
   - **Setup mode**: [Local Dev Server / Remote Server]
   - **Address**: [VAULT_ADDR value]
   - **Auth method**: [Token / AppRole / LDAP / OIDC / Kubernetes]
   - **Config location**: [.env / environment variables / shell profile]
   - **Usage**:
     - Read: `vault kv get secret/<path>`
     - Write: `vault kv put secret/<path> key=value`
   - **Security**: Tokens stored in `.env` (gitignored) or environment variables
   ```

   - If CLAUDE.md already has secrets section, append Vault configuration
   - Preserve existing content in the file

2. **Document installed MCP servers in CLAUDE.md**

   Check for MCP configuration files and document all installed servers:

   ```bash
   # Check for MCP configuration
   cat .mcp.json 2>/dev/null
   cat .claude/mcp.json 2>/dev/null
   ```

   For each MCP server found, add to CLAUDE.md under `## MCP Servers`:

   ```markdown
   ## MCP Servers

   ### [Server Name]

   - **Status**: Configured
   - **Package**: [npm package or command]
   - **GitHub**: [repository URL]
   - **Purpose**: [brief description]
   ```

   **Known MCP Server GitHub Repositories:**

   | Server                                      | GitHub Repository                               |
   | ------------------------------------------- | ----------------------------------------------- |
   | `@modelcontextprotocol/server-filesystem`   | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-github`       | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-gitlab`       | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-google-drive` | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-postgres`     | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-sqlite`       | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-slack`        | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-memory`       | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-puppeteer`    | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-brave-search` | https://github.com/modelcontextprotocol/servers |
   | `@modelcontextprotocol/server-fetch`        | https://github.com/modelcontextprotocol/servers |
   | `@21st-dev/magic-mcp`                       | https://github.com/21st-dev/magic-mcp           |
   | `@anthropic/claude-code-mcp`                | https://github.com/anthropics/claude-code       |
   | `mcp-server-kubernetes`                     | https://github.com/strowk/mcp-k8s-go            |
   | `@trello/mcp-server`                        | https://github.com/trello/mcp-server            |

   **Parsing MCP configuration:**

   ```bash
   # Extract server names from .mcp.json
   cat .mcp.json | jq -r '.mcpServers | keys[]' 2>/dev/null
   ```

   For each server, extract:
   - Server name (key in mcpServers)
   - Command/package (from `command` or `args` fields)
   - Match to known GitHub repositories

3. **Summarize what was configured**
   - Vault address
   - Authentication method
   - Configuration location (env vars, .env, etc.)

4. **Provide next steps**
   - Common Vault CLI commands:
     - `vault kv put` - Write secrets
     - `vault kv get` - Read secrets
     - `vault kv list` - List secrets
     - `vault kv delete` - Delete secrets
   - How to use Vault in applications (SDKs)
   - Link to Vault documentation

5. **Security reminders**
   - Never commit Vault tokens to git
   - Rotate tokens periodically
   - Use short-lived tokens when possible
   - For production, use AppRole or identity-based auth

6. **Cleanup suggestion**
   - "Would you like me to delete the test secret, or keep it as reference?"

   ```bash
   vault kv delete secret/claude-test
   ```

7. **Clean up progress file**
   After successful DOD verification:
   ```bash
   rm vault-setup-progress.md
   ```
   Inform user:
   ```
   ✓ Vault setup complete!
   ✓ Progress file cleaned up
   ✓ Vault configuration documented in CLAUDE.md
   ✓ MCP servers documented in CLAUDE.md (if any found)
   ```

---

## Error Handling

### Common Issues

**"connection refused" error:**
- Vault server not running
- Wrong address/port
- Firewall blocking connection

**"permission denied" error:**
- Token doesn't have access to path
- Policy doesn't allow operation
- Token expired

**"seal status: sealed" error:**
- Vault needs to be unsealed
- In production, requires unseal keys
- Dev server should auto-unseal

**"x509: certificate signed by unknown authority":**
- Custom CA certificate needed
- Set `VAULT_CACERT` environment variable
- Or use `VAULT_SKIP_VERIFY=true` (not recommended)

**"token not found" or "missing client token":**
- `VAULT_TOKEN` not set
- Token file `~/.vault-token` not present
- Need to authenticate first

**KV v1 vs v2 path issues:**
- KV v2 requires `/data/` in path for API
- CLI handles this automatically with `kv` commands
- Check secrets engine version: `vault secrets list`

## Interactive Checkpoints

### Mode Selection
- [ ] "Which setup mode do you need: Full Setup (local dev) or Connect Only (existing server)?"

### Path A (Full Setup)
- [ ] "Vault installed. Ready to start dev server?"
- [ ] "Dev server running. I see the root token. Ready to configure?"
- [ ] "Configuration saved. Ready to test?"

### Path B (Connect Only)
- [ ] "What is the Vault server address?"
- [ ] "Which authentication method do you use?"
- [ ] "I have the credentials. Ready to configure?"
- [ ] "Configuration saved. Ready to test?"

### Final Verification (Both Paths)
- [ ] "Test secret written and read successfully. Setup complete?"
- [ ] "Would you like me to delete the test secret?"
