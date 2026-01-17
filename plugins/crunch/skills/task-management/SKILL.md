---
name: task-management
description: Unified task management skill. Reads CLAUDE.md to detect configured task management backend (Trello, etc.) and performs create/list/update/move/delete operations using the appropriate MCP tools.
---

# Task Management Skill

This skill provides a unified interface for task management by detecting the configured backend from CLAUDE.md and routing operations to the appropriate MCP tools.

## How It Works

1. **Read CLAUDE.md** to detect which task management system is configured
2. **Determine the backend** (currently Trello, extensible for future backends)
3. **Execute the requested operation** using the appropriate MCP tools
4. **Return results** in a consistent format

## Supported Backends

| Backend    | Detection                       | Operations                                 |
| ---------- | ------------------------------- | ------------------------------------------ |
| **Trello** | `## MCP Servers` → `### Trello` | MCP tools (`trello_*`)                     |
| _(Future)_ | `## MCP Servers` → `### Jira`   | MCP tools (`jira_*`)                       |
| _(Future)_ | `## MCP Servers` → `### Asana`  | MCP tools (`asana_*`)                      |
| _(Future)_ | `## MCP Servers` → `### Linear` | MCP tools (`linear_*`)                     |
| _(Future)_ | `## MCP Servers` → `### GitHub` | MCP tools (`github_*` for Issues/Projects) |

## Supported Operations

| Operation    | Description                          | Example                              |
| ------------ | ------------------------------------ | ------------------------------------ |
| **Create**   | Create a new task/card/issue         | "create task 'Fix login bug'"        |
| **List**     | List tasks in a board/project/list   | "show tasks in the Sprint board"     |
| **Get**      | Get details of a specific task       | "show details of the login bug task" |
| **Update**   | Update task title, description, etc. | "update the description of task X"   |
| **Move**     | Move task to different list/status   | "move 'Fix login' to Done"           |
| **Assign**   | Assign task to a user                | "assign the bug to @alice"           |
| **Label**    | Add/remove labels/tags               | "add 'urgent' label to the task"     |
| **Comment**  | Add comment to a task                | "comment 'Working on it' on the bug" |
| **Delete**   | Delete/archive a task                | "archive the old task"               |
| **Due Date** | Set/update due date                  | "set due date to Friday"             |

## Workflow

### Phase 1: Detect Backend

1. **Read CLAUDE.md from project root**

   ```bash
   cat CLAUDE.md
   ```

2. **Parse for task management configuration**
   Look for these sections:

   a. **Trello**

   ```markdown
   ## MCP Servers

   ### Trello

   - **Status**: Configured
   - **Config location**: `.mcp.json`
   - **Capabilities**: List boards, create/update/delete cards, manage lists
   ```

   b. **Future: Jira**

   ```markdown
   ## MCP Servers

   ### Jira

   - **Status**: Configured
   - **Project**: MYPROJECT
   - **Capabilities**: Create/update issues, manage sprints
   ```

   c. **Future: GitHub Issues/Projects**

   ```markdown
   ## MCP Servers

   ### GitHub

   - **Status**: Configured
   - **Repository**: owner/repo
   - **Capabilities**: Issues, Projects, Milestones
   ```

3. **If no backend detected**
   - Inform user: "No task management system configured in CLAUDE.md"
   - Suggest running a setup skill:
     - `setup-trello` for Trello boards
   - Ask if they want to set one up now

4. **If multiple backends configured**
   - List available backends
   - Ask user which one to use OR
   - Use context clues (e.g., "create Trello card" vs "create Jira ticket")

### Phase 2: Parse User Request

Understand what operation the user wants:

| Intent          | Keywords                             | Target Hints                        |
| --------------- | ------------------------------------ | ----------------------------------- |
| **Create task** | create, add, new, make               | task, card, ticket, issue           |
| **List tasks**  | list, show, get, what's in           | board, list, column, sprint         |
| **Get details** | show, details, describe, what is     | specific task name/ID               |
| **Update**      | update, change, edit, modify, rename | title, description, details         |
| **Move**        | move, transfer, change status        | to [list/column], done, in progress |
| **Assign**      | assign, give to, set owner           | @user, to [person]                  |
| **Label**       | label, tag, add label, remove label  | label name, color                   |
| **Comment**     | comment, note, add comment           | on [task]                           |
| **Delete**      | delete, remove, archive              | task name/ID                        |
| **Due date**    | due, deadline, set due, due date     | date, tomorrow, next week           |

**Extract from request:**

- Operation type
- Target (board, list, task)
- Content (title, description, comment text)
- Options (labels, assignees, due date)

### Phase 3: Execute Operation

Based on detected backend, use the appropriate MCP tools:

---

## Backend: Trello MCP

**Configuration needed from CLAUDE.md:**

- Config file location (`.mcp.json`)
- Default board (optional)

**Available MCP Tools (typical):**

