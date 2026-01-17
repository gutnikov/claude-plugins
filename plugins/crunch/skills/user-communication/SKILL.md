---
name: user-communication
description: Unified communication skill. Reads CLAUDE.md to detect configured messenger platforms (Slack, Telegram) and performs send/read/list operations using the appropriate MCP tools.
---

# User Communication Skill

This skill provides a unified interface for communicating with users across different messaging platforms by detecting the configured backend from CLAUDE.md and routing operations to the appropriate MCP tools.

## How It Works

1. **Read CLAUDE.md** to detect which communication platforms are configured
2. **Determine the backend** (Slack or Telegram)
3. **Execute the requested operation** using the appropriate MCP tools
4. **Return results** in a consistent format

## Supported Backends

| Backend      | Detection                        | Primary Use                        |
| ------------ | -------------------------------- | ---------------------------------- |
| **Slack**    | `## MCP Servers` → `### Slack`   | Team messaging, channel notifications |
| **Telegram** | `## MCP Servers` → `### Telegram`| Direct messaging, bot notifications |

## Supported Operations

| Operation         | Description                                        | Example                                   |
| ----------------- | -------------------------------------------------- | ----------------------------------------- |
| **Send**          | Send a message to a channel/user/chat              | "send 'deploy complete' to #releases"     |
| **Notify**        | Send a notification (may use different formatting) | "notify the team about the outage"        |
| **List Channels** | List available channels/chats                      | "what channels can I post to?"            |
| **Read**          | Read recent messages from a channel/chat           | "show recent messages in #general"        |
| **Reply**         | Reply to a specific message/thread                 | "reply to that thread with 'fixed'"       |
| **React**         | Add a reaction/emoji to a message                  | "react with thumbsup to the last message" |

## Workflow

### Phase 1: Detect Backend

1. **Read CLAUDE.md from project root**

   ```bash
   cat CLAUDE.md
   ```

2. **Parse for communication platform configuration**
   Look for these sections:

   a. **Slack**

   ```markdown
   ## MCP Servers

   ### Slack

   - **Status**: Configured
   - **Workspace**: mycompany.slack.com
   - **Capabilities**: Send messages, list channels, read users
   ```

   b. **Telegram**

   ```markdown
   ## MCP Servers

   ### Telegram

   - **Status**: Configured
   - **Bot username**: @my_project_bot
   - **Capabilities**: Send messages, receive updates, manage chats
   ```

3. **If no backend detected**
   - Inform user: "No communication platform configured in CLAUDE.md"
   - Suggest running one of the setup skills:
     - `setup-slack` for team/channel-based messaging
     - `setup-telegram` for bot-based direct messaging
   - Ask if they want to set one up now

4. **If multiple backends configured**
   - List available platforms
   - Ask user which one to use OR
   - Use context clues (e.g., "post to Slack" vs "send via Telegram")

### Phase 2: Parse User Request

Understand what operation the user wants:

