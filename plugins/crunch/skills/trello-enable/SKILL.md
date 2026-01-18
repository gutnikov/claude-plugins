---
name: trello-enable
description: Interactive setup wizard for Trello MCP integration. Guides user through enabling Trello, configuring authentication, and verifying access by creating a test card.
---

# Enable Trello

This skill guides users through the complete end-to-end process of setting up Trello MCP integration for task management in their project.

## Definition of Done

The setup is complete when:

1. Trello MCP is accessible (either local MCP server or connection to existing)
2. Authentication is configured (API Key + Token)
3. User successfully creates and sees a test card in Trello

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                 | Use When                             |
| ---------------- | ------------------------------------------- | ------------------------------------ |
| **Full Setup**   | Get API credentials + run local MCP server  | Starting fresh, local development    |
| **Connect Only** | Configure client to connect to existing MCP | MCP server already running elsewhere |

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `trello-setup-progress.md`

Location: Project root (`./trello-setup-progress.md`)

**Format:**

```markdown
# Trello Setup Progress

## Status

- **Started**: {timestamp}
- **Current Phase**: Phase {N} - {Phase Name}
- **Setup Mode**: {Selected Mode}

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [ ] Phase 2: {Next Phase} <- CURRENT
- [ ] Phase 3: ...

## Collected Information

- **Setup Mode**: {value}
- **Test Board**: {value}
- **Config Location**: {value}
```

### Progress Tracking Rules

1. Create progress file at Phase 1 start
2. Update after each phase completion
3. Store non-sensitive data only (never API keys/tokens)
4. Delete only after successful DoD verification
5. Check for existing progress on session start

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: Check for Existing Installation & Progress

**ALWAYS start here.** Before anything else:

#### Step 1: Check for Existing Trello Configuration

First, detect if Trello MCP is already set up in this project:

```bash
# Check CLAUDE.md for Trello configuration
grep -A 10 "### Trello" CLAUDE.md 2>/dev/null

# Check for MCP configuration
grep -A 5 '"trello"' .mcp.json 2>/dev/null
```

**If Trello is already configured:**

Display status and offer options:

```
Trello MCP is already configured in this project!

Current Configuration:
  MCP Server: @modelcontextprotocol/server-trello
  Documented in: CLAUDE.md

What would you like to do?
1. Keep current setup (exit - you can use /trello-use for operations)
2. Reconfigure (update .mcp.json and CLAUDE.md settings)
3. Start fresh (run /trello-disable first, then set up again)
```

- Option 1 -> Exit setup mode, suggest using trello-use skill
- Option 2 -> Skip to Phase 4A/3B (Configure MCP) with existing values
- Option 3 -> Suggest running trello-disable first, then re-running setup

**If Trello is partially configured (some components missing):**

```
Trello is partially configured:

Found:
  OK .mcp.json trello server entry
  X Cannot connect to Trello (tools not available)

Would you like to:
1. Fix the current setup (resume from connection test)
2. Start fresh (clear existing config and begin setup)
```

#### Step 2: Check for Progress File

