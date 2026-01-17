---
name: setup-slack-bot
description: Interactive setup wizard for Slack MCP integration. Guides user through creating a Slack App, obtaining bot credentials, configuring the MCP, and verifying the connection by listing channels or sending a test message.
---

# Setup Slack Bot MCP

This skill guides users through the complete end-to-end process of setting up Slack MCP (Model Context Protocol) integration in their project using `@modelcontextprotocol/server-slack`.

## Definition of Done

The setup is complete when:

1. MCP configuration is added to the project (either new server or existing server connection)
2. User sees Slack channels listed or a test message sent via the configured MCP

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                        | Use When                         |
| ---------------- | -------------------------------------------------- | -------------------------------- |
| **Full Setup**   | Create Slack App + get bot token + run local MCP   | Starting fresh, need everything  |
| **Connect Only** | Configure client to connect to existing MCP server | Server already running elsewhere |

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `setup-slack-bot-progress.md`

Location: Project root (`./setup-slack-bot-progress.md`)

**Format:**

```markdown
# Slack Bot MCP Setup Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 4A - MCP Configuration
- **Setup Mode**: Full Setup (Path A)

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [x] Phase 2A: Verify Prerequisites
- [x] Phase 3A: Slack App & Bot Token
- [ ] Phase 4A: MCP Configuration <- CURRENT
- [ ] Phase 5: Connection Test
- [ ] Phase 6: Completion

## Collected Information

- **Setup Mode**: Full Setup (Local MCP Server)
- **Node.js Version**: v20.10.0
- **Team ID**: T01234567
- **Test Channel**: #general

## Notes

- Waiting for Claude Code reload to test MCP connection
- Resume from Phase 5 after reload
```

### Progress Tracking Rules

1. **Create progress file** at the start of Phase 1
2. **Update after each phase** completion
3. **Store collected information** (non-sensitive) for resumption
4. **Delete progress file** only after successful DOD verification
5. **On session start**, check for existing progress file and resume

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat setup-slack-bot-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing Slack Bot MCP setup in progress!

     Current Phase: Phase 4A - MCP Configuration
     Setup Mode: Full Setup
     Team ID: T01234567

     Would you like to:
     1. Resume from where you left off
     2. Start over (will delete progress)
     ```

   - If resuming, skip to the indicated phase with collected information
   - If starting over, delete progress file and begin Phase 1

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Prerequisites & Mode Selection

First, determine what kind of setup the user needs:

1. **Check for existing MCP configuration**
   - Look for `.mcp.json` or `mcp.json` in project root
   - Check for `.claude/settings.json` or similar config files
   - If Slack MCP already configured, ask user if they want to reconfigure

2. **Ask the user about setup mode**:

   "How would you like to set up Slack Bot MCP?"

   **Option A: Full Setup (Local MCP Server)**
   - "I need to create a Slack App and get bot credentials, then run the MCP server locally"
   - Requires: Node.js, Slack workspace admin access (or ability to request app installation)
   - Result: MCP server runs via npx when Claude Code starts

   **Option B: Connect to Existing MCP Server**
   - "There's already a Slack MCP server running that I need to connect to"
   - Requires: Server URL/endpoint, any authentication details
   - Result: Claude Code connects to remote/existing server

   **Option C: Not Sure**
   - Help user determine which option fits their situation
   - Ask: "Is there a team/infrastructure managing MCP servers for you?"
   - Ask: "Do you have connection details (URL, port) for an existing server?"

3. **Based on selection, proceed to appropriate phase:**
   - Option A -> Continue to Phase 2A (Full Setup)
   - Option B -> Skip to Phase 2B (Connect Only)

4. **Create progress file**
   Create `setup-slack-bot-progress.md` with initial status:

   ```markdown
   # Slack Bot MCP Setup Progress

   ## Status

   - **Started**: [timestamp]
   - **Current Phase**: Phase 2A/2B
   - **Setup Mode**: [Full Setup / Connect Only]

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [ ] Phase 2: [Verify Prerequisites / Gather Connection Details]
   - [ ] Phase 3: [Slack App & Bot Token / Configure Client]
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
   - Run `node --version` and `npm --version`
   - If not installed, guide user to install Node.js first
   - Minimum required: Node.js 18+

2. **Ask the user**:
   - "Do you have access to a Slack workspace where you can create apps (or request app installation)?"
   - "Do you already have Slack bot credentials (Bot Token and Team ID), or do we need to create a Slack App?"

### Phase 3A: Slack App & Bot Token

If user needs to create a Slack App and obtain credentials, guide them through the process:

