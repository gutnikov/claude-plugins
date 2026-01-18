---
name: vault-disable
description: Disable HashiCorp Vault configuration in the project with tiered cleanup options - from config-only to complete system removal.
---

# Disable HashiCorp Vault

This skill disables Vault configuration in the project with tiered cleanup options.

## Definition of Done

The disable is complete when:

1. Vault section is removed from CLAUDE.md
2. Environment variables are cleaned up (based on tier selected)
3. User confirms the removal is complete

## Progress Tracking

### Progress File: `vault-disable-progress.md`

Location: Project root (`./vault-disable-progress.md`)

**Format:**

```markdown
# Vault Disable Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 3 - Execution
- **Selected Tier**: Full Project

## Completed Steps

- [x] Phase 1: Assessment
- [x] Phase 2: Confirmation
- [ ] Phase 3: Execution ← CURRENT
- [ ] Phase 4: Verification
- [ ] Phase 5: Cleanup

## Inventory

- CLAUDE.md Vault section: Found
- .env VAULT_ADDR: Found
- .env VAULT_TOKEN: Found
- ~/.vault-token: Found
- Vault binary: /usr/local/bin/vault

## Selected Tier

Full Project - Remove CLAUDE.md section, .env entries, and progress files
```

## Workflow

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat vault-disable-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase
   - Display status and offer to resume or start over

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Assessment

Inventory what Vault components exist in the project:

1. **Check CLAUDE.md for Vault section**

   ```bash
   grep -A 20 "### HashiCorp Vault" CLAUDE.md
   ```

2. **Check .env for Vault variables**

   ```bash
   grep "^VAULT_" .env 2>/dev/null
   ```

3. **Check for progress files**

   ```bash
   ls -la vault-setup-progress.md 2>/dev/null
   ```

4. **Check for ~/.vault-token**

   ```bash
   ls -la ~/.vault-token 2>/dev/null
   ```

5. **Check if Vault binary is installed**

   ```bash
   which vault
   vault version 2>/dev/null
   ```

6. **Check for running Vault dev server**
   ```bash
   pgrep -f "vault server" 2>/dev/null
   ```

**Display inventory to user:**

```
Vault Installation Inventory:

Project Configuration:
  ✓ CLAUDE.md Vault section: Found
  ✓ .env VAULT_ADDR: Found (http://127.0.0.1:8200)
  ✓ .env VAULT_TOKEN: Found
  ✓ vault-setup-progress.md: Not found

System Configuration:
  ✓ ~/.vault-token: Found
  ✓ Vault binary: /usr/local/bin/vault (v1.15.0)
  ✓ Vault dev server: Running (PID 12345)
```

### Phase 2: Confirmation

Present tiered uninstall options:

```
How would you like to disable Vault?

1. Config Only (Light)
   - Remove Vault section from CLAUDE.md
   - Remove VAULT_ADDR and VAULT_TOKEN from .env
   - Keeps: binary, ~/.vault-token, dev server

2. Full Project (Medium) - Recommended
   - Everything above
   - Plus: Remove vault-setup-progress.md (if exists)
   - Keeps: binary, ~/.vault-token, dev server

3. Complete (Heavy)
   - Everything above
   - Plus: Stop dev server (if running)
   - Plus: Remove ~/.vault-token
   - Plus: Uninstall Vault binary (will ask for each)
```

**For "Complete" tier, get confirmation for each destructive action:**

- "Stop the running Vault dev server? (yes/no)"
- "Remove ~/.vault-token? (yes/no)"
- "Uninstall Vault binary? (yes/no)"

### Phase 3: Execution

Based on selected tier, perform the removal:

#### Tier 1: Config Only

1. **Remove Vault section from CLAUDE.md**
   - Find `### HashiCorp Vault` section
   - Remove from that header until next `###` or `##` header
   - Preserve rest of file

2. **Remove from .env**
   ```bash
   # Remove VAULT_* lines from .env
   grep -v "^VAULT_" .env > .env.tmp && mv .env.tmp .env
   ```

#### Tier 2: Full Project

1. Everything from Tier 1
2. **Remove progress files**
   ```bash
   rm -f vault-setup-progress.md
   ```

#### Tier 3: Complete

1. Everything from Tier 2
2. **Stop dev server** (if confirmed)
   ```bash
   pkill -f "vault server -dev"
   ```
3. **Remove ~/.vault-token** (if confirmed)
   ```bash
   rm ~/.vault-token
   ```
4. **Uninstall binary** (if confirmed)

   **macOS (Homebrew):**

   ```bash
   brew uninstall hashicorp/tap/vault
   ```

   **Ubuntu/Debian:**

   ```bash
   sudo apt remove vault
   ```

   **Binary installation:**

   ```bash
   sudo rm /usr/local/bin/vault
   ```

### Phase 4: Verification

Confirm removal was successful:

1. **Check CLAUDE.md**

   ```bash
   grep "HashiCorp Vault" CLAUDE.md
   # Should return nothing
   ```

2. **Check .env**

   ```bash
   grep "^VAULT_" .env
   # Should return nothing
   ```

3. **For Complete tier, verify:**
   ```bash
   ls ~/.vault-token 2>/dev/null  # Should fail
   which vault 2>/dev/null         # Should fail (if uninstalled)
   pgrep -f "vault server"         # Should return nothing
   ```

**Report results:**

```
✓ Vault disable complete!

Removed:
- CLAUDE.md Vault section
- .env VAULT_ADDR
- .env VAULT_TOKEN
[- ~/.vault-token]
[- Vault binary]
[- Stopped dev server]

Kept:
[- Vault binary (still installed)]
[- ~/.vault-token (preserved)]
```

### Phase 5: Cleanup

1. **Remove uninstall progress file**

   ```bash
   rm vault-disable-progress.md
   ```

2. **Final message**

   ```
   ✓ Vault has been disabled from this project
   ✓ Progress file cleaned up

   To set up Vault again, run /vault-enable
   ```

---

## Error Handling

### Common Issues

**Cannot remove from CLAUDE.md:**
- File is read-only
- Vault section not found in expected format

**Cannot modify .env:**
- File is read-only
- File doesn't exist

**Cannot stop dev server:**
- Process not found
- Permission denied

**Cannot uninstall binary:**
- Permission denied (need sudo)
- Binary not found at expected path

## Interactive Checkpoints

- [ ] "Which uninstall tier would you like?"
- [ ] For Complete tier: Confirm each destructive action individually
- [ ] "Uninstall complete. Verify the removal worked?"

## Related Skills

- `/vault-enable` - Set up Vault for this project
- `/vault-use` - Perform secrets operations
