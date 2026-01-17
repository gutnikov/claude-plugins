---
name: setup-telegram
description: Interactive setup wizard for Telegram MCP integration. Guides user through creating a Telegram bot, configuring tokens, and verifying the connection with a test message.
---

# Setup Telegram MCP

This skill guides users through the complete end-to-end process of setting up Telegram MCP (Model Context Protocol) integration in their project.

## Definition of Done

The setup is complete when:

1. MCP configuration is added to the project (either new server or existing server connection)
2. User receives a test message in Telegram sent via the configured MCP

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                        | Use When                         |
| ---------------- | -------------------------------------------------- | -------------------------------- |
| **Full Setup**   | Create Telegram bot + run local MCP server         | Starting fresh, need everything  |
| **Connect Only** | Configure client to connect to existing MCP server | Server already running elsewhere |

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `setup-telegram-progress.md`

Location: Project root (`./setup-telegram-progress.md`)

**Format:**

```markdown
# Telegram MCP Setup Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 4A - MCP Configuration
- **Setup Mode**: Full Setup (Path A)

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [x] Phase 2A: Verify Prerequisites
- [x] Phase 3A: Telegram Bot Creation
- [ ] Phase 4A: MCP Configuration ← CURRENT
- [ ] Phase 5: Connection Test
- [ ] Phase 6: Completion

## Collected Information

- **Setup Mode**: Full Setup (Local MCP Server)
- **Node.js Version**: v20.10.0
- **Bot Username**: @my_project_bot
- **Bot Token**: (stored in .mcp.json)
- **Test Chat ID**: 123456789

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
   cat setup-telegram-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing Telegram MCP setup in progress!

     Current Phase: Phase 4A - MCP Configuration
     Setup Mode: Full Setup
     Bot Username: @my_project_bot

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
   - If Telegram MCP already configured, ask user if they want to reconfigure

2. **Ask the user about setup mode**:

   "How would you like to set up Telegram MCP?"

   **Option A: Full Setup (Local MCP Server)**
   - "I need to create a new Telegram bot and run the MCP server locally"
   - Requires: Node.js, Telegram account
   - Result: MCP server runs via npx when Claude Code starts

   **Option B: Connect to Existing MCP Server**
   - "There's already a Telegram MCP server running that I need to connect to"
   - Requires: Server URL/endpoint, any authentication details
   - Result: Claude Code connects to remote/existing server

   **Option C: Not Sure**
   - Help user determine which option fits their situation
   - Ask: "Is there a team/infrastructure managing MCP servers for you?"
   - Ask: "Do you have connection details (URL, port) for an existing server?"

3. **Based on selection, proceed to appropriate phase:**
   - Option A → Continue to Phase 2A (Full Setup)
   - Option B → Skip to Phase 2B (Connect Only)

4. **Create progress file**
   Create `setup-telegram-progress.md` with initial status:

   ```markdown
   # Telegram MCP Setup Progress

   ## Status

   - **Started**: [timestamp]
   - **Current Phase**: Phase 2A/2B
   - **Setup Mode**: [Full Setup / Connect Only]

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [ ] Phase 2: [Verify Prerequisites / Gather Connection Details]
   - [ ] Phase 3: [Bot Creation / Configure Client]
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
   - "Do you have a Telegram account?"
   - "Do you already have a Telegram bot created, or do we need to create one?"

### Phase 3A: Telegram Bot Creation

If user needs to create a Telegram bot, guide them through `telegram-bot-setup.md`.

**Telegram Bot Creation via BotFather:**

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` command
3. Choose a name for your bot (display name)
4. Choose a username for your bot (must end in `bot`)
5. BotFather will provide the Bot Token

**Key information to collect from user:**

- Bot Token (from BotFather, format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
- Bot Username (e.g., `@my_project_bot`)
- Test Chat ID (user's chat ID or a group ID for testing)

**Getting Chat ID:**

The user needs to know their Chat ID for testing. Methods:

- Send a message to the bot, then check `https://api.telegram.org/bot<TOKEN>/getUpdates`
- Use `@userinfobot` or `@getidsbot` on Telegram
- For groups, add the bot to group and check getUpdates

