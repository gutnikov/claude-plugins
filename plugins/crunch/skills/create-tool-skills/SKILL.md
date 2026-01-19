---
name: create-tool-skills
description: Meta-skill for creating enable/use/disable skill sets for external tools. Generates SKILL.md files following the Tool Skill Specification with Vault as reference.
---

# Create Tool Skills

This meta-skill guides you through creating a complete skill set (enable, use, disable) for an external tool, following the Tool Skill Specification.

## Definition of Done

The skill creation is complete when:

1. Three skill directories are created: `{tool}-enable/`, `{tool}-use/`, `{tool}-disable/`
2. Each directory contains a valid SKILL.md with all required sections
3. All SKILL.md files follow the specification format
4. The skill set passes the integration checklist

## Reference Documents

Before proceeding, read these files for context:

1. **Specification**: `plugins/crunch/skills/create-tool-skills/TOOL-SKILL-SPECIFICATION.md`
2. **Enable Example**: `plugins/crunch/skills/vault-enable/SKILL.md`
3. **Use Example**: `plugins/crunch/skills/vault-use/SKILL.md`
4. **Disable Example**: `plugins/crunch/skills/vault-disable/SKILL.md`

## Workflow

### Phase 1: Gather Tool Information

Ask the user for:

1. **Tool name** (lowercase, e.g., `redis`, `postgres`, `s3`)
   - "What tool do you want to create skills for?"

2. **Tool category** for CLAUDE.md documentation:
   - Secrets Management
   - Task Management
   - Communication
   - Database
   - Storage
   - Monitoring
   - Other (specify)

3. **Tool description** (one sentence explaining what the tool does)

4. **Setup modes** the tool supports:
   - Full Setup (install locally)
   - Connect Only (connect to existing)
   - Both (most common)

5. **Authentication methods** the tool uses:
   - Token/API Key
   - Username/Password
   - OAuth
   - Certificate
   - IAM/Role-based
   - Other

6. **Primary operations** the tool supports (for use skill):
   - Get/Read
   - Set/Write/Create
   - List
   - Delete
   - Update/Patch
   - Other (specify)

7. **Environment variables** needed:
   - Address/URL variable (e.g., `REDIS_URL`)
   - Auth variable(s) (e.g., `REDIS_PASSWORD`)
   - Other required variables

8. **CLI command** (if applicable):
   - Command name (e.g., `redis-cli`, `psql`, `aws s3`)
   - Or SDK/API only

### Phase 2: Create Directory Structure

Create the skill directories:

```bash
mkdir -p plugins/crunch/skills/{tool}-enable
mkdir -p plugins/crunch/skills/{tool}-use
mkdir -p plugins/crunch/skills/{tool}-disable
```

### Phase 3: Generate Enable Skill

Create `plugins/crunch/skills/{tool}-enable/SKILL.md` with:

#### Required Sections

1. **Frontmatter**

   ```yaml
   ---
   name: {tool}-enable
   description: Interactive setup wizard for {Tool Name} integration. Guides user through enabling {tool}, configuring authentication, and verifying access.
   ---
   ```

2. **Title and Introduction**

   ```markdown
   # Enable {Tool Name}

   This skill guides users through the complete end-to-end process of setting up {Tool Name} for {purpose} in their project.
   ```

3. **Definition of Done**
   - Tool is accessible (local or remote)
   - Authentication is configured
   - User successfully performs a test operation
   - Configuration documented in CLAUDE.md
   - Progress file cleaned up

4. **Setup Modes** table

5. **Progress Tracking** section with file format

6. **Workflow** with phases:
   - Phase 0: Check for Existing Installation & Progress
   - Phase 1: Prerequisites & Mode Selection
   - Phase 2A: Install {Tool} (Full Setup)
   - Phase 2B: Gather Connection Details (Connect Only)
   - Phase 3: Configure Environment
   - Phase 4: Connection Test
   - Phase 5: Completion

7. **Error Handling** with common issues

8. **Interactive Checkpoints**

9. **Related Skills** referencing use and disable

