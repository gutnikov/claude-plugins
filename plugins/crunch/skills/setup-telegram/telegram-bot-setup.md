# Telegram Bot Setup Guide

Step-by-step instructions for creating a Telegram bot and obtaining the necessary credentials for MCP integration.

## Overview

Telegram bots are created through BotFather, Telegram's official bot for managing bots.

| Credential    | Purpose                  | Format                                               |
| ------------- | ------------------------ | ---------------------------------------------------- |
| **Bot Token** | Authenticates your bot   | `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`               |
| **Chat ID**   | Identifies where to send | Numeric ID (positive for users, negative for groups) |

## Step 1: Create a Bot with BotFather

1. **Open Telegram** and search for `@BotFather`
2. **Start a conversation** with BotFather (click Start or send `/start`)
3. **Create a new bot** by sending `/newbot`
4. **Choose a display name** for your bot
   - This is the name users will see
   - Example: `My Project Notifications`
5. **Choose a username** for your bot
   - Must be unique and end with `bot`
   - Example: `my_project_bot` or `MyProjectBot`
6. **Receive your Bot Token**
   - BotFather will respond with your token
   - Format: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`
   - **IMPORTANT**: Keep this token secret!

**Example conversation:**

```
You: /newbot
BotFather: Alright, a new bot. How are we going to call it? Please choose a name for your bot.
You: My Project Bot
BotFather: Good. Now let's choose a username for your bot. It must end in `bot`. Like this, for example: TetrisBot or tetris_bot.
You: my_project_bot
BotFather: Done! Congratulations on your new bot. You will find it at t.me/my_project_bot.
         Use this token to access the HTTP API:
         123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

## Step 2: Configure Bot Settings (Optional)

You can customize your bot with additional BotFather commands:

| Command           | Purpose                                |
| ----------------- | -------------------------------------- |
| `/setdescription` | Set bot description (shown in profile) |
| `/setabouttext`   | Set "About" text                       |
| `/setuserpic`     | Set bot profile picture                |
| `/setcommands`    | Define bot commands menu               |
| `/setprivacy`     | Toggle group messages access           |

### Privacy Mode

By default, bots in groups only receive:

- Commands starting with `/`
- Messages mentioning the bot
- Replies to bot's messages

To receive ALL messages in groups:

1. Send `/setprivacy` to BotFather
2. Select your bot
3. Choose "Disable"

**Note:** This requires re-adding the bot to existing groups.

## Step 3: Get Your Chat ID

To send messages, you need the Chat ID of the recipient.

### Method 1: Using getUpdates API

1. **Start a chat with your bot** (search for @your_bot_username)
2. **Send any message** to the bot (e.g., `/start` or `hello`)
3. **Open this URL** in your browser (replace YOUR_TOKEN):
   ```
   https://api.telegram.org/botYOUR_TOKEN/getUpdates
   ```
4. **Find the chat ID** in the response:
   ```json
   {
     "result": [{
       "message": {
         "chat": {
           "id": 123456789,  ← This is your Chat ID
           "first_name": "Your Name",
           "type": "private"
         }
       }
     }]
   }
   ```

### Method 2: Using ID Bots

1. Search for `@userinfobot` or `@getidsbot` on Telegram
2. Start a chat and it will reply with your Chat ID

### Method 3: For Group Chat IDs

1. **Add your bot to the group**
2. **Send a message** in the group
3. **Check getUpdates** (same as Method 1)
4. Group IDs are **negative numbers** (e.g., `-1001234567890`)

### Chat ID Types

| Type         | Format                     | Example          |
| ------------ | -------------------------- | ---------------- |
| Private chat | Positive integer           | `123456789`      |
| Group        | Negative integer           | `-123456789`     |
| Supergroup   | Negative, starts with -100 | `-1001234567890` |
| Channel      | Negative, starts with -100 | `-1001234567890` |

## Step 4: Verify Bot Token

Test your bot token works by calling the `getMe` API:

```bash
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getMe"
```

**Expected response:**

```json
{
  "ok": true,
  "result": {
    "id": 123456789,
    "is_bot": true,
    "first_name": "My Project Bot",
    "username": "my_project_bot",
    "can_join_groups": true,
    "can_read_all_group_messages": false,
    "supports_inline_queries": false
  }
}
```

**If you get an error:**

- `401 Unauthorized`: Token is invalid or revoked
- Check for typos in the token
- Get a new token from BotFather if needed