**Ask user to provide:**

1. Bot Token (from BotFather)
2. Bot Username
3. Chat ID for test message (their personal chat or a test group)

### Phase 3.5A: Secrets Storage (Optional)

After collecting the bot token, check if the project has a secrets backend configured:

1. **Check CLAUDE.md for secrets backend**
   Look for "Secrets Management" section in CLAUDE.md to determine if Vault, SOPS, or another backend is configured.

2. **If secrets backend is configured:**

   Ask user: "This project has [Vault/SOPS] configured for secrets management. Would you like to store the Telegram bot token there as well?"

   **Option 1: Yes, store in secrets backend (Recommended)**
   - Use the `secrets` skill to store the token:
     ```
     secrets set telegram/bot_token <token>
     ```
   - This provides:
     - Centralized secrets management
     - Audit trail (if using Vault)
     - Easy rotation
     - Team sharing via existing key management

   **Option 2: No, only store in .mcp.json**
   - Token will only be in the MCP configuration file
   - Less secure but simpler

3. **If NO secrets backend is configured:**

   Inform user: "No secrets backend (Vault/SOPS) is configured for this project. Token will be stored directly in .mcp.json."

   Optionally offer: "Would you like to set up a secrets backend first? (Run `setup-vault` or `setup-sops-age`)"

   If user declines, proceed with direct storage.

4. **Update progress file**
   Record secrets storage choice:

   ```markdown
   ## Collected Information

   - **Secrets Backend**: [Vault / SOPS / None]
   - **Token Stored In Backend**: [Yes / No]
   ```

### Phase 4A: MCP Configuration (Local Server)

Once the bot token is collected, configure the MCP to run locally:

1. **Determine configuration location**
   Ask user: "Where should I add the Telegram MCP configuration?"
   - Project-level: `.mcp.json` in project root
   - User-level: `~/.claude/settings.json`

2. **Configure local MCP server** (using npx, no install needed)
   The recommended approach uses `npx` which doesn't require installation:

   ```json
   {
     "mcpServers": {
       "telegram": {
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-telegram"],
         "env": {
           "TELEGRAM_BOT_TOKEN": "<user-provided-token>"
         }
       }
     }
   }
   ```

   **Note:** Verify the actual package name for Telegram MCP server. If official package doesn't exist, may need to use community package or guide user to alternative.

3. **Write the configuration**
   - If `.mcp.json` exists, merge the telegram config into existing `mcpServers`
   - If creating new file, create complete structure
   - NEVER commit tokens to git - warn user about this
   - **Note**: Even if token is stored in a secrets backend (Phase 3.5A), it must also be in .mcp.json for the MCP server to function. The secrets backend serves as the secure source of truth for rotation and audit purposes.

4. **Verify .gitignore**
   - Check if `.mcp.json` is in `.gitignore`
   - If not, offer to add it (tokens should not be committed)

5. **Update progress file for reload**
   Update `setup-telegram-progress.md`:

   ```markdown
   ## Status

   - **Current Phase**: Phase 5 - Connection Test (PENDING RELOAD)

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [x] Phase 2A: Verify Prerequisites
   - [x] Phase 3A: Telegram Bot Creation
   - [x] Phase 4A: MCP Configuration
   - [ ] Phase 5: Connection Test ← RESUME HERE AFTER RELOAD
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: Full Setup (Local MCP Server)
   - **Bot Username**: [bot_username]
   - **Test Chat ID**: [chat_id]
   - **Config Location**: .mcp.json
   ```

6. **Instruct user to reload**

   ```
   ✓ MCP configuration written to .mcp.json

   ⚠️ Claude Code needs to reload to activate the Telegram MCP.

   Please restart Claude Code, then run this skill again.
   Progress has been saved - setup will resume from the connection test.
   ```

