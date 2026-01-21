---
name: user-communication
description: Two-way communication with users via configured messaging vendor. Supports DM and group chat modes with polling-based message fetching.
arguments:
  - name: mode
    required: true
    description: "Communication mode: 'dm' for direct message or 'channel' for group chat"
  - name: target
    required: true
    description: "Target identifier: user ID/name for DM mode, channel ID/name for channel mode"
  - name: context
    required: false
    description: "Optional context string to include in initial message"
---

# User Communication

A utility skill for two-way communication with users through the configured messaging vendor (Slack, Discord, Teams, etc.).

## Purpose

This skill enables Claude to have conversations with users outside of the CLI:
- Gather requirements or clarifications asynchronously
- Collaborate with multiple stakeholders in a channel
- Get approvals or feedback on proposals
- Conduct surveys or interviews

## Prerequisites

The **User Communication Bot** domain must be configured in CLAUDE.md with a vendor. Check configuration:

```bash
grep -A 10 "## User Communication Bot" CLAUDE.md
grep -A 5 "### Vendor:" CLAUDE.md | head -10
```

If not configured, run `/setup-domain-vendor user-communication-bot` first.

---

## Arguments

| Argument  | Required | Description                                                    |
|-----------|----------|----------------------------------------------------------------|
| `mode`    | Yes      | `dm` for direct message, `channel` for group chat              |
| `target`  | Yes      | User ID/name (dm mode) or channel ID/name (channel mode)       |
| `context` | No       | Context to include in opening message                          |

**Examples:**
- `/user-communication dm @john.doe "Need clarification on auth requirements"`
- `/user-communication channel #project-team "Gathering feedback on API design"`

---

## Communication Modes

### DM Mode (1-1)

Direct conversation between Claude and a single user.

| Aspect          | Behavior                                          |
|-----------------|---------------------------------------------------|
| Target          | User ID, username, or email                       |
| Participants    | Claude bot + 1 user                               |
| Use case        | Private clarifications, sensitive topics          |
| Message fetch   | DM history with that user                         |

### Channel Mode (Group Chat)

Conversation in a shared channel with multiple participants.

| Aspect          | Behavior                                          |
|-----------------|---------------------------------------------------|
| Target          | Channel ID or name                                |
| Participants    | Claude bot + all channel members                  |
| Use case        | Group decisions, team feedback, announcements     |
| Message fetch   | Channel history (may filter by thread)            |

---

## Workflow

### Phase 1: Validate Prerequisites

#### Step 1.1: Check Domain Configuration

```bash
grep -A 20 "## User Communication Bot" CLAUDE.md
```

**If not configured:**

```
User Communication Bot is not configured.

Run `/setup-domain-vendor user-communication-bot` to configure a messaging vendor.
```

Exit skill.

#### Step 1.2: Extract Vendor Information

Parse CLAUDE.md to get:
- Vendor name (Slack, Discord, etc.)
- Available operations
- Required environment/config

```typescript
const vendorInfo = {
  name: "Slack",                    // From "### Vendor: Slack"
  send_message: "slack_post_message",      // MCP tool or CLI command
  send_dm: "slack_post_message",           // With user channel
  get_history: "slack_get_channel_history", // MCP tool or CLI command
  get_user: "slack_get_users"              // To resolve user IDs
};
```

---

### Phase 2: Initialize Conversation

#### Step 2.1: Resolve Target

**For DM mode:**

```typescript
// Resolve user to get DM channel
if (mode === 'dm') {
  // Use vendor's user lookup
  const user = await vendor.getUser(target);  // by name, email, or ID
  const dmChannel = await vendor.openDM(user.id);
  conversationId = dmChannel.id;
}
```

**For channel mode:**

```typescript
if (mode === 'channel') {
  // Resolve channel name to ID if needed
  const channel = await vendor.getChannel(target);
  conversationId = channel.id;
}
```

#### Step 2.2: Send Opening Message

Compose and send initial message:

```typescript
const openingMessage = buildOpeningMessage(context, mode);

await vendor.sendMessage({
  channel: conversationId,
  text: openingMessage
});
```

**Opening message template:**

```markdown
**[Claude Code]** Starting conversation.

{context if provided}

I'll monitor this conversation for your responses. Reply here and I'll process your messages.

_Type "done" when finished, or "cancel" to abort._
```

