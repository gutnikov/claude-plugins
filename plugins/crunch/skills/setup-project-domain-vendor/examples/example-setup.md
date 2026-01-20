---
name: setup-secrets
description: Interactive setup wizard for secrets management integration. Guides through vendor selection, configuration, and CLAUDE.md documentation.
---

# Setup Secrets Management

> **This file serves as a reference example for creating domain-specific setup skills.**
> It demonstrates how domain skills consume shared skills for vendor discovery and progress tracking.
> The setup logic focuses on the workflow, while vendor details and progress management come from shared skills.

---

## Architecture

This skill uses a **separation of concerns** pattern with two shared skills:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         setup-secrets                                │
│  (This skill - domain-specific setup workflow)                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Phase 0: State Detection  ◄────────┐                                │
│  Phase 1: Vendor Selection  ◄───────┼──── lookup-vendor              │
│  Phase 2: Prerequisites             │                                │
│  Phase 3: Configuration             │                                │
│  Phase 4: Connection Test           │                                │
│  Phase 5: Documentation             │                                │
│           │                         │                                │
│           └─────────────────────────┼──── track-setup-progress       │
│             (progress after phases) │                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
┌───────────────────────────────┐  ┌───────────────────────────────┐
│        lookup-vendor          │  │    track-setup-progress       │
│  ───────────────────────────  │  │  ───────────────────────────  │
│  • Web search for vendors     │  │  • Create progress files      │
│  • Normalized vendor schema   │  │  • Update phase status        │
│  • Caching                    │  │  • Handle resume/start-over   │
│  • MCP/CLI/API details        │  │  • Cleanup on completion      │
└───────────────────────────────┘  └───────────────────────────────┘
```

---

## Dependencies

This skill depends on shared skills:

```yaml
dependencies:
  - skill: lookup-vendor
    operations_used:
      - discover    # Get list of vendors for domain
      - get         # Get full vendor details
      - search      # Find vendor by name

  - skill: track-setup-progress
    operations_used:
      - resume      # Check for existing progress, handle user decision
      - create      # Create new progress file
      - update      # Update phase status and collected data
      - complete    # Mark complete and cleanup

  - skill: setup-mcp
    use_when: "vendor.integrations.mcp.available == true"
    description: "Delegate MCP configuration to setup-mcp skill"
```

---

## Definition of Done

The setup is complete when:

1. Secrets management vendor is selected
2. Required tools are installed (per vendor.integrations.cli.tools)
3. Authentication is configured (per vendor.setup.auth_methods)
4. User successfully executes test operation (per vendor.testing.test_operation)
5. CLAUDE.md is updated with "Secrets Management" section

---

## Progress Tracking

**This skill uses `track-setup-progress` for all progress management.**

Progress file: `secrets-setup-progress.md` (managed by track-setup-progress)

### Phase Definitions

```yaml
phases:
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
```

---

## Workflow

### Phase 0: State Detection

**ALWAYS start here.**

#### Step 1: Check for Existing Configuration

```bash
# Check CLAUDE.md for Secrets Management section
grep -A 10 "## Secrets Management" CLAUDE.md 2>/dev/null
```

**If configured:** Show Management Mode menu (see end of document).

#### Step 2: Check for Progress (using track-setup-progress)

Invoke `track-setup-progress`:

```yaml
operation: resume
domain: secrets
```

**Handle response:**

| Response | Action |
|----------|--------|
| `decision: "no_progress"` | Proceed to Phase 1 |
| `decision: "resume"` | Skip to `resume_phase` with `collected_data` |
| `decision: "start_over"` | Proceed to Phase 1 |

**If resuming:**

```yaml
# Response contains:
resume_phase: 3
phase_name: "Configuration"
collected_data:
  vendor_key: "vault"
  vendor_name: "HashiCorp Vault"
  setup_mode: "full_setup"

# Use collected_data to restore state, skip to resume_phase
```

---

### Phase 1: Vendor Selection

**This phase uses lookup-vendor to discover available vendors.**

#### Step 1: Discover Vendors

Invoke `lookup-vendor`:

```yaml
operation: discover
domain: secrets
```

#### Step 2: Present Selection

Build options from discovery response:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which secrets management solution would you like to set up?",
    header: "Vendor",
    options: vendors.map(v => ({
      label: v.has_mcp ? `${v.name} (MCP available)` : v.name,
      description: `${v.description} - Best for: ${v.best_for}`
    })),
    multiSelect: false
  }]
})
```