#### Template Substitutions

Replace these placeholders:

- `{tool}` → lowercase tool name (e.g., `redis`)
- `{Tool}` → capitalized tool name (e.g., `Redis`)
- `{Tool Name}` → full tool name (e.g., `Redis`)
- `{TOOL}` → uppercase for env vars (e.g., `REDIS`)
- `{purpose}` → tool's purpose (e.g., "caching", "database", "secrets management")
- `{test_command}` → command to test connection
- `{test_write}` → command to write test data
- `{test_read}` → command to read test data

### Phase 4: Generate Use Skill

Create `plugins/crunch/skills/{tool}-use/SKILL.md` with:

#### Required Sections

1. **Frontmatter**

   ```yaml
   ---
   name: {tool}-use
   description: {Tool Name} operations skill. Performs {operations} operations by detecting configuration from CLAUDE.md.
   ---
   ```

2. **Title and Introduction**

   ```markdown
   # Use {Tool Name}

   This skill provides a unified interface for {Tool Name} operations by detecting the configuration from CLAUDE.md and executing the appropriate commands.
   ```

3. **How It Works** (4-step flow)

4. **Backend Detection** (what to look for in CLAUDE.md)

5. **Pre-flight Check** (environment validation)

6. **Operations** (one section per operation):
   - Parse from user request
   - Commands
   - Response format

7. **Response Format** (success/error templates)

8. **Error Handling** with error table

9. **Interactive Checkpoints** (confirmations for destructive operations)

10. **Related Skills** referencing enable and disable

### Phase 5: Generate Disable Skill

Create `plugins/crunch/skills/{tool}-disable/SKILL.md` with:

#### Required Sections

1. **Frontmatter**

   ```yaml
   ---
   name: {tool}-disable
   description: Disable {Tool Name} configuration in the project with tiered cleanup options - from config-only to complete system removal.
   ---
   ```

2. **Title and Introduction**

   ```markdown
   # Disable {Tool Name}

   This skill disables {Tool Name} configuration in the project with tiered cleanup options.
   ```

3. **Definition of Done**
   - {Tool} section removed from CLAUDE.md
   - Environment variables cleaned up (per tier)
   - User confirms removal complete

4. **Progress Tracking** section

5. **Disable Tiers** table (3 tiers)

6. **Workflow** with phases:
   - Phase 0: Check for Existing Progress
   - Phase 1: Assessment (inventory)
   - Phase 2: Confirmation (tier selection)
   - Phase 3: Execution
   - Phase 4: Verification
   - Phase 5: Cleanup

7. **Error Handling**

8. **Interactive Checkpoints**

9. **Related Skills** referencing enable and use

### Phase 6: Verification

After generating all three skills, verify:

#### Checklist

**Enable Skill:**

- [ ] Frontmatter with name and description
- [ ] Clear Definition of Done
- [ ] Setup modes table
- [ ] Progress tracking specification
- [ ] Phase 0 checks existing installation
- [ ] Multiple setup paths (full/connect)
- [ ] Test operation before completion
- [ ] CLAUDE.md documentation format
- [ ] Progress file cleanup
- [ ] Error handling section
- [ ] Interactive checkpoints
- [ ] Related skills references

**Use Skill:**

- [ ] Frontmatter with name and description
- [ ] How It Works section
- [ ] Backend detection from CLAUDE.md
- [ ] Pre-flight validation
- [ ] All operations documented
- [ ] Consistent response format
- [ ] Error handling section
- [ ] Destructive operation confirmations
- [ ] Related skills references

**Disable Skill:**

- [ ] Frontmatter with name and description
- [ ] Clear Definition of Done
- [ ] Tiered cleanup options (3 tiers)
- [ ] Progress tracking for disable
- [ ] Phase 0 checks existing progress
- [ ] Inventory before removal
- [ ] Individual confirmation for destructive actions
- [ ] Verification phase
- [ ] Rollback guidance
- [ ] Related skills references

#### Integration Check

Verify the skill set works together:

1. Enable creates config that Use can detect
2. Use suggests Enable when config missing
3. Disable removes all traces Enable created
4. Enable can start fresh after Disable

### Phase 7: Completion

Display summary:

```
✓ Tool skills created for {Tool Name}!

Created:
  plugins/crunch/skills/{tool}-enable/SKILL.md
  plugins/crunch/skills/{tool}-use/SKILL.md
  plugins/crunch/skills/{tool}-disable/SKILL.md

Available commands:
  /{tool}-enable  - Set up {Tool Name}
  /{tool}-use     - Perform {tool} operations
  /{tool}-disable - Remove {Tool Name} configuration

Next steps:
1. Review generated SKILL.md files
2. Customize tool-specific commands and error messages
3. Test the skill set with a real {tool} instance
```

---

## Skill Templates

### Enable Skill Template

```markdown
---
name: {tool}-enable
description: Interactive setup wizard for {Tool Name} integration. Guides user through enabling {tool}, configuring authentication, and verifying access.
---

# Enable {Tool Name}

This skill guides users through the complete end-to-end process of setting up {Tool Name} for {purpose} in their project.

## Definition of Done

The setup is complete when:

1. {Tool Name} is accessible (either local or remote)
2. Authentication is configured
3. User successfully performs a test operation via {Tool Name}

## Setup Modes

| Mode             | Description                                    | Use When                           |
|------------------|------------------------------------------------|------------------------------------|
| **Full Setup**   | Install {tool} + run locally                   | Starting fresh, local development  |
| **Connect Only** | Configure client to connect to existing {tool} | Production instance, shared server |

## Progress Tracking

### Progress File: `{tool}-setup-progress.md`

Location: Project root (`./{tool}-setup-progress.md`)

**Format:**

\`\`\`markdown

# {Tool Name} Setup Progress

## Status

- **Started**: {timestamp}
- **Current Phase**: Phase {N} - {Phase Name}
- **Setup Mode**: {Selected Mode}

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [ ] Phase 2: {Next Phase} ← CURRENT
- [ ] Phase 3: ...

## Collected Information

- **Setup Mode**: {value}
- **Address**: {value}
- **Auth Method**: {value}
  \`\`\`

### Progress Tracking Rules

1. Create progress file at Phase 1 start
2. Update after each phase completion
3. Store non-sensitive data only
4. Delete only after successful DoD verification
5. Check for existing progress on session start

## Workflow

### Phase 0: Check for Existing Installation & Progress

**ALWAYS start here.**

1. Check for existing configuration in CLAUDE.md
2. Check for progress file from interrupted setup
3. Offer appropriate options based on findings

### Phase 1: Prerequisites & Mode Selection

1. Ask user which setup mode they need
2. Create progress file
3. Branch to appropriate path

### Phase 2A: Install {Tool Name} (Full Setup)

1. Check if {tool} is already installed
2. Install based on OS (brew/apt/binary)
3. Verify installation

### Phase 2B: Gather Connection Details (Connect Only)

1. Ask for {tool} address/URL
2. Ask for authentication credentials
3. Collect any additional configuration

### Phase 3: Configure Environment

1. Ask about configuration approach (.env / shell profile / environment)
2. Write configuration
3. Verify .gitignore includes credential files

### Phase 4: Connection Test

1. Check {tool} status/connectivity
2. Perform test write operation
3. Perform test read operation
4. Confirm with user

### Phase 5: Completion

1. Document configuration in CLAUDE.md
2. Provide next steps and common commands
3. Clean up progress file

## Error Handling

### Common Issues

**"connection refused" error:**

- {Tool} not running
- Wrong address/port
- Firewall blocking connection

**"authentication failed" error:**

- Invalid credentials
- Credentials expired
- Wrong auth method

### Error Table

| Error                | Cause               | Solution                      |
|----------------------|---------------------|-------------------------------|
| `connection refused` | Service not running | Start {tool} or check address |
| `auth failed`        | Invalid credentials | Check credentials, regenerate |

## Interactive Checkpoints

- [ ] "Which setup mode: Full Setup or Connect Only?"
- [ ] "Configuration saved. Ready to test?"
- [ ] "Test successful. Setup complete?"

## Related Skills

- `/{tool}-use` - Perform {tool} operations
- `/{tool}-disable` - Remove {tool} configuration
```

