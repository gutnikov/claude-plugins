---
name: trello-use
description: Trello operations skill. Performs board/card/list operations using Trello MCP by detecting configuration from CLAUDE.md.
---

# Use Trello

This skill provides a unified interface for Trello operations by detecting the configuration from CLAUDE.md and executing the appropriate MCP tool calls.

## How It Works

1. **Read CLAUDE.md** to detect Trello configuration
2. **Verify MCP connection** to Trello
3. **Execute the requested operation** via MCP tools
4. **Return results** in a consistent format

## Backend Detection

**Read CLAUDE.md from project root and look for:**

```markdown
## Task Management

### Trello

- **Status**: Configured
- **Setup mode**: Full Setup
- **Config location**: .mcp.json
```

**If Trello not detected:**

- Inform user: "No Trello configuration found in CLAUDE.md"
- Suggest running setup: "Would you like to set up Trello? Run `/trello-enable`"

## Pre-flight Check

Before any operation, ensure MCP is configured:

1. **Check CLAUDE.md for Trello section**
   ```bash
   grep -A 5 "### Trello" CLAUDE.md 2>/dev/null
   ```

2. **Check MCP configuration**
   ```bash
   grep -A 10 '"trello"' .mcp.json 2>/dev/null
   ```

3. **Verify Trello MCP tools are available**
   - Check if Trello MCP tools are loaded in current session
   - If not available, MCP may need restart

**If not configured:**

```
WARNING Trello MCP not configured.

No Trello configuration found in CLAUDE.md or .mcp.json.

To fix this:
1. Run `/trello-enable` to set up Trello MCP
2. Or verify your .mcp.json contains the trello server configuration
```

## Operations

### List Boards

**Parse from user request:**
- Optional: filter by workspace
- Optional: limit number of results

**MCP Tool Call:**
Use `trello_get_boards` or equivalent MCP tool

**Response:**

```
OK Your Trello Boards:

1. Project Alpha (id: abc123)
   - Lists: To Do, In Progress, Done
2. Personal Tasks (id: def456)
   - Lists: Backlog, This Week, Completed
3. Team Roadmap (id: ghi789)
   - Lists: Q1, Q2, Q3, Q4

Total: 3 boards
```

### List Cards

**Parse from user request:**
- Board name or ID
- Optional: specific list
- Optional: filter (labels, due date, assigned)

**MCP Tool Call:**
Use `trello_get_cards` or equivalent MCP tool

**Response:**

```
OK Cards in "Project Alpha" / "In Progress":

1. Implement user authentication
   - Labels: feature, high-priority
   - Due: 2024-01-20
   - Assigned: @john

2. Fix login bug
   - Labels: bug
   - Due: 2024-01-18

3. Update documentation
   - Labels: docs

Total: 3 cards
```

### Create Card

**Parse from user request:**
- Card title (required)
- Board name or ID (required)
- List name or ID (required, or use default)
- Description (optional)
- Labels (optional)
- Due date (optional)
- Assigned members (optional)

**Confirmation (optional):**

```
You're about to create a card:

Board: Project Alpha
List: To Do
Title: Implement dark mode
Description: Add dark mode toggle to settings page
Labels: feature
Due: 2024-01-25

Proceed? (yes/no)
```

**MCP Tool Call:**
Use `trello_create_card` or equivalent MCP tool

**Response:**

```
OK Card created: "Implement dark mode"

Board: Project Alpha
List: To Do
Card ID: xyz789
URL: https://trello.com/c/xyz789
```

### Update Card

**Parse from user request:**
- Card identifier (name, ID, or URL)
- Fields to update:
  - Title
  - Description
  - Labels (add/remove)
  - Due date
  - Assigned members
  - Checklist items

**MCP Tool Call:**
Use `trello_update_card` or equivalent MCP tool

**Response:**

```
OK Card updated: "Implement dark mode"

Changes:
- Description: Updated
- Due date: 2024-01-25 -> 2024-01-30
- Labels: Added "in-progress"

Card ID: xyz789
```

### Move Card

**Parse from user request:**
- Card identifier (name, ID, or URL)
- Destination list (required)
- Destination board (optional, defaults to same board)
- Position (optional: top, bottom, or specific index)

**MCP Tool Call:**
Use `trello_move_card` or equivalent MCP tool

**Response:**

```
OK Card moved: "Implement dark mode"

From: To Do
To: In Progress
Board: Project Alpha
```

### Delete Card

**Parse from user request:**
- Card identifier (name, ID, or URL)

**Confirmation required:**

