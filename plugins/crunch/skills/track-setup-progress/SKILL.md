---
name: track-setup-progress
description: Shared progress tracking service for domain setup skills. Manages persistent state across Claude Code sessions using markdown files.
---

# Track Setup Progress

A shared skill that manages setup progress files for domain setup skills. Enables resuming multi-phase setups after session restarts or Claude Code reloads.

---

## Purpose

Domain setup skills (secrets, MCP, CI/CD, etc.) often require multiple phases that may span:
- Multiple conversation turns
- Claude Code reloads (e.g., after MCP configuration)
- Session restarts

This skill provides a **consistent interface** for tracking progress across all these scenarios.

```
┌─────────────────────────────────────────────────────────────────────┐
│                    track-setup-progress                              │
│  (Shared skill - progress file management)                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Operations:                                                         │
│    • check    - Does progress file exist?                            │
│    • create   - Create new progress file                             │
│    • update   - Update phase, add collected data                     │
│    • read     - Parse and return structured progress                 │
│    • complete - Mark complete, cleanup file                          │
│    • resume   - Handle resume/start-over decision                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## File Naming Convention

Progress files are stored in the **project root** with the naming pattern:

```
{domain}-setup-progress.md
```

Examples:
- `secrets-setup-progress.md`
- `mcp-setup-progress.md`
- `ci-cd-setup-progress.md`
- `task-management-setup-progress.md`

---

## Operations

### 1. `check` - Check for Existing Progress

Quickly check if a progress file exists and get basic status.

**Input:**

```yaml
operation: check
domain: secrets              # Domain key (required)
```

**Process:**

```bash
# Check if progress file exists
test -f "{domain}-setup-progress.md" && echo "exists" || echo "not_found"

# If exists, extract basic info
grep -E "^\- \*\*Current Phase\*\*:" "{domain}-setup-progress.md" 2>/dev/null
grep -E "^\- \*\*Started\*\*:" "{domain}-setup-progress.md" 2>/dev/null
```

**Output:**

```yaml
# If exists:
exists: true
file_path: "secrets-setup-progress.md"
current_phase: 2
phase_name: "Prerequisites"
started: "2024-01-20T10:00:00Z"
can_resume: true

# If not exists:
exists: false
file_path: "secrets-setup-progress.md"
```

---

### 2. `create` - Create New Progress File

Create a new progress file when starting a domain setup.

**Input:**

```yaml
operation: create
domain: secrets              # Domain key (required)
display_name: "Secrets Management"  # Human-readable name (optional)
phases:                      # Phase definitions (required)
  - key: 0
    name: "State Detection"
  - key: 1
    name: "Vendor Selection"
  - key: 2
    name: "Prerequisites"
  - key: 3
    name: "Configuration"
  - key: 4
    name: "Connection Test"
  - key: 5
    name: "Documentation"
initial_phase: 1             # Starting phase (default: 0)
initial_data:                # Optional initial collected data
  vendor_key: "vault"
  vendor_name: "HashiCorp Vault"
  setup_mode: "full_setup"
```

**Process:**

```bash
# Generate progress file
cat > "{domain}-setup-progress.md" << 'EOF'
# {Display Name} Setup Progress

## Status

- **Started**: {current_timestamp}
- **Current Phase**: Phase {initial_phase} - {phase_name}
- **Setup Mode**: {initial_data.setup_mode or "pending"}

## Completed Steps

{for each phase:}
- [{x if phase.key < initial_phase else " "}] Phase {phase.key}: {phase.name} {<- CURRENT if phase.key == initial_phase}

## Collected Information

{for each key, value in initial_data:}
- **{key}**: {value}
EOF
```

**Output:**

```yaml
created: true
file_path: "secrets-setup-progress.md"
current_phase: 1
```

**Example Generated File:**

```markdown
# Secrets Management Setup Progress

## Status

- **Started**: 2024-01-20T10:30:00Z
- **Current Phase**: Phase 1 - Vendor Selection
- **Setup Mode**: pending

## Completed Steps

- [x] Phase 0: State Detection
- [ ] Phase 1: Vendor Selection <- CURRENT
- [ ] Phase 2: Prerequisites
- [ ] Phase 3: Configuration
- [ ] Phase 4: Connection Test
- [ ] Phase 5: Documentation

## Collected Information

- **vendor_key**: vault
- **vendor_name**: HashiCorp Vault
```

---

### 3. `update` - Update Progress

Update the progress file after phase completion or when collecting data.

**Input:**

```yaml
operation: update
domain: secrets              # Domain key (required)

# Phase updates (optional - provide one or both)
complete_phase: 2            # Mark this phase as completed
set_phase: 3                 # Set current phase to this

# Data updates (optional)
add_data:                    # Add/update collected information
  auth_method: "token"
  config_location: ".env"