1. **Check for progress file**

   ```bash
   cat trello-setup-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing Trello setup in progress!

     Current Phase: Phase 4A - MCP Configuration
     Setup Mode: Full Setup
     Test Board: My Test Board

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

1. **Ask the user about setup mode**:

   "How would you like to set up Trello MCP?"

   **Option A: Full Setup (Local MCP Server)**
   - "I need to get Trello API credentials and run the MCP server locally"
   - Requires: Node.js, Trello account
   - Result: MCP server runs via npx when Claude Code starts

   **Option B: Connect to Existing MCP Server**
   - "There's already a Trello MCP server running that I need to connect to"
   - Requires: Server URL/endpoint, any authentication details
   - Result: Claude Code connects to remote/existing server

   **Option C: Not Sure**
   - Help user determine which option fits their situation
   - Ask: "Is there a team/infrastructure managing MCP servers for you?"
   - Ask: "Do you have connection details (URL, port) for an existing server?"

2. **Based on selection, proceed to appropriate phase:**
   - Option A -> Continue to Phase 2A (Full Setup)
   - Option B -> Skip to Phase 2B (Connect Only)

3. **Create progress file**
   Create `trello-setup-progress.md` with initial status:

   ```markdown
   # Trello Setup Progress

   ## Status

   - **Started**: [timestamp]
   - **Current Phase**: Phase 2A/2B
   - **Setup Mode**: [Full Setup / Connect Only]

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [ ] Phase 2: [Verify Prerequisites / Gather Connection Details]
   - [ ] Phase 3: [API Credentials / Configure Client]
   - [ ] Phase 4: MCP Configuration
   - [ ] Phase 5: Connection Test
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: [selected mode]
   ```

---

## Path A: Full Setup (Local MCP Server)

### Phase 2A: Verify Prerequisites

1. **Verify Node.js/npm availability**

   ```bash
   node --version
   npm --version
   ```

   - If not installed, guide user to install Node.js first
   - Minimum required: Node.js 18+

2. **Ask the user**:
   - "Do you have a Trello account?"
   - "Do you already have Trello API credentials (API key and token), or do we need to get them?"

### Phase 3A: Trello API Credentials

If user needs to obtain API credentials, guide them through the process.

**Trello uses two credentials:**

| Credential    | Description                        | Format                   |
| ------------- | ---------------------------------- | ------------------------ |
| **API Key**   | Identifies your application        | 32-character hex string  |
| **API Token** | Authorizes access to user's boards | Long alphanumeric string |

**Guide user to get credentials:**

1. **Get API Key:**
   - Go to [trello.com/power-ups/admin](https://trello.com/power-ups/admin)
   - Log in with Trello account
   - Click "New" to create a new Power-Up (or use existing)
   - Fill in basic details:
     - Name: `Claude MCP Integration`
     - Workspace: Select your workspace
   - After creation, find and copy the **API Key** (32 characters)

   **Alternative:** Go to [trello.com/app-key](https://trello.com/app-key) for quick access

2. **Generate API Token:**
   - Construct authorization URL:
     ```
     https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&name=Claude%20MCP&key=YOUR_API_KEY
     ```
   - Click "Allow" to authorize
   - Copy the token displayed

3. **Verify credentials work:**
   ```bash
   curl "https://api.trello.com/1/members/me?key=YOUR_API_KEY&token=YOUR_TOKEN"
   ```
   Expected: JSON with user information

**Ask user to provide:**

1. Trello API Key
2. Trello API Token (with read/write permissions)
3. Target board name for test card

### Phase 3.5A: Secrets Storage (Optional)

After collecting credentials, check if the project has a secrets backend configured:

1. **Check CLAUDE.md for secrets backend**
   Look for "Secrets Management" section in CLAUDE.md to determine if Vault, SOPS, or another backend is configured.

2. **If secrets backend is configured:**

   Ask user: "This project has [Vault/SOPS] configured for secrets management. Would you like to store the Trello credentials there as well?"

   **Option 1: Yes, store in secrets backend (Recommended)**
   - Use the `secrets` skill to store the credentials:
     ```
     secrets set trello/api_key <api_key>
     secrets set trello/api_token <api_token>
     ```

   **Option 2: No, only store in .mcp.json**
   - Credentials will only be in the MCP configuration file

3. **If NO secrets backend is configured:**
   - Inform user credentials will be stored directly in .mcp.json
   - Optionally offer to set up a secrets backend first

### Phase 4A: MCP Configuration (Local Server)

Once credentials are collected, configure the MCP to run locally:

1. **Determine configuration location**
   Ask user: "Where should I add the Trello MCP configuration?"
   - Project-level: `.mcp.json` in project root (recommended)
   - User-level: `~/.claude/settings.json`

2. **Configure local MCP server** (using npx, no install needed)

   ```json
   {
     "mcpServers": {
       "trello": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-trello"],
         "env": {
           "TRELLO_API_KEY": "<user-provided-api-key>",
           "TRELLO_TOKEN": "<user-provided-token>"
         }
       }
     }
   }
   ```

3. **Write the configuration**
   - If `.mcp.json` exists, merge the trello config into existing `mcpServers`
   - If creating new file, create complete structure
   - NEVER commit credentials to git

4. **Verify .gitignore**
   - Check if `.mcp.json` is in `.gitignore`
   - If not, offer to add it (credentials should not be committed)

5. **Update progress file for reload**
   Update `trello-setup-progress.md`:

   ```markdown
   ## Status

   - **Current Phase**: Phase 5 - Connection Test (PENDING RELOAD)

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [x] Phase 2A: Verify Prerequisites
   - [x] Phase 3A: Trello API Credentials
   - [x] Phase 4A: MCP Configuration
   - [ ] Phase 5: Connection Test <- RESUME HERE AFTER RELOAD
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: Full Setup (Local MCP Server)
   - **Test Board**: [board name]
   - **Config Location**: .mcp.json
   ```

6. **Instruct user to reload**

   ```
   OK MCP configuration written to .mcp.json

   WARNING Claude Code needs to reload to activate the Trello MCP.

   Please restart Claude Code, then run this skill again.
   Progress has been saved - setup will resume from the connection test.
   ```

-> After reload, resume at Phase 5: Connection Test

---

## Path B: Connect to Existing MCP Server

### Phase 2B: Gather Connection Details

Ask the user for existing server information:

1. **Server connection type** - Ask: "How does the existing MCP server accept connections?"

   **Option 1: HTTP/SSE (Server-Sent Events)**

   ```json
   {
     "mcpServers": {
       "trello": {
         "url": "http://server-address:port/sse"
       }
     }
   }
   ```

   **Option 2: WebSocket**

   ```json
   {
     "mcpServers": {
       "trello": {
         "url": "ws://server-address:port"
       }
     }
   }
   ```

   **Option 3: Stdio (via SSH or remote command)**

   ```json
   {
     "mcpServers": {
       "trello": {
         "command": "ssh",
         "args": ["user@server", "mcp-server-trello"]
       }
     }
   }
   ```

2. **Collect connection details from user:**
   - Server URL or hostname
   - Port number
   - Authentication requirements (API key, token, etc.)
   - Any custom headers needed

### Phase 3B: Configure Client Connection

1. **Determine configuration location**
   Ask user: "Where should I add the Trello MCP configuration?"
   - Project-level: `.mcp.json` in project root
   - User-level: `~/.claude/settings.json`

2. **Build appropriate configuration based on connection type**

   Example for HTTP/SSE with auth:

   ```json
   {
     "mcpServers": {
       "trello": {
         "url": "https://mcp.company.internal:8080/trello/sse",
         "headers": {
           "Authorization": "Bearer <auth-token>"
         }
       }
     }
   }
   ```

3. **Write the configuration**
   - If `.mcp.json` exists, merge the trello config into existing `mcpServers`
   - If creating new file, create complete structure

4. **Verify .gitignore** (if config contains secrets)

5. **Update progress file for reload**
   Update `trello-setup-progress.md` and instruct user to reload

-> After reload, resume at Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths).

**Note:** If resuming from progress file, this phase runs after Claude Code reload.

1. **Verify MCP is loaded**
   - Check that Trello MCP tools are now available
   - If not available, configuration may have issues - troubleshoot

2. **Inform user about testing**
   "I'll now attempt to create a test card in Trello to verify the MCP is working correctly."

3. **Get test board from progress file or ask user**
   - If resuming: read test board from `trello-setup-progress.md`
   - If not stored: ask user for board name
   - Recommend using a test/sandbox board first
   - Ask which list to add the card to (or use first list)

4. **Create test card**
   Use the Trello MCP tools to:
   - List boards (verify connection)
   - Get lists from target board
   - Create a test card: "Trello MCP Setup Successful - [timestamp]"
     - Description: "This card was created automatically by Claude Code to verify Trello MCP integration."

5. **Confirm with user**
   "Did you see the test card created in Trello? Please check board '[board-name]'"

6. **Update progress file**
   Mark Phase 5 as complete

### Phase 6: Completion

Once test card is confirmed:

1. **Document in CLAUDE.md**
   - Check if `CLAUDE.md` exists in project root
   - If not, create it with basic project structure
   - Add or update the "Task Management" or "MCP Servers" section:

   ```markdown
   ## Task Management

   ### Trello

   - **Status**: Configured
   - **Setup mode**: [Full Setup / Connect Only]
   - **Config location**: `.mcp.json`
   - **Capabilities**: List boards, create/update/delete cards, manage lists, move cards
   - **Usage**: Available via MCP tools when Claude Code is running
   - **Security**: API credentials stored in `.mcp.json` (gitignored)
   - **Secrets backend**: [Vault / SOPS / None] - Credentials also stored at `trello/api_key` and `trello/api_token` if backend configured
   ```

2. **Summarize what was configured**
   - Configuration file location
   - Connected Trello account
   - Available Trello MCP capabilities

3. **Provide next steps**
   - How to use Trello MCP in future sessions
   - Common operations available:
     - List boards and cards
     - Create, update, delete cards
     - Move cards between lists
     - Add comments, labels, due dates
   - Link to Trello MCP documentation

4. **Security reminders**
   - Never commit `.mcp.json` with credentials
   - API tokens can be revoked at trello.com/power-ups/admin
   - Review token permissions periodically

5. **Cleanup suggestion**
   - "Would you like me to delete the test card, or keep it as reference?"

6. **Clean up progress file**
   After successful DOD verification:
   ```bash
   rm trello-setup-progress.md
   ```
   Inform user:
   ```
   OK Trello MCP setup complete!
   OK Progress file cleaned up
   OK Configuration documented in CLAUDE.md
   ```

## Error Handling

### Common Issues

**"Invalid API key" error:**

- Verify API key is 32 characters
- Check key at trello.com/power-ups/admin
- Ensure no extra whitespace

**"Invalid token" error:**

- Token may have expired or been revoked
- Generate new token with correct permissions
- Ensure token was generated for the correct API key

**"Board not found" error:**

- Verify board name/ID is correct
- Check token has access to that board
- Board may be in a different workspace

**"Unauthorized" error:**

- Token doesn't have required permissions
- Regenerate token with read/write access
- Check if board is private and token has access

**MCP not loading (Local Server - Path A):**

- Check JSON syntax in config file
- Verify Node.js is accessible from Claude Code's environment
- Run `npx -y @modelcontextprotocol/server-trello` manually to test

**Connection refused (Remote Server - Path B):**

- Verify server URL is correct and server is running
- Check firewall/network allows connection
- Verify authentication credentials are correct

**Rate limiting:**

- Trello API limits: 300 requests per 10 seconds per token
- If hitting limits, wait and retry
- Consider batching operations

### Error Table

| Error                | Cause                    | Solution                               |
| -------------------- | ------------------------ | -------------------------------------- |
| `invalid key`        | API key malformed        | Verify 32-char key, no whitespace      |
| `invalid token`      | Token expired/revoked    | Generate new token                     |
| `unauthorized`       | Insufficient permissions | Regenerate token with read,write scope |
| `board not found`    | Wrong board or no access | Verify board name and token access     |
| `connection refused` | MCP server not running   | Check config, restart Claude Code      |

## Interactive Checkpoints

### Mode Selection

- [ ] "Which setup mode do you need: Full Setup (local MCP server) or Connect Only (existing server)?"

### Path A (Full Setup) Checkpoints

- [ ] "Node.js verified. Do you have a Trello account?"
- [ ] "Do you have API credentials, or should I guide you through getting them?"
- [ ] "I have the API key and token. Ready to configure MCP?"
- [ ] "Configuration written. Ready to restart Claude Code?"

### Path B (Connect Only) Checkpoints

- [ ] "What type of connection does the existing server use (HTTP/SSE, WebSocket, Stdio)?"
- [ ] "I have the connection details. Ready to configure MCP?"
- [ ] "Configuration written. Ready to restart Claude Code?"

### Final Verification (Both Paths)

- [ ] "Test card created. Did you see it in Trello?"
- [ ] "Would you like me to delete the test card?"

**Definition of Done:** Only mark setup as complete when user confirms seeing the test card in Trello.

## Related Skills

- `/trello-use` - Perform Trello operations (create cards, move cards, etc.)
- `/trello-disable` - Remove Trello configuration