#### Step 3: Get Full Vendor Details

Invoke `lookup-vendor`:

```yaml
operation: get
domain: secrets
vendor: "{selected_vendor_key}"
```

#### Step 4: Create Progress File

Invoke `track-setup-progress`:

```yaml
operation: create
domain: secrets
display_name: "Secrets Management"
phases:
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
initial_phase: 2              # Moving to Phase 2
initial_data:
  vendor_key: "{vendor.key}"
  vendor_name: "{vendor.name}"
```

---

### Phase 2: Prerequisites Check

**Use vendor.integrations.cli.tools from lookup-vendor response.**

#### Step 1: Check CLI Tools

```bash
# For each tool in vendor.integrations.cli.tools:
{tool.check}
```

#### Step 2: Install Missing Tools

If missing, use commands from vendor definition:

```bash
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
{tool.install[platform]}
```

#### Step 3: Setup Mode Selection

If `vendor.setup.modes` has multiple options, present choice.

#### Step 4: Update Progress

Invoke `track-setup-progress`:

```yaml
operation: update
domain: secrets
complete_phase: 2
set_phase: 3
add_data:
  setup_mode: "{selected_mode}"
```

---

### Phase 3: Configuration

**Route based on vendor.integrations.**

#### Branch A: MCP Configuration

If `vendor.integrations.mcp.available`:

```json
// Write to .mcp.json
{
  "mcpServers": {
    "{vendor.key}": {
      "command": "npx",
      "args": ["-y", "{vendor.integrations.mcp.community.package}"],
      "env": { "{env_var}": "{value}" }
    }
  }
}
```

#### Branch B: CLI Configuration

If `vendor.integrations.cli.available`:

1. Select auth method from `vendor.setup.auth_methods`
2. Collect credentials
3. Write to `.env` or shell profile

#### Branch C: File-Based Configuration

If `vendor.setup.config_files` exists:

1. Generate keys if needed (`vendor.setup.key_generation`)
2. Create config files from templates

#### Step 4: Update Progress

Invoke `track-setup-progress`:

```yaml
operation: update
domain: secrets
complete_phase: 3
set_phase: 4
add_data:
  auth_method: "{selected_auth}"
  config_location: "{location}"
```

---

### Phase 4: Connection Test

**Use vendor.testing.test_operation.**

#### Step 1: Run Test

```bash
{vendor.testing.test_operation.setup}    # If exists
{vendor.testing.test_operation.write}
{vendor.testing.test_operation.read}
```

#### Step 2: Verify Success

```bash
output | grep -q "{vendor.testing.test_operation.success_indicator}"
```

#### Step 3: Handle Failure

Use `vendor.errors.patterns` to diagnose.

#### Step 4: Cleanup & Update Progress

```bash
{vendor.testing.test_operation.cleanup}
```

Invoke `track-setup-progress`:

```yaml
operation: update
domain: secrets
complete_phase: 4
set_phase: 5
```

---

### Phase 5: Documentation (CLAUDE.md Update)

#### Step 0: Check for Domain Template

```bash
# Check if template exists for this domain
template_path="plugins/crunch/templates/{domain}.template.md"
test -f "$template_path" && echo "template_exists" || echo "no_template"
```

#### Step 1: Generate Content

**Branch A: Template Exists**

If template file exists, use it as the base and augment with collected data:

```bash
# Read template content
cat "plugins/crunch/templates/{domain}.template.md"
```

Process template:
1. Use template content as-is (preserves all static documentation)
2. Replace placeholders with vendor-specific values from `collected_data` and `vendor` definition
3. Append vendor-specific status section at the top

**Placeholder Mapping:**

| Template Placeholder   | Source                                        |
|------------------------|-----------------------------------------------|
| `{create_*_cmd}`       | `vendor.integrations.cli.operations.*.command`|
| `{transition_cmd}`     | `vendor.integrations.cli.operations.*.command`|
| `{search_cmd}`         | `vendor.integrations.cli.operations.*.command`|
| `{*_cmd}`              | Map to appropriate vendor CLI operation       |

