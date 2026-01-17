# Slack App Setup Guide

Step-by-step instructions for creating a Slack app for MCP integration.

## Step 1: Create New Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **"Create New App"**
3. Choose **"From scratch"**
4. Enter app details:
   - **App Name**: `Claude MCP Bot` (or your preferred name)
   - **Workspace**: Select your target workspace
5. Click **"Create App"**

## Step 2: Configure Bot Permissions

1. In the left sidebar, click **"OAuth & Permissions"**
2. Scroll to **"Scopes"** section
3. Under **"Bot Token Scopes"**, add these permissions:

| Scope           | Purpose                                      |
| --------------- | -------------------------------------------- |
| `channels:read` | View basic information about public channels |
| `chat:write`    | Send messages as the bot                     |
| `users:read`    | View people in the workspace                 |

**Optional scopes** (add if needed):
| Scope | Purpose |
|-------|---------|
| `channels:history` | View messages in public channels |
| `groups:read` | View private channels the bot is in |
| `groups:write` | Manage private channels |
| `im:read` | View direct messages |
| `im:write` | Send direct messages |
| `files:read` | View files shared in channels |
| `files:write` | Upload files |
| `reactions:read` | View emoji reactions |
| `reactions:write` | Add emoji reactions |

## Step 3: Install App to Workspace

1. Scroll to top of **"OAuth & Permissions"** page
2. Click **"Install to Workspace"**
3. Review permissions and click **"Allow"**
4. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

**Important:** Keep this token secure. Never commit it to version control.

## Step 4: Get Team ID

1. Open Slack in a web browser
2. Go to your workspace
3. The URL will be: `https://app.slack.com/client/TXXXXXXXX/...`
4. The `TXXXXXXXX` part is your **Team ID**

Alternative method:

1. In Slack app settings, go to **"Basic Information"**
2. Look for **"App ID"** section
3. Team ID is shown there

## Step 5: Invite Bot to Channel

Before the bot can post to a channel:

1. Open the target channel in Slack
2. Type `/invite @YourBotName`
3. Or click the channel name → "Integrations" → "Add apps"

**Note:** For private channels, the bot must be explicitly invited.

## Step 6: Verify Setup

You should now have:

- [ ] Bot User OAuth Token (`xoxb-...`)
- [ ] Team ID (`T...`)
- [ ] Bot invited to target channel

## Troubleshooting

### "missing_scope" Error

- Go back to OAuth & Permissions
- Add the missing scope
- Reinstall the app (new token will be generated)

### "channel_not_found" Error

- Ensure bot is invited to the channel
- Use channel ID instead of name (starts with `C`)
- Find channel ID: right-click channel → "View channel details" → scroll to bottom

### "invalid_auth" Error

- Token may have been revoked
- Regenerate token in OAuth & Permissions
- Update your MCP configuration with new token

### Bot Can't See Messages

- Add `channels:history` scope for public channels
- Add `groups:history` scope for private channels
- Reinstall app after adding scopes

## Security Best Practices

1. **Minimal Permissions**: Only request scopes you actually need
2. **Token Storage**: Use environment variables, never hardcode
3. **Rotation**: Rotate tokens periodically
4. **Audit**: Review app activity in Slack admin panel
5. **Revocation**: Know how to revoke tokens if compromised

## Quick Reference

| Item       | Format     | Example            |
| ---------- | ---------- | ------------------ |
| Bot Token  | `xoxb-...` | `xoxb-123-456-abc` |
| Team ID    | `T...`     | `T01ABC23DEF`      |
| Channel ID | `C...`     | `C04XYZ789AB`      |
| User ID    | `U...`     | `U02DEF456GH`      |
