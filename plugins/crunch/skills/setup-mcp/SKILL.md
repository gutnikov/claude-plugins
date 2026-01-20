---
name: setup-mcp
description: Generic MCP setup wizard. Dynamically fetches MCP documentation, extracts configuration requirements, and guides through setup with DOD at every phase.
---

# Setup MCP Server

This skill guides users through the complete end-to-end process of setting up **any** MCP server by dynamically fetching documentation, extracting configuration requirements, and guiding through setup with Definition of Done (DOD) at every phase.

## Key Differentiator

Unlike specific MCP setup skills (vault-enable, slack-enable, trello-enable) which have hardcoded configuration knowledge, this skill is **dynamic** - it fetches and parses MCP documentation at runtime.

## Dependencies

This skill depends on `track-setup-progress` for state management across sessions:

```yaml
dependencies:
  - skill: track-setup-progress
    operations_used:
      - resume      # Check for existing progress, handle user decision
      - create      # Create new progress file
      - update      # Update phase status and collected data
      - complete    # Mark complete and cleanup
```

## Definition of Done

The setup is complete when:

1. MCP server is configured (either local npx or connection to existing)
2. Authentication/credentials are configured (as required by the MCP)
3. User successfully executes a test operation via the MCP

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                 | Use When                             |
|------------------|---------------------------------------------|--------------------------------------|
| **Full Setup**   | Install dependencies + run local MCP server | Starting fresh, local development    |
| **Connect Only** | Configure client to connect to existing MCP | MCP server already running elsewhere |

## Progress Tracking

**This skill uses `track-setup-progress` for all progress management.**

Progress file: `mcp-setup-progress.md` (managed by track-setup-progress)

### Phase Definitions

```yaml
phases:
  - key: 0
    name: "Check Existing"
  - key: 1
    name: "MCP Discovery"
  - key: 2
    name: "Prerequisites"
  - key: 3
    name: "Credentials Collection"
  - key: 4
    name: "MCP Configuration"
  - key: 5
    name: "Connection Test"
  - key: 6
    name: "Completion"
```

Since MCP setup requires reloading Claude Code (which loses session context), progress tracking is critical for resuming after reload

---

## Known MCP Registry

The following popular MCPs have pre-defined configurations for faster setup:

| Name           | Package                                     | Required Env Vars                                                          | Test Operation  |
|----------------|---------------------------------------------|----------------------------------------------------------------------------|-----------------|
| `slack`        | `@modelcontextprotocol/server-slack`        | `SLACK_BOT_TOKEN`, `SLACK_TEAM_ID`                                         | `list_channels` |
| `github`       | `@modelcontextprotocol/server-github`       | `GITHUB_PERSONAL_ACCESS_TOKEN`                                             | `list_repos`    |
| `filesystem`   | `@modelcontextprotocol/server-filesystem`   | (uses `args` for allowed_directories)                                      | `list_directory` |
| `postgres`     | `@modelcontextprotocol/server-postgres`     | `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DATABASE` | `list_tables`   |
| `brave-search` | `@modelcontextprotocol/server-brave-search` | `BRAVE_API_KEY`                                                            | `search`        |
| `memory`       | `@modelcontextprotocol/server-memory`       | (none)                                                                     | `list_entities` |
| `sqlite`       | `@modelcontextprotocol/server-sqlite`       | `SQLITE_DB_PATH`                                                           | `list_tables`   |
| `puppeteer`    | `@modelcontextprotocol/server-puppeteer`    | (none)                                                                     | `navigate`      |
| `fetch`        | `@modelcontextprotocol/server-fetch`        | (none)                                                                     | `fetch`         |
| `gitlab`       | `@modelcontextprotocol/server-gitlab`       | `GITLAB_PERSONAL_ACCESS_TOKEN`, `GITLAB_API_URL`                           | `list_projects` |
| `google-drive` | `@modelcontextprotocol/server-google-drive` | `GOOGLE_CREDENTIALS_PATH`                                                  | `list_files`    |
| `trello`       | `@modelcontextprotocol/server-trello`       | `TRELLO_API_KEY`, `TRELLO_TOKEN`                                           | `list_boards`   |

