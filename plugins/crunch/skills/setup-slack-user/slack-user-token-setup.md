# Slack User Token Setup Guide

Step-by-step instructions for obtaining a Slack User OAuth Token (xoxp) for use with the Slack MCP server.

## Overview

### What is a User Token?

A **User OAuth Token** (xoxp-...) represents a specific user's access to Slack. It allows actions on behalf of that user, including:

- Reading all channels the user can access
- Posting messages as the user
- Searching messages across the workspace
- Reading threads and DMs

### User Token vs Bot Token

| Aspect | User Token (xoxp) | Bot Token (xoxb) |
|--------|-------------------|------------------|
| Identity | Acts as you | Acts as a bot |
| Channel Access | All your channels | Only invited channels |
| Message Search | Full search API | Not available |
| Permissions | User-level OAuth | Workspace admin approval |
| Thread Access | Full access | Limited |
| Sensitivity | High (treat as password) | Medium |

## Prerequisites

- A Slack account in the workspace you want to connect
- Ability to create Slack Apps (usually available to all workspace members)

## Step 1: Create a Slack App

1. **Go to the Slack API portal**
   - Open https://api.slack.com/apps
   - Sign in with your Slack account if prompted

2. **Create a new app**
   - Click **"Create New App"**
   - Choose **"From scratch"**

3. **Configure app basics**
   - **App Name**: Choose a descriptive name (e.g., "Claude MCP Integration")
   - **Workspace**: Select your target workspace
   - Click **"Create App"**

## Step 2: Configure OAuth Scopes

1. **Navigate to OAuth settings**
   - In the left sidebar, click **"OAuth & Permissions"**

2. **Scroll to "User Token Scopes"**
   - This is in the **Scopes** section
   - Do NOT use "Bot Token Scopes" - we need user scopes

3. **Add the following scopes**
   Click "Add an OAuth Scope" for each:

   **Required scopes:**

   | Scope | Description |
   |-------|-------------|
   | `channels:history` | View messages in public channels |
   | `channels:read` | View public channel info and list |
   | `groups:history` | View messages in private channels |
   | `groups:read` | View private channel info and list |
   | `im:history` | View direct message history |
   | `im:read` | View direct message info |
   | `mpim:history` | View group DM history |
   | `mpim:read` | View group DM info |
   | `users:read` | View user information |
   | `search:read` | Search messages and files |

   **Optional but recommended:**

   | Scope | Description |
   |-------|-------------|
   | `chat:write` | Post messages as yourself |
   | `reactions:read` | View emoji reactions |
   | `reactions:write` | Add emoji reactions |
   | `files:read` | View files shared in channels |

## Step 3: Install the App

1. **Scroll to the top of OAuth & Permissions**
   - Find the **"OAuth Tokens for Your Workspace"** section

2. **Click "Install to Workspace"**
   - You'll see a permission request screen
   - Review the permissions being requested

3. **Click "Allow"**
   - This authorizes the app to access your Slack data

4. **Copy the User OAuth Token**
   - After installation, you'll see **"User OAuth Token"**
   - It starts with `xoxp-`
   - Click **"Copy"** to copy it to your clipboard

   ```
   xoxp-XXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

   **IMPORTANT**: This token is like a password. Never share it or commit it to git.

## Step 4: Verify Your Token

You can verify the token works by running this curl command:

```bash
curl -s -H "Authorization: Bearer xoxp-YOUR-TOKEN-HERE" \
  https://slack.com/api/auth.test | jq
```

Expected response:

```json
{
  "ok": true,
  "url": "https://yourworkspace.slack.com/",
  "team": "Your Workspace",
  "user": "your.name",
  "team_id": "T01234567",
  "user_id": "U01234567"
}
```

## Step 5: Use with Slack MCP Server

Configure your `.mcp.json` with the token:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server"],
      "env": {
        "SLACK_MCP_XOXP_TOKEN": "xoxp-your-token-here",
        "SLACK_MCP_ADD_MESSAGE_TOOL": "true"
      }
    }
  }
}
```

## Security Best Practices

### DO:

- Store the token in `.mcp.json` which is gitignored
- Use a secrets manager (Vault, SOPS) for team environments
- Revoke the token if compromised
- Periodically review app permissions
- Use separate apps for different purposes

### DON'T:

- Commit tokens to git (ever!)
- Share tokens via Slack, email, or chat
- Use production tokens in development
- Keep tokens for apps you no longer use

## Token Management

### Viewing Your Token

1. Go to https://api.slack.com/apps
2. Select your app
3. Go to "OAuth & Permissions"
4. Your token is under "User OAuth Token"

### Revoking a Token

If your token is compromised:

1. Go to https://api.slack.com/apps
2. Select your app
3. Go to "OAuth & Permissions"
4. Click **"Revoke Token"** (or uninstall the app)

After revoking, you'll need to reinstall the app to get a new token.

### Token Expiration

User OAuth tokens do **not** automatically expire, but they can become invalid if:

- The app is uninstalled from the workspace
- The token is explicitly revoked
- The user is deactivated
- Scopes are modified (may require re-authorization)

## Troubleshooting

### "invalid_auth" Error

- Token is invalid, expired, or revoked
- Double-check you copied the entire token
- Try revoking and reinstalling the app

### "missing_scope" Error

- The token doesn't have a required permission
- Go to OAuth & Permissions → User Token Scopes
- Add the missing scope
- Reinstall the app to update the token

### "not_in_channel" Error

- You're trying to access a channel you're not a member of
- Join the channel first, or use a channel you're in

### "account_inactive" Error

- Your Slack account has been deactivated
- Contact your workspace admin

## Reference: All Available User Scopes

For a complete list of available user token scopes, see:
https://api.slack.com/scopes

Common scope categories:

- `channels:*` - Public channels
- `groups:*` - Private channels
- `im:*` - Direct messages
- `mpim:*` - Group direct messages
- `chat:*` - Posting messages
- `files:*` - File access
- `search:*` - Search functionality
- `users:*` - User information
- `reactions:*` - Emoji reactions
