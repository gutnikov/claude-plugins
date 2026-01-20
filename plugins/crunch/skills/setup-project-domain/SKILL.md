---
name: setup-project-domain
description: Meta-skill for creating domain-specific setup skills. Generates SKILL.md files for project domains (Task Management, Secrets, Communication, CI/CD, etc.).
---

# Setup Project Domain

This meta-skill generates domain-specific setup skills for different project domains. It abstracts the common patterns and allows creating new ones for any integration domain.

## Definition of Done

The skill creation is complete when:

1. Domain is selected from pre-defined list
2. Vendor matrix is configured (pre-defined or gathered)
3. SKILL.md is generated at `plugins/crunch/skills/setup-{domain-key}/SKILL.md`
4. Generated skill follows the standard setup skill pattern
5. User verifies the generated skill

## Domain Abstraction Model

### What Defines a "Project Domain"

| Component               | Description                    | Example (Task Mgmt)                        |
|-------------------------|--------------------------------|--------------------------------------------|
| **Domain Name**         | Human-readable name            | "Task Management"                          |
| **Domain Key**          | Lowercase identifier           | `task-manager`                             |
| **Purpose**             | What the domain accomplishes   | "Track and manage work items"              |
| **Domain Explanation**  | Educational content for users  | "Why this domain matters..."               |
| **Required Features**   | Features vendors MUST have     | Tasks, Tags, Statuses, Dependencies        |
| **CLAUDE.md Section**   | Section header                 | `## Task Management`                       |
| **MCP Key Pattern**     | Keys in .mcp.json              | `jira`, `asana`, `linear`                  |

### Integration Methods

Each vendor has an `integration_method` that determines setup workflow:

| Method          | Config Location                   | Setup Approach              | Test Method   |
|-----------------|-----------------------------------|-----------------------------|---------------|
| `mcp-official`  | `.mcp.json`                       | OAuth flow via mcp-remote   | MCP tool call |
| `mcp-community` | `.mcp.json`                       | npm package + env vars      | MCP tool call |
| `file-based`    | Config files (e.g., `.sops.yaml`) | File creation + env vars    | CLI command   |
| `cli`           | Env vars / config files           | Install CLI + configure     | CLI command   |
| `api`           | Env vars                          | Collect API credentials     | API call      |

### Vendor Definition Schema

Each vendor definition includes:

```yaml
vendors:
  - name: "Vendor Name"           # Display name
    key: "vendor-key"             # Lowercase identifier
    integration_method: "mcp-community"  # Primary integration method
    alternative_method: "cli"     # Optional fallback method
    features: [...]               # Supported features
    official_mcp: "url or null"   # Official MCP URL if available
    community_mcp: "pkg or null"  # Community npm package if available
    config_files:                 # For file-based integrations
      - path: ".config.yaml"
        description: "Configuration file"
        template: |
          # Template content
    cli_tools:                    # For CLI integrations
      - name: "toolname"
        install: "brew install toolname"
        check: "toolname --version"
    env_vars:                     # Environment variables
      - name: "ENV_VAR"
        description: "Description"
        default: "optional default"
    setup_steps:                  # For non-MCP workflows
      - "Step 1 description"
      - "Step 2 description"
    auth: [...]                   # Auth methods
    test_op: "command or tool"    # Test operation
    notes: "Brief description"
```

---

## Pre-Defined Domains

These domains have known purposes, feature requirements, and popular vendors.

| Domain                       | Key                          | Purpose                                      |
|------------------------------|------------------------------|----------------------------------------------|
| **Task Management**          | `task-management`            | Track and manage work items                  |
| **Secrets**                  | `secrets`                    | Store and retrieve secrets securely          |
| **CI/CD**                    | `ci-cd`                      | Continuous integration/deployment            |
| **Pipelines**                | `pipelines`                  | Define project pipelines (local, CI, deploy) |
| **Configuration**            | `configuration`              | Manage env variables per environment         |
| **Observability**            | `observability`              | Metrics, logs, traces, alerting              |
| **Documentation**            | `documentation`              | Doc site generation and publishing           |
| **Localization**             | `localization`               | Internationalization and translation         |
| **Memory Management**        | `memory-management`          | Persistent AI context across sessions        |
| **Deploy Environments**      | `deploy-environments`        | Manage dev/staging/prod environments         |
| **Problem Remediation**      | `problem-remediation`        | Runbook automation, self-healing             |
| **Tech Stack**               | `tech-stack`                 | Auto-detect and configure project stack      |
| **User Communication Bot**   | `user-communication-bot`     | Slack app/bot for project development        |
| **Agents & Orchestration**   | `agents-and-orchestration`   | Configure Claude Code agents                 |

**Note:** Users select their existing vendor from the popular list. The skill then analyzes vendor compatibility with the domain requirements.

---

## Workflow

### Phase 1: Domain Selection

Present domain options using AskUserQuestion. Since only 4 options can be shown at once, use pagination - if user selects "Other", show the next set of domains.

```typescript
// First set (most common domains)
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
// User can select "Other" to see more options

// Second set (if user selected "Other")
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

// Third set (if user selected "Other" again)
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

// Fourth set (if user selected "Other" again)
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

**Flow:**
1. Show first 4 domains
2. If user selects "Other" → show next 4 domains
3. Repeat until user selects a domain or all options exhausted

**After domain selection:** Continue to Phase 1.5 (Story Collection).

**DOD:** Domain selected

---

### Phase 1.5: Story Collection

Collect user stories that describe required capabilities for the selected domain.

#### Entry Dialog

```
{Domain Name} Setup - Story Collection
--------------------------------------

Let's understand what capabilities you need from {domain_name}.

Describe what should be possible using "it should be possible to..." statements.
Focus on concrete actions and outcomes.

Examples:
  - "it should be possible to create a task with a description"
  - "it should be possible to set one task to be dependent on another task"
  - "it should be possible to filter tasks by status and assignee"
  - "it should be possible to move a task between projects"

Enter your first story:
>
```

#### Multi-Turn Collection Loop

1. User provides a story
2. Claude confirms and displays the story
3. Ask: "Add another story, or type 'done'"
4. Repeat until user says "done"

#### After Each Story

```
Story {N} captured!

  "{story_text}"

Stories collected so far: {total}

Add another story, or type 'done':
>
```

**DOD:** At least 1 story collected, user says "done"

---

### Phase 1.6: Story Review

Review and organize collected stories before vendor matching.

#### Consolidated Review (After "done")

```
Story Review
============

You've collected {N} stories:

REQUIRED CAPABILITIES
| #  | Story                                                          |
|----|----------------------------------------------------------------|
| 1  | it should be possible to create a task with a description     |
| 2  | it should be possible to set one task dependent on another    |
| 3  | it should be possible to filter tasks by status and assignee  |
| 4  | it should be possible to move a task between projects         |

Do these stories capture your requirements?
1. Yes, continue to vendor selection
2. Add more stories
3. Edit a story (enter story number)
4. Remove a story (enter "remove" + number)
>
```

**If user selects "Edit":**
```
Editing story #{N}:
Current: "{current_story_text}"

Enter updated story:
>
```

**If user selects "Remove":**
```
Removed story #{N}: "{removed_story_text}"

{N-1} stories remaining.
```

#### Story Quality Guidelines

Good stories are:
- **Specific**: "create a task with a description" (not "manage tasks")
- **Testable**: Can verify if a tool supports this capability
- **Action-oriented**: Describe what should be possible to do
- **Self-contained**: Each story represents one capability

If a story is too vague, suggest breaking it down:
```
Story seems broad: "it should be possible to manage tasks"

Consider breaking into specific stories:
  - "it should be possible to create a task"
  - "it should be possible to update a task's status"
  - "it should be possible to delete a task"

Would you like to replace with these? (yes/no)
>
```

**DOD:** Stories reviewed and confirmed

---

### Phase 1.7: Vendor Selection

Present popular vendors for the selected domain and let the user choose which one they use.

#### Step 1: Present Vendor Options

Use AskUserQuestion with the domain's popular vendors:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which {domain_name} vendor do you use?",
    header: "Vendor",
    options: [
      // Populated from domain's popular_vendors list
      { label: "{Vendor1}", description: "{brief description}" },
      { label: "{Vendor2}", description: "{brief description}" },
      { label: "{Vendor3}", description: "{brief description}" },
      { label: "{Vendor4}", description: "{brief description}" }
    ],
    multiSelect: false
  }]
})
```