### Use Skill Template

```markdown
---
name: {tool}-use
description: {Tool Name} operations skill. Performs {operations} operations by detecting configuration from CLAUDE.md.
---

# Use {Tool Name}

This skill provides a unified interface for {Tool Name} operations by detecting the configuration from CLAUDE.md and executing the appropriate commands.

## How It Works

1. **Read CLAUDE.md** to detect {tool} configuration
2. **Verify connection** to {tool}
3. **Execute the requested operation**
4. **Return results** in a consistent format

## Backend Detection

**Read CLAUDE.md from project root and look for:**

\`\`\`markdown

## {Category}

### {Tool Name}

- **Status**: Configured
- **Address**: {address}
- **Auth method**: {method}
  \`\`\`

**If {tool} not detected:**

- Inform user: "No {tool} configuration found in CLAUDE.md"
- Suggest: "Run `/{tool}-enable` to set up {Tool Name}"

## Pre-flight Check

Before any operation:

\`\`\`bash

# Load from .env if specified

source .env 2>/dev/null || true

# Check required variables

echo ${TOOL}\_URL
echo ${TOOL}\_AUTH
\`\`\`

**If not configured:**

\`\`\`
⚠️ {Tool Name} environment not configured.

{TOOL}\_URL or authentication not set.

To fix:

1. Check CLAUDE.md for {tool} configuration
2. Ensure .env contains required variables
3. Or run: /{tool}-enable
   \`\`\`

## Operations

### Get {Resource}

**Parse from user request:**

- Resource identifier
- Specific field (optional)

**Commands:**
\`\`\`bash
{tool_command} get <resource>
\`\`\`

**Response:**
\`\`\`
✓ {Resource} retrieved: <identifier>

Value: **\*\*\*** (hidden)
\`\`\`

### Set {Resource}

**Parse from user request:**

- Resource identifier
- Value(s) to set

**Confirmation:**
\`\`\`
You're about to set: <identifier>
Value: [hidden]

Proceed? (yes/no)
\`\`\`

**Commands:**
\`\`\`bash
{tool_command} set <resource> <value>
\`\`\`

**Response:**
\`\`\`
✓ {Resource} stored: <identifier>

Backend: {Tool Name}
\`\`\`

### List {Resources}

**Commands:**
\`\`\`bash
{tool_command} list <path>
\`\`\`

**Response:**
\`\`\`
✓ {Resources} in <path>:

- item1
- item2
- item3

Total: 3 items
\`\`\`

### Delete {Resource}

**Confirmation required:**
\`\`\`
⚠️ You're about to delete: <identifier>

This action cannot be undone. Continue? (yes/no)
\`\`\`

**Commands:**
\`\`\`bash
{tool_command} delete <resource>
\`\`\`

**Response:**
\`\`\`
✓ {Resource} deleted: <identifier>

Backend: {Tool Name}
\`\`\`

## Response Format

### Success

\`\`\`
✓ {Operation} complete: <identifier>

{Details}
Backend: {Tool Name}
\`\`\`

### Error

\`\`\`
✗ Failed to {operation}: <identifier>

Error: <message>
Backend: {Tool Name}

Suggestions:

- <suggestion>
  \`\`\`

## Error Handling

### Error Table

| Error                | Cause               | Solution                      |
|----------------------|---------------------|-------------------------------|
| `connection refused` | Service not running | Start {tool} or check address |
| `not found`          | Resource missing    | Verify path/identifier        |
| `permission denied`  | Auth issue          | Check credentials             |

## Interactive Checkpoints

- [ ] Confirm before set/write operations (optional)
- [ ] Confirm before delete operations (required)

## Related Skills

- `/{tool}-enable` - Set up {Tool Name}
- `/{tool}-disable` - Remove {Tool Name} configuration
```

