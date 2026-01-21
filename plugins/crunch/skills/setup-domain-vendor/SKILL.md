---
name: setup-domain-vendor
description: Generic setup wizard for any project domain vendor. Handles domain selection, vendor lookup, tool installation, verification, and CLAUDE.md documentation.
arguments:
  - name: domain
    required: false
    description: "Domain key (e.g., 'secrets', 'task-management'). If omitted, presents a selector."
  - name: vendor
    required: false
    description: "Vendor name (e.g., 'HashiCorp Vault'). If omitted, presents a selector."
---

# Setup Domain Vendor

Interactive wizard that configures a vendor for any project domain.

---

## Arguments

| Argument | Required | Description                                          |
|----------|----------|------------------------------------------------------|
| `domain` | No       | Domain key from `domains.yaml`. Shows selector if omitted. |
| `vendor` | No       | Vendor name. Shows selector if omitted.              |

**Examples:**
- `/setup-domain-vendor` → Domain selector, then vendor selector
- `/setup-domain-vendor secrets` → Vendor selector for Secrets domain
- `/setup-domain-vendor secrets "HashiCorp Vault"` → Direct setup

---

## Definition of Done

Setup is complete when:

1. Domain is selected (from argument or selector)
2. Vendor is selected (from argument or selector)
3. Vendor definition is retrieved via `lookup-vendor`
4. Required tools are installed and verified
5. All `vendor_check` steps pass
6. CLAUDE.md is updated with domain section including operations mapping

---

## Dependencies

```yaml
dependencies:
  - skill: lookup-vendor
    purpose: "Retrieve vendor definition with integrations, operations, and tests"

  - skill: track-setup-progress
    purpose: "Persist state across session restarts"
    operations: [check, create, update, complete, resume]

  - data: plugins/crunch/data/domains.yaml
    purpose: "Domain definitions with vendor_requirements and vendor_check"
```

---

## Workflow

### Phase 0: State Detection

**Check for existing progress file.**

```yaml
invoke: track-setup-progress
operation: resume
domain: "{domain_key}"
```

| Response                  | Action                                           |
|---------------------------|--------------------------------------------------|
| `decision: "no_progress"` | Continue to Phase 1                              |
| `decision: "resume"`      | Skip to `resume_phase` with `collected_data`     |
| `decision: "start_over"`  | Delete progress, continue to Phase 1             |

---

### Phase 1: Domain Selection

**Skip if `domain` argument provided.**

#### Step 1.1: Load Domains

```bash
cat plugins/crunch/data/domains.yaml
```

#### Step 1.2: Check Configured Domains

```bash
# Check which domains have sections in CLAUDE.md
grep -E "^## (Secrets|Task Management|CI/CD|...)" CLAUDE.md 2>/dev/null
```

#### Step 1.3: Present Domain Selector

Only show domains where `has_vendor: true`:

```typescript
const vendorDomains = domains.filter(d => d.has_vendor);

// Sort: unconfigured required first, then unconfigured optional, then configured
const sorted = [
  ...vendorDomains.filter(d => d.required && !d.configured),
  ...vendorDomains.filter(d => !d.required && !d.configured),
  ...vendorDomains.filter(d => d.configured)
];

AskUserQuestion({
  questions: [{
    question: "Which domain would you like to configure?",
    header: "Domain",
    options: sorted.slice(0, 4).map(d => ({
      label: d.configured ? `${d.name} ✓` : d.name,
      description: d.configured ? "Reconfigure?" : d.purpose
    })),
    multiSelect: false
  }]
})
```

---

### Phase 2: Vendor Selection

**Skip if `vendor` argument provided.**

#### Step 2.1: Load Vendor List

```typescript
const domain = domains.find(d => d.key === selectedDomainKey);
const vendors = domain.vendors || [];
```

#### Step 2.2: Present Vendor Selector

```typescript
AskUserQuestion({
  questions: [{
    question: `Which ${domain.name} vendor would you like to use?`,
    header: "Vendor",
    options: vendors.slice(0, 4).map(name => ({
      label: name,
      description: `Set up ${name}`
    })),
    multiSelect: false
  }]
})
// "Other" option allows custom vendor entry
```

---

### Phase 3: Vendor Lookup

**Retrieve vendor definition via `lookup-vendor`.**