**Slack Bot MCP requires two credentials:**

| Credential         | Description                              | Format                    |
| ------------------ | ---------------------------------------- | ------------------------- |
| **Bot Token**      | Authenticates the bot to Slack API       | Starts with `xoxb-`       |
| **Team ID**        | Identifies your Slack workspace          | Starts with `T` (e.g., T01234567) |

#### Step-by-step Slack App Creation:

1. **Go to Slack API portal**
   - Direct user to: https://api.slack.com/apps
   - Click "Create New App"
   - Choose "From scratch"
   - Enter App Name (e.g., "Claude MCP Bot")
   - Select the workspace

2. **Configure Bot Token Scopes**
   Navigate to "OAuth & Permissions" in the sidebar, then add these Bot Token Scopes:

   | Scope               | Purpose                                         |
   | ------------------- | ----------------------------------------------- |
   | `chat:write`        | Send messages to channels, DMs, and threads     |
   | `chat:write.public` | Write to public channels without explicit invite |

3. **Install App to Workspace**
   - Click "Install to Workspace" button
   - Review permissions and authorize
   - Copy the "Bot User OAuth Token" (starts with `xoxb-`)

4. **Get Team ID**
   - The Team ID is visible in the Slack workspace URL or can be found:
     - In Slack desktop app: Click workspace name -> Settings & administration -> Workspace settings
     - The URL will contain the team ID: `https://app.slack.com/client/T01234567/...`
   - Alternatively, use the Slack API test endpoint

5. **Bot channel access**
   - With `chat:write.public`, the bot can post to any public channel without being invited
   - For private channels, invite the bot with `/invite @YourBotName`

**Information to collect from user:**
- Bot User OAuth Token (xoxb-...)
- Team ID (T...)
- Test channel name for verification

### Phase 3.5A: Secrets Storage (Optional)

After collecting credentials, check if the project has a secrets backend configured:

1. **Check CLAUDE.md for secrets backend**
   Look for "Secrets Management" section in CLAUDE.md to determine if Vault, SOPS, or another backend is configured.

2. **If secrets backend is configured:**

   Ask user: "This project has [Vault/SOPS] configured for secrets management. Would you like to store the Slack credentials there as well?"

   **Option 1: Yes, store in secrets backend (Recommended)**
   - Use the `secrets` skill to store the credentials:
     ```
     secrets set slack/bot_token <bot_token>
     secrets set slack/team_id <team_id>
     ```
   - This provides:
     - Centralized secrets management
     - Audit trail (if using Vault)
     - Easy rotation
     - Team sharing via existing key management

   **Option 2: No, only store in .mcp.json**
   - Credentials will only be in the MCP configuration file
   - Less secure but simpler

3. **If NO secrets backend is configured:**

   Inform user: "No secrets backend (Vault/SOPS) is configured for this project. Credentials will be stored directly in .mcp.json."

   Optionally offer: "Would you like to set up a secrets backend first? (Run `setup-vault` or `setup-sops-age`)"

   If user declines, proceed with direct storage.

4. **Update progress file**
   Record secrets storage choice:
   ```markdown
   ## Collected Information

   - **Secrets Backend**: [Vault / SOPS / None]
   - **Credentials Stored In Backend**: [Yes / No]
   ```

### Phase 4A: MCP Configuration (Local Server)

Once credentials are collected, configure the MCP to run locally:

1. **Determine configuration location**
   Ask user: "Where should I add the Slack MCP configuration?"
   - Project-level: `.mcp.json` in project root
   - User-level: `~/.claude/settings.json`

2. **Configure local MCP server** (using npx, no install needed)
   The recommended approach uses `npx` which doesn't require installation:

   ```json
   {
     "mcpServers": {
       "slack": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-slack"],
         "env": {
           "SLACK_BOT_TOKEN": "<user-provided-bot-token>",
           "SLACK_TEAM_ID": "<user-provided-team-id>"
         }
       }
     }
   }
   ```

   **Optional: Restrict to specific channels**
   If user wants to limit bot access to specific channels:

   ```json
   {
     "mcpServers": {
       "slack": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-slack"],
         "env": {
           "SLACK_BOT_TOKEN": "<bot-token>",
           "SLACK_TEAM_ID": "<team-id>",
           "SLACK_CHANNEL_IDS": "C01234567,C76543210"
         }
       }
     }
   }
   ```

3. **Write the configuration**
   - If `.mcp.json` exists, merge the slack config into existing `mcpServers`
   - If creating new file, create complete structure
   - NEVER commit credentials to git - warn user about this
   - **Note**: Even if credentials are stored in a secrets backend (Phase 3.5A), they must also be in .mcp.json for the MCP server to function. The secrets backend serves as the secure source of truth for rotation and audit purposes.

