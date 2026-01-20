---
name: setup-project
description: Main project setup wizard. Detects CLAUDE.md status, shows domain configuration progress, and guides through setting up unconfigured domains.
---

# Setup Project

The main entry point for project configuration. This skill orchestrates the setup of all project domains by:
1. Checking if CLAUDE.md exists
2. Detecting which domains are configured vs pending
3. Guiding the user through configuring selected domains
4. Updating CLAUDE.md with results

## Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Check CLAUDE.md                                         │
│  Does it exist? → Create from template or update existing        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: Load Domains                                            │
│  Read plugins/crunch/data/domains.yaml                           │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: Analyze Domain Status                                   │
│  For each domain section in CLAUDE.md:                           │
│    - Has unchecked boxes [ ] → pending                           │
│    - All boxes checked [x] → configured ✓                        │
│    - No boxes → configured ✓                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: Present Domain Selector                                 │
│  ✓ Tech Stack (configured)                                       │
│    Secrets (2 pending)                                           │
│    Task Management (3 pending)                                   │
│  ✓ Pipelines (configured)                                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 5: Execute Domain Setup                                    │
│  Read unchecked items → perform actions → mark done              │
│  Update CLAUDE.md with results                                   │
└─────────────────────────────────────────────────────────────────┘
```

## Definition of Done

A domain is considered configured when:
- All checkboxes in its section are checked `[x]`
- Or the section has no checkboxes (static content only)

The skill session is complete when:
- User has configured selected domains
- CLAUDE.md is updated with results
- User exits the domain selector

---

## Workflow

### Step 1: Check CLAUDE.md Existence

```bash
test -f CLAUDE.md && echo "exists" || echo "missing"
```

**If missing:**

```typescript
AskUserQuestion({
  questions: [{
    question: "No CLAUDE.md found. Would you like to create one?",
    header: "Create",
    options: [
      { label: "Yes, create from template", description: "Use the full project template" },
      { label: "Yes, minimal", description: "Create with just essential sections" },
      { label: "No, skip", description: "Exit setup" }
    ],
    multiSelect: false
  }]
})
```

If creating, copy from `plugins/crunch/templates/CLAUDE.template.md`.

**If exists:**

```typescript
AskUserQuestion({
  questions: [{
    question: "Found existing CLAUDE.md. What would you like to do?",
    header: "Action",
    options: [
      { label: "Configure domains", description: "Set up unconfigured project domains" },
      { label: "View status", description: "Show configuration status for all domains" },
      { label: "Reset", description: "Replace with fresh template" }
    ],
    multiSelect: false
  }]
})
```

---

### Step 2: Load Domain Definitions

Read the canonical domain list:

```bash
cat plugins/crunch/data/domains.yaml
```

Extract domain names and keys:

```yaml
domains:
  - { name: "Tech Stack", key: "tech-stack", required: true }
  - { name: "Configuration", key: "configuration", required: true }
  - { name: "Secrets", key: "secrets", required: true }
  # ... etc
```

---

### Step 3: Analyze Domain Status in CLAUDE.md

For each domain, find its section and count checkboxes:

```bash
# Extract section content between ## Domain Name and next ## or EOF
# Count unchecked [ ] and checked [x] boxes
```

**Parsing logic:**

```python
def analyze_domain(claude_md_content, domain_name):
    # Find section starting with "## {domain_name}"
    section = extract_section(claude_md_content, f"## {domain_name}")

    if section is None:
        return { "status": "missing", "pending": 0, "done": 0 }

    unchecked = count_pattern(section, r"- \[ \]")
    checked = count_pattern(section, r"- \[x\]")

    if unchecked == 0:
        return { "status": "configured", "pending": 0, "done": checked }
    else:
        return { "status": "pending", "pending": unchecked, "done": checked }
```

**Result structure:**

```yaml
domain_status:
  - name: "Tech Stack"
    status: configured  # or "pending" or "missing"
    pending_count: 0
    done_count: 2

  - name: "Secrets"
    status: pending
    pending_count: 2
    done_count: 0
    pending_items:
      - "Setup vendor for Secrets"
      - "Update this section with vendor-specific operation commands"
```

---

### Step 4: Present Domain Selector

Show domains grouped by status:

```
Project Setup - Domain Status
=============================

Required Domains:
  ✓ Tech Stack
    Configuration (2 pending)
  ✓ Secrets
    Pipelines (1 pending)
    Deploy Environments (3 pending)
    Task Management (2 pending)
    Agents & Orchestration

Optional Domains:
    Memory Management (2 pending)
    User Communication Bot (2 pending)
    CI/CD (2 pending)
  ✓ Observability
    Problem Remediation (2 pending)
    Documentation (2 pending)
    Localization (2 pending)
```

```typescript
// Present domains with pending items first
const pendingDomains = domains.filter(d => d.status === "pending");
const configuredDomains = domains.filter(d => d.status === "configured");

AskUserQuestion({
  questions: [{
    question: "Which domain would you like to configure?",
    header: "Domain",
    options: [
      ...pendingDomains.slice(0, 3).map(d => ({
        label: d.name,
        description: `${d.pending_count} pending items`
      })),
      { label: "Show all domains", description: "See complete list" }
    ],
    multiSelect: false
  }]
})
```

---

### Step 5: Execute Domain Setup

When user selects a domain:

#### Step 5.1: Extract Pending Checkboxes

```bash
# Get the section content
section=$(sed -n '/^## Secrets$/,/^## /p' CLAUDE.md | head -n -1)