```yaml
invoke: lookup-vendor
operation: get
domain: "{domain_key}"
vendor: "{vendor_name}"
```

**Expected response:** Cached or web-searched vendor definition with:
- `integrations` (mcp, cli, api)
- `setup` (environment variables, auth methods)
- `operations` (CRUD commands mapped to domain requirements)
- `testing` (verification steps)
- `errors` (common patterns and solutions)

#### Step 3.1: Create Progress File

```yaml
invoke: track-setup-progress
operation: create
domain: "{domain_key}"
display_name: "{domain.name}"
phases:
  - { key: 0, name: "State Detection" }
  - { key: 1, name: "Domain Selection" }
  - { key: 2, name: "Vendor Selection" }
  - { key: 3, name: "Vendor Lookup" }
  - { key: 4, name: "Installation" }
  - { key: 5, name: "Verification" }
  - { key: 6, name: "Documentation" }
initial_phase: 4
initial_data:
  domain_key: "{domain_key}"
  domain_name: "{domain.name}"
  vendor_key: "{vendor.key}"
  vendor_name: "{vendor.name}"
```

---

### Phase 4: Installation

**Notify user and install required tools.**

#### Step 4.1: Installation Preview

Present what will be installed:

```markdown
## Installation Plan for {vendor.name}

The following will be installed/configured:

### CLI Tool
- **Tool**: `{vendor.integrations.cli.tool_name}`
- **Install**: `{vendor.integrations.cli.install.macos.homebrew}`
- **Verify**: `{vendor.integrations.cli.version_check}`

### Environment Variables
{for each var in vendor.setup.environment_variables:}
- `{var.name}` - {var.description} {var.required ? "(required)" : "(optional)"}

### MCP Server (if available)
- **Status**: {vendor.integrations.mcp.status}
- **Repository**: {vendor.integrations.mcp.repository}

Proceed with installation?
```

```typescript
AskUserQuestion({
  questions: [{
    question: "Ready to install? Review the plan above.",
    header: "Install",
    options: [
      { label: "Yes, install", description: "Proceed with installation" },
      { label: "Skip CLI", description: "I'll install manually" },
      { label: "Cancel", description: "Exit setup" }
    ],
    multiSelect: false
  }]
})
```

#### Step 4.2: Install CLI Tool

```bash
# Check if already installed
{vendor.integrations.cli.version_check}

# If not installed, run install command for current platform
{vendor.integrations.cli.install[platform]}

# Verify installation
{vendor.integrations.cli.version_check}
```

#### Step 4.3: Configure Environment Variables

For each required environment variable:

```typescript
// Check if already set
const isSet = process.env[varName] !== undefined;

if (!isSet) {
  AskUserQuestion({
    questions: [{
      question: `Enter value for ${varName}:`,
      header: varName,
      options: [
        { label: "Enter value", description: var.description },
        { label: "Skip for now", description: "Set manually later" }
      ],
      multiSelect: false
    }]
  })
}
```

#### Step 4.4: Update Progress

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
complete_phase: 4
set_phase: 5
add_data:
  cli_installed: true
  env_vars_configured: ["VAULT_ADDR", "VAULT_TOKEN"]
```

---

### Phase 5: Verification

**Interactively run vendor_check steps and remediate failures.**

#### Step 5.1: Load Verification Steps

Get `vendor_check` from `domains.yaml` and `testing.verification_steps` from vendor definition.

```typescript
const domainChecks = domain.vendor_check;    // High-level checks
const vendorSteps = vendor.testing.verification_steps;  // Specific commands
```

#### Step 5.2: Execute Each Check

For each verification step:

```typescript
for (const step of vendorSteps) {
  console.log(`\n### ${step.step}`);
  console.log(`Running: ${step.command}`);

  const result = await exec(step.command);

  if (result.includes(step.expect)) {
    console.log(`✓ Passed`);
  } else {
    console.log(`✗ Failed`);
    console.log(`Expected: ${step.expect}`);
    console.log(`Got: ${result}`);

    // Attempt remediation
    await remediate(step, result, vendor.errors);
  }
}
```

#### Step 5.3: Remediation

When a check fails:

1. **Match error pattern:**

```typescript
function findErrorSolution(output, errors) {
  for (const err of errors) {
    if (output.includes(err.pattern)) {
      return {
        cause: err.cause,
        solution: err.solution
      };
    }
  }
  return null;
}
```

2. **Present remediation options:**

```typescript
const diagnosis = findErrorSolution(result, vendor.errors);