**Generated Content (with template):**

```markdown
## {display_name}

### Configuration

- **Status**: Configured
- **Vendor**: {vendor.name}
- **Integration**: {integration_type}
- **Setup Mode**: {collected_data.setup_mode}
- **Auth Method**: {collected_data.auth_method}

{template_content_with_placeholders_replaced}

### Troubleshooting

{for error in vendor.errors.patterns:}
- **{error.pattern}**: {error.solution}
```

**Branch B: No Template**

If no template exists, generate content from vendor definition only:

```markdown
## {display_name}

### {vendor.name}

- **Status**: Configured
- **Integration**: {integration_type}
- **Setup Mode**: {setup_mode}
- **Auth Method**: {auth_method}

### Available Operations

| Operation   | Command                 | Description           |
|-------------|-------------------------|-----------------------|
{for op in vendor.integrations.cli.operations:}
| {op_name}   | `{op.command}`          | {op.description}      |

### Troubleshooting

{for error in vendor.errors.patterns:}
- **{error.pattern}**: {error.solution}
```

#### Step 2: Update CLAUDE.md

- If section exists: Replace
- If section doesn't exist: Append
- If file doesn't exist: Create

#### Step 3: Complete Setup

Invoke `track-setup-progress`:

```yaml
operation: complete
domain: secrets
```

**Response:**

```yaml
completed: true
file_deleted: true
duration: "12m 30s"
```

#### Step 4: Summary

```
Secrets Management Setup Complete!
==================================

Vendor: {vendor.name}
Duration: {duration}
Configuration documented in CLAUDE.md

Available operations:
  • get: {vendor.integrations.cli.operations.get.command}
  • set: {vendor.integrations.cli.operations.set.command}
  • list: {vendor.integrations.cli.operations.list.command}
```

---

## Management Mode

When already configured (detected in Phase 0):

```typescript
AskUserQuestion({
  questions: [{
    question: "What would you like to do?",
    header: "Action",
    options: [
      { label: "Keep current setup", description: "Exit" },
      { label: "Add another vendor", description: "Configure additional vendor" },
      { label: "Change vendor", description: "Switch to different solution" },
      { label: "Test connection", description: "Verify setup works" }
    ],
    multiSelect: false
  }]
})
```

---

## Error Handling

### Using Vendor Error Patterns

```typescript
function diagnoseError(error, vendor) {
  for (const pattern of vendor.errors.patterns) {
    if (error.includes(pattern.pattern)) {
      return {
        cause: pattern.cause,
        solution: pattern.solution,
        action: pattern.recovery_action
      };
    }
  }
  return { cause: "Unknown", solution: "Search for solution", action: "manual" };
}
```

### Generic Fallbacks

| Error | Cause | Solution |
|-------|-------|----------|
| "command not found" | Tool not installed | Re-run Phase 2 |
| "connection refused" | Server not running | Check address |
| "permission denied" | Invalid credentials | Re-run Phase 3 |

---

## Interactive Checkpoints

### Phase 0
- [ ] "Found existing setup. What would you like to do?" (Management Mode)
- [ ] "Found incomplete setup. Resume or start over?" (via track-setup-progress)

### Phase 1
- [ ] "Which secrets management solution would you like to set up?"

### Phase 2
- [ ] "{tool} not installed. Install automatically?"
- [ ] "How would you like to set up {vendor}?"

### Phase 3
- [ ] "How do you want to authenticate?"
- [ ] "Where should I save the configuration?"

### Phase 4
- [ ] "Test successful! Remove test secret?"

### Phase 5
- [ ] "Setup complete!"

---

## Key Patterns

1. **Consume shared skills** - lookup-vendor for vendors, track-setup-progress for state
2. **Schema-driven** - Workflow adapts to vendor definition structure
3. **Integration priority** - Prefer MCP > CLI > API when available
4. **Error patterns** - Use vendor-specific error diagnosis
5. **Progress tracking** - Delegate to track-setup-progress for all state management
6. **CLAUDE.md output** - Self-documenting configuration