### Credential Guide Templates

| Pattern                   | Type       | Guide Template                                         |
|---------------------------|------------|--------------------------------------------------------|
| `*_TOKEN`                 | Token      | "Go to {service} developer portal to generate a token" |
| `*_BOT_TOKEN`             | Bot Token  | "Create a {service} app and get the bot token"         |
| `*_API_KEY`               | API Key    | "Get API key from {service} developer settings"        |
| `*_PERSONAL_ACCESS_TOKEN` | PAT        | "Generate a personal access token at {service}"        |
| `*_ID`                    | Identifier | "Find the ID in {service} URL or settings"             |
| `*_HOST`                  | Hostname   | "Database server hostname or IP address"               |
| `*_USER`                  | Username   | "Database username with appropriate permissions"       |
| `*_PASSWORD`              | Password   | "Database password (will be stored securely)"          |
| `*_DATABASE`              | DB Name    | "Name of the database to connect to"                   |
| `*_PATH`                  | File Path  | "Absolute path to the file or directory"               |

---

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: Check for Existing Installation & Progress

**ALWAYS start here.** Before anything else:

#### Step 1: Ask User Which MCP to Set Up

First, determine what MCP the user wants to configure:

```
Which MCP server would you like to set up?

You can provide:
1. MCP name from popular list (e.g., "slack", "github", "filesystem")
2. npm package name (e.g., "@modelcontextprotocol/server-slack")
3. GitHub repo URL (e.g., "https://github.com/owner/repo")
4. Type "list" to see popular MCPs
```

#### Step 2: Check for Existing Configuration

Once MCP is identified, detect if it's already set up:

```bash
# Check CLAUDE.md for MCP configuration
grep -A 10 "### {MCP Name}" CLAUDE.md 2>/dev/null

# Check for MCP configuration in .mcp.json
grep -A 5 '"{mcp-key}"' .mcp.json 2>/dev/null
```

**If MCP is already configured:**

Display status and offer options:

```
{MCP Name} is already configured in this project!

Current Configuration:
  MCP Server: {package}
  Documented in: CLAUDE.md

What would you like to do?
1. Keep current setup (exit)
2. Reconfigure (update .mcp.json and CLAUDE.md settings)
3. Start fresh (remove existing config and set up again)
```

- Option 1 -> Exit setup
- Option 2 -> Skip to Phase 4 (Configure MCP) with existing values
- Option 3 -> Remove existing config and start from Phase 1

#### Step 3: Check for Progress (using track-setup-progress)

Invoke `track-setup-progress`:

```yaml
operation: resume
domain: mcp
```

**Handle response:**

| Response | Action |
|----------|--------|
| `decision: "no_progress"` | Proceed to Phase 1 |
| `decision: "resume"` | Skip to `resume_phase` with `collected_data` |
| `decision: "start_over"` | Proceed to Phase 1 |

**If resuming:**

```yaml
# Response contains:
resume_phase: 5
phase_name: "Connection Test"
collected_data:
  mcp_name: "Slack"
  mcp_package: "@modelcontextprotocol/server-slack"
  setup_mode: "full_setup"

# Use collected_data to restore state, skip to resume_phase
```

**If no progress and no existing configuration:**
- Proceed to Phase 1

---

### Phase 1: MCP Discovery and Documentation Fetch

This phase identifies the MCP and extracts configuration requirements.

#### Step 1: Identify MCP Package

Based on user input from Phase 0:

**If MCP name from known registry:**
- Use pre-defined package name and requirements
- Skip documentation fetch (requirements already known)

**If npm package name:**
- Validate package exists: `npm view {package} --json`
- Proceed to documentation fetch

**If GitHub URL:**
- Extract owner/repo from URL
- Check for package.json to find npm package name
- Proceed to documentation fetch

**If user typed "list":**
- Display the Known MCP Registry table
- Ask user to select one or provide custom