AskUserQuestion({
  questions: [{
    question: `Check failed: ${step.step}\n\nCause: ${diagnosis?.cause || 'Unknown'}\nSuggested fix: ${diagnosis?.solution || 'Check configuration'}\n\nHow would you like to proceed?`,
    header: "Fix",
    options: [
      { label: "Retry", description: "Run the check again" },
      { label: "Skip", description: "Continue without this check" },
      { label: "Abort", description: "Stop setup and investigate" }
    ],
    multiSelect: false
  }]
})
```

3. **Loop until pass or user skips/aborts.**

#### Step 5.4: Update Progress After Each Check

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
add_data:
  checks_passed: ["check_cli", "check_connection", "create_secret"]
  checks_skipped: []
  checks_failed: []
```

#### Step 5.5: Final Verification Summary

```markdown
## Verification Results

| Check                    | Status  |
|--------------------------|---------|
| CLI installation         | ✓ Pass  |
| Server connection        | ✓ Pass  |
| Create test secret       | ✓ Pass  |
| Read test secret         | ✓ Pass  |
| List secrets             | ✓ Pass  |
| Delete test secret       | ✓ Pass  |
| Verify deletion          | ✓ Pass  |

All checks passed!
```

```yaml
invoke: track-setup-progress
operation: update
domain: "{domain_key}"
complete_phase: 5
set_phase: 6
```

---

### Phase 6: Documentation

**Update CLAUDE.md vendor subsection only, preserving abstract domain content.**

#### CLAUDE.md Section Structure

A domain section may contain both abstract (vendor-free) content and vendor-specific content:

```markdown
## Secrets

[Abstract domain content - MUST BE PRESERVED]
This section describes how secrets work in this project,
naming conventions, policies, etc. This is vendor-agnostic.

### Vendor: HashiCorp Vault

[Vendor-specific content - REPLACED BY THIS SKILL]
Configuration, operations, troubleshooting for this vendor.
```

**Critical Rule:** Only replace content from `### Vendor: {vendor.name}` to the next `## ` or `### Vendor:` heading. Never touch abstract domain content.

#### Step 6.1: Generate Vendor Subsection Content

Generate **only** the vendor subsection (not the domain header):

```markdown
### Vendor: {vendor.name}

- **Status**: Configured
- **CLI Tool**: `{vendor.integrations.cli.tool_name}`
- **Documentation**: {vendor.resources.documentation[0].url}

#### Environment Variables

| Variable       | Description                    | Required |
|----------------|--------------------------------|----------|
| `VAULT_ADDR`   | Vault server address           | Yes      |
| `VAULT_TOKEN`  | Authentication token           | Yes      |

#### Operations

How domain requirements are satisfied:

| Requirement                  | Command                                           |
|------------------------------|---------------------------------------------------|
| Create a new secret          | `vault kv put -mount=secret {path} {key}={value}` |
| Read a secret value          | `vault kv get -mount=secret {path}`               |
| Update an existing secret    | `vault kv patch -mount=secret {path} {key}={val}` |
| Delete a secret              | `vault kv delete -mount=secret {path}`            |
| List available secrets       | `vault kv list -mount=secret {path}`              |
| Check whether a secret exists| `vault kv get -mount=secret {path} 2>/dev/null`   |

#### Verification

```bash
# Check connection
vault status

# Test CRUD operations
vault kv put -mount=secret test/claude value=test123
vault kv get -mount=secret -field=value test/claude
vault kv delete -mount=secret test/claude
```

#### Troubleshooting

| Error                   | Cause                              | Solution                           |
|-------------------------|------------------------------------|------------------------------------|
| `permission denied`     | Token lacks required permissions   | Check token policies               |
| `connection refused`    | Server not running                 | Verify VAULT_ADDR                  |
| `Vault is sealed`       | Vault needs unsealing              | Run `vault operator unseal`        |
```

#### Step 6.2: Update CLAUDE.md (Smart Replace)

**Scenario A: Domain section exists with existing vendor subsection**