**Note:** User can select "Other" to specify a vendor not in the list.

**If user selects "Other":** Ask for vendor name via text input.

**DOD:** Vendor selected

---

### Phase 1.8: Vendor Compatibility Analysis

After vendor selection, analyze how well the vendor's tools match the required stories.

#### Step 1: Match Stories to Vendor Tools

For each collected story, identify which vendor tool(s) can fulfill it:

1. **Full Support** - A vendor tool directly supports this capability
2. **Partial Support** - Can be achieved with workarounds or multiple tools
3. **Gap** - No tool available for this capability

#### Step 2: Display Compatibility Report

```
Vendor Compatibility Analysis: {Vendor} for {Domain Name}
=========================================================

Story Coverage:

| #  | Story                                               | Support         | Tool/Method              |
|----|-----------------------------------------------------|-----------------|--------------------------|
| 1  | create a task with a description                    | ✓ Full          | createCard               |
| 2  | set one task dependent on another                   | ~ Partial       | attachments + convention |
| 3  | filter tasks by status and assignee                 | ✓ Full          | getCardsOnBoard + filter |
| 4  | move a task between projects                        | ✗ Gap           | not supported            |

Overall Compatibility: {X}% ({Y} of {Z} stories supported)

Gaps & Workarounds:
  - Story #2: No native dependencies; use card attachments with naming convention
  - Story #4: Cannot move cards between boards; must recreate in target board

Recommendation: {Proceed / Consider alternatives / Not recommended}
```

#### Step 3: Confirm or Change Vendor

```typescript
AskUserQuestion({
  questions: [{
    question: "How would you like to proceed?",
    header: "Continue",
    options: [
      { label: "Continue with {Vendor}", description: "Generate skill with noted limitations" },
      { label: "Choose different vendor", description: "Go back to vendor selection" }
    ],
    multiSelect: false
  }]
})
```

**DOD:** User confirms vendor choice after seeing compatibility analysis

---

### Phase 2: Check for Existing Skill

Before generating, check if skill already exists:

```bash
ls plugins/crunch/skills/setup-{domain_key}/SKILL.md 2>/dev/null
```

**If exists:**

```
Setup skill for {Domain Name} already exists!

Location: plugins/crunch/skills/setup-{domain_key}/SKILL.md

What would you like to do?
1. Overwrite existing skill
2. Cancel (keep existing)
```

**DOD:** Confirmed ready to generate

---

### Phase 3: Generate Setup Skill

Create the SKILL.md file using the domain configuration.

#### Step 1: Create Directory

```bash
mkdir -p plugins/crunch/skills/setup-{domain_key}
```

#### Step 2: Generate SKILL.md

Use the **Template Structure** (below) with these substitutions:

| Placeholder                       | Value                                          |
|-----------------------------------|------------------------------------------------|
| `{domain_name}`                   | Domain name (e.g., "Secret Management")        |
| `{domain_key}`                    | Domain key (e.g., "secret-manager")            |
| `{purpose}`                       | Domain purpose                                 |
| `{feature_list}`                  | Comma-separated features                       |
| `{feature_summary}`               | Brief feature summary for description          |
| `{vendor_list}`                   | Comma-separated vendor names                   |
| `{qualified_vendors_table}`       | Markdown table of qualified vendors            |
| `{excluded_vendors_table}`        | Markdown table of excluded vendors             |
| `{mcp_options_table}`             | Markdown table of MCP options                  |
| `{progress_file_format}`          | Progress file template                         |
| `{phase_N_content}`               | Content for each workflow phase                |
| `{vendor_credentials_guide}`      | Vendor-specific credential instructions        |
| `{error_table}`                   | Error handling table                           |
| `{checkpoints}`                   | Interactive checkpoints                        |
| `{related_skills}`                | Related skill links                            |
| `{preflight_env_checks}`          | Bash commands to verify env vars               |
| `{preflight_connectivity_check}`  | Bash command to verify service connectivity    |
| `{missing_config_description}`    | Description of missing config for error msg    |
| `{operations_table}`              | Table of available operations for domain       |
| `{domain_specific_security_notes}`| Security guidance specific to domain           |

#### Step 3: Write File

Write generated content to:
```
plugins/crunch/skills/setup-{domain_key}/SKILL.md
```

**DOD:** SKILL.md file created

---

### Phase 4: Verification

Display result summary:

```
Setup skill generated!

Created: plugins/crunch/skills/setup-{domain_key}/SKILL.md

Domain: {Domain Name}
Vendors: {vendor_count}
Features: {feature_list}

To test the generated skill:
1. Run /setup-{domain_key}
2. Select a vendor
3. Complete the setup flow
4. Verify CLAUDE.md is updated
```

Then use AskUserQuestion to present options:

```typescript
AskUserQuestion({
  questions: [{
    question: "What would you like to do next?",
    header: "Next Step",
    options: [
      { label: "Review the generated skill", description: "View the SKILL.md content" },
      { label: "Generate another domain skill", description: "Create a skill for a different domain" },
      { label: "Done", description: "Exit the skill generator" }
    ],
    multiSelect: false
  }]
})
```

**If user selects "Review":** Read and display the generated SKILL.md

**DOD:** User confirms skill is correct or exits

---

## Pre-Defined Domain Configurations

### Example: Task Management (Reference Only)

This example shows the domain configuration structure that gets generated:

```yaml
domain_name: "Task Management"
domain_key: "task-manager"
purpose: "Track and manage work items, bugs, features, and team tasks"
claude_section: "## Task Management"

# Popular vendors for user selection
popular_vendors:
  - Jira
  - Linear
  - Trello
  - Asana
  - GitHub Issues

# Required stories for compatibility analysis
required_stories:
  - "it should be possible to create a task with a title and description"
  - "it should be possible to assign a task to a team member"
  - "it should be possible to set task priority (high, medium, low)"
  - "it should be possible to add labels/tags to a task"
  - "it should be possible to change task status (todo, in progress, done)"
  - "it should be possible to list and filter tasks by status or assignee"
  - "it should be possible to set one task as dependent on another"
  - "it should be possible to move a task between projects"

explanation: |
  ## Why Task Management Integration?

  Task management tools (Jira, Trello, Linear) track what needs to be done.
  With this integration, Claude can create tasks, update status, and help
  you stay organized without switching between tools.

  ### The Solution

  "Claude, create a high-priority bug ticket for the login issue"

  Claude: "Created PROJ-123: Login flow bug
           Priority: High, Assigned to: You"
```

### Compatibility Analysis Example

When user selects "Trello" for Task Management:

```
Vendor Compatibility Analysis: Trello for Task Management
=========================================================

Story Coverage:

| #  | Story                                          | Support   | Tool/Method              |
|----|------------------------------------------------|-----------|--------------------------|
| 1  | create a task with a title and description    | ✓ Full    | createCard               |
| 2  | assign a task to a team member                | ✓ Full    | addMemberToCard          |
| 3  | set task priority (high, medium, low)         | ~ Partial | labels (colored)         |
| 4  | add labels/tags to a task                     | ✓ Full    | addLabelToCard           |
| 5  | change task status (todo, in progress, done)  | ✓ Full    | moveCardToList           |
| 6  | list and filter tasks by status or assignee   | ✓ Full    | getCardsOnBoard + filter |
| 7  | set one task as dependent on another          | ~ Partial | attachments (workaround) |
| 8  | move a task between projects                  | ✗ Gap     | not supported            |

Overall Compatibility: 81% (6.5 of 8 stories supported)

Gaps & Workarounds:
  - Story #3: No native priority field; use colored labels (red=high, yellow=medium, green=low)
  - Story #7: No native dependencies; use card attachments with naming convention
  - Story #8: Cannot move cards between boards; must recreate in target board

Recommendation: Proceed - excellent fit with minor workarounds
```