| Intent            | Keywords                                 | Platform Hints              |
| ----------------- | ---------------------------------------- | --------------------------- |
| **Send message**  | send, post, message, tell, notify, alert | channel (#), @user, chat ID |
| **List targets**  | list channels, show chats, where can I   | -                           |
| **Read messages** | read, show, get messages, what's new     | channel, chat               |
| **Reply**         | reply, respond, answer, thread           | thread, message             |

**Extract from request:**

- Operation type
- Target (channel, user, chat ID)
- Content (message text)
- Options (thread, urgency, formatting)

### Phase 3: Execute Operation

Based on detected backend, use the appropriate MCP tools:

---

## Backend: Slack MCP

**Available MCP Tools (typical):**

- `slack_list_channels` - List available channels
- `slack_post_message` - Send a message to a channel
- `slack_get_channel_history` - Read messages from a channel
- `slack_get_users` - List workspace users
- `slack_add_reaction` - Add emoji reaction

### Send Message

```
User: "send 'Deployment complete!' to #releases"

→ Parse: operation=send, target=#releases, content="Deployment complete!"
→ MCP: slack_post_message(channel="releases", text="Deployment complete!")
→ Response: ✓ Message sent to #releases
```

**With formatting:**

```
User: "notify #alerts about the database issue with high priority"

→ Parse: operation=notify, target=#alerts, content="database issue", priority=high
→ MCP: slack_post_message(
   channel="alerts",
   text="🚨 *Alert*: database issue",
   blocks=[...rich formatting...]
 )
```

### List Channels

```
User: "what Slack channels can I post to?"

→ MCP: slack_list_channels()
→ Response:
 Available Slack channels:
 - #general (public)
 - #engineering (public)
 - #releases (public)
 - #alerts (private)
```

### Read Messages

```
User: "show me recent messages in #general"

→ MCP: slack_get_channel_history(channel="general", limit=10)
→ Response:
 Recent messages in #general:

 [10:30] @alice: Good morning team!
 [10:35] @bob: Morning! Ready for standup?
 [10:40] @alice: Yes, let's do it
```

### Reply to Thread

```
User: "reply to that thread saying 'I'll take a look'"

→ Context: previous message had thread_ts
→ MCP: slack_post_message(
   channel="general",
   text="I'll take a look",
   thread_ts="1234567890.123456"
 )
```

### Add Reaction

```
User: "react with 👍 to the last message"

→ MCP: slack_add_reaction(
   channel="general",
   timestamp="1234567890.123456",
   emoji="thumbsup"
 )
```

---

## Backend: Telegram MCP

**Available MCP Tools (typical):**

- `telegram_get_me` - Get bot info
- `telegram_send_message` - Send a message to a chat
- `telegram_get_updates` - Get incoming messages/updates
- `telegram_send_photo` - Send a photo
- `telegram_send_document` - Send a file

### Send Message

```
User: "send 'Build completed successfully!' to chat 123456789"

→ Parse: operation=send, target=123456789, content="Build completed successfully!"
→ MCP: telegram_send_message(chat_id=123456789, text="Build completed successfully!")
→ Response: ✓ Message sent to chat 123456789
```

**With formatting:**

```
User: "notify the user about deployment with markdown"

→ MCP: telegram_send_message(
   chat_id=123456789,
   text="*Deployment Complete* ✅\n\nVersion: `v2.1.0`\nEnvironment: Production",
   parse_mode="Markdown"
 )
```

### Send to Default Chat

If a default chat ID is configured in CLAUDE.md:

```
User: "notify that the tests passed"

→ Reads default chat from CLAUDE.md
→ MCP: telegram_send_message(chat_id=<default>, text="✅ Tests passed!")
→ Response: ✓ Notification sent via Telegram
```

### Get Bot Info

```
User: "what's my Telegram bot?"

→ MCP: telegram_get_me()
→ Response:
 Telegram Bot Info:
 - Username: @my_project_bot
 - Name: My Project Bot
 - Can join groups: Yes
```

### Read Updates

```
User: "show recent Telegram messages"

→ MCP: telegram_get_updates(limit=10)
→ Response:
 Recent Telegram messages:

 [10:30] User 123456789: Hello bot!
 [10:35] User 123456789: Any updates?
 [10:40] User 987654321: /start
```

### Reply to Message

```
User: "reply 'Working on it!' to the last message"

→ Context: previous message_id
→ MCP: telegram_send_message(
   chat_id=123456789,
   text="Working on it!",
   reply_to_message_id=<message_id>
 )
```

### Send Media

```
User: "send the screenshot to Telegram"

→ MCP: telegram_send_photo(
   chat_id=123456789,
   photo="<file_path_or_url>",
   caption="Here's the screenshot"
 )
```

---

## Message Formatting

### Standard Formatting

The skill should adapt formatting based on platform:

| Format      | Slack         | Telegram (Markdown)    |
| ----------- | ------------- | ---------------------- |
| **Bold**    | `*text*`      | `*text*`               |
| **Italic**  | `_text_`      | `_text_`               |
| **Code**    | `` `code` ``  | `` `code` ``           |
| **Link**    | `<url\|text>` | `[text](url)`          |
| **Mention** | `<@USER>`     | (by username or reply) |

### Priority/Urgency Indicators

```
User: "send urgent message to #alerts"

→ Adds urgency formatting:
 - Slack: 🚨 emoji, @channel mention
 - Telegram: 🚨 emoji, bold text, optional notification sound
```

---

## Interactive Behavior

### When Platform Not Detected

```
I couldn't find a communication platform configured in CLAUDE.md.

Would you like to set one up?
1. Slack - Team messaging with channels (run `setup-slack`)
2. Telegram - Bot-based direct messaging (run `setup-telegram`)
```

### When Multiple Platforms Configured

```
I found multiple communication platforms configured:
1. Slack - #general, #engineering, #alerts
2. Telegram - @my_project_bot (chat 123456789)

Which platform should I use? Or specify in your request
(e.g., "post to Slack #general" or "send via Telegram")
```

### When Target Ambiguous

```
User: "send a message about the deployment"

→ Multiple targets available:
 - Slack: #deployments, #releases, #engineering
 - Telegram: Default chat 123456789

Which target should I send to?
```

### Confirmation for Broad Messages

```
User: "notify everyone about the maintenance"

⚠️ This will send to:
- Slack: @channel in #announcements (52 members)

This is a broad notification. Proceed? (yes/no)
```

---

## Response Format

### Success - Send (Slack)

```
✓ Message sent

Platform: Slack
Target: #releases
Content: "Deployment complete! 🚀"
Timestamp: 2024-01-15 10:30:00
```

### Success - Send (Telegram)

```
✓ Message sent

Platform: Telegram
Bot: @my_project_bot
Chat ID: 123456789
Content: "Build succeeded!"
Message ID: 456
```

### Success - List

```
✓ Available channels

Platform: Slack
Channels:
 Public:
   - #general (450 members)
   - #engineering (28 members)
   - #releases (15 members)
 Private:
   - #alerts (5 members)

Total: 4 channels
```

### Error

```
✗ Failed to send message

Platform: Slack
Target: #nonexistent
Error: Channel not found

Suggestions:
- Check channel name spelling
- Use /list-channels to see available channels
- You may need to be invited to private channels
```

---

## Context Awareness

The skill should maintain context for follow-up operations:

### Thread Context (Slack)

```
User: "send 'Looking into the bug' to #engineering"
→ Message sent, store thread context

User: "add that I found the issue"
→ Recognizes follow-up, replies in same thread
→ "Found the issue - it's a null pointer in the auth module"
```

### Chat Context (Telegram)

```
User: "send 'Starting deployment' to Telegram"
→ Message sent, store chat context

User: "update them that it's done"
→ Recognizes context, sends follow-up to same chat
→ "Deployment complete!"
```

### Channel Context

```
User: "check messages in #alerts"
→ Shows messages, store channel context

User: "reply to the last one"
→ Knows which channel and message to reply to
```

---

## Error Handling

### Slack-Specific Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `channel_not_found` | Channel doesn't exist | Check spelling, list channels |
| `not_in_channel` | Bot not in private channel | Invite bot to channel |
| `rate_limited` | Too many requests | Wait and retry |
| `invalid_auth` | Token expired/invalid | Re-run setup-slack |

### Telegram-Specific Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `chat not found` | Invalid chat ID | Verify chat ID, user must /start |
| `bot was blocked` | User blocked the bot | User needs to unblock |
| `Unauthorized` | Invalid bot token | Re-run setup-telegram |
| `Bad Request` | Invalid parameters | Check message format |

### General Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `MCP not available` | Server not running | Restart Claude Code |
| `timeout` | Network/server issue | Check connectivity |

---

## Usage Examples

### Simple Slack message

```
User: "tell #engineering that the build is fixed"
→ Detects Slack
→ Sends: "The build is fixed" to #engineering
→ ✓ Message sent
```

### Simple Telegram message

```
User: "send 'Tests passed!' via Telegram"
→ Detects Telegram
→ Sends to configured chat
→ ✓ Message sent
```

### Platform-specific request

```
User: "post to Slack #releases that v2.0 is out"
→ Explicitly uses Slack
→ Sends: "v2.0 is out" to #releases
→ ✓ Message sent
```

### Broadcast to multiple platforms

```
User: "announce that v2.0 is released"
→ Multiple platforms detected
→ Asks: "Send to Slack #announcements, Telegram, or both?"
→ User: "both"
→ Sends to Slack and Telegram
→ ✓ Announced on 2 platforms
```

### Read and respond

```
User: "what's the latest in #alerts?"
→ Shows recent messages
→ User: "respond that I'm on it"
→ Replies in thread: "I'm on it"
→ ✓ Reply sent
```