4. **Verify .gitignore**
   - Check if `.mcp.json` is in `.gitignore`
   - If not, offer to add it (credentials should not be committed)

5. **Update progress file for reload**
   Update `setup-slack-bot-progress.md`:

   ```markdown
   ## Status

   - **Current Phase**: Phase 5 - Connection Test (PENDING RELOAD)

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [x] Phase 2A: Verify Prerequisites
   - [x] Phase 3A: Slack App & Bot Token
   - [x] Phase 4A: MCP Configuration
   - [ ] Phase 5: Connection Test <- RESUME HERE AFTER RELOAD
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: Full Setup (Local MCP Server)
   - **Team ID**: [team-id]
   - **Test Channel**: [channel name]
   - **Config Location**: .mcp.json
   ```

6. **Instruct user to reload**

   ```
   MCP configuration written to .mcp.json

   Claude Code needs to reload to activate the Slack MCP.

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
       "slack": {
         "url": "http://server-address:port/sse"
       }
     }
   }
   ```

   **Option 2: WebSocket**

   ```json
   {
     "mcpServers": {
       "slack": {
         "url": "ws://server-address:port"
       }
     }
   }
   ```

   **Option 3: Stdio (via SSH or remote command)**

   ```json
   {
     "mcpServers": {
       "slack": {
         "command": "ssh",
         "args": ["user@server", "mcp-server-slack"]
       }
     }
   }
   ```

2. **Collect connection details from user:**
   - Server URL or hostname
   - Port number
   - Authentication requirements (API key, token, etc.)
   - Any custom headers needed

3. **Ask about authentication:**
   - "Does the server require authentication?"
   - "Do you have the credentials/tokens needed to connect?"

### Phase 3B: Configure Client Connection

1. **Determine configuration location**
   Ask user: "Where should I add the Slack MCP configuration?"
   - Project-level: `.mcp.json` in project root
   - User-level: `~/.claude/settings.json`

2. **Build appropriate configuration based on connection type**

   Example for HTTP/SSE with auth:

   ```json
   {
     "mcpServers": {
       "slack": {
         "url": "https://mcp.company.internal:8080/slack/sse",
         "headers": {
           "Authorization": "Bearer <auth-token>"
         }
       }
     }
   }
   ```

3. **Write the configuration**
   - If `.mcp.json` exists, merge the slack config into existing `mcpServers`
   - If creating new file, create complete structure

4. **Verify .gitignore** (if config contains secrets)
   - Check if `.mcp.json` is in `.gitignore`
   - If auth tokens are in config, ensure file won't be committed

5. **Update progress file for reload**
   Update `setup-slack-bot-progress.md`:

   ```markdown
   ## Status

   - **Current Phase**: Phase 5 - Connection Test (PENDING RELOAD)

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [x] Phase 2B: Gather Connection Details
   - [x] Phase 3B: Configure Client Connection
   - [ ] Phase 5: Connection Test <- RESUME HERE AFTER RELOAD
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: Connect Only
   - **Server URL**: [url]
   - **Test Channel**: [channel]
   - **Config Location**: .mcp.json
   ```

6. **Instruct user to reload**

   ```
   MCP configuration written to .mcp.json

   Claude Code needs to reload to activate the Slack MCP.

   Please restart Claude Code, then run this skill again.
   Progress has been saved - setup will resume from the connection test.
   ```

-> After reload, resume at Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths).

**Note:** If resuming from progress file, this phase runs after Claude Code reload.

1. **Verify MCP is loaded**
   - Check that Slack MCP tools are now available
   - If not available, configuration may have issues - troubleshoot

2. **Inform user about testing**
   "I'll now attempt to list Slack channels and optionally send a test message to verify the MCP is working correctly."

3. **Get test channel from progress file or ask user**
   - If resuming: read test channel from `setup-slack-bot-progress.md`
   - If not stored: ask user for channel name
   - Recommend using a test channel first

4. **Test the connection**
   Use the Slack MCP tools to:
   - List channels (verify connection and permissions)
   - Optionally: Send a test message to the specified channel:
     "Slack MCP Setup Successful - [timestamp]. This message was sent automatically by Claude Code to verify Slack MCP integration."

5. **Confirm with user**
   "Did you see the channels listed? If a test message was sent, did you see it in Slack channel '#[channel-name]'?"