---

## Vendor Capability Registry

This registry maps **common story patterns to vendor tools** for compatibility analysis.

### Story Pattern Recognition

When matching stories to vendor tools, recognize these common patterns:

```yaml
story_patterns:
  create_item:
    pattern: "create a {item} with {attributes}"
    tools: [createCard, createIssue, addTask, createItem]

  assign_item:
    pattern: "assign a {item} to {target}"
    tools: [addMemberToCard, assignIssue, setAssignee]

  set_property:
    pattern: "set {property} to {value}"
    tools: [updateCard, updateIssue, setField]

  add_tag:
    pattern: "add {tag_type} to a {item}"
    tools: [addLabelToCard, addLabels, setTags]

  change_status:
    pattern: "change {item} status"
    tools: [moveCardToList, transitionIssue, updateStatus]

  list_filter:
    pattern: "list and filter {items} by {criteria}"
    tools: [getCardsOnBoard, searchIssues, listTasks]

  set_dependency:
    pattern: "set {item} as dependent on another"
    tools: [createIssueLink, addRelation, linkItems]

  move_item:
    pattern: "move a {item} between {containers}"
    tools: [moveIssue, moveCard, transferItem]
```

### Vendor Tool Mappings

```yaml
vendor_tools:
  trello:
    createCard: "Create new card on a board"
    addMemberToCard: "Assign member to card"
    addLabelToCard: "Add label to card"
    moveCardToList: "Move card to different list"
    getCardsOnBoard: "List all cards on board"

  jira:
    createIssue: "Create new issue"
    assignIssue: "Assign issue to user"
    addLabels: "Add labels to issue"
    transitionIssue: "Change issue status"
    searchIssues: "Search with JQL"
    createIssueLink: "Link issues together"
    moveIssue: "Move issue to different project"

  linear:
    createIssue: "Create new issue"
    updateIssue: "Update issue properties"
    issues: "Query issues with filters"
```

---

## Template Structure

The generated SKILL.md must follow this exact structure:

```markdown
---
name: setup-{domain_key}
description: Interactive setup wizard for {domain_name} integration. Guides through vendor selection, configuration, and CLAUDE.md documentation.
---

# Setup {Domain Name}

This skill guides users through the complete end-to-end process of setting up {domain_name} integration with vendors that support {feature_list}.

## Definition of Done

The setup is complete when:

1. {Domain name} vendor is selected
2. Integration is configured (MCP, CLI, or file-based depending on vendor)
3. User successfully executes a test operation
4. CLAUDE.md is updated with "{Domain Name}" section documenting capabilities and integration method

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                                            | Use When                            |
|------------------|--------------------------------------------------------|-------------------------------------|
| **Full Setup**   | Install tools + configure from scratch                 | Starting fresh, local development   |
| **Connect Only** | Configure client to connect to existing infrastructure | Team server, cloud service, shared  |

### Mode Selection Prompt

At the start of setup (after Phase 0 state detection), if the vendor supports both modes:

\`\`\`
How would you like to set up {vendor}?

1. Full Setup - Install and configure from scratch
2. Connect Only - I already have {vendor} running/configured elsewhere
\`\`\`

**Full Setup path:**
- Check for existing installation
- Install if needed (OS-specific instructions)
- Configure and start service (if applicable)
- Set up authentication
- Proceed to connection test

**Connect Only path:**
- Ask for connection details (address/URL/endpoint)
- Ask for authentication credentials
- Configure environment variables
- Proceed to connection test

**Note:** Not all vendors support both modes. CLI tools typically only support Full Setup, while cloud services typically only support Connect Only.

## Domain Template

This skill uses a template file to generate the CLAUDE.md section for {domain_name}.

**Template Location**: `plugins/crunch/templates/{domain_key}.template.md`

### Template Usage

When updating CLAUDE.md in Phase 5:

#### If Template Exists

1. Read the template from `plugins/crunch/templates/{domain_key}.template.md`
2. Use the template content **without modifications** (preserve exact wording and structure)
3. **Augment** with tool-specific information from the configured vendor:
   - MCP tools available (if MCP integration)
   - CLI commands (if CLI integration)
   - API methods (if API integration)
   - How each template capability maps to the vendor's tools
4. If CLAUDE.md exists, find and replace the existing `## {Domain Section}` or append
5. If CLAUDE.md doesn't exist, create it and add the augmented template

#### If Template Does Not Exist

1. Generate a simple CLAUDE.md section listing common ways to use the configured tool
2. Include:
   - Vendor name and integration type
   - List of available MCP tools / CLI commands / API methods
   - Brief description of what each tool/command does
   - Basic usage examples

### Template Augmentation Format

When a template exists, append a "Tool Reference" subsection after the template content:

```markdown
### Tool Reference ({Vendor})

**Integration**: {MCP | CLI | File-based}

**Available Operations**:

| Operation        | Tool/Command         | Description                    |
|------------------|----------------------|--------------------------------|
| {operation_1}    | {tool_name}          | {what it does}                 |
| {operation_2}    | {tool_name}          | {what it does}                 |

**Examples**:
- To {action}: use `{tool_name}` with {parameters}
```

### Fallback Documentation Format (No Template)

When no template exists, generate this structure:

```markdown
## {Domain Name}

**Vendor**: {vendor_name}
**Integration**: {integration_type}
**Configuration**: {config_location}

### Available Tools

| Tool/Command     | Description                              |
|------------------|------------------------------------------|
| {tool_1}         | {description}                            |
| {tool_2}         | {description}                            |

### Common Operations

- **{Operation 1}**: Use `{tool}` to {description}
- **{Operation 2}**: Use `{tool}` to {description}

### Examples

{Basic usage examples for the vendor}
```

## Required Stories

Stories collected during Phase 1.5/1.6 that define the domain requirements.

### Story List

| #  | Story                                          | Vendor Tool          |
|----|------------------------------------------------|----------------------|
| 1  | {story_1_text}                                 | {vendor_tool_1}      |
| 2  | {story_2_text}                                 | {vendor_tool_2}      |

### Vendor Tool Coverage

When checking vendor compatibility, match stories against available tools:

```
For each story:
  1. Identify the action pattern (create, assign, filter, etc.)
  2. Find vendor tool that fulfills this capability
  3. Mark as: ✓ Full | ~ Partial | ✗ Gap
```

## Qualified Vendors

Only vendors that support **all** of the following features are included:

{required_features_list}

{qualified_vendors_table}

### Excluded Vendors

{excluded_vendors_table}

## Integration Options by Vendor

{integration_options_table}

## Integration Methods

This domain supports multiple integration approaches:

### MCP Integration
{If any vendors have MCP}
Vendors with MCP integration get tools directly available in Claude.
- Configuration: `.mcp.json`
- Benefits: Seamless tool access, auto-refresh

### File-Based Integration
{If any vendors use file-based}
Vendors using file-based integration store config in project files.
- Configuration: {list config files}
- Benefits: Git-friendly, works offline, full control

### CLI Integration
{If any vendors use CLI}
Vendors using CLI integration work through command-line tools.
- Requirements: {list CLI tools}
- Benefits: Native tooling, scripting support

## Progress Tracking

Since MCP setup requires reloading Claude Code (which loses session context), progress is tracked in a file.

### Progress File: `{domain_key}-setup-progress.md`

Location: Project root (`./{domain_key}-setup-progress.md`)

**Format:**

