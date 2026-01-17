---
name: setup-slack-user
description: Interactive setup wizard for Slack MCP integration using user tokens. Guides user through obtaining OAuth credentials, configuring the korotovsky/slack-mcp-server, and verifying the connection by reading and posting a test message.
---

# Setup Slack MCP (User Token)

This skill guides users through the complete end-to-end process of setting up Slack MCP integration using **user tokens** (xoxp) with the `korotovsky/slack-mcp-server`.

## Why User Tokens?

| Aspect | Bot Token (xoxb) | User Token (xoxp) |
|--------|------------------|-------------------|
| Access | Only invited channels | All channels user can access |
| Search | Not available | Full message search |
| Setup | Requires workspace admin approval | User-level OAuth |
| Threads | Limited | Full access to `conversations_replies` |

User tokens provide broader access and are ideal for personal productivity and multi-turn conversations.

## Definition of Done

The setup is complete when:

1. MCP configuration is added to the project
2. User successfully lists channels via the MCP
3. User successfully reads messages from a channel
4. (Optional) User posts a test message

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                        | Use When                         |
| ---------------- | -------------------------------------------------- | -------------------------------- |
| **Full Setup**   | Create Slack App + get user token + run MCP server | Starting fresh, need everything  |
| **Connect Only** | Configure client to connect to existing MCP server | Server already running elsewhere |

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `setup-slack-progress.md`

Location: Project root (`./setup-slack-progress.md`)

**Format:**

