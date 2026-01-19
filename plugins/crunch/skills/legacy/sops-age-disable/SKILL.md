---
name: sops-age-disable
description: Disable SOPS+age configuration in the project with tiered cleanup options - from config-only to complete removal including key deletion.
---

# Disable SOPS with age

This skill disables SOPS+age configuration in the project with tiered cleanup options.

## Definition of Done

The disable is complete when:

1. SOPS+age section is removed from CLAUDE.md
2. Configuration is cleaned up (based on tier selected)
3. User confirms the removal is complete

## Progress Tracking

### Progress File: `sops-age-disable-progress.md`

Location: Project root (`./sops-age-disable-progress.md`)

**Format:**

```markdown
# SOPS+age Disable Progress

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

- CLAUDE.md SOPS section: Found/Not found
- .sops.yaml: Found/Not found
- Key file: Found/Not found
- Encrypted files: X found
- Environment variable: Set/Not set
```

## Disable Tiers

| Tier | Name           | What It Removes                                    | Use When                  |
| ---- | -------------- | -------------------------------------------------- | ------------------------- |
| 1    | Config Only    | CLAUDE.md section, .sops.yaml                      | Switching encryption methods |
| 2    | Full Project   | Above + progress files, env var guidance           | Clean project removal     |
| 3    | Complete       | Above + age key file (DANGEROUS)                   | Full system cleanup       |

**WARNING for Tier 3:** Deleting the age key file means ALL encrypted files become permanently unrecoverable. Only proceed if you have decrypted all files first.

## Workflow

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat sops-age-disable-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase
   - Display status and offer to resume or start over

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Assessment

Inventory what SOPS+age components exist in the project:

1. **Check CLAUDE.md for SOPS section**

   ```bash
   grep -A 15 "### SOPS" CLAUDE.md 2>/dev/null
   ```

2. **Check for .sops.yaml**

   ```bash
   ls -la .sops.yaml 2>/dev/null
   cat .sops.yaml 2>/dev/null
   ```

3. **Check for progress files**

   ```bash
   ls -la sops-age-setup-progress.md 2>/dev/null
   ls -la setup-sops-age-progress.md 2>/dev/null
   ```

4. **Check for age key file**

   ```bash
   ls -la ~/.config/sops/age/keys.txt 2>/dev/null
   ```

5. **Check environment variable**

   ```bash
   echo $SOPS_AGE_KEY_FILE
   ```

6. **Check for encrypted files**

   ```bash
   # Find files with SOPS metadata
   grep -r "sops:" --include="*.yaml" --include="*.yml" --include="*.json" . 2>/dev/null | head -20
   ```

**Display inventory to user:**

```
SOPS+age Installation Inventory:

Project Configuration:
  OK CLAUDE.md SOPS section: Found
  OK .sops.yaml: Found (2 recipients)
  X  sops-age-setup-progress.md: Not found

System Configuration:
  OK Key file: ~/.config/sops/age/keys.txt
  OK SOPS_AGE_KEY_FILE: Set

Encrypted Files:
  OK secrets/config.yaml (encrypted)
  OK secrets/api-keys.yaml (encrypted)
  Total: 2 encrypted files found

WARNING: If you delete the key file without decrypting these files first,
they will become PERMANENTLY UNRECOVERABLE.
```

### Phase 2: Confirmation

Present tiered disable options:

```
How would you like to disable SOPS+age?

1. Config Only (Light)
   - Remove SOPS section from CLAUDE.md
   - Remove .sops.yaml
   - Keeps: Key file, encrypted files, environment variable

2. Full Project (Medium) - Recommended
   - Everything above
   - Plus: Remove progress files
   - Plus: Provide guidance to unset environment variable
   - Keeps: Key file, encrypted files

3. Complete (Heavy) - DANGEROUS
   - Everything above
   - Plus: DELETE age key file (~/.config/sops/age/keys.txt)
   - WARNING: This makes all encrypted files PERMANENTLY UNRECOVERABLE
   - Only proceed if you have decrypted all needed files first!
```

**For "Complete" tier, require explicit confirmation:**

```
DANGER You selected Complete tier which will DELETE your age key.

Current encrypted files that will become UNRECOVERABLE:
- secrets/config.yaml
- secrets/api-keys.yaml

Have you decrypted all files you need? Type "I UNDERSTAND" to proceed:
```

### Phase 3: Execution

Based on selected tier, perform the removal:

#### Tier 1: Config Only

1. **Remove SOPS section from CLAUDE.md**
   - Find `### SOPS` section under Secrets Management
   - Remove from that header until next `###` or `##` header
   - Preserve rest of file

2. **Remove .sops.yaml**
   ```bash
   rm .sops.yaml
   ```

#### Tier 2: Full Project

1. Everything from Tier 1