\`\`\`markdown
# {Domain Name} Setup Progress

## Status

- **Started**: {timestamp}
- **Current Phase**: Phase {N} - {Phase Name}
- **Vendor**: {selected vendor}
- **MCP Type**: {Official / Community}
- **Mode**: {Setup | Management | Resume}

## Completed Steps

- [x] Phase 0: State Detection
- [x] Phase 0.5: Domain Explanation
- [x] Phase 1: Domain Selection
- [x] Phase 1.5: Story Collection
- [x] Phase 1.6: Story Review
- [x] Phase 1.7: Vendor Selection
- [ ] Phase 2: Integration Selection <- CURRENT
- [ ] Phase 3: Integration Setup
- [ ] Phase 4: Connection Test
- [ ] Phase 5: Documentation

## Management History

Tracks management operations performed on configured setup.

| Timestamp  | Operation          | Details                    | Result                    |
|------------|--------------------|----------------------------|---------------------------|
| {datetime} | Test Connection    | {vendor}                   | {Success / Failed: error} |
| {datetime} | Update Credentials | {env_vars updated}         | {Success / Failed}        |
| {datetime} | Change Vendor      | {old_vendor} → {new_vendor} | {Success / Failed}        |
| {datetime} | Diagnostics        | {issues_found}             | {recommendations}         |
| {datetime} | Reset              | {vendor removed}           | Success                   |

## Connection Tests

| Timestamp  | Vendor   | Test Operation | Result | Error           |
|------------|----------|----------------|--------|-----------------|
| {datetime} | {vendor} | {test_op}      | ✓ Pass | -               |
| {datetime} | {vendor} | {test_op}      | ✗ Fail | {error_message} |

## Last Known State

- **Last Tested**: {timestamp}
- **Last Test Result**: {Pass | Fail}
- **Last Error**: {error_message or "None"}

## Collected Stories

| #  | Story                                                    |
|----|----------------------------------------------------------|
| 1  | it should be possible to create a task with description |
| 2  | it should be possible to set task dependent on another  |
| 3  | it should be possible to filter tasks by status         |

## Collected Information

- **Vendor**: {value}
- **Integration Method**: {mcp-official / mcp-community / file-based / cli / api}
- **MCP Type**: {Official / Community / N/A}
- **MCP Package/URL**: {value or "N/A"}
- **Config Files**: {list of config file paths or "N/A"}
- **CLI Tools**: {list of CLI tools or "N/A"}
- **Test Operation**: {value}
- **Config Location**: {value}

## Credential Information (Non-sensitive)

Tracks which credentials are configured (not the values).

- **Auth Type**: {OAuth | API Token}
- **Environment Variables**: {list of env var names}
- **Last Credential Update**: {timestamp or "Never"}
- **Credential Regeneration URL**: {url}
\`\`\`

### Progress Tracking Rules

1. Create progress file at Phase 1 start (after domain selected)
2. Update after each phase completion
3. Store non-sensitive data only (never credentials/tokens)
4. Delete only after successful DOD verification
5. Check for existing progress on session start
6. Store stories as collected (verbatim) after Phase 1.5
7. Store reviewed stories after Phase 1.6
8. Log all management operations in Management History
9. Update Connection Tests after each test (keep last 10)
10. Update Last Known State after each connection test
11. Track credential metadata (not values) for troubleshooting

---

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: State Detection & Mode Selection

**ALWAYS start here.** The skill detects current state and routes to the appropriate mode:

\`\`\`
┌─────────────────────────────────────────┐
│          /setup-{domain_key}            │
└─────────────────┬───────────────────────┘
                  │
                  ▼
         ┌───────────────────┐
         │  Detect State     │
         └─────────┬─────────┘
                   │
       ┌───────────┼───────────┐
       │           │           │
       ▼           ▼           ▼
  Not Setup    Configured    Progress File
       │           │           │
       ▼           ▼           ▼
  Setup Mode   Manage Mode   Resume Mode
\`\`\`

#### Step 1: Check for Existing Configuration

Detect if {domain_name} is already set up in this project:

\`\`\`bash
# Check CLAUDE.md for {Domain Name} configuration
grep -A 10 "{claude_section}" CLAUDE.md 2>/dev/null

# Check for known MCP entries in .mcp.json
grep -E '"({vendor_keys_pattern})"' .mcp.json 2>/dev/null

# Extract current vendor and MCP details
\`\`\`

#### Step 2: Check for Progress File

\`\`\`bash
cat {domain_key}-setup-progress.md 2>/dev/null
\`\`\`

**If progress file exists:** Offer to resume or start over

#### Step 3: Mode Routing

**If NOT configured (no CLAUDE.md section, no MCP entry):**
- Proceed directly to Phase 1 (Setup Mode)

**If progress file exists:**
- Display Resume Mode dialog (see below)

**If already configured:**
- Display Management Mode menu (see below)

---

### Management Mode Menu

When {domain_name} is already configured, first display the current configuration status:

\`\`\`
{Domain Name} Management
========================

Current Configuration:
  Vendor: {detected vendor}
  Integration: {MCP (Official) | MCP (Community) | CLI | File-based}
  Config: {.mcp.json | env vars | config files}
  Status: {Connected | Disconnected | Error}
  Last tested: {timestamp from progress file or "never"}
\`\`\`

Then use AskUserQuestion to present management options:

```typescript
AskUserQuestion({
  questions: [{
    question: "What would you like to do with your {domain_name} configuration?",
    header: "Action",
    options: [
      { label: "Add another vendor", description: "Configure additional vendor alongside current" },
      { label: "Change vendor", description: "Migrate to a different vendor" },
      { label: "Update credentials", description: "Refresh API tokens or re-authenticate" },
      { label: "Test connection", description: "Verify current setup is working" }
    ],
    multiSelect: false
  }]
})
```

**Note:** User can select "Other" to access additional options like diagnostics, view configuration, or reset.

---

### Mode A: Change Vendor (Option 2)

**Use case:** User wants to switch from one vendor to another (e.g., Trello to Jira), keeping domain continuity.

#### Workflow Display

\`\`\`
Change Vendor
-------------

Current vendor: {current_vendor}

This will:
1. Configure new vendor MCP
2. Update CLAUDE.md documentation
3. Optionally remove old vendor configuration

Select new vendor:
{vendor_list excluding current}

>
\`\`\`

#### Steps

1. Show current vendor and new options (excluding current vendor)
2. User selects new vendor
3. Run standard setup flow (Phases 2-4) for new vendor
4. Ask whether to keep or remove old vendor config:
   \`\`\`
   Would you like to:
   1. Replace old vendor (remove {old_vendor} configuration)
   2. Keep both vendors configured

   Select (1-2):
   \`\`\`
5. Update CLAUDE.md (replace or add section based on choice)

**Key difference from fresh setup:** Skip vendor selection intro, show migration context.

---

### Mode B: Update Credentials (Option 3)

**Use case:** API token expired, OAuth needs refresh, keys need regeneration, or user got new credentials.

#### Workflow Display

\`\`\`
Update Credentials
------------------

Current vendor: {vendor}
Integration type: {MCP (OAuth) | MCP (API Token) | CLI | File-based}
\`\`\`

**For MCP OAuth integrations:**

\`\`\`
To re-authenticate:
1. I'll update .mcp.json to force re-auth
2. Restart Claude Code
3. Complete OAuth flow in browser

Proceed with OAuth refresh? (yes/no)
>
\`\`\`

**For MCP API Token integrations:**

\`\`\`
Current environment variables:
  {ENV_VAR1}: ****{last4}
  {ENV_VAR2}: ****{last4}

Which credential to update?
1. {ENV_VAR1} - {description}
2. {ENV_VAR2} - {description}
3. All credentials
4. Cancel

>
\`\`\`

**For CLI integrations:**

\`\`\`
Current environment variables:
  {ENV_VAR1}: {configured | not set}
  {ENV_VAR2}: {configured | not set}

Which credential to update?
1. {ENV_VAR1} - {description}
2. {ENV_VAR2} - {description}
3. All credentials
4. Cancel

>
\`\`\`

**For File-based integrations:**

\`\`\`
Current configuration files:
  {config_file1}: {exists | missing}
  {config_file2}: {exists | missing}

Current environment variables:
  {ENV_VAR}: {configured | not set}

What would you like to update?
1. Regenerate keys
2. Update configuration files
3. Update environment variables
4. Cancel

>
\`\`\`

#### Steps

1. Detect current integration type
2. **For MCP OAuth:** Update config to trigger re-auth on reload
3. **For MCP API tokens:** Collect new values, update .mcp.json env section
4. **For CLI:** Collect new credentials, guide user to update shell profile
5. **For File-based:**
   - If regenerating keys: Run key generation command (e.g., `age-keygen`)
   - If updating config: Guide through config file updates
   - If updating env vars: Guide to update shell profile
6. Instruct action:
   \`\`\`
   {For MCP:}
   Credentials updated in .mcp.json
   Please restart Claude Code to apply changes.

   {For CLI/File-based:}
   Credentials updated.
   Please restart your terminal or run: source ~/.{shell}rc
   \`\`\`
7. Run connection test to verify

---

### Mode C: Test Connection (Option 4)

**Use case:** Quick health check without changing anything.

#### Workflow Display

**For MCP integrations:**

\`\`\`
Connection Test
---------------

Testing {vendor} connection...

Step 1: Checking MCP is loaded... {✓ | ✗}
Step 2: Running test operation ({test_op})... {✓ | ✗}
Step 3: Verifying response... {✓ | ✗}

{If all pass}
✓ Connection healthy!
  Last test: {timestamp}

{If any fail}
✗ Connection issue detected

Problem: {description}
Suggested fix: {action}

Would you like to run diagnostics? (yes/no)
>
\`\`\`

**For CLI integrations:**

\`\`\`
Connection Test
---------------

Testing {vendor} CLI connection...

Step 1: Checking CLI tool installed... {✓ | ✗}
        {tool_name} --version: {version or "not found"}
Step 2: Checking environment variables... {✓ | ✗}
        {ENV_VAR}: {configured | not set}
Step 3: Running test operation... {✓ | ✗}
        {test_op}
Step 4: Verifying response... {✓ | ✗}

{If all pass}
✓ Connection healthy!
  Last test: {timestamp}

{If any fail}
✗ Connection issue detected

Problem: {description}
Suggested fix: {action}

Would you like to run diagnostics? (yes/no)
>
\`\`\`

**For File-based integrations:**

\`\`\`
Connection Test
---------------

Testing {vendor} file-based integration...

Step 1: Checking CLI tools installed...
        {tool1}: {✓ installed | ✗ not found}
        {tool2}: {✓ installed | ✗ not found}
Step 2: Checking configuration files...
        {config_file1}: {✓ exists | ✗ missing}
        {config_file2}: {✓ exists | ✗ missing}
Step 3: Checking environment variables...
        {ENV_VAR}: {✓ configured | ✗ not set}
Step 4: Running test operation... {✓ | ✗}
        {test_op}

{If all pass}
✓ Integration healthy!
  Last test: {timestamp}

{If any fail}
✗ Integration issue detected

Problem: {description}
Suggested fix: {action}

Would you like to run diagnostics? (yes/no)
>
\`\`\`

#### Test Operations by Vendor

{test_operations_table}

---

### Mode D: Diagnose Issues (Option 5)

**Use case:** Something isn't working, user needs help figuring out why.

#### Diagnostic Checklist Display

**For MCP integrations:**

\`\`\`
Diagnostics: {Domain Name} (MCP)
================================

Running diagnostics...

CONFIGURATION
  [✓] .mcp.json exists
  [✓] {vendor} entry present
  [✓] JSON syntax valid
  [?] Environment variables set (cannot verify values)

MCP STATUS
  [✓] MCP server loaded
  [✗] Test operation failed
      Error: "401 Unauthorized"

CREDENTIALS
  [!] API token may be expired or invalid

RECOMMENDATIONS
  1. Regenerate API token at {regenerate_url}
  2. Run "Update credentials" (option 3)
  3. Restart Claude Code

Would you like to:
1. Update credentials now
2. View full configuration
3. Exit
>
\`\`\`

**For CLI integrations:**

\`\`\`
Diagnostics: {Domain Name} (CLI)
================================

Running diagnostics...

CLI TOOLS
  [✓] {tool1} installed ({version})
  [✗] {tool2} not found
      Install with: {install_command}

ENVIRONMENT
  [✓] {ENV_VAR1} is set
  [✗] {ENV_VAR2} not set
      Expected: {description}

CONNECTIVITY
  [✗] Test operation failed
      Error: "connection refused"

RECOMMENDATIONS
  1. Install missing CLI tools
  2. Set required environment variables
  3. Check network connectivity

Would you like to:
1. Update credentials now
2. View full configuration
3. Exit
>
\`\`\`

**For File-based integrations:**

\`\`\`
Diagnostics: {Domain Name} (File-based)
=======================================

Running diagnostics...

CLI TOOLS
  [✓] {tool1} installed ({version})
  [✓] {tool2} installed ({version})

CONFIGURATION FILES
  [✓] {config_file1} exists
  [✗] {config_file2} missing
      Create with: {creation_instructions}

FILE CONTENT VALIDATION
  [✓] {config_file1} syntax valid
  [?] {config_file1} public key configured (cannot verify)

ENVIRONMENT
  [✓] {ENV_VAR} is set

KEY FILES
  [✗] Private key file not found at {key_path}
      Generate with: {key_generation_command}

RECOMMENDATIONS
  1. Create missing configuration files
  2. Generate required keys
  3. Set environment variables pointing to key files

Would you like to:
1. Run setup steps again
2. View full configuration
3. Exit
>
\`\`\`

#### Diagnostic Checks

**For MCP integrations:**

| Check                | Method                       | Pass Condition        |
|----------------------|------------------------------|-----------------------|
| .mcp.json exists     | File read                    | File present          |
| Vendor entry present | JSON parse                   | Key exists            |
| JSON valid           | Parse attempt                | No errors             |
| Env vars defined     | Check .mcp.json env section  | Variables have values |
| MCP loaded           | Check available tools        | Vendor tools present  |
| Test operation       | Execute test                 | Returns valid data    |

**For CLI integrations:**

| Check              | Method                  | Pass Condition        |
|--------------------|-------------------------|-----------------------|
| CLI tool installed | Run `{tool} --version`  | Command succeeds      |
| Env vars set       | Check shell environment | Variables have values |
| Test operation     | Execute CLI command     | Returns valid data    |

**For File-based integrations:**

| Check               | Method                  | Pass Condition               |
|---------------------|-------------------------|------------------------------|
| CLI tools installed | Run `{tool} --version`  | Commands succeed             |
| Config files exist  | File read               | Files present                |
| Config syntax valid | Parse attempt           | No errors                    |
| Key files exist     | File read               | Files present at expected paths |
| Env vars set        | Check shell environment | Variables have values        |
| Test operation      | Execute test command    | Returns valid data           |

#### Common Diagnostic Scenarios

**Scenario: 401 Unauthorized (MCP)**
- Likely cause: API token expired or invalid
- Fix: Regenerate token, run Update credentials

**Scenario: MCP not loaded**
- Likely cause: .mcp.json syntax error or missing dependency
- Fix: Validate JSON, check npx availability

**Scenario: CLI tool not found**
- Likely cause: Tool not installed or not in PATH
- Fix: Install tool with package manager, verify PATH

**Scenario: Config file missing (File-based)**
- Likely cause: Setup incomplete or file deleted
- Fix: Re-run setup steps to create config file

**Scenario: Key file not found (File-based)**
- Likely cause: Keys not generated or env var pointing to wrong path
- Fix: Generate keys or correct SOPS_AGE_KEY_FILE path

**Scenario: Connection timeout**
- Likely cause: Network issue or service down
- Fix: Check network, verify service status

---

### Mode E: View Configuration (Option 6)

**Use case:** User wants to see what's configured without changing anything.

#### Display Format

**For MCP integrations:**

\`\`\`
Configuration View: {Domain Name}
=================================

Integration Type: MCP ({official | community})

.mcp.json entry:
\`\`\`json
{
  "{vendor_key}": {
    "command": "npx",
    "args": [...],
    "env": {
      "API_KEY": "****{last4}"
    }
  }
}
\`\`\`

CLAUDE.md section:
\`\`\`markdown
## {Domain Name}

Backend: {vendor}
Integration: MCP
...
\`\`\`

Files:
  - .mcp.json: {path}
  - CLAUDE.md: {path}
  - Progress file: {exists | not found}

Press Enter to continue...
\`\`\`

**For CLI integrations:**

\`\`\`
Configuration View: {Domain Name}
=================================

Integration Type: CLI

CLI Tools:
  - {tool1}: {version}
  - {tool2}: {version}

Environment Variables:
  - {ENV_VAR1}: ****{last4} (configured)
  - {ENV_VAR2}: ****{last4} (configured)

CLAUDE.md section:
\`\`\`markdown
## {Domain Name}

Backend: {vendor}
Integration: CLI
...
\`\`\`

Files:
  - CLAUDE.md: {path}
  - Progress file: {exists | not found}

Press Enter to continue...
\`\`\`

**For File-based integrations:**

\`\`\`
Configuration View: {Domain Name}
=================================

Integration Type: File-based

Configuration Files:
  - {config_file1}: {path} ({exists | missing})
  - {config_file2}: {path} ({exists | missing})

CLI Tools:
  - {tool1}: {version}
  - {tool2}: {version}

Environment Variables:
  - {ENV_VAR}: {value or "not set"}

CLAUDE.md section:
\`\`\`markdown
## {Domain Name}

Backend: {vendor}
Integration: File-based
Config: {config_file1}
...
\`\`\`

Files:
  - {config_file1}: {path}
  - {config_file2}: {path}
  - CLAUDE.md: {path}
  - Progress file: {exists | not found}

Press Enter to continue...
\`\`\`

**Security Note:** Always mask sensitive values (show only last 4 characters).

---

### Mode F: Reset Configuration (Option 7)

**Use case:** User wants to completely remove setup and start fresh.

#### Workflow Display

**For MCP integrations:**

\`\`\`
Reset Configuration
-------------------

This will remove:
  [x] {vendor} entry from .mcp.json
  [x] {Domain Name} section from CLAUDE.md
  [ ] Progress file (if exists)

WARNING: This cannot be undone.

Type "RESET" to confirm, or "cancel" to abort:
>
\`\`\`

**For CLI integrations:**

\`\`\`
Reset Configuration
-------------------

This will remove:
  [x] {Domain Name} section from CLAUDE.md
  [ ] Progress file (if exists)

NOTE: Environment variables in your shell profile will NOT be removed automatically.
      You may want to remove these manually:
        - {ENV_VAR1}
        - {ENV_VAR2}

WARNING: This cannot be undone.

Type "RESET" to confirm, or "cancel" to abort:
>
\`\`\`

**For File-based integrations:**

\`\`\`
Reset Configuration
-------------------

This will remove:
  [x] {config_file1} (project config)
  [x] {Domain Name} section from CLAUDE.md
  [ ] Progress file (if exists)

This will NOT remove (for safety):
  [ ] {key_file} (private keys - remove manually if needed)
  [ ] {ENV_VAR} from shell profile

WARNING: This cannot be undone.

Type "RESET" to confirm, or "cancel" to abort:
>
\`\`\`

#### Steps

1. Show what will be removed (varies by integration type)
2. Require explicit confirmation (user must type "RESET")
3. If confirmed:
   **For MCP:**
   a. Remove MCP entry from .mcp.json
   b. Remove section from CLAUDE.md
   c. Delete progress file if exists

   **For CLI:**
   a. Remove section from CLAUDE.md
   b. Delete progress file if exists
   c. Show reminder about env vars to remove manually

   **For File-based:**
   a. Remove project config files (e.g., .sops.yaml)
   b. Remove section from CLAUDE.md
   c. Delete progress file if exists
   d. Show reminder about key files and env vars (don't auto-delete for safety)

4. Offer to run fresh setup:
   \`\`\`
   Configuration removed.

   Would you like to set up {domain_name} again?
   1. Yes, start fresh setup
   2. No, exit

   >
   \`\`\`

---

### Resume Mode

When a progress file exists (setup was interrupted), first display the status:

\`\`\`
{Domain Name} Setup - Resume
============================

Found incomplete setup from {timestamp}

Progress:
  Vendor: {selected_vendor}
  Current Phase: Phase {N} - {phase_name}
  Completed: {completed_steps}
\`\`\`

Then use AskUserQuestion to present options:

```typescript
AskUserQuestion({
  questions: [{
    question: "How would you like to proceed with the incomplete setup?",
    header: "Resume",
    options: [
      { label: "Resume from Phase {N}", description: "Continue where you left off" },
      { label: "Start over", description: "Discard progress and begin fresh" }
    ],
    multiSelect: false
  }]
})
```

---

### Phase 0.5: Domain Explanation

Display domain explanation to help user understand why this setup matters.

\`\`\`
{domain_explanation}

Ready to set up {domain_name}?

Press Enter to continue, or type "skip" to go directly to vendor selection.
\`\`\`

**Note:** This phase is informational. User can skip if already familiar with the domain.

**DOD:** User acknowledges or skips explanation

---

### Phase 1: Vendor Selection

Present qualified vendors with feature highlights:

{vendor_selection_display}

**After vendor selection, create progress file.**

**DOD:** User selects a vendor

---

### Phase 2: Integration Selection

Based on selected vendor's available integration methods:

#### For Vendors with Multiple Integration Methods

Use AskUserQuestion to present integration options:

```typescript
AskUserQuestion({
  questions: [{
    question: "How would you like to integrate {vendor}?",
    header: "Integration",
    options: [
      { label: "MCP Integration (Recommended)", description: "Tools available directly in Claude with auto-refresh" },
      { label: "CLI/File-based Integration", description: "Uses native tools and config files, more control" }
    ],
    multiSelect: false
  }]
})
```

#### For Vendors with Single Integration Method

Skip this phase - proceed directly with the vendor's integration method.

#### Integration Method Selection by Vendor

{integration_selection_by_vendor}

**Update progress file with integration method selection**

**DOD:** User selects an integration method (or auto-selected for single-method vendors)

---

### Phase 3: Integration Setup

Setup varies based on selected integration method.

\`\`\`
                  Integration Method
┌─────────────────────────────────────────────────────────┐
│                                                         │
└───────────┬─────────────┬─────────────┬────────────────┘
            │             │             │
    ┌───────▼───────┐ ┌───▼───┐ ┌───────▼───────┐
    │ MCP (Official │ │  CLI  │ │  File-Based   │
    │ or Community) │ │       │ │               │
    └───────┬───────┘ └───┬───┘ └───────┬───────┘
            │             │             │
            ▼             ▼             ▼
     Configure        Install &     Create config
     .mcp.json       configure CLI   files & set
                                    env vars
\`\`\`

#### Branch A: MCP Setup (mcp-official, mcp-community)

##### For Official Remote MCPs (OAuth-based)

1. **Configure `.mcp.json` with remote URL:**

{official_mcp_configs}

2. **Instruct user to restart Claude Code**

3. **After reload, OAuth flow will trigger automatically**

##### For Community Local MCPs (API Token-based)

{community_mcp_setup_guides}

##### Verify .gitignore

\`\`\`bash
grep -q "^\.mcp\.json$" .gitignore 2>/dev/null
\`\`\`

- If `.mcp.json` is not in `.gitignore`, offer to add it

##### Instruct User to Reload

\`\`\`
MCP configuration written to .mcp.json

Claude Code needs to reload to activate the {Vendor} MCP.

Please restart Claude Code, then run this skill again.
Progress has been saved - setup will resume from the connection test.
\`\`\`

#### Branch B: CLI Setup (cli)

\`\`\`
CLI Integration Setup
---------------------

{vendor} uses CLI tools for integration.

Step 1: Verify CLI tools installed

  Checking for: {cli_tools}

  {tool_name}: {✓ installed | ✗ not found}

  {If not found}
  Install with: {install_command}

Step 2: Configure authentication

  {Collect credentials based on vendor.auth}

Step 3: Set environment variables

  {List required env_vars}

  Add to your shell profile (~/.bashrc, ~/.zshrc):
  export {ENV_VAR}="{value}"

Step 4: Verify installation

  Running: {test_op}
\`\`\`

#### Branch C: File-Based Setup (file-based)

\`\`\`
File-Based Integration Setup
----------------------------

{vendor} uses configuration files for integration.

Step 1: Verify CLI tools installed

  Checking for: {cli_tools}

  {tool_name}: {✓ installed | ✗ not found}

  {If not found}
  Install with: {install_command}

Step 2: Create configuration files

  File: {config_file.path}
  Purpose: {config_file.description}

  {Generate appropriate config content from template}

Step 3: Generate/configure keys (if applicable)

  {For SOPS+age: run age-keygen}
  {For other file-based: appropriate key setup}

Step 4: Set environment variables

  {List required env_vars}

Step 5: Verify installation

  Running: {test_op}
\`\`\`

#### Update Progress File

Update to indicate pending verification and resume point.

**DOD:** Integration configured (MCP written to .mcp.json, CLI tools installed, or config files created)

---

### Phase 4: Connection Test

After setup, verify integration is working.

#### For MCP integrations (after Claude Code reload):

##### Step 1: Verify MCP is Loaded

- Check that vendor MCP tools are now available
- If not available, troubleshoot configuration

##### Step 2: Run Test Operation

{test_operations_table}

##### Step 3: Confirm with User

\`\`\`
Test successful! I was able to {describe what was retrieved}.

Did you see the expected data? Please confirm.
\`\`\`

#### For CLI integrations:

##### Step 1: Verify CLI Tool

\`\`\`bash
{tool} --version
\`\`\`

- If not found, guide user to install

##### Step 2: Verify Environment Variables

\`\`\`bash
echo ${ENV_VAR}
\`\`\`

- If not set, guide user to configure

##### Step 3: Run Test Operation

\`\`\`bash
{test_op}  # e.g., "vault kv list secret/"
\`\`\`

##### Step 4: Confirm with User

\`\`\`
Test successful! CLI tool is working.

Did you see the expected output? Please confirm.
\`\`\`

#### For File-based integrations:

##### Step 1: Verify CLI Tools

\`\`\`bash
{tool1} --version
{tool2} --version
\`\`\`

##### Step 2: Verify Configuration Files

\`\`\`bash
cat {config_file}
\`\`\`

##### Step 3: Verify Keys/Credentials

\`\`\`bash
ls -la {key_file_path}
\`\`\`

##### Step 4: Run Test Operation

\`\`\`bash
{test_op}  # e.g., "sops -d test.enc.yaml"
\`\`\`

##### Step 5: Confirm with User

\`\`\`
Test successful! File-based integration is working.

Did you see the expected output? Please confirm.
\`\`\`

**DOD:** Test operation succeeds, user confirms

---

### Phase 5: Documentation

Update CLAUDE.md with "{Domain Name}" section.

#### Step 1: Check if CLAUDE.md Exists

- If not, create it with basic structure
- If exists, prepare to add/update "{Domain Name}" section

#### Step 2: Check for Domain Template

\`\`\`bash
cat plugins/crunch/templates/{domain_key}.template.md 2>/dev/null
\`\`\`

#### Step 3: Generate CLAUDE.md Content

**If template exists:**

1. Read the template file
2. Use template content exactly as-is (no placeholder replacement)
3. Gather tool information from the configured vendor:
   - For MCP: List all available MCP tools and their descriptions
   - For CLI: List all CLI commands available
   - For API: List API methods available
4. Append "Tool Reference" section after template content:

\`\`\`markdown
### Tool Reference ({Vendor})

**Integration**: {integration_type}

**Available Operations**:

| Operation              | Tool/Command           | Description                      |
|------------------------|------------------------|----------------------------------|
| Create task            | mcp_trello_createCard  | Creates a new card on a board    |
| List tasks             | mcp_trello_getCards    | Gets all cards from a board      |
| Update task            | mcp_trello_updateCard  | Updates card properties          |

**Examples**:
- To create a task: use \`mcp_trello_createCard\` with name, description, and listId
- To find tasks: use \`mcp_trello_getCards\` with boardId filter
\`\`\`

**If template does NOT exist:**

Generate documentation from vendor tools directly:

\`\`\`markdown
## {Domain Name}

**Vendor**: {vendor_name}
**Integration**: {integration_type}
**Configuration**: {config_location}

### Available Tools

| Tool/Command              | Description                              |
|---------------------------|------------------------------------------|
| mcp_trello_createCard     | Create a new card on a Trello board      |
| mcp_trello_getCards       | Get cards from a board or list           |
| mcp_trello_updateCard     | Update card properties                   |
| mcp_trello_moveCard       | Move card to a different list            |

### Common Operations

- **Create item**: Use \`mcp_trello_createCard\` to create new cards
- **List items**: Use \`mcp_trello_getCards\` to retrieve cards
- **Update item**: Use \`mcp_trello_updateCard\` to modify cards

### Examples

\`\`\`
# Create a new task
mcp_trello_createCard(name: "Fix login bug", idList: "abc123")

# Get all tasks from a board
mcp_trello_getCards(idBoard: "xyz789")
\`\`\`
\`\`\`

#### Step 4: Update CLAUDE.md

**If section exists:** Replace the existing `## {Domain Section}` with generated content

