---
name: slack-use
description: Slack messaging skill. Sends messages to channels, DMs, and threads using Slack MCP by detecting configuration from CLAUDE.md.
---

# Use Slack

This skill provides a unified interface for Slack messaging operations by detecting the configuration from CLAUDE.md and executing the appropriate MCP tool calls.

## How It Works

1. **Read CLAUDE.md** to detect Slack configuration
2. **Verify MCP connection** to Slack
3. **Execute the requested operation** via MCP tools
4. **Return results** in a consistent format

## Backend Detection

**Read CLAUDE.md from project root and look for:**

```markdown
## Communication

### Slack

- **Status**: Configured
- **Setup mode**: Full Setup
- **Config location**: .mcp.json
```

**If Slack not detected:**

- Inform user: "No Slack configuration found in CLAUDE.md"
- Suggest running setup: "Would you like to set up Slack? Run `/slack-enable`"

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
1. Run `/slack-enable` to set up Slack MCP
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

## Error Handling

### Common Issues

**"invalid_auth" error:**
- Bot token is invalid or expired
- Regenerate token from Slack API portal

**"channel_not_found" error:**
- Channel doesn't exist or bot doesn't have access
- Check channel name/ID is correct
- Invite bot to the channel

**"not_in_channel" error:**
- Bot hasn't been invited to a private channel
- Use `/invite @BotName` in the target channel

**"missing_scope" error:**
- Bot doesn't have required permissions
- Add missing scopes in Slack API portal

**"rate_limited" error:**
- Too many requests to Slack API
- Wait and retry

**MCP tools not available:**
- Claude Code may need restart
- Check .mcp.json configuration

### Error Table

| Error               | Cause                     | Solution                              |
| ------------------- | ------------------------- | ------------------------------------- |
| `invalid_auth`      | Bad bot token             | Regenerate token                      |
| `channel_not_found` | Wrong channel or no access| Verify channel, invite bot            |
| `not_in_channel`    | Bot not in private channel| Use /invite @BotName                  |
| `missing_scope`     | Insufficient permissions  | Add scopes, reinstall app             |
| `rate_limited`      | Too many requests         | Wait and retry                        |
| `MCP not available` | Server not running        | Restart Claude Code                   |

## Interactive Checkpoints

- [ ] Confirm before sending messages (optional, can be skipped)
- [ ] Confirm before sending to new channels (recommended)

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

## Usage Examples

**List channels:**
```
/slack-use list channels
```

**Send a message:**
```
/slack-use send to #engineering: "Build completed!"
```

**Reply to a thread:**
```
/slack-use reply to thread 1705234567.123456 in #engineering: "Thanks for the update"
```

**Send a DM:**
```
/slack-use dm @john.doe: "Can you review the PR?"
```

**Add a reaction:**
```
/slack-use react :thumbsup: to message 1705234567.123456 in #engineering
```

## Related Skills

- `/slack-enable` - Set up Slack MCP
- `/slack-disable` - Remove Slack configuration