# Extract unchecked items
echo "$section" | grep -E "^- \[ \]"
```

**Example pending items:**

```
- [ ] Setup vendor for Secrets
- [ ] Update this section with vendor-specific operation commands
```

#### Step 5.2: Parse Action from Checkbox

Each checkbox text maps to an action:

| Checkbox Pattern | Action |
|------------------|--------|
| `Prompt user with {schema}` | Invoke `prompt-user` skill with schema file |
| `Setup vendor for {domain}` | Invoke `setup-project-domain-vendor` for domain |
| `Update this section with...` | Mark as done after previous action completes |
| `Document ... in this section` | Write collected data to section |
| `If SSH access exists, help verify` | Run SSH connectivity test |

#### Step 5.3: Execute Action

**For "Prompt user with schema":**

```yaml
# Read schema file
schema_path: "plugins/crunch/schemas/tech-stack.schema.yaml"

# Invoke prompt-user skill
invoke: prompt-user
schema_file: "{schema_path}"

# Capture result
result:
  platforms: ["web_frontend"]
  languages: ["TypeScript"]
  primary_language: "TypeScript"
  # ...
```

**For "Setup vendor":**

```yaml
invoke: setup-project-domain-vendor
domain: "secrets"

# Capture result
result:
  vendor: "Vault"
  integration: "CLI"
  # ...
```

#### Step 5.4: Update CLAUDE.md

After action completes:

1. **Mark checkbox as done:**

```bash
# Replace "- [ ] Setup vendor for Secrets" with "- [x] Setup vendor for Secrets"
sed -i '' 's/- \[ \] Setup vendor for Secrets/- [x] Setup vendor for Secrets/' CLAUDE.md
```

2. **Insert action result into section:**

For `prompt-user` results, format and insert below the checkbox:

```markdown
## Tech Stack

- [x] Prompt user with `plugins/crunch/schemas/tech-stack.schema.yaml` to collect tech stack info
- [x] Document environments and access status in this section ( use natural language )

This project is a **TypeScript** web frontend application using **Next.js** framework.

**Platforms:** web_frontend
**Languages:** TypeScript (primary)
**Package Managers:** npm
**Test Frameworks:** Playwright

**Web Frontend:**
- Framework: Next.js
- Test Frameworks: Playwright
```

For `setup-vendor` results:

```markdown
## Secrets

- [x] Setup vendor for Secrets
- [x] Update this section with vendor-specific operation commands

**Vendor:** HashiCorp Vault
**Integration:** CLI
**Auth Method:** Token

### Operations

| Operation      | Command                           |
|----------------|-----------------------------------|
| Create secret  | `vault kv put secret/name key=val`|
| Read secret    | `vault kv get secret/name`        |
| Delete secret  | `vault kv delete secret/name`     |
| List secrets   | `vault kv list secret/`           |
```

#### Step 5.5: Return to Domain Selector

After completing a domain, return to step 4 to let user select another domain or exit.

---

## Action Handlers

### Handler: Prompt User with Schema

```yaml
pattern: "Prompt user with `{schema_path}`"

action:
  - read_schema: "{schema_path}"
  - invoke_skill: prompt-user
  - capture_result: structured_data
  - format_output: natural_language
  - update_section: append_below_checkbox
  - mark_checkbox: done
```

### Handler: Setup Vendor

```yaml
pattern: "Setup vendor for {domain}"

action:
  - invoke_skill: setup-project-domain-vendor
    args:
      domain: "{domain}"
  - capture_result: vendor_config
  - format_output: vendor_section
  - update_section: append_operations_table
  - mark_checkbox: done
```

### Handler: Verify SSH Connectivity

```yaml
pattern: "If SSH access exists, help verify SSH connectivity"

action:
  - read_section: extract_ssh_details
  - for_each: ssh_host
    run: |
      ssh -o ConnectTimeout=5 -o BatchMode=yes {user}@{host} -p {port} "echo OK"
  - format_output: connectivity_status
  - update_section: append_status
  - mark_checkbox: done
```

### Handler: Document in Section

```yaml
pattern: "Document .* in this section"

action:
  # This is typically auto-completed after prompt-user or setup-vendor
  - check_previous_action: has_output
  - if_true: mark_checkbox_done
  - if_false: skip  # Will be done when previous action completes
```

---

## Interactive Checkpoints

- [ ] "No CLAUDE.md found. Create one?"
- [ ] "Which domain would you like to configure?"
- [ ] For each pending item: execute action
- [ ] "Domain configured. Configure another?"

---

## Error Handling

| Error | Recovery |
|-------|----------|
| CLAUDE.md parse error | Show error, offer to reset to template |
| Schema file not found | Skip action, mark as failed |
| Skill invocation fails | Show error, offer retry or skip |
| SSH connection fails | Show error, continue with other hosts |

---

## Example Session

```
User: /setup-project

Claude: Found existing CLAUDE.md. What would you like to do?
  > Configure domains

Claude:
Project Setup - Domain Status
=============================
  ✓ Tech Stack
    Secrets (2 pending)
    Deploy Environments (3 pending)
  ✓ Task Management

Which domain would you like to configure?
  > Secrets

Claude: Setting up Secrets domain...

Pending items:
  1. Setup vendor for Secrets
  2. Update this section with vendor-specific operation commands

Starting: Setup vendor for Secrets
Which secrets management solution would you like to use?
  > Vault

[... vendor setup flow ...]

✓ Vendor configured: HashiCorp Vault
✓ Updated CLAUDE.md with Secrets configuration

Secrets domain is now configured!

Which domain would you like to configure next?
  > Exit

Claude: Project setup complete.
Configured: Tech Stack, Secrets, Task Management
Pending: Deploy Environments (3 items)
```