remove_data:                 # Remove keys from collected data
  - "temp_value"

# Notes (optional)
add_note: "Waiting for Claude Code reload"
```

**Process:**

1. Read existing progress file
2. If `complete_phase`: Mark phase as completed with timestamp
3. If `set_phase`: Update current phase marker
4. If `add_data`: Append/update collected information
5. If `remove_data`: Remove specified keys
6. If `add_note`: Append to notes section
7. Update `updated` timestamp in metadata
8. Write updated file

**Output:**

```yaml
updated: true
current_phase: 3
phase_name: "Configuration"
completed_phases: [0, 1, 2]
```

**Example: After Phase 2 Completion:**

```markdown
# Secrets Management Setup Progress

## Status

- **Started**: 2024-01-20T10:30:00Z
- **Updated**: 2024-01-20T10:35:00Z
- **Current Phase**: Phase 3 - Configuration
- **Setup Mode**: full_setup

## Completed Steps

- [x] Phase 0: State Detection (10:30:00)
- [x] Phase 1: Vendor Selection (10:32:00)
- [x] Phase 2: Prerequisites (10:35:00)
- [ ] Phase 3: Configuration <- CURRENT
- [ ] Phase 4: Connection Test
- [ ] Phase 5: Documentation

## Collected Information

- **vendor_key**: vault
- **vendor_name**: HashiCorp Vault
- **setup_mode**: full_setup
- **auth_method**: token
- **config_location**: .env
```

---

### 4. `read` - Read Progress Data

Parse the progress file and return structured data.

**Input:**

```yaml
operation: read
domain: secrets              # Domain key (required)
```

**Process:**

```bash
# Read and parse progress file
cat "{domain}-setup-progress.md"

# Parse sections:
# - Status section -> started, current_phase, setup_mode
# - Completed Steps -> phase statuses
# - Collected Information -> key-value pairs
# - Notes -> array of notes
```

**Output:**

```yaml
exists: true
file_path: "secrets-setup-progress.md"

metadata:
  started: "2024-01-20T10:30:00Z"
  updated: "2024-01-20T10:35:00Z"

status:
  current_phase: 3
  phase_name: "Configuration"
  setup_mode: "full_setup"

phases:
  - key: 0
    name: "State Detection"
    status: "completed"
    completed_at: "2024-01-20T10:30:00Z"
  - key: 1
    name: "Vendor Selection"
    status: "completed"
    completed_at: "2024-01-20T10:32:00Z"
  - key: 2
    name: "Prerequisites"
    status: "completed"
    completed_at: "2024-01-20T10:35:00Z"
  - key: 3
    name: "Configuration"
    status: "current"
  - key: 4
    name: "Connection Test"
    status: "pending"
  - key: 5
    name: "Documentation"
    status: "pending"

completed_phases: [0, 1, 2]
pending_phases: [3, 4, 5]

collected_data:
  vendor_key: "vault"
  vendor_name: "HashiCorp Vault"
  setup_mode: "full_setup"
  auth_method: "token"
  config_location: ".env"

notes: []
```

**If file doesn't exist:**

```yaml
exists: false
file_path: "secrets-setup-progress.md"
```

---

### 5. `complete` - Mark Complete & Cleanup

Mark setup as complete and delete the progress file.

**Input:**

```yaml
operation: complete
domain: secrets              # Domain key (required)
keep_file: false             # Optional: keep file for debugging (default: false)
```

**Process:**

1. Read progress file to calculate duration
2. Verify all phases are completed (warning if not)
3. Delete progress file (unless `keep_file: true`)
4. Return completion summary

**Output:**

```yaml
completed: true
file_deleted: true
started: "2024-01-20T10:30:00Z"
finished: "2024-01-20T10:45:00Z"
duration: "15m 0s"
phases_completed: 6
collected_data:              # Final collected data for reference
  vendor_key: "vault"
  # ...
```

**If phases incomplete:**

```yaml
completed: true
file_deleted: true
warning: "Completed with 1 phase still pending: Phase 5 - Documentation"
```

---

### 6. `resume` - Handle Resume Decision

Interactive operation that checks for progress and handles user decision.

**Input:**

```yaml
operation: resume
domain: secrets              # Domain key (required)
```

**Process:**

1. Check if progress file exists
2. If not exists: return `no_progress`
3. If exists: Read progress and present options to user

**Interactive Prompt:**

```typescript
AskUserQuestion({
  questions: [{
    question: "Found incomplete {domain} setup from {started}. How would you like to proceed?",
    header: "Resume",
    options: [
      {
        label: "Resume from Phase {N}",
        description: "Continue where you left off ({phase_name})"
      },
      {
        label: "Start over",
        description: "Discard progress and begin fresh"
      }
    ],
    multiSelect: false
  }]
})
```

**Output (if no progress):**

```yaml
decision: "no_progress"
exists: false
```

**Output (if user chooses resume):**

```yaml
decision: "resume"
exists: true
resume_phase: 3
phase_name: "Configuration"
collected_data:
  vendor_key: "vault"
  vendor_name: "HashiCorp Vault"
  setup_mode: "full_setup"
  auth_method: "token"