```
## Secrets                          ← Keep
[abstract content]                  ← Keep
### Vendor: HashiCorp Vault         ← Replace from here
[old vendor content]                ← Replace
[until next ## or ### Vendor:]      ← Replace boundary
```

→ Replace only `### Vendor: {vendor.name}` subsection

**Scenario B: Domain section exists, no vendor subsection**

```
## Secrets                          ← Keep
[abstract content]                  ← Keep
                                    ← Insert vendor subsection here
```

→ Append vendor subsection at end of domain section (before next `## `)

**Scenario C: No domain section exists**

→ Append new domain section with vendor subsection:

```markdown
## {domain.name}

### Vendor: {vendor.name}
[generated vendor content]
```

#### Step 6.3: Implementation

```typescript
// 1. Read CLAUDE.md
const content = readFile('CLAUDE.md');

// 2. Find domain section boundaries
const domainStart = content.indexOf(`## ${domain.name}`);
const domainEnd = findNextH2(content, domainStart + 1);  // Next ## or EOF

// 3. If domain section exists
if (domainStart !== -1) {
  const domainContent = content.slice(domainStart, domainEnd);

  // Find vendor subsection within domain
  const vendorStart = domainContent.indexOf(`### Vendor: ${vendor.name}`);
  const vendorEnd = findNextVendorOrH2(domainContent, vendorStart + 1);

  if (vendorStart !== -1) {
    // Scenario A: Replace existing vendor subsection
    replaceRange(domainStart + vendorStart, domainStart + vendorEnd, newVendorContent);
  } else {
    // Scenario B: Append vendor subsection to domain
    insertAt(domainEnd, '\n' + newVendorContent);
  }
} else {
  // Scenario C: Append new domain section
  appendToFile(`\n## ${domain.name}\n\n${newVendorContent}`);
}
```

**Boundary detection patterns:**
- Next `## ` = end of domain section
- Next `### Vendor:` = end of current vendor subsection (if multiple vendors)
- EOF = end of content

#### Step 6.4: Complete Setup

```yaml
invoke: track-setup-progress
operation: complete
domain: "{domain_key}"
```

#### Step 6.5: Summary

```
{domain.name} Setup Complete!
=============================

Vendor: {vendor.name}
Integration: CLI
Checks: 7/7 passed

Configuration documented in CLAUDE.md

Quick reference:
  • Create: vault kv put -mount=secret {path} {key}={value}
  • Read:   vault kv get -mount=secret {path}
  • List:   vault kv list -mount=secret
  • Delete: vault kv delete -mount=secret {path}
```

---

## Error Handling

### Installation Failures

| Error                    | Recovery                                        |
|--------------------------|-------------------------------------------------|
| `brew: command not found`| Suggest Homebrew install or manual binary       |
| `permission denied`      | Suggest `sudo` or check directory permissions   |
| Network timeout          | Retry or suggest manual download                |

### Verification Failures

| Error                    | Recovery                                        |
|--------------------------|-------------------------------------------------|
| CLI not found            | Re-run installation step                        |
| Connection refused       | Check server address and status                 |
| Authentication failed    | Re-configure environment variables              |
| Permission denied        | Check token/credentials permissions             |

### Progress File Issues

| Error                    | Recovery                                        |
|--------------------------|-------------------------------------------------|
| Corrupted file           | Delete and restart                              |
| Missing file on resume   | Start fresh                                     |

---

## Session Restart Handling

The skill uses `track-setup-progress` to persist state. On session restart:

1. **Phase 4 (Installation)**: Resume from last completed install step
2. **Phase 5 (Verification)**: Resume from last passed check
3. **Phase 6 (Documentation)**: Re-generate and write

Progress file stores:
- Current phase
- Collected data (domain, vendor, config)
- Completed checks list
- Skipped/failed checks list

---

## Interactive Checkpoints

| Phase | Checkpoint                                              |
|-------|---------------------------------------------------------|
| 0     | "Resume previous setup?"                                |
| 1     | "Which domain would you like to configure?"             |
| 2     | "Which vendor would you like to use?"                   |
| 4     | "Ready to install? Review the plan above."              |
| 4     | "Enter value for {env_var}:"                            |
| 5     | "Check failed. Retry, skip, or abort?"                  |
| 6     | "Setup complete!"                                       |
