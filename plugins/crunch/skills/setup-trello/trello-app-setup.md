# Trello API Setup Guide

Step-by-step instructions for obtaining Trello API credentials for MCP integration.

## Overview

Trello uses a two-part authentication system:

| Credential    | Purpose                        | Where to Get        |
| ------------- | ------------------------------ | ------------------- |
| **API Key**   | Identifies your application    | Developer portal    |
| **API Token** | Authorizes access to your data | Generated via OAuth |

## Step 1: Get Your API Key

1. Go to [trello.com/power-ups/admin](https://trello.com/power-ups/admin)
2. Log in with your Trello account
3. Click **"New"** to create a new Power-Up (or use existing)
4. Fill in basic details:
   - **Name**: `Claude MCP Integration` (or your preferred name)
   - **Workspace**: Select your workspace
   - **Iframe connector URL**: Can be left blank for API-only usage
5. After creation, find your **API Key** on the Power-Up page
6. Copy the **API Key** (32-character hexadecimal string)

**Alternative (Legacy Method):**

1. Go to [trello.com/app-key](https://trello.com/app-key)
2. Your API Key is displayed at the top
3. Note: This method may be deprecated in the future

## Step 2: Generate API Token

The API Token authorizes the application to access your Trello data.

### Method 1: Quick Token Generation

1. After getting your API Key, on the same page look for the **"Token"** link
2. Or construct this URL (replace `YOUR_API_KEY`):
   ```
   https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&name=Claude%20MCP&key=YOUR_API_KEY
   ```
3. Click **"Allow"** to authorize
4. Copy the token displayed on the next page

### Method 2: Custom Permissions

For more granular control, customize the authorization URL:

```
https://trello.com/1/authorize?expiration=EXPIRATION&scope=SCOPE&response_type=token&name=APP_NAME&key=YOUR_API_KEY
```

**Parameters:**

| Parameter    | Options                            | Recommended     |
| ------------ | ---------------------------------- | --------------- |
| `expiration` | `1hour`, `1day`, `30days`, `never` | `never` for MCP |
| `scope`      | `read`, `write`, `account`         | `read,write`    |
| `name`       | Any string                         | `Claude MCP`    |

**Scope Details:**

| Scope     | Permissions                               |
| --------- | ----------------------------------------- |
| `read`    | Read boards, lists, cards, members        |
| `write`   | Create/update/delete boards, lists, cards |
| `account` | Read member email, manage Power-Ups       |

**Recommended URL for MCP:**

```
https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&name=Claude%20MCP&key=YOUR_API_KEY
```

## Step 3: Verify Credentials

Test your credentials work by making a simple API call:

```bash
curl "https://api.trello.com/1/members/me?key=YOUR_API_KEY&token=YOUR_TOKEN"
```

**Expected response:** JSON with your Trello user information (username, email, etc.)

**If you get an error:**

- `401 Unauthorized`: Check API key and token are correct
- `invalid key`: API key is malformed or incorrect
- `invalid token`: Token is expired or doesn't match the API key

## Step 4: Find Board and List IDs

For testing, you'll need to know which board to use.

### Get Your Boards

```bash
curl "https://api.trello.com/1/members/me/boards?key=YOUR_API_KEY&token=YOUR_TOKEN"
```

This returns a list of boards with their IDs.

### Get Lists on a Board

```bash
curl "https://api.trello.com/1/boards/BOARD_ID/lists?key=YOUR_API_KEY&token=YOUR_TOKEN"
```

### Quick Reference: Finding IDs in Trello UI

1. Open any board in Trello
2. Add `.json` to the URL: `https://trello.com/b/BOARD_ID/board-name.json`
3. This shows the board's JSON data including list IDs

**Or from card URL:**

- Card URL: `https://trello.com/c/CARD_SHORT_ID/card-name`
- The `CARD_SHORT_ID` is the short ID (8 characters)

## Step 5: Verify Setup Checklist

You should now have:

- [ ] API Key (32-character hex string)
- [ ] API Token (long alphanumeric string)
- [ ] Verified credentials work (`/members/me` returns data)
- [ ] Identified target board for testing

## Token Permissions Reference

| Permission       | What It Allows                           |
| ---------------- | ---------------------------------------- |
| **Read boards**  | View board names, settings, members      |
| **Write boards** | Create, rename, close, delete boards     |
| **Read lists**   | View lists and their cards               |
| **Write lists**  | Create, archive, move lists              |
| **Read cards**   | View card content, comments, attachments |
| **Write cards**  | Create, edit, move, archive cards        |
| **Read members** | View member info on boards               |

## Troubleshooting

### "Invalid API Key"

- Verify key is exactly 32 characters
- Check for leading/trailing whitespace
- Regenerate at trello.com/power-ups/admin

### "Invalid Token"

- Token may have expired (if not set to `never`)
- Token was generated with a different API key
- Token was revoked
- Regenerate token using your current API key

### "Unauthorized" on Specific Board

- Token doesn't have access to that board
- Board is in a workspace you're not a member of
- Board was deleted or you were removed

### Rate Limiting

Trello's API limits:

- **300 requests per 10 seconds** per token
- **100 requests per 10 seconds** per API key

If hitting limits:

- Add delays between requests
- Batch operations where possible
- Consider using webhooks for real-time updates

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for storing API key and token
3. **Minimal permissions** - only request `account` scope if needed
4. **Regular rotation** - regenerate tokens periodically
5. **Monitor usage** - check for unexpected activity
6. **Revoke unused tokens** at trello.com/power-ups/admin

## Revoking Access

If you need to revoke a token:

1. Go to [trello.com/power-ups/admin](https://trello.com/power-ups/admin)
2. Find your Power-Up
3. Click to view details
4. Revoke or regenerate tokens as needed

**Or revoke all third-party access:**

1. Go to Trello Settings
2. Navigate to "Applications"
3. Revoke access for specific applications

## Quick Reference

| Item           | Format                | Example                            |
| -------------- | --------------------- | ---------------------------------- |
| API Key        | 32-char hex           | `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6` |
| API Token      | ~64-char alphanumeric | `ATTA...long-string...xyz`         |
| Board ID       | 24-char alphanumeric  | `5f4e3d2c1b0a9f8e7d6c5b4a`         |
| Short Board ID | 8-char                | `aBcDeFgH`                         |
| List ID        | 24-char alphanumeric  | `5f4e3d2c1b0a9f8e7d6c5b4a`         |
| Card ID        | 24-char alphanumeric  | `5f4e3d2c1b0a9f8e7d6c5b4a`         |

## API Base URL

All Trello API requests go to:

```
https://api.trello.com/1/
```

Common endpoints:

- `/members/me` - Current user info
- `/boards/{id}` - Board details
- `/boards/{id}/lists` - Lists on a board
- `/lists/{id}/cards` - Cards in a list
- `/cards` - Create a new card (POST)