6. **Update progress file**
   Mark Phase 5 as complete:
   ```markdown
   - [x] Phase 5: Connection Test
   - [ ] Phase 6: Completion <- IN PROGRESS
   ```

### Phase 6: Completion

Once test is confirmed:

1. **Document in CLAUDE.md**
   - Check if `CLAUDE.md` exists in project root
   - If not, create it with basic project structure
   - Add or update the "Integrations" or "MCP Servers" section:

   ```markdown
   ## MCP Servers

   ### Slack

   - **Status**: Configured
   - **Config location**: `.mcp.json`
   - **Setup mode**: [Full Setup / Connect Only]
   - **Capabilities**: Send messages to channels, DMs, and threads
   - **Usage**: Available via MCP tools when Claude Code is running
   - **Security**: Bot credentials stored in `.mcp.json` (gitignored)
   - **Secrets backend**: [Vault / SOPS / None] - Credentials also stored at `slack/bot_token` and `slack/team_id` if backend configured
   ```

   - If CLAUDE.md already has MCP section, append Slack configuration
   - Preserve existing content in the file

2. **Summarize what was configured**
   - Configuration file location
   - Connected Slack workspace
   - Available Slack MCP capabilities

3. **Provide next steps**
   - How to use Slack MCP in future sessions
   - Common operations available:
     - Send messages to channels
     - Send messages to DMs
     - Reply to threads
   - Note: With `chat:write.public`, bot can post to public channels without being invited

4. **Security reminders**
   - Never commit `.mcp.json` with credentials
   - Bot tokens can be revoked at https://api.slack.com/apps
   - Review token permissions periodically
   - Bot tokens expire - monitor for rotation needs

5. **Cleanup suggestion**
   - "Would you like me to delete the test message (if sent), or keep it as reference?"

6. **Clean up progress file**
   After successful DOD verification:
   ```bash
   rm setup-slack-bot-progress.md
   ```
   Inform user:
   ```
   Slack Bot MCP setup complete!
   Progress file cleaned up
   Configuration documented in CLAUDE.md
   ```

## Error Handling

### Common Issues

**"invalid_auth" or "not_authed" error:**

- Bot token is invalid or expired
- Verify token starts with `xoxb-`
- Regenerate token from Slack API portal

**"missing_scope" error:**

- Bot doesn't have required permissions
- Add missing scopes in Slack API portal under "OAuth & Permissions"
- Reinstall app after adding scopes

**"channel_not_found" error:**

- Channel doesn't exist or bot isn't a member
- Invite bot to channel with `/invite @BotName`
- Verify channel ID if using SLACK_CHANNEL_IDS

**"not_in_channel" error:**

- Bot hasn't been invited to a private channel
- Use `/invite @BotName` in the target channel
- For public channels, ensure `chat:write.public` scope is enabled

**"team_not_found" error:**

- Team ID is incorrect
- Verify Team ID starts with `T`
- Check workspace URL for correct ID

**MCP not loading (Local Server - Path A):**

- Check JSON syntax in config file
- Verify Node.js is accessible from Claude Code's environment
- Run `npx @modelcontextprotocol/server-slack` manually to check for errors

**Connection refused (Remote Server - Path B):**

- Verify server URL is correct and server is running
- Check firewall/network allows connection
- Verify authentication credentials are correct

**"account_inactive" error:**

- The Slack workspace or app has been deactivated
- Contact workspace admin or reinstall the app

**Rate limiting:**

- Slack API has rate limits (varies by endpoint)
- If hitting limits, wait and retry
- Consider batching operations

## Interactive Checkpoints

At each phase, confirm with user before proceeding:

### Mode Selection

- [ ] "Which setup mode do you need: Full Setup (local server) or Connect Only (existing server)?"

### Path A (Full Setup) Checkpoints

- [ ] "Node.js verified. Do you have access to a Slack workspace?"
- [ ] "Do you have bot credentials, or should I guide you through creating a Slack App?"
- [ ] "I have the Bot Token and Team ID. Ready to configure MCP?"
- [ ] "Configuration written. Ready to test the connection?"

### Path B (Connect Only) Checkpoints

- [ ] "What type of connection does the existing server use (HTTP/SSE, WebSocket, Stdio)?"
- [ ] "I have the connection details. Ready to configure MCP?"
- [ ] "Configuration written. Ready to test the connection?"

### Final Verification (Both Paths)

- [ ] "Channels listed / test message sent. Did you verify it in Slack?"
- [ ] "Would you like me to delete the test message (if applicable)?"

**Definition of Done:** Only mark setup as complete when user confirms seeing channels listed or the test message in Slack.