**If section doesn't exist:** Append the generated content to CLAUDE.md

#### Step 5: Cleanup Progress File

\`\`\`bash
rm {domain_key}-setup-progress.md
\`\`\`

#### Step 6: Summarize Completion

**For MCP integrations:**

\`\`\`
{Vendor} {domain_name} setup complete!

Configuration Summary:
  - Vendor: {vendor}
  - Integration: MCP ({official | community})
  - Config file: .mcp.json
  - Documented in: CLAUDE.md

Available Features:
{feature_bullet_list}

Progress file cleaned up.
\`\`\`

**For CLI integrations:**

\`\`\`
{Vendor} {domain_name} setup complete!

Configuration Summary:
  - Vendor: {vendor}
  - Integration: CLI
  - CLI tools: {tool_list}
  - Environment variables: {env_var_list}
  - Documented in: CLAUDE.md

Available Features:
{feature_bullet_list}

Progress file cleaned up.
\`\`\`

**For File-based integrations:**

\`\`\`
{Vendor} {domain_name} setup complete!

Configuration Summary:
  - Vendor: {vendor}
  - Integration: File-based
  - Config files: {config_file_list}
  - CLI tools: {tool_list}
  - Documented in: CLAUDE.md

Available Features:
{feature_bullet_list}

Progress file cleaned up.
\`\`\`

**DOD:** CLAUDE.md updated, user informed

---

## Error Handling

### Error Table

{error_handling_table}

### Common Troubleshooting

**MCP not appearing after reload:**
1. Verify `.mcp.json` is valid JSON
2. Check for syntax errors (trailing commas, missing quotes)
3. For community MCPs, verify environment variables are correct
4. For OAuth MCPs, check if authorization completed
5. Check Claude Code logs for errors

**"Command not found" errors (community MCPs):**
1. Verify Node.js is in PATH
2. Check npx is available: `which npx`
3. Try with full path to npx

**OAuth flow not starting:**
1. Check internet connectivity
2. Verify remote URL is correct
3. Try mcp-remote directly: `npx -y mcp-remote <url>`

**Authentication failures:**
1. Verify credential format matches expected pattern
2. Check if credentials have expired
3. Verify permissions/scopes are sufficient
4. Regenerate credentials if needed

---

## Interactive Checkpoints

### Phase 0 Checkpoints
- [ ] "Found existing setup. Keep/add/reconfigure?"

### Phase 0.5 Checkpoints
- [ ] "Ready to continue with setup?"

### Phase 1 Checkpoints
- [ ] "Which vendor would you like to use?"

### Phase 2 Checkpoints (Integration Selection)
- [ ] "How would you like to integrate? (MCP / CLI / File-based)"
- [ ] (MCP only) "Official MCP (OAuth) or community option (API Token)?"

### Phase 3 Checkpoints (Integration Setup)
- [ ] "Credentials/config collected. Ready to configure?"
- [ ] (MCP) "Configuration written. Ready to restart Claude Code?"
- [ ] (CLI) "Environment variables set. Ready to test?"
- [ ] (File-based) "Config files created. Ready to test?"

### Phase 4 Checkpoints (Connection Test)
- [ ] "Test successful! Did you see the expected data?"

### Phase 5 Checkpoints (Documentation)
- [ ] "Setup complete! Documented in CLAUDE.md."

**Definition of Done:** Only mark setup as complete when user confirms the test operation succeeded.

---

## Operations (Post-Setup Use)

This section defines ongoing operations after initial setup. Generated skills should include operation templates relevant to the domain.

### How It Works

1. **Read CLAUDE.md** to detect {domain_name} configuration
2. **Verify connection** to the configured backend
3. **Execute the requested operation**
4. **Return results** in a consistent format

### Pre-flight Check

Before any operation, ensure environment is configured:

\`\`\`bash
# Load environment if applicable
source .env 2>/dev/null || true

# Verify required variables
{preflight_env_checks}

# Verify tool/service is accessible
{preflight_connectivity_check}
\`\`\`

**If not configured:**

\`\`\`
⚠️ {Domain Name} environment not configured.

{missing_config_description}

To fix this:
1. Check that {domain_name} is configured in CLAUDE.md
2. Ensure your .env file contains required variables
3. Or run the setup skill: /setup-{domain_key}
\`\`\`

### Available Operations

{operations_table}

**Table format:**

| Operation | Tool/Command | Description | Example |
|-----------|--------------|-------------|---------|
| {op_1}    | {tool_1}     | {desc_1}    | {ex_1}  |
| {op_2}    | {tool_2}     | {desc_2}    | {ex_2}  |

### Operation Templates

Each domain should define CRUD-style operations as appropriate:

**Create/Add Operation:**
\`\`\`
Parse from user request:
- Item name/identifier
- Required attributes

Command: {create_command}

Response:
✓ Created: {item_name}
  ID: {item_id}
  {additional_details}
\`\`\`

**Read/Get Operation:**
\`\`\`
Parse from user request:
- Item identifier

Command: {read_command}

Response:
✓ Retrieved: {item_name}
  {item_details}
\`\`\`

**Update Operation:**
\`\`\`
Parse from user request:
- Item identifier
- Fields to update

Command: {update_command}

Response:
✓ Updated: {item_name}
  Changes: {changes_summary}
\`\`\`

**Delete Operation:**
\`\`\`
Parse from user request:
- Item identifier

Confirmation required:
⚠️ You're about to delete: {item_name}
This action cannot be undone. Continue? (yes/no)

Command: {delete_command}

Response:
✓ Deleted: {item_name}
\`\`\`

**List Operation:**
\`\`\`
Parse from user request:
- Filter criteria (optional)

Command: {list_command}

Response:
✓ {Items} in {context}:
- {item_1}
- {item_2}
- {item_3}

Total: {count} items
\`\`\`

---

## Response Format Standards

### Success Formats

**Success - Create:**
\`\`\`
✓ {Operation}: {identifier}

{details}
\`\`\`

**Success - Read (with --show flag):**
\`\`\`
✓ Retrieved: {identifier}

{full_content}
\`\`\`

**Success - Read (default, sensitive data hidden):**
\`\`\`
✓ Retrieved: {identifier}

Value: ******* (hidden)
Use --show to display value
\`\`\`

**Success - List:**
\`\`\`
✓ {Items} in {path}:

- {item_1}
- {item_2}
- {item_3}

Total: {count} items
\`\`\`

**Success - Update:**
\`\`\`
✓ Updated: {identifier}

Changes: {summary}
\`\`\`

**Success - Delete:**
\`\`\`
✓ Deleted: {identifier}
\`\`\`

### Error Format

\`\`\`
✗ Failed to {operation}: {identifier}

Error: {error_message}

Suggestions:
- {suggestion_1}
- {suggestion_2}
\`\`\`

---

## Security Reminders

Include domain-appropriate security guidance:

### General Security
- Never commit credentials to git
- Ensure sensitive files are in .gitignore
- Use short-lived tokens when possible
- Rotate credentials periodically

### Domain-Specific ({domain_name})
{domain_specific_security_notes}

**Example security notes by domain type:**
- **Secrets**: Never log secret values; use references instead
- **Task Management**: Be careful with project/board access tokens
- **CI/CD**: Pipeline tokens have broad access; scope appropriately
- **Observability**: API keys often have read access to all data

---

## Related Skills

{related_skills_list}
```