→ After reload, resume at Phase 5: Connection Test

---

## Path B: Connect to Existing MCP Server

### Phase 2B: Gather Connection Details

Ask the user for existing server information:

1. **Server connection type** - Ask: "How does the existing MCP server accept connections?"

   **Option 1: HTTP/SSE (Server-Sent Events)**

   ```json
   {
     "mcpServers": {
       "telegram": {
         "url": "http://server-address:port/sse"
       }
     }
   }
   ```

   **Option 2: WebSocket**

   ```json
   {
     "mcpServers": {
       "telegram": {
         "url": "ws://server-address:port"
       }
     }
   }
   ```

   **Option 3: Stdio (via SSH or remote command)**

   ```json
   {
     "mcpServers": {
       "telegram": {
         "command": "ssh",
         "args": ["user@server", "mcp-server-telegram"]
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
   Ask user: "Where should I add the Telegram MCP configuration?"
   - Project-level: `.mcp.json` in project root
   - User-level: `~/.claude/settings.json`

2. **Build appropriate configuration based on connection type**

   Example for HTTP/SSE with auth:

   ```json
   {
     "mcpServers": {
       "telegram": {
         "url": "https://mcp.company.internal:8080/telegram/sse",
         "headers": {
           "Authorization": "Bearer <auth-token>"
         }
       }
     }
   }
   ```

3. **Write the configuration**
   - If `.mcp.json` exists, merge the telegram config into existing `mcpServers`
   - If creating new file, create complete structure

4. **Verify .gitignore** (if config contains secrets)
   - Check if `.mcp.json` is in `.gitignore`
   - If auth tokens are in config, ensure file won't be committed

5. **Update progress file for reload**
   Update `setup-telegram-progress.md`:

   ```markdown
   ## Status

   - **Current Phase**: Phase 5 - Connection Test (PENDING RELOAD)

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [x] Phase 2B: Gather Connection Details
   - [x] Phase 3B: Configure Client Connection
   - [ ] Phase 5: Connection Test ← RESUME HERE AFTER RELOAD
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: Connect Only
   - **Server URL**: [url]
   - **Connection Type**: [HTTP/SSE / WebSocket / Stdio]
   - **Test Chat ID**: [chat_id]
   - **Config Location**: .mcp.json
   ```

6. **Instruct user to reload**

   ```
   ✓ MCP configuration written to .mcp.json

   ⚠️ Claude Code needs to reload to activate the Telegram MCP.

   Please restart Claude Code, then run this skill again.
   Progress has been saved - setup will resume from the connection test.
   ```

→ After reload, resume at Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths).

**Note:** If resuming from progress file, this phase runs after Claude Code reload.

1. **Verify MCP is loaded**
   - Check that Telegram MCP tools are now available
   - If not available, configuration may have issues - troubleshoot

2. **Inform user about testing**
   "I'll now attempt to send a test message to verify the Telegram MCP is working correctly."

3. **Get test chat ID from progress file or ask user**
   - If resuming: read test chat ID from `setup-telegram-progress.md`
   - If not stored: ask user for chat ID
   - Can be their personal chat with the bot or a group

4. **Send test message**
   Use the Telegram MCP tools to:
   - Get bot info (verify connection)
   - Send a test message: "Telegram MCP setup successful! Sent from Claude Code at [timestamp]"

5. **Confirm with user**
   "Did you receive the test message in Telegram? Please check your chat with @[bot-username]"

6. **Update progress file**
   Mark Phase 5 as complete:
   ```markdown
   - [x] Phase 5: Connection Test
   - [ ] Phase 6: Completion ← IN PROGRESS
   ```

### Phase 6: Completion

Once test message is confirmed:

1. **Document in CLAUDE.md**
   - Check if `CLAUDE.md` exists in project root
   - If not, create it with basic project structure
   - Add or update the "Integrations" or "MCP Servers" section:

   ```markdown
   ## MCP Servers

   ### Telegram

   - **Status**: Configured
   - **Config location**: `.mcp.json`
   - **Setup mode**: [Full Setup / Connect Only]
   - **Bot username**: [@bot_username]
   - **Capabilities**: Send messages, receive updates, manage chats
   - **Usage**: Available via MCP tools when Claude Code is running
   - **Security**: Bot token stored in `.mcp.json` (gitignored)
   - **Secrets backend**: [Vault / SOPS / None] - Token also stored at `telegram/bot_token` if backend configured
   ```

   - If CLAUDE.md already has MCP section, append Telegram configuration
   - Preserve existing content in the file

2. **Summarize what was configured**
   - Bot username
   - Configuration file location
   - Available Telegram MCP capabilities

3. **Provide next steps**
   - How to use Telegram MCP in future sessions
   - Common commands/tools available:
     - Send messages to users/groups
     - Receive and process updates
     - Send media (photos, documents)
     - Manage bot settings
   - Link to Telegram Bot API documentation

4. **Security reminders**
   - Never commit `.mcp.json` with bot token
   - Bot token can be revoked via BotFather (`/revoke`)
   - Create new token if compromised (`/token`)
   - Review bot permissions and privacy settings

5. **Clean up progress file**
   After successful DOD verification:
   ```bash
   rm setup-telegram-progress.md
   ```
   Inform user:
   ```
   ✓ Telegram MCP setup complete!
   ✓ Progress file cleaned up
   ✓ Configuration documented in CLAUDE.md
   ```

## Error Handling

### Common Issues

**"Unauthorized" or "401" error:**

- Bot token is invalid or revoked
- Verify token format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
- Get new token from BotFather if needed

**"Chat not found" or "400" error:**

- Chat ID is incorrect
- Bot hasn't been started by the user (they need to send /start first)
- Bot was removed from the group
- Verify chat ID using getUpdates API

**"Forbidden: bot was blocked by the user":**

- User has blocked the bot
- User needs to unblock and send /start again

**"Bad Request: chat not found":**

- For groups: bot may not be a member
- Add bot to the group first
- For private chats: user must initiate conversation with /start

**MCP not loading (Local Server - Path A):**

- Check JSON syntax in config file
- Verify Node.js is accessible from Claude Code's environment
- Check if the MCP package exists and is correct
- Check for port conflicts if using stdio transport

**Connection refused (Remote Server - Path B):**

- Verify server URL is correct and server is running
- Check firewall/network allows connection
- Verify authentication credentials are correct
- Try connecting from terminal: `curl <server-url>/health` (if HTTP)

**Authentication failed (Path B):**

- Verify API key or token is correct
- Check if token has expired
- Ensure token has required permissions on the server side
- Contact server administrator for correct credentials

**Rate limiting:**

- Telegram has rate limits (about 30 messages/second to different chats)
- If hitting limits, wait and retry
- Consider batching operations

## Interactive Checkpoints

At each phase, confirm with user before proceeding:

### Mode Selection

- [ ] "Which setup mode do you need: Full Setup (local server) or Connect Only (existing server)?"

### Path A (Full Setup) Checkpoints

- [ ] "Node.js verified. Do you have a Telegram account?"
- [ ] "Do you have a Telegram bot, or should I guide you through creating one with BotFather?"
- [ ] "I have the bot token and chat ID. Ready to configure MCP?"
- [ ] "Configuration written. Ready to test the connection?"

### Path B (Connect Only) Checkpoints

- [ ] "What type of connection does the existing server use (HTTP/SSE, WebSocket, Stdio)?"
- [ ] "I have the connection details. Ready to configure MCP?"
- [ ] "Configuration written. Ready to test the connection?"

### Final Verification (Both Paths)

- [ ] "Test message sent. Did you receive it in Telegram?"

**Definition of Done:** Only mark setup as complete when user confirms receipt of test message.
