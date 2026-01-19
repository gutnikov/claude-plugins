## Communication

**Platform**: {platform}
**Integration**: {integration_type}

### Configuration

| Setting | Value |
|---------|-------|
| Bot Name | {bot_name} |
| Channels | {channel_list} |
| Permissions | {permissions} |

### Available Operations

| Operation | Description |
|-----------|-------------|
| Send message | Post to channels |
| Send DM | Direct message users |
| Read history | Get channel history |
| React | Add reactions to messages |
| Thread reply | Reply in threads |
| Upload file | Share files |

### Channels

| Channel | Purpose | Notifications |
|---------|---------|---------------|
| #{channel_1} | {purpose_1} | {notification_setting} |
| #{channel_2} | {purpose_2} | {notification_setting} |

### Usage Examples

```
"Post a message to #{channel} about the deployment"
"DM @{user} about the code review"
"Get the last 10 messages from #{channel}"
"React with :+1: to the last message"
```

### Notification Rules

| Event | Channel | Format |
|-------|---------|--------|
| Deploy success | #{deploy_channel} | Status update |
| Build failure | #{alerts_channel} | Alert with details |
| PR merged | #{dev_channel} | Info message |

### Bot Commands

| Command | Description |
|---------|-------------|
| `/status` | Get project status |
| `/deploy {env}` | Trigger deployment |
| `/help` | Show available commands |