---

## Generation Details

### Vendor Table Generation

For qualified vendors table:

```markdown
| Vendor        | {Feature1} | {Feature2} | {Feature3} | Notes   |
|---------------|------------|------------|------------|---------|
| **{Vendor1}** | {support}  | {support}  | {support}  | {notes} |
| **{Vendor2}** | {support}  | {support}  | {support}  | {notes} |
```

For excluded vendors table:

```markdown
| Vendor    | Why Excluded |
|-----------|--------------|
| {Vendor1} | {reason}     |
| {Vendor2} | {reason}     |
```

For integration options table:

```markdown
| Vendor        | Integration | Method Details         | Auth Type    |
|---------------|-------------|------------------------|--------------|
| **{Vendor1}** | MCP         | Official: {url}        | {auth_types} |
| **{Vendor2}** | MCP         | Community: {package}   | {auth_types} |
| **{Vendor3}** | File-based  | Config: {config_files} | {auth_types} |
| **{Vendor4}** | CLI         | Tools: {cli_tools}     | {auth_types} |
| **{Vendor5}** | MCP / CLI   | Primary: MCP, Alt: CLI | {auth_types} |
```

### Vendor Selection Display Generation

Use AskUserQuestion for vendor selection:

```typescript
AskUserQuestion({
  questions: [{
    question: "Which {domain_name} tool would you like to integrate?",
    header: "Vendor",
    options: [
      // Dynamically generated from vendor matrix
      { label: "{Vendor1}", description: "{vendor1_notes} - Best for: {use_case}" },
      { label: "{Vendor2}", description: "{vendor2_notes} - Best for: {use_case}" },
      { label: "{Vendor3}", description: "{vendor3_notes} - Best for: {use_case}" },
      { label: "{Vendor4}", description: "{vendor4_notes} - Best for: {use_case}" }
    ],
    multiSelect: false
  }]
})
```