```

**Output (if user chooses start over):**

```yaml
decision: "start_over"
exists: false                # File was deleted
previous_data:               # Data from deleted file (for reference)
  vendor_key: "vault"
```

---

## Progress File Format

### Full Format Specification

```markdown
# {Display Name} Setup Progress

## Status

- **Started**: {ISO 8601 timestamp}
- **Updated**: {ISO 8601 timestamp}
- **Current Phase**: Phase {N} - {Phase Name}
- **Setup Mode**: {mode or "pending"}

## Completed Steps

- [x] Phase 0: {Phase Name} ({HH:MM:SS})
- [x] Phase 1: {Phase Name} ({HH:MM:SS})
- [ ] Phase 2: {Phase Name} <- CURRENT
- [ ] Phase 3: {Phase Name}
- [ ] Phase 4: {Phase Name}

## Collected Information

- **{key}**: {value}
- **{key2}**: {value2}

## Notes

- {Note 1}
- {Note 2}
```

### Parsing Rules

| Section | Start Marker | Format |
|---------|--------------|--------|
| Status | `## Status` | `- **{Key}**: {Value}` |
| Phases | `## Completed Steps` | `- [{x/ }] Phase {N}: {Name}` |
| Data | `## Collected Information` | `- **{key}**: {value}` |
| Notes | `## Notes` | `- {text}` |

### Current Phase Detection

The current phase is marked with `<- CURRENT` suffix:

```markdown
- [ ] Phase 3: Configuration <- CURRENT
```

### Completed Phase Detection

Completed phases have `[x]` checkbox:

```markdown
- [x] Phase 2: Prerequisites (10:35:00)
```

---

## Error Handling

### File Not Found

When reading a non-existent file:

```yaml
exists: false
error: null                  # Not an error, just doesn't exist
```

### Corrupted File

When file exists but can't be parsed:

```yaml
exists: true
error: "parse_error"
error_message: "Could not parse phase information"
raw_content: "..."           # First 500 chars for debugging
suggestion: "Delete file and restart setup, or fix manually"
```

### Permission Error

When can't write to file:

```yaml
success: false
error: "permission_denied"
error_message: "Cannot write to secrets-setup-progress.md"
suggestion: "Check file permissions or try a different location"
```

---

## Usage by Consumer Skills

### Example: setup-secrets Integration

```markdown
### Phase 0: State Detection

#### Step 1: Check for Progress

Invoke track-setup-progress:

operation: resume
domain: secrets

**Handle response:**

- If `decision: "no_progress"` → Proceed to Phase 1
- If `decision: "resume"` → Skip to `resume_phase` with `collected_data`
- If `decision: "start_over"` → Proceed to Phase 1

#### Step 2: (After vendor selection) Create Progress

Invoke track-setup-progress:

operation: create
domain: secrets
display_name: "Secrets Management"
phases:
  - key: 0
    name: "State Detection"
  # ... all phases
initial_phase: 2
initial_data:
  vendor_key: "{selected_vendor}"

### After Each Phase

Invoke track-setup-progress:

operation: update
domain: secrets
complete_phase: {current_phase}
set_phase: {next_phase}
add_data:
  {new_collected_key}: {value}

### After Final Phase

Invoke track-setup-progress:

operation: complete
domain: secrets
```

---

## Best Practices

### What to Store in `collected_data`

**DO store:**
- Vendor/tool selections
- Setup mode choices
- Configuration file paths
- Auth method selections
- Non-sensitive identifiers

**DON'T store:**
- Passwords, tokens, API keys
- Full file contents
- Sensitive user information
- Temporary/derived values

### When to Update Progress

1. **After user makes a choice** - Vendor selection, auth method, etc.
2. **After phase completion** - Mark phase complete, move to next
3. **Before operations that might fail** - Save state before risky ops
4. **Before Claude Code reload** - Ensure state is persisted

### Handling Reload Scenarios

For operations requiring Claude Code reload (like MCP setup):

```yaml
# Before reload
operation: update
domain: mcp
set_phase: 5
add_note: "Waiting for Claude Code reload to activate MCP"

# After reload - consumer skill checks:
operation: read
domain: mcp
# If phase 5 with reload note → continue from Phase 5
```

---

## Dependency Declaration

Consumer skills should declare dependency:

```yaml
dependencies:
  - skill: track-setup-progress
    operations_used:
      - check
      - create
      - update
      - read
      - complete
      - resume
```