2. **Remove progress files**
   ```bash
   rm -f sops-age-setup-progress.md
   rm -f setup-sops-age-progress.md
   ```

3. **Provide environment variable guidance**

   Display to user:
   ```
   To complete cleanup, remove the environment variable from your shell profile.

   Edit ~/.zshrc (or ~/.bashrc) and remove this line:
     export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

   Then reload your shell:
     source ~/.zshrc

   Note: The key file is kept intact in case you need to decrypt files later.
   ```

#### Tier 3: Complete

1. Everything from Tier 2

2. **Final warning before key deletion**

   ```
   FINAL WARNING

   About to delete: ~/.config/sops/age/keys.txt

   This will make these files PERMANENTLY UNRECOVERABLE:
   - secrets/config.yaml
   - secrets/api-keys.yaml

   Type "DELETE KEY" to proceed:
   ```

3. **Delete key file** (if confirmed)
   ```bash
   rm ~/.config/sops/age/keys.txt
   rmdir ~/.config/sops/age 2>/dev/null  # Remove dir if empty
   rmdir ~/.config/sops 2>/dev/null       # Remove parent if empty
   ```

### Phase 4: Verification

Confirm removal was successful:

1. **Check CLAUDE.md**

   ```bash
   grep "SOPS" CLAUDE.md
   # Should return nothing (or only unrelated mentions)
   ```

2. **Check .sops.yaml removed**

   ```bash
   ls -la .sops.yaml 2>/dev/null
   # Should not exist
   ```

3. **For Complete tier, verify key removed:**

   ```bash
   ls -la ~/.config/sops/age/keys.txt 2>/dev/null
   # Should not exist
   ```

**Report results:**

```
OK SOPS+age disable complete!

Removed:
- CLAUDE.md SOPS section
- .sops.yaml
[- sops-age-setup-progress.md]
[- ~/.config/sops/age/keys.txt]

Kept:
[- Age key file (still available for decryption)]
[- Encrypted files (unchanged)]

Next steps:
[- Unset SOPS_AGE_KEY_FILE in your shell profile]
```

### Phase 5: Cleanup

1. **Remove disable progress file**

   ```bash
   rm sops-age-disable-progress.md
   ```

2. **Final message**

   ```
   OK SOPS+age has been disabled from this project
   OK Progress file cleaned up

   To set up SOPS+age again, run /sops-age-enable
   ```

---

## Error Handling

### Common Issues

**Cannot remove CLAUDE.md section:**
- File is read-only
- SOPS section not found in expected format

**Cannot remove .sops.yaml:**
- File is read-only
- File doesn't exist

**Cannot remove key file:**
- Permission denied
- File doesn't exist

**Encrypted files remain:**
- User didn't decrypt before removing key
- Files are now permanently encrypted

### Error Table

| Error                    | Cause                      | Solution                           |
| ------------------------ | -------------------------- | ---------------------------------- |
| `CLAUDE.md read-only`    | File permissions           | Check file permissions             |
| `.sops.yaml not found`   | Already removed            | Skip this step                     |
| `Permission denied`      | Insufficient access        | Check credentials                  |
| `Key file not found`     | Already removed or different location | Check SOPS_AGE_KEY_FILE |

## Interactive Checkpoints

- [ ] "Which disable tier would you like?"
- [ ] For Complete tier: Require "I UNDERSTAND" confirmation
- [ ] For Complete tier: Require "DELETE KEY" final confirmation
- [ ] "Disable complete. Verify the removal worked?"

## Rollback Guidance

If user needs to undo the disable:

**If key file still exists:**
```
To restore SOPS+age configuration:

1. Run /sops-age-enable and choose "Use Existing Key"
2. Point to your existing key at ~/.config/sops/age/keys.txt
3. Recreate .sops.yaml with your public key
```

**If key file was deleted:**
```
WARNING: If the key file was deleted, encrypted files are UNRECOVERABLE.

To set up fresh:
1. Run /sops-age-enable
2. Generate a new key
3. Re-encrypt files from unencrypted sources (if available)
```

## Pre-Disable Checklist

Before disabling, consider:

1. **Decrypt all needed files first**
   ```bash
   # Decrypt to new unencrypted file
   sops --decrypt secrets/config.yaml > secrets/config.decrypted.yaml
   ```

2. **Backup the key file**
   ```bash
   # Store somewhere secure (password manager, secure storage)
   cp ~/.config/sops/age/keys.txt /secure/backup/location/
   ```

3. **Note your public key**
   ```bash
   age-keygen -y ~/.config/sops/age/keys.txt
   # Save this in case you need to be added as recipient later
   ```

## Related Skills

- `/sops-age-enable` - Set up SOPS+age
- `/sops-age-use` - Encrypt/decrypt secrets with SOPS
