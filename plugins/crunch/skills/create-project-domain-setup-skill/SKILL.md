---
name: create-project-domain-setup-skill
description: Meta-skill for creating domain-specific setup skills. Uses the example skill as a reference to generate SKILL.md files for project domains.
---

# Create Project Domain Setup Skill

This meta-skill generates domain-specific setup skills by studying the example skill and creating a similar one for the selected project domain.

## Reference Example

**Example Location**: `plugins/crunch/skills/create-project-domain-setup-skill/examples/project-domain-setup-skill-example/SKILL.md`

This example demonstrates the complete structure and patterns for a domain setup skill, including:
- Architecture diagram showing skill dependencies
- Phase-based workflow (0-5)
- Integration with `lookup-vendor` and `track-setup-progress` shared skills
- Progress tracking patterns
- CLAUDE.md generation with templates
- Management mode for existing configurations
- Error handling patterns

## Definition of Done

The skill creation is complete when:

1. Domain is selected from pre-defined list
2. Example skill is analyzed in detail (in plan mode)
3. SKILL.md is generated at `plugins/crunch/skills/setup-{domain-key}/SKILL.md`
4. Generated skill follows the example's structure and patterns
5. User verifies the generated skill

## Pre-Defined Domains

| Domain                     | Key                        | Purpose                                      |
|----------------------------|----------------------------|----------------------------------------------|
| **Task Management**        | `task-management`          | Track and manage work items                  |
| **Secrets**                | `secrets`                  | Store and retrieve secrets securely          |
| **CI/CD**                  | `ci-cd`                    | Continuous integration/deployment            |
| **Pipelines**              | `pipelines`                | Define project pipelines (local, CI, deploy) |
| **Configuration**          | `configuration`            | Manage env variables per environment         |
| **Observability**          | `observability`            | Metrics, logs, traces, alerting              |
| **Documentation**          | `documentation`            | Doc site generation and publishing           |
| **Localization**           | `localization`             | Internationalization and translation         |
| **Memory Management**      | `memory-management`        | Persistent AI context across sessions        |
| **Deploy Environments**    | `deploy-environments`      | Manage dev/staging/prod environments         |
| **Problem Remediation**    | `problem-remediation`      | Runbook automation, self-healing             |
| **Tech Stack**             | `tech-stack`               | Auto-detect and configure project stack      |
| **User Communication Bot** | `user-communication-bot`   | Slack app/bot for project development        |
| **Agents & Orchestration** | `agents-and-orchestration` | Configure Claude Code agents                 |

## Workflow

### Step 1: Domain Selection

#### Step 1.1: Check for Existing Skills

First, check which domain skills already exist:

```bash
ls -d plugins/crunch/skills/setup-*/ 2>/dev/null | sed 's|.*/setup-||; s|/$||'
```

Mark existing skills with `✓ exists` in the options below.

#### Step 1.2: Present Domain Options

Present domain options using AskUserQuestion with pagination (4 options at a time).

```typescript
// Page 1 (most common domains)
AskUserQuestion({
  questions: [{
    question: "Which project domain would you like to create a setup skill for?",
    header: "Domain",
    options: [
      { label: "Task Management", description: "Track and manage work items (tasks, bugs, features)" },
      { label: "Secrets", description: "Store and retrieve secrets securely" },
      { label: "CI/CD", description: "Continuous integration and deployment pipelines" },
      { label: "Pipelines", description: "Define project pipelines (local, CI, deploy)" }
    ],
    multiSelect: false
  }]
})

// Page 2 (if user selected "Other")
AskUserQuestion({
  questions: [{
    question: "More domain options:",
    header: "Domain",
    options: [
      { label: "Configuration", description: "Manage env variables per environment" },
      { label: "Observability", description: "Metrics, logs, traces, and alerting" },
      { label: "Documentation", description: "Doc site generation and publishing" },
      { label: "Localization", description: "Internationalization and translation" }
    ],
    multiSelect: false
  }]
})

// Page 3 (if user selected "Other" again)
AskUserQuestion({
  questions: [{
    question: "Additional domains:",
    header: "Domain",
    options: [
      { label: "Memory Management", description: "Persistent AI context across sessions" },
      { label: "Deploy Environments", description: "Manage dev/staging/prod environments" },
      { label: "Problem Remediation", description: "Runbook automation and self-healing" },
      { label: "Tech Stack", description: "Auto-detect and configure project stack" }
    ],
    multiSelect: false
  }]
})

// Page 4 (if user selected "Other" again)
AskUserQuestion({
  questions: [{
    question: "Remaining domains:",
    header: "Domain",
    options: [
      { label: "User Communication Bot", description: "Slack/Discord bot for development" },
      { label: "Agents & Orchestration", description: "Configure Claude Code agents" }
    ],
    multiSelect: false
  }]
})
```

**Note:** If a skill already exists for the selected domain, ask user whether to overwrite or cancel.

### Step 2: Enter Plan Mode

After domain selection, **enter plan mode** to:

1. **Read and analyze the example skill** at `examples/project-domain-setup-skill-example/SKILL.md`
2. **Understand the structure**:
   - Architecture section with dependency diagram
   - Dependencies (lookup-vendor, track-setup-progress, setup-mcp)
   - Definition of Done
   - Progress Tracking with phase definitions
   - Workflow phases (0-5)
   - Management Mode menu
   - Error Handling patterns
   - Interactive Checkpoints
   - Key Patterns summary
3. **Plan the new skill** by adapting the example to the selected domain:
   - Replace domain-specific references (e.g., "secrets" → "{domain_key}")
   - Keep the same architectural patterns
   - Maintain the same phase structure
   - Preserve integration with shared skills
4. **Create the implementation plan** for user approval

### Step 3: Generate Skill

After plan approval:

1. Create directory: `plugins/crunch/skills/setup-{domain_key}/`
2. Generate `SKILL.md` following the example's structure
3. Adapt content for the selected domain

### Step 4: Verification

Display result summary and offer to review the generated skill.

## Interactive Checkpoints

- [ ] "Which domain would you like to create a setup skill for?"
- [ ] Plan mode: Present implementation plan for approval
- [ ] "Skill generated. Would you like to review it?"
