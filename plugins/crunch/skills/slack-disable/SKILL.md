---
name: slack-disable
description: Disable Slack MCP configuration in the project with tiered cleanup options - from config-only to complete removal including secrets backend cleanup.
---

# Disable Slack

This skill disables Slack MCP configuration in the project with tiered cleanup options.

## Definition of Done

The disable is complete when:

1. Slack section is removed from CLAUDE.md
2. MCP configuration is cleaned up (based on tier selected)
3. User confirms the removal is complete

## Progress Tracking

### Progress File: `slack-disable-progress.md`

Location: Project root (`./slack-disable-progress.md`)

**Format:**

```markdown
# Slack Disable Progress

## Status

- **Started**: {timestamp}
- **Current Phase**: Phase {N}
- **Selected Tier**: {tier}

## Completed Steps

- [x] Phase 1: Assessment
- [ ] Phase 2: Confirmation <- CURRENT
- [ ] Phase 3: Execution
- [ ] Phase 4: Verification
- [ ] Phase 5: Cleanup

## Inventory

- CLAUDE.md Slack section: Found/Not found
- .mcp.json slack entry: Found/Not found
- Secrets backend entries: Found/Not found
- Progress files: Found/Not found
```

## Disable Tiers

| Tier | Name           | What It Removes                                    | Use When                  |
| ---- | -------------- | -------------------------------------------------- | ------------------------- |
| 1    | Config Only    | CLAUDE.md section, .mcp.json slack entry           | Switching to different MCP|
| 2    | Full Project   | Above + progress files                             | Clean project removal     |
| 3    | Complete       | Above + secrets backend entries, revoke guidance   | Full cleanup with secrets |

## Workflow

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat slack-disable-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase
   - Display status and offer to resume or start over

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Assessment

Inventory what Slack components exist in the project:

1. **Check CLAUDE.md for Slack section**

   ```bash
   grep -A 15 "### Slack" CLAUDE.md 2>/dev/null
   ```

2. **Check .mcp.json for Slack configuration**

   ```bash
   grep -A 10 '"slack"' .mcp.json 2>/dev/null
   ```

3. **Check for progress files**

   ```bash
   ls -la slack-setup-progress.md 2>/dev/null
   ls -la setup-slack-bot-progress.md 2>/dev/null
   ```

4. **Check for secrets backend entries**

   Check CLAUDE.md for secrets backend configuration, then:

   **If Vault:**
   ```bash
   vault kv list secret/slack 2>/dev/null
   ```

   **If SOPS:**
   ```bash
   grep "slack" secrets.yaml 2>/dev/null
   ```

**Display inventory to user:**

```
Slack Installation Inventory:

Project Configuration:
  OK CLAUDE.md Slack section: Found
  OK .mcp.json slack server: Found
  X  slack-setup-progress.md: Not found

Secrets Backend:
  OK Vault slack/bot_token: Found
  OK Vault slack/team_id: Found

MCP Configuration:
  Package: @modelcontextprotocol/server-slack
  Auth: Bot Token + Team ID in env
```

### Phase 2: Confirmation

Present tiered disable options:

```
How would you like to disable Slack?

1. Config Only (Light)
   - Remove Slack section from CLAUDE.md
   - Remove slack server from .mcp.json
   - Keeps: Secrets backend entries, bot token valid

2. Full Project (Medium) - Recommended
   - Everything above
   - Plus: Remove slack-setup-progress.md (if exists)
   - Keeps: Secrets backend entries, bot token valid

3. Complete (Heavy)
   - Everything above
   - Plus: Remove secrets backend entries (slack/bot_token, slack/team_id)
   - Plus: Provide guidance to revoke bot token at Slack API portal
```

**For "Complete" tier, get confirmation for each destructive action:**

- "Remove slack/bot_token from secrets backend? (yes/no)"
- "Remove slack/team_id from secrets backend? (yes/no)"

### Phase 3: Execution

Based on selected tier, perform the removal:

#### Tier 1: Config Only

1. **Remove Slack section from CLAUDE.md**
   - Find `### Slack` section under Communication or MCP Servers
   - Remove from that header until next `###` or `##` header
   - Preserve rest of file