#### Step 2: Fetch Documentation

**Documentation Fetch Priority:**

1. **npm README** (most reliable):
   ```bash
   npm view {package} readme
   ```

2. **GitHub raw README** (for GitHub URLs):
   ```
   WebFetch: https://raw.githubusercontent.com/{owner}/{repo}/main/README.md
   ```

3. **Known MCP registry** (fallback for recognized MCPs)

#### Step 3: Extract Requirements

**Environment Variable Patterns to Search:**

```
# Markdown table pattern
|\s*\`?([A-Z][A-Z0-9_]+)\`?\s*\|

# Export statement pattern
export\s+([A-Z][A-Z0-9_]+)=

# JSON env config pattern
"env":\s*\{[^}]*"([A-Z][A-Z0-9_]+)"

# Code block examples
[A-Z][A-Z0-9_]+=
```

**Tool/Capability Patterns to Search:**

```
# List item with tool name
-\s+\`?(\w+)\`?:\s+(.+)

# Heading followed by tool list
##.*Tools.*\n([\s\S]*?)(?=\n##|\z)

# Function-style tools
\b(list_\w+|get_\w+|read_\w+|create_\w+|update_\w+|delete_\w+)\b
```

**Prerequisite Patterns:**

```
# Node.js version
Node\.?js?\s*(\d+)

# Other requirements
requires?\s+(.+)
```

#### Step 4: Confirm Extracted Requirements

Present extracted information to user for confirmation:

```
I've analyzed the documentation for {MCP Name}. Here's what I found:

Package: {npm-package}
Documentation: {source URL}

Required Environment Variables:
  - {VAR_1}: {description if found}
  - {VAR_2}: {description if found}

Available Tools:
  - {tool_1}: {description}
  - {tool_2}: {description}
  - ... (showing first 5)

Prerequisites:
  - Node.js {version}+
  - {other prereqs}

Does this look correct? (If not, I can try a different documentation source or you can provide details manually)
```

**DOD:** User confirms extracted requirements are correct

#### Step 5: Create Progress File

Invoke `track-setup-progress`:

```yaml
operation: create
domain: mcp
display_name: "MCP Setup"
phases:
  - key: 0
    name: "Check Existing"
  - key: 1
    name: "MCP Discovery"
  - key: 2
    name: "Prerequisites"
  - key: 3
    name: "Credentials Collection"
  - key: 4
    name: "MCP Configuration"
  - key: 5
    name: "Connection Test"
  - key: 6
    name: "Completion"
initial_phase: 2
initial_data:
  mcp_name: "{display name}"
  mcp_package: "{npm package}"
  documentation_source: "{url}"
  env_vars: "{VAR_1}, {VAR_2}, ..."
  available_tools: "{tool_1}, {tool_2}, ..."
```

#### Step 6: Mode Selection

Ask user about setup mode:

```
How would you like to set up {MCP Name}?

Option A: Full Setup (Local MCP Server)
  - Run MCP server locally via npx
  - Requires: Node.js 18+, npm
  - Best for: Local development, single-user

Option B: Connect to Existing MCP Server
  - Connect to an already running MCP server
  - Requires: Server URL and any auth details
  - Best for: Shared team servers, remote setups
```

- Option A -> Continue to Phase 2A
- Option B -> Skip to Phase 2B

---

## Path A: Full Setup (Local MCP Server)

### Phase 2A: Verify Prerequisites

1. **Verify Node.js/npm availability**

   ```bash
   node --version
   npm --version
   npx --version
   ```

   - If not installed, guide user to install Node.js 18+ first
   - Provide installation options: brew (macOS), apt (Ubuntu), direct download

2. **Check MCP-specific prerequisites**
   - If extracted prerequisites include specific versions, verify them
   - If MCP requires specific tools (e.g., Docker), check availability

3. **Update progress file**

   Invoke `track-setup-progress`:

   ```yaml
   operation: update
   domain: mcp
   complete_phase: 2
   set_phase: 3
   ```

