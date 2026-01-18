---
name: trello-disable
description: Disable Trello MCP configuration in the project with tiered cleanup options - from config-only to complete removal including secrets backend cleanup.
---

# Disable Trello

This skill disables Trello MCP configuration in the project with tiered cleanup options.

## Definition of Done

The disable is complete when:

1. Trello section is removed from CLAUDE.md
2. MCP configuration is cleaned up (based on tier selected)
3. User confirms the removal is complete

## Progress Tracking

### Progress File: `trello-disable-progress.md`

Location: Project root (`./trello-disable-progress.md`)

**Format:**

```markdown
# Trello Disable Progress

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

- CLAUDE.md Trello section: Found/Not found
- .mcp.json trello entry: Found/Not found
- Secrets backend entries: Found/Not found
- Progress files: Found/Not found
```

## Disable Tiers

| Tier | Name         | What It Removes                                  | Use When                   |
| ---- | ------------ | ------------------------------------------------ | -------------------------- |
| 1    | Config Only  | CLAUDE.md section, .mcp.json trello entry        | Switching to different MCP |
| 2    | Full Project | Above + progress files                           | Clean project removal      |
| 3    | Complete     | Above + secrets backend entries, revoke guidance | Full cleanup with secrets  |

## Workflow

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat trello-disable-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase
   - Display status and offer to resume or start over

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Assessment

Inventory what Trello components exist in the project:

1. **Check CLAUDE.md for Trello section**

   ```bash
   grep -A 15 "### Trello" CLAUDE.md 2>/dev/null
   ```

2. **Check .mcp.json for Trello configuration**

   ```bash
   grep -A 10 '"trello"' .mcp.json 2>/dev/null
   ```

3. **Check for progress files**

   ```bash
   ls -la trello-setup-progress.md 2>/dev/null
   ```

4. **Check for secrets backend entries**

   Check CLAUDE.md for secrets backend configuration, then:

   **If Vault:**

   ```bash
   vault kv list secret/trello 2>/dev/null
   ```

   **If SOPS:**

   ```bash
   grep "trello" secrets.yaml 2>/dev/null
   ```

**Display inventory to user:**

```
Trello Installation Inventory:

Project Configuration:
  OK CLAUDE.md Trello section: Found
  OK .mcp.json trello server: Found
  X  trello-setup-progress.md: Not found

Secrets Backend:
  OK Vault trello/api_key: Found
  OK Vault trello/api_token: Found

MCP Configuration:
  Package: @modelcontextprotocol/server-trello
  Auth: API Key + Token in env
```

### Phase 2: Confirmation

Present tiered disable options:

```
How would you like to disable Trello?

1. Config Only (Light)
   - Remove Trello section from CLAUDE.md
   - Remove trello server from .mcp.json
   - Keeps: Secrets backend entries, API credentials valid

2. Full Project (Medium) - Recommended
   - Everything above
   - Plus: Remove trello-setup-progress.md (if exists)
   - Keeps: Secrets backend entries, API credentials valid

3. Complete (Heavy)
   - Everything above
   - Plus: Remove secrets backend entries (trello/api_key, trello/api_token)
   - Plus: Provide guidance to revoke API token at trello.com
```

**For "Complete" tier, get confirmation for each destructive action:**

- "Remove trello/api_key from secrets backend? (yes/no)"
- "Remove trello/api_token from secrets backend? (yes/no)"

### Phase 3: Execution

Based on selected tier, perform the removal:

#### Tier 1: Config Only

1. **Remove Trello section from CLAUDE.md**
   - Find `### Trello` section under Task Management or MCP Servers
   - Remove from that header until next `###` or `##` header
   - Preserve rest of file
   - If Task Management section becomes empty, remove it too

2. **Remove from .mcp.json**
   - Parse the JSON file
   - Remove the `trello` key from `mcpServers`
   - If `mcpServers` becomes empty, consider removing file
   - Write back properly formatted JSON

#### Tier 2: Full Project