```
WARNING You're about to delete card: "Implement dark mode"

Board: Project Alpha
List: To Do
Card ID: xyz789

This action cannot be undone. Continue? (yes/no)
```

**MCP Tool Call:**
Use `trello_delete_card` or `trello_archive_card` (prefer archive)

**Response:**

```
OK Card archived: "Implement dark mode"

Card ID: xyz789
Note: Card has been archived, not permanently deleted.
To restore, find it in the board's archived items.
```

### Add Comment

**Parse from user request:**
- Card identifier (name, ID, or URL)
- Comment text

**MCP Tool Call:**
Use `trello_add_comment` or equivalent MCP tool

**Response:**

```
OK Comment added to "Implement dark mode"

Comment: "Started working on this, ETA tomorrow"
Card ID: xyz789
```

### List Lists

**Parse from user request:**
- Board name or ID

**MCP Tool Call:**
Use `trello_get_lists` or equivalent MCP tool

**Response:**

```
OK Lists in "Project Alpha":

1. Backlog (id: list123)
   - 5 cards
2. To Do (id: list456)
   - 3 cards
3. In Progress (id: list789)
   - 2 cards
4. Done (id: list012)
   - 12 cards

Total: 4 lists, 22 cards
```

### Create List

**Parse from user request:**
- List name (required)
- Board name or ID (required)
- Position (optional: top, bottom, or specific index)

**MCP Tool Call:**
Use `trello_create_list` or equivalent MCP tool

**Response:**

```
OK List created: "Review"

Board: Project Alpha
List ID: newlist123
Position: After "In Progress"
```

## Response Format

### Success - Read Operations

```
OK {Operation} complete

{Details}
```

### Success - Write Operations

```
OK {Resource} {action}: "{identifier}"

{Details}
Backend: Trello MCP
```

### Error

```
X Failed to {operation}: "{identifier}"

Error: {error message}
Backend: Trello MCP

Suggestions:
- {suggestion 1}
- {suggestion 2}
```

## Error Handling

### Common Issues

**"Invalid API key" error:**
- API key in .mcp.json is incorrect
- Regenerate at trello.com/power-ups/admin

**"Invalid token" error:**
- Token expired or revoked
- Generate new token with read,write scope

**"Board not found" error:**
- Board name/ID is incorrect
- Token doesn't have access to the board
- Board may be in a different workspace

**"Card not found" error:**
- Card ID or name is incorrect
- Card may have been archived or deleted

**"Permission denied" error:**
- Token lacks write permissions
- Board is read-only for this user

**MCP tools not available:**
- Claude Code may need restart
- Check .mcp.json configuration

### Error Table

| Error               | Cause                     | Solution                              |
| ------------------- | ------------------------- | ------------------------------------- |
| `invalid key`       | Bad API key               | Check .mcp.json, regenerate key       |
| `invalid token`     | Token expired/revoked     | Generate new token                    |
| `unauthorized`      | Insufficient permissions  | Check token scope, board membership   |
| `not found`         | Board/card doesn't exist  | Verify name/ID, check access          |
| `rate limited`      | Too many requests         | Wait and retry                        |
| `MCP not available` | Server not running        | Restart Claude Code                   |

## Interactive Checkpoints

- [ ] Confirm before create operations (optional, can be skipped)
- [ ] Confirm before delete/archive operations (required)
- [ ] Confirm before bulk operations (required)

## Bulk Operations

For efficiency, this skill supports bulk operations:

### Bulk Create Cards

**Parse from user request:**
- List of card titles
- Target board and list

**Response:**

```
OK Created 5 cards in "Project Alpha" / "To Do":

1. Task 1 (id: card1)
2. Task 2 (id: card2)
3. Task 3 (id: card3)
4. Task 4 (id: card4)
5. Task 5 (id: card5)
```

### Bulk Move Cards

**Parse from user request:**
- Source list
- Destination list
- Optional: specific cards or all cards

**Confirmation required:**

```
WARNING You're about to move 5 cards:

From: "In Progress"
To: "Done"
Board: Project Alpha

Continue? (yes/no)
```

## Usage Examples

**List all boards:**
```
/trello-use list boards
```

**Create a card:**
```
/trello-use create card "Fix login bug" on "Project Alpha" in "To Do"
```

**Move a card:**
```
/trello-use move card "Fix login bug" to "In Progress"
```

**Add a comment:**
```
/trello-use comment on "Fix login bug": "Started investigating this issue"
```

**Archive a card:**
```
/trello-use archive card "Old task"
```

## Related Skills

- `/trello-enable` - Set up Trello MCP
- `/trello-disable` - Remove Trello configuration