### Disable Skill Template

```markdown
---
name: {tool}-disable
description: Disable {Tool Name} configuration in the project with tiered cleanup options - from config-only to complete system removal.
---

# Disable {Tool Name}

This skill disables {Tool Name} configuration in the project with tiered cleanup options.

## Definition of Done

The disable is complete when:

1. {Tool Name} section is removed from CLAUDE.md
2. Environment variables are cleaned up (based on tier)
3. User confirms the removal is complete

## Progress Tracking

### Progress File: `{tool}-disable-progress.md`

Location: Project root

**Format:**

\`\`\`markdown

# {Tool Name} Disable Progress

## Status

- **Started**: {timestamp}
- **Current Phase**: Phase {N}
- **Selected Tier**: {tier}

## Completed Steps

- [x] Phase 1: Assessment
- [ ] Phase 2: Confirmation ← CURRENT
- [ ] Phase 3: Execution
- [ ] Phase 4: Verification
- [ ] Phase 5: Cleanup

## Inventory

- CLAUDE.md section: Found/Not found
- .env entries: Found/Not found
- Binary: Found/Not found
  \`\`\`

## Disable Tiers

| Tier | Name         | What It Removes                                | Use When              |
|------|--------------|------------------------------------------------|-----------------------|
| 1    | Config Only  | CLAUDE.md section, .env entries                | Switching backends    |
| 2    | Full Project | Above + progress files                         | Clean project removal |
| 3    | Complete     | Above + binary, token files, running processes | Full system cleanup   |

## Workflow

### Phase 0: Check for Existing Progress

1. Check for progress file from interrupted disable
2. Offer to resume or start over

### Phase 1: Assessment

Inventory what components exist:

\`\`\`bash

# Check CLAUDE.md

grep -A 10 "### {Tool Name}" CLAUDE.md

# Check .env

grep "^{TOOL}\_" .env

# Check binary

which {tool_command}

# Check running processes

pgrep -f "{tool}"
\`\`\`

Display inventory to user.

### Phase 2: Confirmation

Present tiered options:

\`\`\`
How would you like to disable {Tool Name}?

1. Config Only (Light)
   - Remove CLAUDE.md section
   - Remove .env entries

2. Full Project (Medium) - Recommended
   - Everything above
   - Remove progress files

3. Complete (Heavy)
   - Everything above
   - Stop running processes
   - Remove token/credential files
   - Uninstall binary
     \`\`\`

For Tier 3, confirm each destructive action individually.

### Phase 3: Execution

Perform removal based on selected tier.

### Phase 4: Verification

Confirm each component was removed:

\`\`\`bash

# Verify CLAUDE.md

grep "{Tool Name}" CLAUDE.md # Should return nothing

# Verify .env

grep "^{TOOL}\_" .env # Should return nothing
\`\`\`

### Phase 5: Cleanup

1. Remove disable progress file
2. Display final status
3. Suggest `/{tool}-enable` for re-setup

## Error Handling

### Common Issues

**Cannot modify CLAUDE.md:**

- File is read-only
- Section not in expected format

**Cannot modify .env:**

- File is read-only
- File doesn't exist

## Interactive Checkpoints

- [ ] "Which disable tier?"
- [ ] For Tier 3: Confirm each destructive action
- [ ] "Disable complete. Verify removal worked?"

## Related Skills

- `/{tool}-enable` - Set up {Tool Name}
- `/{tool}-use` - Perform {tool} operations
```

---

## Error Handling

### Common Issues

**Tool name conflicts:**

- Check if skill directories already exist
- Offer to overwrite or rename

**Missing specification:**

- Ensure TOOL-SKILL-SPECIFICATION.md exists
- Reference Vault skills as fallback

**Invalid tool name:**

- Must be lowercase
- No spaces (use hyphens)
- No special characters

## Interactive Checkpoints

- [ ] "What tool do you want to create skills for?"
- [ ] "Confirm tool details are correct?"
- [ ] "Skills generated. Review and customize?"