2. **Remove from .mcp.json**
   - Parse the JSON file
   - Remove the `slack` key from `mcpServers`
   - If `mcpServers` becomes empty, consider removing file
   - Write back properly formatted JSON

#### Tier 2: Full Project

1. Everything from Tier 1
2. **Remove progress files**
   ```bash
   rm -f slack-setup-progress.md
   rm -f setup-slack-bot-progress.md
   ```

#### Tier 3: Complete

1. Everything from Tier 2
2. **Remove secrets backend entries** (if confirmed)

   **For Vault:**
   ```bash
   vault kv delete secret/slack/bot_token
   vault kv delete secret/slack/team_id
   # Or delete entire path:
   vault kv delete secret/slack
   ```

   **For SOPS:**
   - Edit secrets.yaml to remove slack entries
   - Re-encrypt the file

3. **Provide token revocation guidance**

   Display to user:
   ```
   To fully revoke your Slack bot token:

   1. Go to https://api.slack.com/apps
   2. Find your Slack App (e.g., "Claude MCP Bot")
   3. Navigate to "OAuth & Permissions"
   4. Click "Revoke Tokens" to revoke all tokens

   Or to uninstall the app entirely:
   1. Go to https://api.slack.com/apps
   2. Find your app
   3. Go to "Settings" -> "Basic Information"
   4. Scroll down and click "Delete App"

   Note: Until you revoke the token, it remains valid even after
   removing the configuration from this project.
   ```

### Phase 4: Verification

Confirm removal was successful:

1. **Check CLAUDE.md**

   ```bash
   grep "Slack" CLAUDE.md
   # Should return nothing (or only unrelated mentions)
   ```

2. **Check .mcp.json**

   ```bash
   grep '"slack"' .mcp.json
   # Should return nothing
   ```

3. **For Complete tier, verify secrets removed:**

   **Vault:**
   ```bash
   vault kv get secret/slack/bot_token 2>&1  # Should fail
   vault kv get secret/slack/team_id 2>&1  # Should fail
   ```

**Report results:**

```
OK Slack disable complete!

Removed:
- CLAUDE.md Slack section
- .mcp.json slack server entry
[- slack-setup-progress.md]
[- Vault secret/slack/bot_token]
[- Vault secret/slack/team_id]

Kept:
[- Slack bot token (still valid until revoked)]

Next steps:
[- Revoke bot token at api.slack.com/apps]
```

### Phase 5: Cleanup

1. **Remove disable progress file**

   ```bash
   rm slack-disable-progress.md
   ```

2. **Final message**

   ```
   OK Slack has been disabled from this project
   OK Progress file cleaned up

   To set up Slack again, run /slack-enable
   ```

3. **Remind about Claude Code restart**

   ```
   Note: You may need to restart Claude Code for the MCP
   changes to take effect (Slack tools will no longer be available).
   ```

---

## Error Handling

### Common Issues

**Cannot remove from CLAUDE.md:**
- File is read-only
- Slack section not found in expected format

**Cannot modify .mcp.json:**
- File is read-only
- JSON syntax error

**Cannot remove secrets:**
- Not authenticated to secrets backend
- Secret path doesn't exist

### Error Table

| Error                    | Cause                      | Solution                           |
| ------------------------ | -------------------------- | ---------------------------------- |
| `CLAUDE.md read-only`    | File permissions           | Check file permissions             |
| `JSON parse error`       | Malformed .mcp.json        | Fix JSON syntax manually           |
| `Secret not found`       | Already removed or wrong path | Verify path, skip if not found   |
| `Permission denied`      | Insufficient access        | Check credentials                  |

## Interactive Checkpoints

- [ ] "Which disable tier would you like?"
- [ ] For Complete tier: Confirm each secret deletion individually
- [ ] "Disable complete. Verify the removal worked?"
- [ ] "Would you like guidance on revoking your bot token?"

## Rollback Guidance

If user needs to undo the disable:

```
To restore Slack configuration:

1. Run /slack-enable to set up Slack again
2. If you still have your bot credentials:
   - They can be reused (unless token was revoked)
3. If token was revoked:
   - Create a new Slack App or regenerate token
```

## Related Skills

- `/slack-enable` - Set up Slack MCP
- `/slack-use` - Send messages and interact with Slack