**DOD:** All prerequisites satisfied

---

### Phase 3: Credentials Collection

Guide user through obtaining required credentials.

#### Step 1: Generate Credential Guides

For each required environment variable, generate guidance based on patterns:

**For Known MCPs:**
Use the specific credential guide from the registry.

**For Unknown MCPs:**
Generate guides from variable name patterns:

```
{VAR_NAME} Configuration

Based on the variable name, this appears to be a {type}.

{Guide template from Credential Guide Templates table}

Please provide the value for {VAR_NAME}:
```

#### Step 2: Collect Each Credential

For each required environment variable:

1. Display the credential guide
2. Ask user to provide the value
3. Basic format validation:
   - `*_TOKEN` / `*_API_KEY`: Non-empty, reasonable length
   - `*_ID`: Non-empty, check for expected prefix if known
   - `*_HOST`: Valid hostname format
   - `*_PATH`: Valid path format

#### Step 3: Secrets Backend Integration (Optional)

Check if the project has a secrets backend configured:

```bash
# Check CLAUDE.md for secrets backend
grep -A 5 "## Secrets Management" CLAUDE.md 2>/dev/null
```

**If secrets backend is configured:**

Ask user: "This project has {Vault/SOPS} configured for secrets management. Would you like to store the {MCP Name} credentials there as well?"

**Option 1: Yes, store in secrets backend (Recommended)**
- Use the `secrets` skill to store each credential:
  ```
  secrets set {mcp-name}/{var_name} <value>
  ```

**Option 2: No, only store in .mcp.json**
- Credentials will only be in the MCP configuration file

#### Step 4: Update Progress File

Invoke `track-setup-progress`:

```yaml
operation: update
domain: mcp
complete_phase: 3
set_phase: 4
add_data:
  setup_mode: "full_setup"
  credentials_location: "{location}"
```

**DOD:** All credentials collected and format-validated

---

### Phase 4: MCP Configuration

#### Step 1: Determine Configuration Location

Ask user: "Where should I add the {MCP Name} MCP configuration?"
- Project-level: `.mcp.json` in project root (recommended)
- User-level: `~/.claude/settings.json`

#### Step 2: Build Configuration

**Standard npx configuration:**

```json
{
  "mcpServers": {
    "{mcp-key}": {
      "command": "npx",
      "args": ["-y", "{npm-package}"],
      "env": {
        "{ENV_VAR_1}": "{value_1}",
        "{ENV_VAR_2}": "{value_2}"
      }
    }
  }
}
```

**For MCPs with args (like filesystem):**

```json
{
  "mcpServers": {
    "{mcp-key}": {
      "command": "npx",
      "args": ["-y", "{npm-package}", "{arg1}", "{arg2}"]
    }
  }
}
```

#### Step 3: Write Configuration

1. **If `.mcp.json` exists:**
   - Read existing content
   - Merge new MCP config into `mcpServers`
   - Preserve existing configurations

2. **If creating new file:**
   - Create complete structure

3. **NEVER commit credentials to git**

#### Step 4: Verify .gitignore

```bash
grep -q "^\.mcp\.json$" .gitignore 2>/dev/null
```

- If `.mcp.json` is not in `.gitignore`, offer to add it

#### Step 5: Update Progress File for Reload

Invoke `track-setup-progress`:

```yaml
operation: update
domain: mcp
complete_phase: 4
set_phase: 5
add_data:
  config_location: ".mcp.json"
  test_operation: "{selected test operation}"
add_note: "Waiting for Claude Code reload to activate MCP"
```

#### Step 6: Instruct User to Reload

```
MCP configuration written to .mcp.json

Claude Code needs to reload to activate the {MCP Name} MCP.

Please restart Claude Code, then run this skill again.
Progress has been saved - setup will resume from the connection test.
```

**DOD:** Config written, gitignore verified, user instructed to reload

-> After reload, resume at Phase 5: Connection Test

---

## Path B: Connect to Existing MCP Server

### Phase 2B: Gather Connection Details

Ask the user for existing server information:

#### Step 1: Connection Type

Ask: "How does the existing MCP server accept connections?"

**Option 1: HTTP/SSE (Server-Sent Events)**

```json
{
  "mcpServers": {
    "{mcp-key}": {
      "url": "http://server-address:port/sse"
    }
  }
}
```

**Option 2: WebSocket**

```json
{
  "mcpServers": {
    "{mcp-key}": {
      "url": "ws://server-address:port"
    }
  }
}
```

**Option 3: Stdio (via SSH or remote command)**

```json
{
  "mcpServers": {
    "{mcp-key}": {
      "command": "ssh",
      "args": ["user@server", "mcp-command"]
    }
  }
}
```

#### Step 2: Collect Connection Details

Based on connection type, collect:
- Server URL or hostname
- Port number
- Authentication requirements (headers, tokens)
- TLS/SSL settings if needed

#### Step 3: Proceed to Phase 4

Skip Phase 3 (credentials are embedded in connection details) and proceed to Phase 4 with the collected connection configuration.

**DOD:** Connection details collected

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths).

**Note:** If resuming from progress file, this phase runs after Claude Code reload.

#### Step 1: Verify MCP is Loaded

- Check that the MCP tools are now available
- Look for tools matching the extracted capabilities

**If tools not available:**
```
The {MCP Name} MCP doesn't appear to be loaded. Let's troubleshoot:

1. Check .mcp.json syntax - is the JSON valid?
2. Verify environment variables are correct
3. Try running the MCP manually:
   npx -y {npm-package}
```

#### Step 2: Select Test Operation

**Dynamic Test Selection Priority:**

1. Read-only operations (safest):
   - `list_*` (e.g., `list_channels`, `list_repos`, `list_tables`)
   - `get_*` (e.g., `get_user`, `get_file`)
   - `read_*` (e.g., `read_file`, `read_message`)

2. Safe operations:
   - `search_*`
   - `describe_*`
   - `status_*`

3. First available tool (if no safe options found)

**For known MCPs:**
Use the pre-defined test operation from the registry.

**For unknown MCPs:**
Select from extracted tools using priority above.

#### Step 3: Inform User About Testing

```
I'll now test the {MCP Name} MCP by running: {test_operation}

This is a read-only operation that will verify the connection and credentials are working.
```

#### Step 4: Execute Test Operation

Run the selected test operation using the MCP tools.

#### Step 5: Handle Results

**On Success:**
```
Test successful! The {test_operation} returned:
{formatted result summary}

Did this work as expected?
```

**On Failure - Troubleshoot:**

| Error Pattern        | Likely Cause             | Solution                                 |
|----------------------|--------------------------|------------------------------------------|
| `invalid_auth`       | Bad token/credentials    | Verify credentials, regenerate if needed |
| `not_authed`         | Missing authentication   | Check env vars are set correctly         |
| `permission_denied`  | Insufficient permissions | Check token scopes/permissions           |
| `not_found`          | Resource doesn't exist   | Verify resource ID/name                  |
| `connection_refused` | MCP server not running   | Check config, restart Claude Code        |
| `rate_limited`       | Too many requests        | Wait and retry                           |
| JSON syntax error    | Malformed .mcp.json      | Validate and fix JSON                    |

Offer appropriate recovery options based on error.

**DOD:** Test operation succeeds, user confirms

---

### Phase 6: Completion

Once test is confirmed successful:

#### Step 1: Document in CLAUDE.md

Check if `CLAUDE.md` exists; if not, create it. Add or update the MCP section:

```markdown
## MCP Servers

### {MCP Display Name}

- **Status**: Configured
- **Package**: {npm-package}
- **Setup mode**: {Full Setup / Connect Only}
- **Config location**: `.mcp.json`
- **Capabilities**: {list of available tools}
- **Documentation**: {docs-url}
- **Security**: Credentials stored in `.mcp.json` (gitignored)
- **Secrets backend**: {Vault / SOPS / None} - Credentials also stored at `{mcp-name}/*` if backend configured
```

#### Step 2: Summarize Configuration

```
{MCP Name} setup is complete!

Configuration Summary:
  - Package: {npm-package}
  - Config file: {.mcp.json location}
  - Setup mode: {Full Setup / Connect Only}
  - Available tools: {count} tools

Available Operations:
  {list of 5-10 most useful tools with brief descriptions}
```

#### Step 3: Provide Usage Examples

Generate usage examples based on available tools:

```
Example Usage:
  - To {action 1}: Use the {tool_1} tool
  - To {action 2}: Use the {tool_2} tool
```

#### Step 4: Security Reminders

```
Security Notes:
  - Never commit .mcp.json with credentials to git
  - Credentials can be rotated at {service portal if known}
  - Review permissions periodically
```

#### Step 5: Complete Setup

Invoke `track-setup-progress`:

```yaml
operation: complete
domain: mcp
```

**Response:**

```yaml
completed: true
file_deleted: true
duration: "8m 45s"
```

```
{MCP Name} setup complete!
Duration: {duration}
Configuration documented in CLAUDE.md
```

**DOD:** Documented, progress file removed, user informed

---

## Error Handling

### Error Table

| Error                 | Phase | Cause                    | Solution                                    |
|-----------------------|-------|--------------------------|---------------------------------------------|
| Package not found     | 1     | Invalid npm package name | Verify package name, try alternative source |
| Failed to fetch docs  | 1     | Network/URL error        | Try alternative source, manual entry        |
| Node.js not found     | 2A    | Not installed            | Guide Node.js installation                  |
| Node.js version low   | 2A    | Version < 18             | Guide Node.js upgrade                       |
| Invalid credential    | 3     | Wrong format/value       | Re-enter with format hint                   |
| JSON syntax error     | 4     | Malformed .mcp.json      | Validate and fix JSON                       |
| MCP not loading       | 5     | Config error             | Check syntax, verify env vars               |
| Test operation failed | 5     | Auth/permission error    | Verify credentials, check scopes            |
| Rate limited          | 5     | Too many requests        | Wait and retry                              |

### Common Troubleshooting

**MCP not appearing after reload:**
1. Verify `.mcp.json` is valid JSON
2. Check for syntax errors (trailing commas, missing quotes)
3. Try running MCP manually: `npx -y {package}`
4. Check Claude Code logs for errors

**"Command not found" errors:**
1. Verify Node.js is in PATH
2. Check npx is available: `which npx`
3. Try with full path to npx

**Authentication failures:**
1. Verify credential format matches expected pattern
2. Check if credentials have expired
3. Verify permissions/scopes are sufficient
4. Regenerate credentials if needed

---

## Interactive Checkpoints

### Phase 0 Checkpoints
- [ ] "Which MCP would you like to set up?"
- [ ] "Found existing setup. Keep/reconfigure/start fresh?"

### Phase 1 Checkpoints
- [ ] "I extracted these requirements from the docs. Does this look correct?"
- [ ] "Which setup mode: Full Setup or Connect Only?"

### Phase 2 Checkpoints
- [ ] "All prerequisites verified. Ready to collect credentials?"
- [ ] (Path B) "What connection type does the existing server use?"

### Phase 3 Checkpoints
- [ ] "Please provide {credential_name}"
- [ ] "Would you like to store credentials in the secrets backend?"
- [ ] "All credentials collected. Ready to configure?"

### Phase 4 Checkpoints
- [ ] "Where should I add the MCP configuration?"
- [ ] "Configuration written. Ready to restart Claude Code?"

### Phase 5 Checkpoints
- [ ] "Test successful! Did this work as expected?"

### Phase 6 Checkpoints
- [ ] "Setup complete! All documented in CLAUDE.md."

---

## Related Skills

- `/secrets` - Manage credentials in configured secrets backend
- `/vault-enable` - Specific setup for HashiCorp Vault
- `/setup-slack-bot` - Specific setup for Slack MCP
- `/setup-trello` - Specific setup for Trello MCP