```markdown
# Slack MCP Setup Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 4A - MCP Configuration
- **Setup Mode**: Full Setup (Path A)

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [x] Phase 2A: Verify Prerequisites
- [x] Phase 3A: Slack OAuth User Token
- [ ] Phase 4A: MCP Configuration ← CURRENT
- [ ] Phase 5: Connection Test
- [ ] Phase 6: Completion

## Collected Information

- **Setup Mode**: Full Setup (Local MCP Server)
- **Node.js Version**: v20.10.0
- **Workspace**: mycompany.slack.com
- **Test Channel**: #bot-testing

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
   cat setup-slack-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing Slack MCP setup in progress!

     Current Phase: Phase 4A - MCP Configuration
     Setup Mode: Full Setup
     Workspace: mycompany.slack.com

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
   - Check for existing `slack` entry in mcpServers
   - If Slack MCP already configured, ask user if they want to reconfigure

2. **Ask the user about setup mode**:

   "How would you like to set up Slack MCP?"

   **Option A: Full Setup (Local MCP Server)**
   - "I need to create a Slack App and get a user token"
   - Requires: Node.js, Slack account
   - Result: MCP server runs via npx when Claude Code starts

   **Option B: Connect to Existing MCP Server**
   - "There's already a Slack MCP server running that I need to connect to"
   - Requires: Server URL/endpoint, any authentication details
   - Result: Claude Code connects to remote/existing server

   **Option C: I Already Have a User Token**
   - "I have a Slack user token (xoxp-...) ready to use"
   - Skip OAuth setup, go directly to MCP configuration

3. **Based on selection, proceed to appropriate phase:**
   - Option A → Continue to Phase 2A (Full Setup)
   - Option B → Skip to Phase 2B (Connect Only)
   - Option C → Skip to Phase 4A (Configure with existing token)

4. **Create progress file**
   Create `setup-slack-progress.md` with initial status.

---

## Path A: Full Setup (Local MCP Server)

### Phase 2A: Verify Prerequisites

1. **Verify Node.js/npm availability**
   - Run `node --version` and `npm --version`
   - If not installed, guide user to install Node.js first
   - Minimum required: Node.js 18+

2. **Ask the user**:
   - "Do you have a Slack account?"
   - "Do you have admin access to create Slack Apps, or do you need to request one?"

### Phase 3A: Slack OAuth User Token Setup

Guide the user through obtaining a user OAuth token. Reference `slack-user-token-setup.md` for detailed steps.

**Summary of steps:**

1. **Create or select a Slack App**
   - Go to https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name it (e.g., "Claude MCP Integration")
   - Select your workspace

2. **Configure OAuth Scopes**
   Navigate to "OAuth & Permissions" and add these **User Token Scopes**:

   | Scope | Purpose |
   |-------|---------|
   | `channels:history` | Read public channel messages |
   | `channels:read` | List public channels |
   | `chat:write` | Post messages |
   | `groups:history` | Read private channel messages |
   | `groups:read` | List private channels |
   | `im:history` | Read direct messages |
   | `im:read` | List direct messages |
   | `mpim:history` | Read group DMs |
   | `mpim:read` | List group DMs |
   | `search:read` | Search messages |
   | `users:read` | View user info |

3. **Install the App**
   - Click "Install to Workspace"
   - Authorize the requested permissions
   - Copy the **User OAuth Token** (starts with `xoxp-`)

4. **Collect from user:**
   - User OAuth Token (xoxp-...)
   - Workspace name (for documentation)
   - Test channel name (for verification)

### Phase 3.5A: Secrets Storage (Optional)

After collecting the token, check if the project has a secrets backend configured:

1. **Check CLAUDE.md for secrets backend**
   Look for "Secrets Management" section to determine if Vault, SOPS, or another backend is configured.

2. **If secrets backend is configured:**

   Ask user: "This project has [Vault/SOPS] configured for secrets management. Would you like to store the Slack token there as well?"

   **Option 1: Yes, store in secrets backend (Recommended)**
   - Use the `secrets` skill to store the token:
     ```
     secrets set slack/user_token <token>
     ```

   **Option 2: No, only store in .mcp.json**
   - Token will only be in the MCP configuration file

3. **If NO secrets backend is configured:**
   Inform user and proceed with direct storage.

### Phase 4A: MCP Configuration (Local Server)

Once the token is collected, configure the MCP:

1. **Determine configuration location**
   Ask user: "Where should I add the Slack MCP configuration?"
   - Project-level: `.mcp.json` in project root (recommended)
   - User-level: `~/.claude/settings.json`

2. **Configure local MCP server**

   ```json
   {
     "mcpServers": {
       "slack": {
         "command": "npx",
         "args": ["-y", "slack-mcp-server"],
         "env": {
           "SLACK_MCP_XOXP_TOKEN": "<user-oauth-token>",
           "SLACK_MCP_ADD_MESSAGE_TOOL": "true"
         }
       }
     }
   }
   ```

   **Environment variable options:**
   - `SLACK_MCP_XOXP_TOKEN` - Required: User OAuth token
   - `SLACK_MCP_ADD_MESSAGE_TOOL` - Enable message posting (recommended: "true")
   - `SLACK_MCP_PORT` - Server port (default: 13080)
   - `SLACK_MCP_LOG_LEVEL` - Logging level (debug/info/warn/error)

3. **Write the configuration**
   - If `.mcp.json` exists, merge the slack config into existing `mcpServers`
   - If creating new file, create complete structure
   - NEVER commit tokens to git

4. **Verify .gitignore**
   - Check if `.mcp.json` is in `.gitignore`
   - If not, offer to add it

5. **Update progress file for reload**

6. **Instruct user to reload**

   ```
   ✓ MCP configuration written to .mcp.json

   ⚠️ Claude Code needs to reload to activate the Slack MCP.

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
       "slack": {
         "url": "http://server-address:13080/sse"
       }
     }
   }
   ```

   **Option 2: Stdio (via SSH or remote command)**

   ```json
   {
     "mcpServers": {
       "slack": {
         "command": "ssh",
         "args": ["user@server", "slack-mcp-server", "--transport", "stdio"]
       }
     }
   }
   ```

2. **Collect connection details:**
   - Server URL or hostname
   - Port number
   - Authentication (API key if using SSE with `SLACK_MCP_API_KEY`)

### Phase 3B: Configure Client Connection

1. Write configuration based on connection type
2. Verify .gitignore
3. Update progress file
4. Instruct user to reload

→ After reload, resume at Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step.

**Note:** If resuming from progress file, this phase runs after Claude Code reload.

1. **Verify MCP is loaded**
   - Check that Slack MCP tools are now available
   - Expected tools:
     - `channels_list` - List channels
     - `conversations_history` - Read messages
     - `conversations_replies` - Read thread replies
     - `conversations_search_messages` - Search messages
     - `conversations_add_message` - Post messages (if enabled)

2. **Inform user about testing**
   "I'll now verify Slack access by listing channels and reading messages."

3. **Test 1: List channels**
   Use `channels_list` tool to verify connection

   ```
   channels_list()
   ```

   Confirm channels are returned.

4. **Test 2: Read messages**
   Ask user for a test channel, then:

   ```
   conversations_history(channel_id: "<channel-id>", limit: 5)
   ```

   Confirm messages are returned.

5. **Test 3: Post message (optional)**
   If `conversations_add_message` is enabled:

   Ask: "Would you like to send a test message to verify posting works?"

   If yes:
   ```
   conversations_add_message(
     channel_id: "<channel-id>",
     message: "Slack MCP setup successful! Sent from Claude Code at [timestamp]"
   )
   ```

6. **Confirm with user**
   "I was able to connect to Slack and read messages. Did everything work correctly?"

### Phase 6: Completion

Once tests are confirmed:

1. **Document in CLAUDE.md**

   ```markdown
   ## MCP Servers

   ### Slack (User Token)

   - **Status**: Configured
   - **Config location**: `.mcp.json`
   - **Setup mode**: [Full Setup / Connect Only]
   - **MCP Server**: korotovsky/slack-mcp-server (npm: slack-mcp-server)
   - **Token type**: User token (xoxp)
   - **Workspace**: [workspace name]
   - **Capabilities**:
     - List channels (`channels_list`)
     - Read channel history (`conversations_history`)
     - Read thread replies (`conversations_replies`)
     - Search messages (`conversations_search_messages`)
     - Post messages (`conversations_add_message`) - [Enabled/Disabled]
   - **Usage**: Available via MCP tools when Claude Code is running
   - **Security**: User token stored in `.mcp.json` (gitignored)
   - **Secrets backend**: [Vault / SOPS / None]
   ```

2. **Summarize what was configured**
   - Workspace connected
   - Tools available
   - Configuration location

3. **Provide next steps**
   - How to use Slack MCP tools
   - Common operations:
     - Reading channel history
     - Searching messages
     - Posting messages
     - Reading thread replies

4. **Security reminders**
   - User tokens have broad access - treat like a password
   - Never commit `.mcp.json` with tokens
   - Token can be revoked by removing the app at https://api.slack.com/apps
   - Periodically review app permissions

5. **Clean up progress file**
   ```bash
   rm setup-slack-progress.md
   ```

   ```
   ✓ Slack MCP setup complete!
   ✓ Progress file cleaned up
   ✓ Configuration documented in CLAUDE.md
   ```

## Error Handling

### Common Issues

**"invalid_auth" error:**
- Token is invalid, expired, or revoked
- Verify token starts with `xoxp-`
- Generate a new token if needed

**"missing_scope" error:**
- Token doesn't have required permissions
- Add missing scopes in Slack App settings
- Reinstall app to get new token with scopes

**"channel_not_found" error:**
- Channel ID is incorrect
- User doesn't have access to that channel
- Use `channels_list` to find valid channel IDs

**"not_in_channel" error:**
- User is not a member of the channel
- Join the channel first

**MCP not loading:**
- Check JSON syntax in config file
- Verify Node.js is accessible
- Check npx can run: `npx -y slack-mcp-server --help`

**"SLACK_MCP_XOXP_TOKEN not set" error:**
- Environment variable not passed correctly
- Check .mcp.json env section

**Rate limiting:**
- Slack has rate limits per method
- If hitting limits, wait and retry
- Consider caching results

## Interactive Checkpoints

### Mode Selection

- [ ] "Which setup mode: Full Setup, Connect Only, or I have a token?"

### Path A (Full Setup) Checkpoints

- [ ] "Node.js verified. Do you have a Slack account?"
- [ ] "Slack App created. Ready to configure OAuth scopes?"
- [ ] "I have the user token. Ready to configure MCP?"
- [ ] "Configuration written. Please reload Claude Code."

### Path B (Connect Only) Checkpoints

- [ ] "What type of connection (HTTP/SSE or Stdio)?"
- [ ] "I have the connection details. Ready to configure?"
- [ ] "Configuration written. Please reload Claude Code."

### Final Verification

- [ ] "Channels listed successfully?"
- [ ] "Messages read successfully?"
- [ ] "Test message posted successfully?" (if enabled)
- [ ] "Setup complete. Would you like to keep the test message?"

**Definition of Done:** Only mark setup as complete when user confirms successful channel listing and message reading.
