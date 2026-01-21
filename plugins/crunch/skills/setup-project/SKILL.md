---
name: setup-project
description: Main project setup wizard. Creates CLAUDE.md and guides through configuring project domains with Survey, Abstract, and Vendor sections.
---

# Setup Project

The main entry point for project configuration. This skill orchestrates the setup of all project domains.

## Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Check CLAUDE.md                                         │
│  Does it exist? → Create minimal or use existing                 │
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
│  Step 3: Present Domain Selector                                 │
│  Show domains, indicate which have sections in CLAUDE.md         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: Configure Domain                                        │
│  - Run user-survey (if survey file exists)                       │
│  - Run general checks (if domain_check.general_check exists)     │
│  - Setup vendor via setup-domain-vendor (if has_vendor)          │
│  - Write domain section to CLAUDE.md                             │
└─────────────────────────────────────────────────────────────────┘
```

## Definition of Done

A domain is configured when its CLAUDE.md section contains (in order):
1. **Survey result** (from `user-survey` if `survey` file exists)
2. **Abstract** subsection (from `data/abstract/{domain}.md` if exists)
3. **Vendor** subsection (from `setup-domain-vendor` if `has_vendor: true`)

The skill session is complete when user exits the domain selector.

---

## CLAUDE.md Domain Section Structure

Each domain section follows this structure:

```markdown
## {Domain Name}

{Survey result - collected project-specific info}

### Abstract

{Content from data/abstract/{domain-key}.md - vendor-agnostic concepts}

### Vendor: {Vendor Name}

{Content from setup-domain-vendor - vendor-specific configuration}
```

**Example: Task Management with all three parts**

```markdown
## Task Management

**Workflow style:** Kanban with WIP limits
**Sprint cadence:** 2-week sprints
**Primary board:** Linear

### Abstract

[Task types, states, relationships, operations - from abstract file]

### Vendor: Linear

[Linear-specific configuration, commands, troubleshooting]
```

**Example: Project Info (survey only, no abstract or vendor)**

```markdown
## Project Info

**Name:** Acme Dashboard

**Goal:** Build a real-time analytics dashboard for e-commerce metrics

**Problem:** Merchants lack visibility into real-time sales data

**Target Users:** E-commerce store owners

**Objectives:**
- Display real-time revenue and order counts
- Show conversion funnel visualization
- Enable custom date range filtering
```

**Example: Secrets (vendor only, no survey or abstract)**

```markdown
## Secrets

### Vendor: HashiCorp Vault

[Vault-specific configuration, commands, troubleshooting]
```

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
    question: "No CLAUDE.md found. Create one to start project configuration?",
    header: "Create",
    options: [
      { label: "Yes, create", description: "Create CLAUDE.md and start configuring" },
      { label: "No, skip", description: "Exit setup" }
    ],
    multiSelect: false
  }]
})
```

If creating, write minimal header:

```markdown
# CLAUDE.md

Project configuration managed by Claude Code.
```

---

### Step 2: Load Domain Definitions

```bash
cat plugins/crunch/data/domains.yaml
```

Extract domains with their properties:

```yaml
domains:
  - name: "Project Info"
    key: "project-info"
    required: true
    has_vendor: false
    survey: "plugins/crunch/data/survey/project-info.md"

  - name: "Task Management"
    key: "task-management"
    required: true
    has_vendor: true
    # Abstract auto-detected: data/abstract/task-management.md
```

---

### Step 3: Present Domain Selector

Check which domains have sections in CLAUDE.md:

```bash
# For each domain, check if section exists
grep -q "^## Project Info" CLAUDE.md && echo "configured" || echo "pending"
grep -q "^## Task Management" CLAUDE.md && echo "configured" || echo "pending"
```

Present selector:

```
Project Setup - Domain Status
=============================

Required Domains:
    Project Info
  ✓ Tech Stack
    Secrets
  ✓ Task Management

Optional Domains:
    CI/CD
    Observability
```