### MCP Config Generation

For official MCPs:

```json
{
  "mcpServers": {
    "{vendor_key}": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "{official_mcp_url}"]
    }
  }
}
```

For community MCPs:

```json
{
  "mcpServers": {
    "{vendor_key}": {
      "command": "npx",
      "args": ["-y", "{community_mcp_package}"],
      "env": {
        "{ENV_VAR1}": "<user-provided-value>",
        "{ENV_VAR2}": "<user-provided-value>"
      }
    }
  }
}
```

### Required Stories Section Generation

When generating a skill, include the Required Stories section with collected stories:

**Story Coverage Table:**
```markdown
| #  | Story                                               | Support   | Vendor Tool              |
|----|-----------------------------------------------------|-----------|--------------------------|
| 1  | it should be possible to create a task              | ✓ Full    | createIssue              |
| 2  | it should be possible to set one task dependent     | ~ Partial | attachments (workaround) |
| 3  | it should be possible to filter tasks by status     | ✓ Full    | searchIssues             |
```

- List all collected stories from Phase 1.5/1.6
- Map each story to vendor tools that fulfill it
- Indicate support level: ✓ Full, ~ Partial, ✗ Gap

**Vendor Compatibility:**
When the generated skill checks vendor compatibility, it should:
1. List the vendor's available tools
2. Match each story against available tools
3. Calculate overall story coverage percentage
4. Identify gaps and suggest workarounds

---

## Error Handling

### Common Issues

**Skill already exists:**
- Offer to overwrite or cancel
- If overwriting, backup existing first

**Invalid domain key:**
- Must be lowercase
- No spaces (use hyphens)
- No special characters except hyphens

**Missing vendor information:**
- All vendors must have at least one MCP option
- All vendors must have a test operation

**Template rendering errors:**
- Validate all placeholders are filled
- Check for unescaped special characters in markdown

---

## Interactive Checkpoints

- [ ] "Which domain would you like to create a setup skill for?"
- [ ] "Describe your first story (it should be possible to...)"
- [ ] "Add another story, or type 'done'"
- [ ] "Do these stories capture your requirements?"
- [ ] "Which vendor do you use?"
- [ ] "Ready to generate skill at plugins/crunch/skills/setup-{domain_key}/?"
- [ ] "Skill generated. Review the output?"