1. Everything from Tier 1
2. **Remove progress files**
   ```bash
   rm -f trello-setup-progress.md
   ```

#### Tier 3: Complete

1. Everything from Tier 2
2. **Remove secrets backend entries** (if confirmed)

   **For Vault:**

   ```bash
   vault kv delete secret/trello/api_key
   vault kv delete secret/trello/api_token
   # Or delete entire path:
   vault kv delete secret/trello
   ```

   **For SOPS:**
   - Edit secrets.yaml to remove trello entries
   - Re-encrypt the file

3. **Provide token revocation guidance**

   Display to user:

   ```
   To fully revoke your Trello API token:

   1. Go to https://trello.com/power-ups/admin
   2. Find the Power-Up used for Claude MCP
   3. Click to view details
   4. Revoke the token

   Or revoke all third-party access:
   1. Go to Trello Settings
   2. Navigate to "Applications"
   3. Revoke access for "Claude MCP"

   Note: Until you revoke the token, it remains valid even after
   removing the configuration from this project.
   ```

### Phase 4: Verification

Confirm removal was successful:

1. **Check CLAUDE.md**

   ```bash
   grep "Trello" CLAUDE.md
   # Should return nothing (or only unrelated mentions)
   ```

2. **Check .mcp.json**

   ```bash
   grep '"trello"' .mcp.json
   # Should return nothing
   ```

3. **For Complete tier, verify secrets removed:**

   **Vault:**

   ```bash
   vault kv get secret/trello/api_key 2>&1  # Should fail
   vault kv get secret/trello/api_token 2>&1  # Should fail
   ```

**Report results:**

```
OK Trello disable complete!

Removed:
- CLAUDE.md Trello section
- .mcp.json trello server entry
[- trello-setup-progress.md]
[- Vault secret/trello/api_key]
[- Vault secret/trello/api_token]

Kept:
[- Trello API token (still valid until revoked)]

Next steps:
[- Revoke API token at trello.com/power-ups/admin]
```

### Phase 5: Cleanup

1. **Remove disable progress file**

   ```bash
   rm trello-disable-progress.md
   ```

2. **Final message**

   ```
   OK Trello has been disabled from this project
   OK Progress file cleaned up

   To set up Trello again, run /trello-enable
   ```

3. **Remind about Claude Code restart**

   ```
   Note: You may need to restart Claude Code for the MCP
   changes to take effect (Trello tools will no longer be available).
   ```

---

## Error Handling

### Common Issues

**Cannot remove from CLAUDE.md:**

- File is read-only
- Trello section not found in expected format
- Multiple Trello sections exist

**Cannot modify .mcp.json:**

- File is read-only
- JSON syntax error
- File doesn't exist

**Cannot remove secrets:**

- Not authenticated to secrets backend
- Secret path doesn't exist
- Permission denied

**Trello section format not recognized:**

- Manual removal may be needed
- Show user the location and content to remove

### Error Table

| Error                 | Cause                         | Solution                           |
| --------------------- | ----------------------------- | ---------------------------------- |
| `CLAUDE.md read-only` | File permissions              | Check file permissions             |
| `JSON parse error`    | Malformed .mcp.json           | Fix JSON syntax manually           |
| `Secret not found`    | Already removed or wrong path | Verify path, skip if not found     |
| `Permission denied`   | Insufficient access           | Check credentials, run with access |

## Interactive Checkpoints

- [ ] "Which disable tier would you like?"
- [ ] For Complete tier: Confirm each secret deletion individually
- [ ] "Disable complete. Verify the removal worked?"
- [ ] "Would you like guidance on revoking your API token?"

## Rollback Guidance

If user needs to undo the disable:

```
To restore Trello configuration:

1. Run /trello-enable to set up Trello again
2. If you still have your API credentials:
   - They can be reused (unless token was revoked)
3. If token was revoked:
   - Generate a new token at trello.com/power-ups/admin
```

## Related Skills

- `/trello-enable` - Set up Trello MCP
- `/trello-use` - Perform Trello operations