- `trello_list_boards` - List all boards
- `trello_get_board` - Get board details
- `trello_get_lists` - Get lists on a board
- `trello_list_cards` - List cards in a list
- `trello_get_card` - Get card details
- `trello_create_card` - Create a new card
- `trello_update_card` - Update card details
- `trello_move_card` - Move card to different list
- `trello_delete_card` - Delete a card
- `trello_add_comment` - Add comment to card
- `trello_add_label` - Add label to card

### Create Task

```
User: "create task 'Fix login bug' in the Bugs board"

→ Parse: operation=create, target="Bugs" board, title="Fix login bug"
→ MCP: trello_list_boards() → find "Bugs" board ID
→ MCP: trello_get_lists(board_id) → get default list (e.g., "To Do")
→ MCP: trello_create_card(list_id, name="Fix login bug")
→ Response: ✓ Task created: "Fix login bug" in Bugs → To Do
```

**With details:**

```
User: "create a card 'Add dark mode' with description 'Allow users to toggle dark theme' in Product board, add label 'feature'"

→ MCP: Find board, get lists
→ MCP: trello_create_card(
   list_id=<to_do_list>,
   name="Add dark mode",
   desc="Allow users to toggle dark theme"
 )
→ MCP: trello_add_label(card_id, label="feature")
→ Response: ✓ Task created with label
```

### List Tasks

```
User: "show tasks in the Sprint board"

→ MCP: trello_list_boards() → find "Sprint" board
→ MCP: trello_get_lists(board_id)
→ MCP: For each list, trello_list_cards(list_id)
→ Response:
 Tasks in Sprint Board:

 To Do (3):
   • Fix login bug
   • Update documentation
   • Add dark mode

 In Progress (2):
   • API refactor
   • Database migration

 Done (5):
   • User auth
   • ...
```

**Filter by list:**

```
User: "what's in the To Do list?"

→ MCP: Find "To Do" list
→ MCP: trello_list_cards(to_do_list_id)
→ Response:
 To Do (3 tasks):
   • Fix login bug (due: Jan 20)
   • Update documentation
   • Add dark mode (label: feature)
```

### Get Task Details

```
User: "show details of the login bug task"

→ MCP: Search for card by name
→ MCP: trello_get_card(card_id)
→ Response:
 Task: Fix login bug

 Board: Bugs
 List: To Do
 Description: Users can't log in with special characters
 Labels: bug, high-priority
 Assignees: @alice
 Due: Jan 20, 2024
 Comments: 2
 Created: Jan 15, 2024
```

### Update Task

```
User: "update the description of 'Fix login' to 'Handle special chars in password'"

→ MCP: Find card "Fix login"
→ MCP: trello_update_card(card_id, desc="Handle special chars in password")
→ Response: ✓ Task updated: "Fix login bug"
```

**Rename task:**

```
User: "rename 'Fix login bug' to 'Fix special character login issue'"

→ MCP: trello_update_card(card_id, name="Fix special character login issue")
→ Response: ✓ Task renamed
```

### Move Task

```
User: "move 'Fix login' to Done"

→ MCP: Find card "Fix login"
→ MCP: Find list "Done"
→ MCP: trello_move_card(card_id, list_id=done_list_id)
→ Response: ✓ Task moved: "Fix login bug" → Done
```

**With position:**

```
User: "move 'API refactor' to top of In Progress"

→ MCP: trello_move_card(card_id, list_id, pos="top")
→ Response: ✓ Task moved to top of In Progress
```

### Assign Task

```
User: "assign the login bug to @alice"

→ MCP: Find card
→ MCP: Find member "alice"
→ MCP: trello_update_card(card_id, members=[alice_id])
→ Response: ✓ Task assigned to @alice
```

### Add Label

```
User: "add 'urgent' label to the bug"

→ MCP: Find card
→ MCP: Find or create label "urgent"
→ MCP: trello_add_label(card_id, label_id)
→ Response: ✓ Label "urgent" added
```

### Add Comment

```
User: "comment 'I'm working on this' on the login bug"

→ MCP: Find card
→ MCP: trello_add_comment(card_id, text="I'm working on this")
→ Response: ✓ Comment added to "Fix login bug"
```

### Set Due Date

```
User: "set due date to Friday for the login bug"

→ Parse: "Friday" → calculate date
→ MCP: trello_update_card(card_id, due="2024-01-19")
→ Response: ✓ Due date set: Jan 19, 2024
```

### Delete/Archive Task

```
User: "archive the old migration task"

→ MCP: Find card
→ MCP: trello_update_card(card_id, closed=true)
→ Response: ✓ Task archived: "Old migration task"
```

**Permanent delete:**

```
User: "delete the test card permanently"

→ Confirm with user
→ MCP: trello_delete_card(card_id)
→ Response: ✓ Task deleted permanently
```

---

## Response Format

Always return results in a consistent format:

### Success - Create

```
✓ Task created

Backend: Trello
Board: Sprint Board
List: To Do
Title: "Fix login bug"
URL: https://trello.com/c/abc123
```

### Success - List

