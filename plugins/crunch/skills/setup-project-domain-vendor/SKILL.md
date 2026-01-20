---
name: setup-project-domain-vendor
description: Generic setup wizard for any project domain. Selects a domain, then uses the reference workflow to configure vendor integration and document in CLAUDE.md.
---

# Setup Project Domain Vendor

This skill provides a generic setup wizard that works for any project domain. It dynamically adapts the reference workflow pattern to the selected domain.

## Reference Workflow

**Pattern Location**: `plugins/crunch/skills/setup-project-domain-vendor/examples/example-setup.md`

This reference demonstrates the complete setup workflow including:
- 6-phase structure (State Detection → Vendor Selection → Prerequisites → Configuration → Connection Test → Documentation)
- Integration with `lookup-vendor` and `track-setup-progress` shared skills
- MCP/CLI/file-based configuration branches
- Error handling patterns from vendor definitions
- CLAUDE.md generation

## Definition of Done

The setup is complete when:

1. Domain is selected from the pre-defined list
2. Vendor is selected for that domain (via lookup-vendor)
3. Required tools are installed
4. Authentication/configuration is complete
5. Connection test passes
6. CLAUDE.md is updated with the domain section

## Shared Data

**Domains**: `plugins/crunch/data/domains.yaml`

## Dependencies

```yaml
dependencies:
  - skill: lookup-vendor
    operations_used:
      - discover    # Get list of vendors for selected domain
      - get         # Get full vendor details

  - skill: track-setup-progress
    operations_used:
      - resume      # Check for existing progress
      - create      # Create new progress file
      - update      # Update phase status
      - complete    # Mark complete and cleanup

  - skill: setup-mcp
    use_when: "vendor.integrations.mcp.available == true"
    description: "Delegate MCP configuration to setup-mcp skill"
```

---

## Workflow

### Step 1: Domain Selection

#### Step 1.1: Load Domains

```bash
# Read shared domains data
cat plugins/crunch/data/domains.yaml
```

#### Step 1.2: Check Existing Configurations

```bash
# Check which domains are already configured in CLAUDE.md
for domain in "Tech Stack" "Configuration" "Secrets" "Pipelines" "Deploy Environments" \
              "Task Management" "Agents" "Memory Management" "CI/CD" "Observability" \
              "Documentation" "Localization" "Problem Remediation" "User Communication"; do
  grep -q "## $domain" CLAUDE.md 2>/dev/null && echo "configured: $domain"
done
```

#### Step 1.3: Present Domain Options

```typescript
// Load domains from shared data file
const domains = loadYaml('plugins/crunch/data/domains.yaml').domains;

// Mark configured domains
const domainOptions = domains.map(d => ({
  ...d,
  configured: isConfiguredInClaudeMd(d.name)
}));

// Present required domains first, then optional
const sortedDomains = [
  ...domainOptions.filter(d => d.required && !d.configured),
  ...domainOptions.filter(d => !d.required && !d.configured),
  ...domainOptions.filter(d => d.configured)  // Already configured at end
];

AskUserQuestion({
  questions: [{
    question: "Which project domain would you like to set up?",
    header: "Domain",
    options: sortedDomains.slice(0, 4).map(d => ({
      label: d.configured ? `${d.name} ✓` : d.name,
      description: d.configured ? "Already configured - reconfigure?" : d.purpose
    })),
    multiSelect: false
  }]
})

// Continue pagination if user selects "Other"...
```

---

### Step 2: Enter Plan Mode

After domain selection, **enter plan mode** to plan the setup.

#### Step 2.1: Read Reference Workflow

Read and analyze the reference workflow pattern:

```bash
cat plugins/crunch/skills/setup-project-domain-vendor/examples/example-setup.md
```

#### Step 2.2: Check for Domain Template

```bash
# Check if a template exists for this domain
template_path="plugins/crunch/templates/${domain_key}.template.md"
test -f "$template_path" && cat "$template_path"
```

#### Step 2.3: Create Setup Plan

Create a plan that adapts the reference workflow to the selected domain:

1. **Phase 0: State Detection**
   - Check CLAUDE.md for existing `## {Domain Name}` section
   - Check for `{domain_key}-setup-progress.md` via track-setup-progress

2. **Phase 1: Vendor Selection**
   - Use lookup-vendor to discover vendors for `{domain_key}`
   - Present vendor options with MCP availability highlighted

3. **Phase 2: Prerequisites**
   - Check/install CLI tools from vendor definition
   - Select setup mode if vendor has multiple options

4. **Phase 3: Configuration**
   - Branch based on vendor.integrations (MCP → CLI → file-based)
   - Collect required credentials/settings

5. **Phase 4: Connection Test**
   - Execute vendor.testing.test_operation
   - Handle failures using vendor.errors.patterns

6. **Phase 5: Documentation**
   - Generate CLAUDE.md section using template (if exists) or vendor definition
   - Include troubleshooting from vendor.errors.patterns

---

### Step 3: Execute Setup (After Plan Approval)

Follow the approved plan, executing each phase:

#### Phase 0: State Detection

```yaml
# Check for existing progress
invoke: track-setup-progress
operation: resume
domain: "{domain_key}"
```

Handle response:
- `no_progress` → Continue to Phase 1
- `resume` → Skip to indicated phase with collected data
- `start_over` → Continue to Phase 1

#### Phase 1: Vendor Selection

```yaml
# Discover available vendors
invoke: lookup-vendor
operation: discover
domain: "{domain_key}"
```

Present vendor selection, then get full details:

```yaml
invoke: lookup-vendor
operation: get
domain: "{domain_key}"
vendor: "{selected_vendor_key}"
```

Create progress file:

```yaml
invoke: track-setup-progress
operation: create
domain: "{domain_key}"
display_name: "{Domain Name}"
phases:
  - { key: 0, name: "State Detection" }
  - { key: 1, name: "Vendor Selection" }
  - { key: 2, name: "Prerequisites" }
  - { key: 3, name: "Configuration" }
  - { key: 4, name: "Connection Test" }
  - { key: 5, name: "Documentation" }
initial_phase: 2
initial_data:
  vendor_key: "{vendor.key}"
  vendor_name: "{vendor.name}"
```

#### Phase 2: Prerequisites

Check and install CLI tools from `vendor.integrations.cli.tools`:

```bash
# For each tool
{tool.check}  # e.g., "which vault"

# If missing, install
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
{tool.install[platform]}
```

Update progress:

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
complete_phase: 2
set_phase: 3
add_data:
  setup_mode: "{selected_mode}"
```

#### Phase 3: Configuration

Route based on `vendor.integrations`:

**Branch A: MCP** (if `vendor.integrations.mcp.available`)
```yaml
invoke: setup-mcp
vendor: "{vendor_key}"
package: "{vendor.integrations.mcp.community.package}"
```

**Branch B: CLI** (if `vendor.integrations.cli.available`)
- Select auth method from `vendor.setup.auth_methods`
- Collect credentials
- Write to `.env` or config file

**Branch C: File-based** (if `vendor.setup.config_files`)
- Generate keys if needed
- Create config files from templates

Update progress:

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
complete_phase: 3
set_phase: 4
add_data:
  auth_method: "{selected_auth}"
  config_location: "{location}"
```

#### Phase 4: Connection Test

Execute test from vendor definition:

```bash
{vendor.testing.test_operation.setup}    # If exists
{vendor.testing.test_operation.write}
{vendor.testing.test_operation.read}
```

Verify success:

```bash
output | grep -q "{vendor.testing.test_operation.success_indicator}"
```

On failure, diagnose using `vendor.errors.patterns`.

Cleanup and update:

```bash
{vendor.testing.test_operation.cleanup}
```

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
complete_phase: 4
set_phase: 5
```

#### Phase 5: Documentation

Generate CLAUDE.md content:

**If template exists** (`plugins/crunch/templates/{domain_key}.template.md`):
- Use template as base
- Replace placeholders with vendor-specific values
- Add configuration status section

**If no template**:
- Generate from vendor definition
- Include available operations table
- Add troubleshooting section from vendor.errors.patterns

Update CLAUDE.md (append or replace section).

Complete setup:

```yaml
invoke: track-setup-progress
operation: complete
domain: "{domain_key}"
```

---

### Step 4: Summary

Display completion summary:

```
{Domain Name} Setup Complete!
=============================

Vendor: {vendor.name}
Integration: {integration_type}
Duration: {duration}

Configuration documented in CLAUDE.md

Next steps:
  • {vendor-specific next steps}
```

---

## Management Mode

If domain is already configured (detected in Phase 0):

```typescript
AskUserQuestion({
  questions: [{
    question: "This domain is already configured. What would you like to do?",
    header: "Action",
    options: [
      { label: "Keep current setup", description: "Exit without changes" },
      { label: "Add another vendor", description: "Configure additional vendor" },
      { label: "Change vendor", description: "Switch to different solution" },
      { label: "Test connection", description: "Verify current setup works" }
    ],
    multiSelect: false
  }]
})
```

---

## Interactive Checkpoints

### Domain Selection
- [ ] "Which project domain would you like to set up?"

### Plan Mode
- [ ] Present setup plan for approval

### Phase 1
- [ ] "Which {domain} vendor would you like to use?"

### Phase 2
- [ ] "{tool} not installed. Install automatically?"

### Phase 3
- [ ] "How do you want to authenticate?"
- [ ] "Where should I save the configuration?"

### Phase 4
- [ ] "Test successful! Remove test data?"

### Phase 5
- [ ] "Setup complete!"

---

## Key Patterns

1. **Generic workflow** - Same 6-phase structure works for any domain
2. **Dynamic adaptation** - Workflow adapts based on lookup-vendor response
3. **Shared data** - Domains loaded from `plugins/crunch/data/domains.yaml`
4. **Reference-driven** - Uses example skill as canonical workflow pattern
5. **Plan mode** - Creates domain-specific plan before execution
6. **Template-aware** - Uses domain templates when available