```typescript
const pendingDomains = domains.filter(d => !hasSection(d.name));
const configuredDomains = domains.filter(d => hasSection(d.name));

AskUserQuestion({
  questions: [{
    question: "Which domain would you like to configure?",
    header: "Domain",
    options: [
      ...pendingDomains.slice(0, 3).map(d => ({
        label: d.name,
        description: d.purpose
      })),
      { label: "Show all", description: "See complete domain list" }
    ],
    multiSelect: false
  }]
})
```

---

### Step 4: Configure Domain

#### Step 4.1: Run User Survey (if survey exists)

If domain has `survey` property:

```yaml
invoke: user-survey
file: "{domain.survey}"
```

Capture markdown result for inclusion in CLAUDE.md.

#### Step 4.2: Run General Checks (if domain_check.general_check exists)

If domain has `domain_check.general_check`, run verification steps interactively.

**Load checks:**

```typescript
const generalChecks = domain.domain_check?.general_check;
```

**Execute each check:**

```typescript
for (const check of generalChecks) {
  console.log(`\n### ${check}`);

  // Determine the command based on survey results and check description
  const command = deriveCommand(check, surveyResult);

  if (command) {
    console.log(`Running: ${command}`);
    const result = await exec(command);

    if (isSuccess(result)) {
      console.log(`✓ Passed`);
    } else {
      console.log(`✗ Failed`);
      console.log(`Result: ${result}`);

      // Present remediation options
      const action = await askRemediation(check, result);
      if (action === 'retry') continue;
      if (action === 'skip') continue;
      if (action === 'abort') return;
    }
  } else {
    // Check requires manual verification
    const confirmed = await askManualVerification(check);
    if (confirmed) {
      console.log(`✓ Confirmed by user`);
    } else {
      console.log(`✗ Skipped`);
    }
  }
}
```

**Remediation options:**

```typescript
AskUserQuestion({
  questions: [{
    question: `Check failed: ${check}\n\nResult: ${result}\n\nHow would you like to proceed?`,
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

**Manual verification (for checks that can't be automated):**

```typescript
AskUserQuestion({
  questions: [{
    question: `Please verify: ${check}\n\nIs this check satisfied?`,
    header: "Verify",
    options: [
      { label: "Yes", description: "Check is satisfied" },
      { label: "No, skip", description: "Skip this check" },
      { label: "No, abort", description: "Stop and fix first" }
    ],
    multiSelect: false
  }]
})
```

**Verification summary:**

```markdown
## General Verification Results

| Check                                    | Status    |
|------------------------------------------|-----------|
| Verify Node.js is installed              | ✓ Pass    |
| Verify npm is installed                  | ✓ Pass    |
| Run npm install                          | ✓ Pass    |
```

#### Step 4.3: Setup Vendor (if has_vendor)

If domain has `has_vendor: true`:

```yaml
invoke: setup-domain-vendor
domain: "{domain.key}"
```

Capture vendor configuration for inclusion in CLAUDE.md.

#### Step 4.4: Write Domain Section to CLAUDE.md

Build the domain section in order: **Survey → Abstract → Vendor**

```typescript
function buildDomainSection(domain, surveyResult, vendorResult) {
  let section = `## ${domain.name}\n\n`;

  // 1. Add survey result if collected (no subsection header)
  if (surveyResult) {
    section += surveyResult + '\n\n';
  }

  // 2. Add Abstract subsection if file exists
  const abstractPath = `plugins/crunch/data/abstract/${domain.key}.md`;
  if (fileExists(abstractPath)) {
    const abstractContent = readFile(abstractPath);
    // Remove the H1 header from abstract file
    const contentWithoutH1 = abstractContent.replace(/^# .+\n+/, '');
    section += `### Abstract\n\n${contentWithoutH1}\n\n`;
  }

  // 3. Add Vendor subsection if configured
  if (vendorResult) {
    section += `### Vendor: ${vendorResult.vendor_name}\n\n`;
    section += vendorResult.content + '\n';
  }

  return section;
}
```

**Update CLAUDE.md:**

```typescript
// If section exists: replace it
// If not: append at appropriate position (required domains first)

if (sectionExists(domain.name)) {
  replaceSectionInClaudeMd(domain.name, newSection);
} else {
  appendSectionToClaudeMd(newSection);
}
```

---

### Step 5: Return to Domain Selector

After completing a domain, return to Step 3 to let user select another or exit.

---

## Dependencies

```yaml
dependencies:
  - skill: user-survey
    use_when: "domain.survey exists"
    purpose: "Collect project info via conversational survey"

  - skill: setup-domain-vendor
    use_when: "domain.has_vendor == true"
    purpose: "Configure vendor for domain"

  - data: plugins/crunch/data/domains.yaml
    purpose: "Domain definitions"

  - data: plugins/crunch/data/abstract/*.md
    purpose: "Vendor-agnostic domain content"

  - data: plugins/crunch/data/survey/*.md
    purpose: "Survey descriptions for user-survey"
```

---

## Data Files

### Domain Definitions

`plugins/crunch/data/domains.yaml`:

```yaml
domains:
  - name: Project Info
    key: project-info
    purpose: Capture project goal, objectives, and context
    required: true
    has_vendor: false
    survey: plugins/crunch/data/survey/project-info.md

  - name: Task Management
    key: task-management
    purpose: Track and manage work items
    required: true
    has_vendor: true
    # Abstract file auto-detected: data/abstract/task-management.md
```

### Survey Files

`plugins/crunch/data/survey/{domain-key}.md`:

Markdown files describing what to clarify for each domain. Used by user-survey skill.

Currently exists:
- `project-info.md` - Project goal, objectives, constraints
- `tech-stack.md` - Languages, frameworks, build tools
- `deploy-environments.md` - Environments, hosting, deployment

### Abstract Files

`plugins/crunch/data/abstract/{domain-key}.md`:

Vendor-agnostic content for domains. Auto-detected by domain key.

Currently exists:
- `task-management.md` - Task types, states, relationships, operations

---

## Interactive Checkpoints

| Step | Checkpoint                                        |
|------|---------------------------------------------------|
| 1    | "No CLAUDE.md found. Create one?"                 |
| 3    | "Which domain would you like to configure?"       |
| 4.1  | user-survey questions (if survey exists)          |
| 4.2  | general_check verification (if exists)            |
| 4.3  | setup-domain-vendor flow (if has_vendor)          |
| 5    | "Domain configured. Configure another or exit?"   |

---

## Error Handling

| Error                    | Recovery                                |
|--------------------------|-----------------------------------------|
| CLAUDE.md write error    | Show error, suggest permissions check   |
| Survey file not found    | Skip survey, continue to abstract/vendor|
| Abstract file not found  | Skip Abstract subsection, continue      |
| Vendor setup fails       | Show error, offer retry or skip         |

---

## Example Session

```
User: /setup-project

Claude: Found existing CLAUDE.md. Which domain would you like to configure?
  > Task Management

Claude: Setting up Task Management domain...

[No survey file for Task Management, skip to vendor]

Which Task Management vendor would you like to use?
  > Linear

[... vendor setup flow ...]

✓ Task Management configured with Linear

Updated CLAUDE.md:
  ## Task Management
  ### Abstract
  [Task types, states, relationships...]
  ### Vendor: Linear
  [Linear configuration, commands...]

Which domain would you like to configure next?
  > Project Info

Claude: Tell me about your project!
[... user-survey flow ...]

✓ Project Info configured

Updated CLAUDE.md:
  ## Project Info
  **Name:** Acme Dashboard
  **Goal:** Build a real-time analytics dashboard...
  [... survey results ...]

Which domain would you like to configure next?
  > Exit

Claude: Project setup complete.
```