```
✓ Tasks in Sprint Board

To Do (3):
  • Fix login bug (@alice, due: Jan 20)
  • Update documentation
  • Add dark mode [feature]

In Progress (2):
  • API refactor (@bob)
  • Database migration

Done (5):
  • User authentication
  • Setup CI/CD
  • ...

Total: 10 tasks
```

### Success - Update

```
✓ Task updated

Backend: Trello
Task: "Fix login bug"
Changes:
  - Description updated
  - Due date set to Jan 20
```

### Success - Move

```
✓ Task moved

Backend: Trello
Task: "Fix login bug"
From: To Do
To: Done
```

### Error

```
✗ Failed to create task

Backend: Trello
Error: Board not found: "Nonexistent Board"

Suggestions:
- Check board name spelling
- Run "list boards" to see available boards
- Verify MCP connection with setup-trello
```

---

## Interactive Behavior

### When Backend Not Detected

```
I couldn't find a task management system configured in CLAUDE.md.

Would you like to set one up?
1. Trello - Visual boards with lists and cards (run `setup-trello`)

More options coming soon: Jira, Asana, Linear, GitHub Issues
```

### When Multiple Backends Configured (Future)

```
I found multiple task management systems configured:
1. Trello - Sprint Board, Bugs Board
2. Jira - MYPROJECT

Which one should I use? Or specify in your request
(e.g., "create Trello card" or "create Jira ticket")
```

### When Board/Target Ambiguous

```
User: "create a task 'Fix bug'"

→ Multiple boards found:
 - Sprint Board
 - Bugs Board
 - Product Backlog

Which board should I add this task to?
```

### When List Not Specified

```
User: "create task 'New feature' in Product board"

→ Board has multiple lists:
 - Backlog
 - To Do
 - In Progress
 - Done

Which list should I add this task to? (default: To Do)
```

### Confirmation for Destructive Operations

```
⚠️ You're about to permanently delete task: "Test card"

This action cannot be undone. Continue? (yes/no)
```

---

## Context Awareness

The skill should maintain context for follow-up operations:

### Board Context

```
User: "show the Sprint board"
→ Shows board, store board context

User: "create task 'New feature'"
→ Knows to use Sprint board
```

### Task Context

```
User: "show details of the login bug"
→ Shows details, store task context

User: "move it to Done"
→ Knows which task to move

User: "add a comment saying 'Fixed!'"
→ Adds comment to the same task
```

### List Context

```
User: "show To Do list"
→ Shows tasks, store list context

User: "add task 'Quick fix'"
→ Creates in the To Do list
```

---

## Error Handling

### Trello-Specific Errors

| Error             | Cause                  | Solution                    |
| ----------------- | ---------------------- | --------------------------- |
| `board not found` | Board doesn't exist    | Check name, list boards     |
| `list not found`  | List doesn't exist     | Check name, get board lists |
| `card not found`  | Card doesn't exist     | Check name/ID, list cards   |
| `unauthorized`    | Token lacks permission | Re-run setup-trello         |
| `invalid id`      | Malformed ID           | Verify ID format            |
| `rate limited`    | Too many requests      | Wait and retry              |

### General Errors

| Error                   | Cause                | Solution            |
| ----------------------- | -------------------- | ------------------- |
| `MCP not available`     | Server not running   | Restart Claude Code |
| `timeout`               | Network/server issue | Check connectivity  |
| `no backend configured` | Missing setup        | Run setup-trello    |

---

## Usage Examples

### Quick task creation

```
User: "add task 'Review PR #123' to Sprint board"
→ Detects Trello
→ Creates card in default list
→ ✓ Task created in Sprint → To Do
```

### Task with full details

```
User: "create card 'Implement caching' in Backend board, In Progress list, assign to @bob, due next Friday, label 'performance'"
→ Creates card with all details
→ ✓ Task created with assignee, due date, and label
```

### Bulk status update

```
User: "move all done tasks to archive"
→ Lists done tasks
→ Confirms with user
→ Archives each task
→ ✓ 5 tasks archived
```

### Daily standup view

```
User: "what's everyone working on?"
→ Lists all "In Progress" tasks with assignees
→ Shows recent activity
```

### Sprint planning

```
User: "what's in the backlog?"
→ Lists all backlog items
→ Shows priorities and estimates
```

---

## Extensibility Notes

This skill is designed to be extended with additional backends. When adding a new backend:

1. **Add detection pattern** in Phase 1 for the new backend's CLAUDE.md section
2. **Map operations** to the backend's MCP tools
3. **Handle backend-specific features** (e.g., Jira has sprints, GitHub has milestones)
4. **Maintain consistent response format** across all backends
5. **Add backend-specific error handling**

### Future Backend Considerations

**Jira:**

- Projects instead of boards
- Issue types (bug, story, epic)
- Sprints and versions
- Custom fields

**GitHub Issues:**

- Repository-based
- Milestones
- Project boards
- Pull request linking

**Asana:**

- Workspaces and projects
- Sections instead of lists
- Subtasks support
- Portfolio views

**Linear:**

- Teams and projects
- Cycles (sprints)
- Roadmaps
- Integrations with GitHub
