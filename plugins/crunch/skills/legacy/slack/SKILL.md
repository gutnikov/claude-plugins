---
name: slack
description: Unified Slack skill for setup and operations. Automatically detects if Slack MCP is configured and either guides through setup or executes messaging operations.
---

# Slack

This skill provides a unified interface for Slack MCP - handling both initial setup and day-to-day messaging operations.

## How It Works

1. **Check Configuration** - Automatically detect if Slack MCP is configured
2. **If Configured** - Execute the requested operation (send message, list channels, etc.)
3. **If Not Configured** - Guide through interactive setup wizard

## Usage

**For messaging operations** (when already configured):
```
/slack list channels
/slack send to #engineering: "Build completed!"
/slack dm @john.doe: "Can you review the PR?"
```

**For initial setup** (when not configured):
```
/slack
```
The skill will detect missing configuration and guide you through setup.

---

## Phase 0: Configuration Detection

**ALWAYS start here.** Before any operation:

### Step 1: Check for Existing Slack Configuration

```bash
# Check CLAUDE.md for Slack configuration
grep -A 10 "### Slack" CLAUDE.md 2>/dev/null

# Check for MCP configuration
grep -A 5 '"slack"' .mcp.json 2>/dev/null
```

### Step 2: Determine Next Action

**If Slack is configured:**
- Proceed to [Operations Section](#operations) to execute user's request

**If Slack is NOT configured:**
- Check for progress file (resuming setup)
- If no progress file, start at [Phase 1: Setup Mode Selection](#phase-1-setup-prerequisites--mode-selection)

**If Slack is configured but user explicitly wants to reconfigure:**

Display options:
```
Slack MCP is already configured in this project!

Current Configuration:
  MCP Server: @modelcontextprotocol/server-slack
  Documented in: CLAUDE.md

What would you like to do?
1. Keep current setup (proceed with operations)
2. Reconfigure (update .mcp.json and CLAUDE.md settings)
3. Start fresh (suggest running /slack-disable first)
```

### Step 3: Check for Progress File (Setup Mode Only)

If configuration not found, check for interrupted setup:

```bash
cat slack-setup-progress.md 2>/dev/null
```

**If progress file exists:**
- Parse current phase and collected information
- Display status to user and offer to resume or start over

**If no progress file:**
- Proceed to Phase 1

---

# PART 1: Setup Wizard

Use this section when Slack MCP is not yet configured.

## Definition of Done (Setup)

The setup is complete when:

1. Slack MCP is accessible (either local MCP server or connection to existing)
2. Authentication is configured (Bot Token + Team ID)
3. User successfully lists channels or sends a test message via Slack MCP
4. Configuration is documented in CLAUDE.md

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                     | Use When                                 |
| ---------------- | ----------------------------------------------- | ---------------------------------------- |
| **Full Setup**   | Create Slack App + get bot token + run local MCP| Starting fresh, need everything          |
| **Connect Only** | Configure client to connect to existing MCP     | MCP server already running elsewhere     |

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `slack-setup-progress.md`

Location: Project root (`./slack-setup-progress.md`)

**Format:**

```markdown
# Slack Setup Progress

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
- **Team ID**: {value}
- **Test Channel**: {value}
- **Config Location**: {value}
```

### Progress Tracking Rules

1. Create progress file at Phase 1 start
2. Update after each phase completion
3. Store non-sensitive data only (never bot tokens)
4. Delete only after successful DoD verification
5. Check for existing progress on session start

## Setup Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 1: Setup Prerequisites & Mode Selection

First, determine what kind of setup the user needs:

1. **Ask the user about setup mode**:

   "How would you like to set up Slack MCP?"

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

2. **Based on selection, proceed to appropriate phase:**
   - Option A -> Continue to Phase 2A (Full Setup)
   - Option B -> Skip to Phase 2B (Connect Only)

3. **Create progress file**

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
   - "Do you have access to a Slack workspace where you can create apps?"
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
   - The Team ID is visible in the Slack workspace URL
   - In Slack desktop app: Click workspace name -> Settings & administration -> Workspace settings
   - The URL will contain the team ID: `https://app.slack.com/client/T01234567/...`

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
   Look for "Secrets Management" section in CLAUDE.md.

2. **If secrets backend is configured:**

   Ask user: "This project has [Vault/SOPS] configured for secrets management. Would you like to store the Slack credentials there as well?"

   **Option 1: Yes, store in secrets backend (Recommended)**
   - Use the `secrets` skill to store the credentials:
     ```
     secrets set slack/bot_token <bot_token>
     secrets set slack/team_id <team_id>
     ```

   **Option 2: No, only store in .mcp.json**
   - Credentials will only be in the MCP configuration file

3. **If NO secrets backend is configured:**
   - Inform user credentials will be stored directly in .mcp.json

### Phase 4A: MCP Configuration (Local Server)

Once credentials are collected, configure the MCP to run locally:

1. **Determine configuration location**
   Ask user: "Where should I add the Slack MCP configuration?"
   - Project-level: `.mcp.json` in project root (recommended)
   - User-level: `~/.claude/settings.json`

2. **Configure local MCP server** (using npx, no install needed)

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
   - NEVER commit credentials to git

4. **Verify .gitignore**
   - Check if `.mcp.json` is in `.gitignore`
   - If not, offer to add it

5. **Update progress file for reload**

6. **Instruct user to reload**

   ```
   OK MCP configuration written to .mcp.json

   WARNING Claude Code needs to reload to activate the Slack MCP.

   Please restart Claude Code, then run this skill again.
   Progress has been saved - setup will resume from the connection test.
   ```

-> After reload, resume at Phase 5: Connection Test

---

## Path B: Connect to Existing MCP Server

### Phase 2B: Gather Connection Details

Ask the user for existing server information:

1. **Server connection type** - Ask: "How does the existing MCP server accept connections?"

   - HTTP/SSE (Server-Sent Events)
   - WebSocket
   - Stdio (via SSH or remote command)

2. **Collect connection details from user:**
   - Server URL or hostname
   - Port number
   - Authentication requirements
   - Any custom headers needed

### Phase 3B: Configure Client Connection

1. **Determine configuration location**
2. **Build appropriate configuration based on connection type**
3. **Write the configuration**
4. **Verify .gitignore** (if config contains secrets)
5. **Update progress file for reload**
6. **Instruct user to reload**

-> After reload, resume at Phase 5: Connection Test

---

## Common Path: Testing & Completion

### Phase 5: Connection Test

This is the critical verification step (same for both paths).

1. **Verify MCP is loaded**
   - Check that Slack MCP tools are now available
   - If not available, configuration may have issues - troubleshoot

2. **Inform user about testing**
   "I'll now attempt to list Slack channels and optionally send a test message to verify the MCP is working correctly."

3. **Get test channel from progress file or ask user**
   - If resuming: read test channel from `slack-setup-progress.md`
   - If not stored: ask user for channel name
   - Recommend using a test channel first

4. **Test the connection**
   Use the Slack MCP tools to:
   - List channels (verify connection and permissions)
   - Optionally: Send a test message to the specified channel

5. **Confirm with user**
   "Did you see the channels listed? If a test message was sent, did you see it in Slack?"

### Phase 6: Completion

Once test is confirmed:

1. **Document in CLAUDE.md**

   ```markdown
   ## Communication

   ### Slack

   - **Status**: Configured
   - **Setup mode**: [Full Setup / Connect Only]
   - **Config location**: `.mcp.json`
   - **Capabilities**: Send messages to channels, DMs, and threads
   - **Usage**: Available via MCP tools when Claude Code is running
   - **Security**: Bot credentials stored in `.mcp.json` (gitignored)
   - **Secrets backend**: [Vault / SOPS / None] - Credentials also stored at `slack/bot_token` and `slack/team_id` if backend configured
   ```

2. **Summarize what was configured**
   - Configuration file location
   - Connected Slack workspace
   - Available capabilities

3. **Provide next steps**
   - How to use Slack MCP in future sessions
   - Common operations available (see Operations section below)

4. **Security reminders**
   - Never commit `.mcp.json` with credentials
   - Bot tokens can be revoked at https://api.slack.com/apps
   - Review token permissions periodically

5. **Cleanup suggestion**
   - "Would you like me to delete the test message (if sent), or keep it as reference?"

6. **Clean up progress file**
   ```
   OK Slack MCP setup complete!
   OK Progress file cleaned up
   OK Configuration documented in CLAUDE.md
   ```

---

# PART 2: Operations

Use this section when Slack MCP is already configured.

## Pre-flight Check

Before any operation, ensure MCP is configured:

1. **Check CLAUDE.md for Slack section**
   ```bash
   grep -A 5 "### Slack" CLAUDE.md 2>/dev/null
   ```

2. **Check MCP configuration**
   ```bash
   grep -A 10 '"slack"' .mcp.json 2>/dev/null
   ```

3. **Verify Slack MCP tools are available**
   - Check if Slack MCP tools are loaded in current session
   - If not available, MCP may need restart

**If not configured:**

```
WARNING Slack MCP not configured.

No Slack configuration found in CLAUDE.md or .mcp.json.

To fix this:
1. Run this skill again - it will guide you through setup
2. Or verify your .mcp.json contains the slack server configuration
```

## Operations

### List Channels

**Parse from user request:**
- Optional: filter by type (public, private, im, mpim)
- Optional: limit number of results

**MCP Tool Call:**
Use `slack_list_channels` or equivalent MCP tool

**Response:**

```
OK Your Slack Channels:

Public Channels:
1. #general (C01234567)
2. #random (C01234568)
3. #engineering (C01234569)

Private Channels:
4. #team-private (C01234570)

Direct Messages:
5. @john.doe (D01234571)

Total: 5 channels accessible
```

### Send Message

**Parse from user request:**
- Channel name or ID (required)
- Message text (required)
- Optional: thread_ts (for replies)
- Optional: unfurl_links, unfurl_media

**Confirmation (optional):**

```
You're about to send a message:

Channel: #engineering
Message: "Build completed successfully! All tests passed."

Proceed? (yes/no)
```

**MCP Tool Call:**
Use `slack_post_message` or equivalent MCP tool

**Response:**

```
OK Message sent to #engineering

Channel: C01234569
Timestamp: 1705234567.123456
Message: "Build completed successfully! All tests passed."
```

### Reply to Thread

**Parse from user request:**
- Channel name or ID (required)
- Thread timestamp (required)
- Reply message text (required)

**MCP Tool Call:**
Use `slack_post_message` with `thread_ts` parameter

**Response:**

```
OK Reply posted in #engineering thread

Channel: C01234569
Thread: 1705234567.123456
Reply: "Here are the test results..."
```

### Send Direct Message

**Parse from user request:**
- User name, email, or ID (required)
- Message text (required)

**MCP Tool Call:**
First open/get DM channel, then send message

**Response:**

```
OK Direct message sent to @john.doe

User: U01234567
Message: "Hey, can you review the PR?"
```

### Get Channel History

**Parse from user request:**
- Channel name or ID (required)
- Optional: limit (default 10)
- Optional: oldest/latest timestamps

**MCP Tool Call:**
Use `slack_get_channel_history` or equivalent MCP tool

**Response:**

```
OK Recent messages in #engineering:

1. @alice (10:30 AM): "Deploying to staging"
2. @bob (10:35 AM): "Looks good, approved"
3. @alice (10:40 AM): "Deployed successfully"

Showing 3 of 3 messages
```

### Get Thread Replies

**Parse from user request:**
- Channel name or ID (required)
- Thread timestamp (required)
- Optional: limit

**MCP Tool Call:**
Use `slack_get_thread_replies` or equivalent MCP tool

**Response:**

```
OK Thread replies in #engineering:

Original: @alice (10:30 AM): "Deploying to staging"

Replies:
1. @bob (10:35 AM): "Looks good, approved"
2. @charlie (10:38 AM): "+1"
3. @alice (10:40 AM): "Thanks team!"

Total: 3 replies
```

### Add Reaction

**Parse from user request:**
- Channel name or ID (required)
- Message timestamp (required)
- Emoji name (required, without colons)

**MCP Tool Call:**
Use `slack_add_reaction` or equivalent MCP tool

**Response:**

```
OK Reaction added

Channel: #engineering
Message: 1705234567.123456
Reaction: :thumbsup:
```

### Get User Info

**Parse from user request:**
- User name, email, or ID (required)

**MCP Tool Call:**
Use `slack_get_users` or equivalent MCP tool

**Response:**

```
OK User information:

Name: John Doe
Username: @john.doe
Email: john.doe@company.com
User ID: U01234567
Status: Active
```

## Response Format

### Success - Read Operations

```
OK {Operation} complete

{Details}
```

### Success - Write Operations

```
OK {Action}: "{target}"

{Details}
Backend: Slack MCP
```

### Error

```
X Failed to {operation}

Error: {error message}
Backend: Slack MCP

Suggestions:
- {suggestion 1}
- {suggestion 2}
```

## Message Formatting

Slack supports special formatting:

```
*bold*           -> bold
_italic_         -> italic
~strikethrough~  -> strikethrough
`code`           -> code
```code block``` -> code block
<URL|text>       -> hyperlink
<@USER_ID>       -> mention user
<#CHANNEL_ID>    -> mention channel
:emoji_name:     -> emoji
```

---

# Error Handling

## Common Issues

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

**"rate_limited" error:**
- Slack API has rate limits (varies by endpoint)
- If hitting limits, wait and retry

**MCP not loading:**
- Check JSON syntax in config file
- Verify Node.js is accessible
- Run `npx @modelcontextprotocol/server-slack` manually to check for errors

**MCP tools not available:**
- Claude Code may need restart
- Check .mcp.json configuration

## Error Table

| Error               | Cause                     | Solution                              |
| ------------------- | ------------------------- | ------------------------------------- |
| `invalid_auth`      | Bad bot token             | Check token starts with xoxb-, regenerate |
| `missing_scope`     | Insufficient permissions  | Add scopes, reinstall app             |
| `channel_not_found` | Wrong channel or no access| Verify channel name, invite bot       |
| `not_in_channel`    | Bot not in private channel| Use /invite @BotName                  |
| `team_not_found`    | Wrong Team ID             | Verify Team ID from workspace URL     |
| `rate_limited`      | Too many requests         | Wait and retry                        |
| `MCP not available` | Server not running        | Restart Claude Code                   |

## Interactive Checkpoints

### Setup Mode Checkpoints

#### Mode Selection
- [ ] "Which setup mode: Full Setup (local MCP server) or Connect Only (existing server)?"

#### Path A (Full Setup) Checkpoints
- [ ] "Node.js verified. Do you have access to a Slack workspace?"
- [ ] "Do you have bot credentials, or should I guide you through creating a Slack App?"
- [ ] "I have the Bot Token and Team ID. Ready to configure MCP?"
- [ ] "Configuration written. Ready to restart Claude Code?"

#### Path B (Connect Only) Checkpoints
- [ ] "What type of connection does the existing server use?"
- [ ] "I have the connection details. Ready to configure MCP?"
- [ ] "Configuration written. Ready to restart Claude Code?"

#### Final Verification (Both Paths)
- [ ] "Channels listed / test message sent. Did you verify it in Slack?"
- [ ] "Would you like me to delete the test message (if applicable)?"

**Definition of Done (Setup):** Only mark setup as complete when user confirms seeing channels listed or the test message in Slack.

### Operations Mode Checkpoints
- [ ] Confirm before sending messages (optional, can be skipped)
- [ ] Confirm before sending to new channels (recommended)

## Usage Examples

**Check status / setup if needed:**
```
/slack
```

**List channels:**
```
/slack list channels
```

**Send a message:**
```
/slack send to #engineering: "Build completed!"
```

**Reply to a thread:**
```
/slack reply to thread 1705234567.123456 in #engineering: "Thanks for the update"
```

**Send a DM:**
```
/slack dm @john.doe: "Can you review the PR?"
```

**Add a reaction:**
```
/slack react :thumbsup: to message 1705234567.123456 in #engineering
```

## Related Skills

- `/slack-disable` - Remove Slack configuration (if still available)