#### Step 2.3: Record Conversation State

Store state for polling:

```typescript
const conversationState = {
  id: conversationId,
  mode: mode,
  target: target,
  vendor: vendorInfo.name,
  started_at: new Date().toISOString(),
  last_message_ts: openingMessage.ts,  // Track last seen message
  messages: []
};
```

---

### Phase 3: Polling Loop

#### Step 3.1: Fetch New Messages

Poll for new messages since last check:

```typescript
async function pollMessages(state) {
  const history = await vendor.getHistory({
    channel: state.id,
    oldest: state.last_message_ts,
    limit: 20
  });

  // Filter to messages after our last seen
  const newMessages = history.messages.filter(
    m => m.ts > state.last_message_ts && !m.bot_id
  );

  return newMessages;
}
```

#### Step 3.2: Process Messages

For each new message:

```typescript
for (const message of newMessages) {
  // Update last seen timestamp
  state.last_message_ts = message.ts;

  // Check for control commands
  if (message.text.toLowerCase() === 'done') {
    return { action: 'complete', messages: state.messages };
  }
  if (message.text.toLowerCase() === 'cancel') {
    return { action: 'cancel' };
  }

  // Store message
  state.messages.push({
    user: message.user,
    text: message.text,
    ts: message.ts
  });

  // Acknowledge receipt (optional)
  await vendor.addReaction({
    channel: state.id,
    timestamp: message.ts,
    emoji: 'eyes'
  });
}
```

#### Step 3.3: Present to Caller

Return new messages to the calling skill:

```typescript
return {
  action: 'continue',
  new_messages: newMessages.map(m => ({
    from: m.user_name || m.user,
    text: m.text,
    timestamp: m.ts
  }))
};
```

---

### Phase 4: Send Response

When the calling skill needs to respond:

#### Step 4.1: Send Message

```typescript
async function sendMessage(state, text, options = {}) {
  const result = await vendor.sendMessage({
    channel: state.id,
    text: text,
    thread_ts: options.thread_ts  // Optional: reply in thread
  });

  return {
    sent: true,
    timestamp: result.ts
  };
}
```

#### Step 4.2: Message Formatting

Format messages appropriately for the vendor:

```typescript
function formatMessage(text, vendor) {
  // Vendor-specific formatting
  switch (vendor) {
    case 'Slack':
      // Slack uses *bold*, _italic_, `code`
      return text;
    case 'Discord':
      // Discord uses **bold**, *italic*, `code`
      return text.replace(/\*([^*]+)\*/g, '**$1**');
    case 'Teams':
      // Teams uses **bold**, _italic_
      return text;
    default:
      return text;
  }
}
```

---

### Phase 5: Complete Conversation

#### Step 5.1: Send Closing Message

```typescript
async function closeConversation(state, summary) {
  await vendor.sendMessage({
    channel: state.id,
    text: `**[Claude Code]** Conversation complete.\n\n${summary || 'Thank you for the responses!'}`
  });
}
```

#### Step 5.2: Return Collected Data

Return all collected messages to the caller:

```typescript
return {
  status: 'complete',
  mode: state.mode,
  target: state.target,
  duration: calculateDuration(state.started_at),
  messages: state.messages,
  summary: generateSummary(state.messages)
};
```

---

## API for Calling Skills

Skills that invoke user-communication should use this interface:

### Start Conversation

```yaml
invoke: user-communication
operation: start
mode: "dm"                    # or "channel"
target: "@john.doe"           # user or channel
context: "Clarifying auth requirements for the API"
```

**Response:**

```yaml
status: "started"
conversation_id: "D01234567"
mode: "dm"
target: "@john.doe"
```

### Poll for Messages

```yaml
invoke: user-communication
operation: poll
conversation_id: "D01234567"
```

**Response:**

```yaml
status: "continue"            # or "complete" or "cancel"
new_messages:
  - from: "john.doe"
    text: "We need OAuth2 with PKCE flow"
    timestamp: "1705234567.123456"
```

### Send Message

```yaml
invoke: user-communication
operation: send
conversation_id: "D01234567"
text: "Got it. Should we support refresh tokens?"
```

**Response:**