## Step 5: Test Sending a Message

Verify you can send a message:

```bash
curl -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage" \
  -H "Content-Type: application/json" \
  -d '{"chat_id": "<YOUR_CHAT_ID>", "text": "Hello from API!"}'
```

**Expected response:**

```json
{
  "ok": true,
  "result": {
    "message_id": 1,
    "from": { "id": 123456789, "is_bot": true, "first_name": "My Project Bot" },
    "chat": { "id": 987654321, "first_name": "Your Name", "type": "private" },
    "date": 1705312800,
    "text": "Hello from API!"
  }
}
```

## Step 6: Verify Setup Checklist

You should now have:

- [ ] Bot Token (from BotFather)
- [ ] Bot Username (e.g., @my_project_bot)
- [ ] Chat ID for testing (your personal chat or a test group)
- [ ] Verified token works (`getMe` returns bot info)
- [ ] Verified messaging works (test message received)

## Bot Token Management

### Get New Token

If your token is compromised:

1. Send `/token` to BotFather
2. Select your bot
3. BotFather will generate a new token
4. **Old token is immediately revoked**

### Revoke Token

To revoke without getting a new one:

1. Send `/revoke` to BotFather
2. Select your bot
3. Confirm revocation

### Delete Bot

To permanently delete a bot:

1. Send `/deletebot` to BotFather
2. Select your bot
3. Confirm deletion
4. Bot and all its data will be removed

## API Limits and Best Practices

### Rate Limits

| Action                      | Limit                    |
| --------------------------- | ------------------------ |
| Messages to same chat       | ~1 per second            |
| Messages to different chats | ~30 per second           |
| Bulk notifications          | ~30 messages per second  |
| Group/channel messages      | ~20 per minute per group |

### Best Practices

1. **Handle errors gracefully** - Implement retry with exponential backoff
2. **Respect rate limits** - Add delays between bulk messages
3. **Use webhooks for production** - More efficient than polling
4. **Validate chat IDs** - Store and verify before sending
5. **Handle blocked bots** - Users can block your bot anytime

## Common Bot Permissions

When adding bot to groups, consider these settings:

| Permission        | BotFather Command   | Purpose                    |
| ----------------- | ------------------- | -------------------------- |
| Read all messages | `/setprivacy`       | Receive all group messages |
| Inline mode       | `/setinline`        | Enable @bot inline queries |
| Group admin       | (in group settings) | Delete messages, ban users |

## Troubleshooting

### "Unauthorized" Error

- Token is invalid or has been revoked
- Check for extra spaces or characters in token
- Generate new token from BotFather

### "Chat not found" Error

- Chat ID is incorrect
- User hasn't started conversation with bot (need to send /start)
- Bot was removed from group
- Verify chat ID using getUpdates

### "Forbidden: bot was blocked by the user"

- User has blocked the bot
- They need to unblock and send /start again
- Check user's Telegram privacy settings

### "Bad Request: chat not found"

- For private chats: user must initiate with /start first
- For groups: bot must be added to the group
- Check if using correct chat ID format

### Bot not receiving messages in group

- Privacy mode may be enabled
- Disable with `/setprivacy` in BotFather
- Re-add bot to group after changing setting

### Messages not being delivered

- Check if bot is still in the chat
- Verify rate limits aren't exceeded
- Check for Telegram service status

## Quick Reference

| Item            | Format/Example                            |
| --------------- | ----------------------------------------- |
| Bot Token       | `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`    |
| Private Chat ID | `123456789` (positive)                    |
| Group Chat ID   | `-123456789` (negative)                   |
| Supergroup ID   | `-1001234567890` (starts with -100)       |
| Bot Username    | `@my_bot` or `my_bot` (must end in `bot`) |

## API Base URL

All Telegram Bot API requests go to:

```
https://api.telegram.org/bot<TOKEN>/
```

Common endpoints:

- `getMe` - Get bot info
- `sendMessage` - Send text message
- `sendPhoto` - Send photo
- `sendDocument` - Send file
- `getUpdates` - Get incoming updates (polling)
- `setWebhook` - Set webhook URL

## Resources

- **Bot API Documentation**: https://core.telegram.org/bots/api
- **BotFather**: https://t.me/BotFather
- **Bot FAQ**: https://core.telegram.org/bots/faq
- **API Changelog**: https://core.telegram.org/bots/api-changelog