```yaml
status: "sent"
timestamp: "1705234570.654321"
```

### Close Conversation

```yaml
invoke: user-communication
operation: close
conversation_id: "D01234567"
summary: "Decided on OAuth2 with PKCE, refresh tokens enabled"
```

---

## Vendor Operation Mapping

Maps skill operations to vendor-specific implementations:

| Skill Operation | Slack                      | Discord              | Teams                |
|-----------------|----------------------------|----------------------|----------------------|
| Get user        | `slack_get_users`          | Get user by ID       | Graph API user lookup|
| Open DM         | Open DM channel            | Create DM channel    | Create chat          |
| Get channel     | `slack_list_channels`      | Get channel          | Get channel          |
| Send message    | `slack_post_message`       | Send message         | Send message         |
| Get history     | `slack_get_channel_history`| Get messages         | Get messages         |
| Add reaction    | `slack_add_reaction`       | Add reaction         | Add reaction         |

---

## Error Handling

| Error                       | Cause                              | Recovery                          |
|-----------------------------|------------------------------------|-----------------------------------|
| User not found              | Invalid user ID/name               | Ask caller to verify target       |
| Channel not found           | Invalid channel or no access       | Verify channel name, check access |
| Permission denied           | Bot lacks permissions              | Check bot scopes/permissions      |
| Rate limited                | Too many requests                  | Back off polling interval         |
| Vendor not configured       | Domain not set up                  | Run setup-domain-vendor first     |
| Connection lost             | Network or server issue            | Retry with exponential backoff    |

### Error Response Format

```yaml
status: "error"
error:
  code: "user_not_found"
  message: "Could not find user '@john.doe'"
  suggestion: "Verify the username or try using the user's email address"
```

---

## Polling Configuration

| Parameter        | Default | Description                                |
|------------------|---------|--------------------------------------------|
| `poll_interval`  | 5s      | Seconds between polls                      |
| `max_polls`      | 120     | Maximum polls before timeout (10 min)      |
| `idle_timeout`   | 300s    | Close if no messages for this long         |
| `batch_size`     | 20      | Messages to fetch per poll                 |

These can be adjusted by the calling skill:

```yaml
invoke: user-communication
operation: start
mode: "channel"
target: "#team"
config:
  poll_interval: 10
  idle_timeout: 600
```

---

## Example: Survey Flow

A skill using user-communication to gather requirements:

```typescript
// 1. Start conversation
const conv = await invoke('user-communication', {
  operation: 'start',
  mode: 'dm',
  target: '@product-owner',
  context: 'Gathering requirements for the new dashboard feature'
});

// 2. Send first question
await invoke('user-communication', {
  operation: 'send',
  conversation_id: conv.conversation_id,
  text: 'What are the top 3 metrics you want to see on the dashboard?'
});

// 3. Poll for response
let response;
while (true) {
  response = await invoke('user-communication', {
    operation: 'poll',
    conversation_id: conv.conversation_id
  });

  if (response.status === 'complete' || response.new_messages.length > 0) {
    break;
  }
  await sleep(5000);
}

// 4. Process response and continue
const metrics = parseMetrics(response.new_messages[0].text);

// 5. Send follow-up
await invoke('user-communication', {
  operation: 'send',
  conversation_id: conv.conversation_id,
  text: `Got it: ${metrics.join(', ')}. Should these update in real-time?`
});

// ... continue conversation ...

// 6. Close when done
await invoke('user-communication', {
  operation: 'close',
  conversation_id: conv.conversation_id,
  summary: 'Requirements gathered for dashboard feature'
});
```

---

## Interactive Checkpoints

| Phase | Checkpoint                                              |
|-------|---------------------------------------------------------|
| 1     | Validate vendor is configured                           |
| 2     | Confirm target is reachable, send opening message       |
| 3     | Process control commands (done/cancel)                  |
| 5     | Send closing message, return collected data             |

---

## Definition of Done

A conversation is complete when:

1. Opening message was sent successfully
2. User responded with "done" OR caller invoked close operation
3. Closing message was sent
4. All collected messages are returned to caller

A conversation is cancelled when:

1. User responded with "cancel"
2. Idle timeout reached
3. Max polls exceeded
4. Caller invoked close with cancel flag
