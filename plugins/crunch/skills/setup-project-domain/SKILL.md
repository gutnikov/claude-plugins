---
name: setup-project-domain
description: Meta-skill for creating domain-specific setup skills. Generates SKILL.md files for project domains (Task Management, Secrets, Communication, CI/CD, etc.) following the setup-task-manager pattern.
---

# Setup Project Domain

This meta-skill generates domain-specific setup skills (like `setup-task-manager`) for different project domains. It abstracts the common patterns from setup skills and allows creating new ones for any integration domain.

## Definition of Done

The skill creation is complete when:

1. Domain is selected or defined (pre-defined or custom)
2. Vendor matrix is configured (pre-defined or gathered)
3. SKILL.md is generated at `plugins/crunch/skills/setup-{domain-key}/SKILL.md`
4. Generated skill follows the setup-task-manager pattern exactly
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

| Domain                       | Key                          | Purpose                                    | Required Features                    | Popular Vendors                               |
|------------------------------|------------------------------|--------------------------------------------|--------------------------------------|-----------------------------------------------|
| **Task Management**          | `task-management`            | Track and manage work items                | Tasks, Tags, Statuses, Dependencies  | Jira, Linear, Trello, Asana, GitHub Issues    |
| **Secrets**                  | `secrets`                    | Store and retrieve secrets securely        | Get, Set, List, Delete               | Vault, SOPS+age, AWS Secrets Manager, 1Password |
| **CI/CD**                    | `ci-cd`                      | Continuous integration/deployment          | Pipelines, Triggers, Logs, Artifacts | GitHub Actions, GitLab CI, CircleCI, Jenkins  |
| **Pipelines**                | `pipelines`                  | Define project pipelines (local, CI, deploy) | Detect, Define, Document, Validate   | Depends on tech-stack + CI + environments     |
| **Configuration**            | `configuration`              | Manage env variables per environment       | Define, Switch, Validate, Sync       | dotenv, direnv, Doppler, Infisical            |
| **Observability**            | `observability`              | Metrics, logs, traces, alerting            | Metrics, Logs, Traces, Alerts        | Datadog, Grafana, Prometheus, Honeycomb       |
| **Documentation**            | `documentation`              | Doc site generation and publishing         | Generate, Publish, Version, Search   | Docusaurus, GitBook, ReadTheDocs, Mintlify    |
| **Localization**             | `localization`               | Internationalization and translation       | Extract, Translate, Sync, Manage keys | Lokalise, Crowdin, Phrase, i18next            |
| **Memory Management**        | `memory-management`          | Persistent AI context across sessions      | Store, Retrieve, Search, Update      | Memory MCP, Pinecone, Chroma, Weaviate        |
| **Deploy Environments**      | `deploy-environments`        | Manage dev/staging/prod environments       | Config, Feature flags, Env switching | LaunchDarkly, ConfigCat, Vercel, Netlify      |
| **Problem Remediation**      | `problem-remediation`        | Runbook automation, self-healing           | Detect, Execute, Verify, Rollback    | Rundeck, Ansible, PagerDuty Runbooks, Shoreline |
| **Tech Stack**               | `tech-stack`                 | Auto-detect and configure project stack    | Detect, Configure, Validate          | Custom detection, Nx, Turborepo, mise         |
| **User Communication Bot**   | `user-communication-bot`     | Slack app/bot for project development      | Send, Receive, React, Thread         | Slack Bot, Discord Bot                        |
| **Agents & Orchestration**   | `agents-and-orchestration`   | Configure Claude Code agents               | Define, Connect, Coordinate          | Claude Code agents, custom configs            |
| **Custom**                   | (user-defined)               | (user-defined)                             | (user-defined)                       | (user-defined)                                |

**Note:** Users select their existing vendor from the popular list (or specify "Other"). The skill then analyzes vendor compatibility with the domain requirements.

---

## Workflow

### Phase 1: Domain Selection

Use the AskUserQuestion tool to present domain options with an interactive selector:

```typescript
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

// If user needs more options, present second set:
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

// Additional domains:
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

// More domains:
AskUserQuestion({
  questions: [{
    question: "More domains:",
    header: "Domain",
    options: [
      { label: "User Communication Bot", description: "Slack/Discord bot for development" },
      { label: "Agents & Orchestration", description: "Configure Claude Code agents" }
    ],
    multiSelect: false
  }]
})
```

**Note:** User can select "Other" to define a custom domain.

**If pre-defined domain selected:** Continue to Phase 1.7 (Vendor Selection)

**If custom domain selected (Other):** Continue to Phase 1.5 (Scenario Collection)

**DOD:** Domain selected

---

### Phase 1.5: Scenario Collection (Custom Only)

Before defining domain details, collect usage scenarios to extract the domain model.

#### Entry Dialog

```
Custom Domain Setup - Scenario Collection
-----------------------------------------

Before defining your domain, let's understand how you'll use it.

Describe a scenario where you'd interact with this system. Be specific about:
- What you're trying to accomplish
- What data or objects you're working with
- What actions you need to take

Example: "I want to create a new support ticket for a customer,
assign it to an agent, set priority to high, and add labels."

Describe your first scenario:
>
```

#### Multi-Turn Collection Loop

1. User provides scenario
2. Claude extracts and displays extraction (see Phase 1.6)
3. Ask: "Add another scenario, or type 'done'"
4. Repeat until user says "done"

#### After Each Scenario

```
Scenario {N} captured!

I've extracted:
  Entities: {new_entities}
  Operations: {new_operations}
  Attributes: {new_attributes}

Your domain model now includes:
  {total} entities, {total} operations, {total} attributes

Add another scenario, or type 'done':
>
```

**DOD:** At least 1 scenario collected, user says "done"

---

### Phase 1.6: Model Extraction & Review (Custom Only)

Extract and consolidate domain model from collected scenarios.

#### Extraction Rules

**Entities (nouns):**
- Direct objects: "create a **ticket**" → `ticket`
- Subjects: "**agent** handles..." → `agent`
- Implicit entities from relationships: "assign to **team**" → `team`
- Possessives: "customer's **order**" → `order`, `customer`

**Operations (verbs):**
- CRUD operations: create, read/get/list, update, delete
- Relationships: assign, link, attach, add, remove
- State changes: transition, close, resolve, approve, reject
- Bulk operations: import, export, archive

**Attributes (properties):**
- Set expressions: "set **priority** to high" → `priority` (enum)
- Filter criteria: "filter by **status**" → `status`
- Inferred from operations:
  - assign → `assignee` (reference)
  - create → `created_at` (timestamp)
  - update → `updated_at` (timestamp)
- Described values: "with **description**" → `description` (text)

#### Per-Scenario Extraction Display

```
Scenario Analysis
-----------------
"{user's scenario text}"

Extracted:

ENTITIES:
  + ticket      [NEW] - Support ticket
  + agent       [NEW] - Support agent
  + customer    [NEW] - Customer record

OPERATIONS:
  + create      [NEW] - Create new items
  + assign      [NEW] - Assign to owner
  + set         [NEW] - Set property value

ATTRIBUTES:
  + priority    [NEW] on ticket - enum
  + labels      [NEW] on ticket - list
  + assignee    [INFERRED] on ticket - reference to agent

Does this look correct? (yes / adjust / skip)
>
```

**If user says "adjust":**
```
What would you like to change?
1. Add entity: <name> - <description>
2. Remove entity: <name>
3. Add operation: <name> - <description>
4. Remove operation: <name>
5. Add attribute: <name> on <entity> - <type>
6. Remove attribute: <name>
7. Done adjusting
>
```

#### Consolidated Review (After "done")

```
Domain Model Review
===================

Based on your {N} scenarios:

ENTITIES ({count})
| Entity   | Description      | Attributes                 |
|----------|------------------|----------------------------|
| ticket   | Support ticket   | priority, status, assignee |
| agent    | Support agent    | name, email, team          |
| customer | Customer record  | name, email                |

OPERATIONS ({count})
| Operation  | Applies To    | Description      |
|------------|---------------|------------------|
| create     | ticket, agent | Create new items |
| assign     | ticket        | Assign to owner  |
| transition | ticket        | Change status    |

ATTRIBUTES ({count})
| Attribute | Entity | Type              |
|-----------|--------|-------------------|
| priority  | ticket | enum              |
| status    | ticket | enum              |
| assignee  | ticket | reference (agent) |
| labels    | ticket | list              |

Does this model represent your domain?
1. Yes, continue to domain configuration
2. Add more scenarios
3. Make adjustments
>
```

**DOD:** Domain model extracted and confirmed

---

### Phase 1.7: Vendor Selection

**Applies to:** Both pre-defined and custom domains. For pre-defined domains, this is the next step after Phase 1. For custom domains, this follows Phase 1.6.

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

After vendor selection, analyze how well the vendor matches the domain's requirements.

#### Step 1: Map Vendor Capabilities

Using the Entity and Operation Mapping Aliases (see Vendor Capability Registry), determine:

1. **Entity Coverage** - Which domain entities the vendor supports
2. **Operation Coverage** - Which domain operations the vendor supports
3. **Gaps** - What's missing or requires workarounds

#### Step 2: Display Compatibility Report

```
Vendor Compatibility Analysis: {Vendor} for {Domain Name}
=========================================================

Entity Mapping:
  {domain_entity_1} → {vendor_entity} [Full Support]
  {domain_entity_2} → {vendor_entity} [Full Support]
  {domain_entity_3} → (custom field)  [Workaround Required]
  {domain_entity_4} → (not supported) [Gap]

Operation Mapping:
  {operation_1} → {vendor_api_method} [Full Support]
  {operation_2} → {vendor_api_method} [Full Support]
  {operation_3} → (manual process)    [Workaround Required]

Overall Compatibility: {X}% ({Y} of {Z} capabilities supported)

Gaps & Workarounds:
  - {entity/operation}: {description of workaround or limitation}

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

### Phase 2: Domain Configuration (Custom Only)

For custom domains, gather the following. If Phase 1.5/1.6 was completed, fields are **auto-populated from the extracted model**.

#### Step 1: Domain Definition

```
Custom Domain Setup
-------------------

Based on your scenarios, I've prepared these defaults:

1. What is this domain called? (e.g., "Database Management")
   [Auto-populated: "{inferred_domain_name}"]
   > [press Enter to accept, or type new name]

2. What is the purpose of this domain? (one sentence)
   [Auto-populated: "{inferred_purpose}"]
   > [press Enter to accept, or type new purpose]

3. What features must vendors support? (comma-separated)
   [Auto-populated from extracted operations: {operation_list}]
   > [press Enter to accept, or type new features]
```

**Auto-population from Extracted Model:**

| Field               | Source                                                              |
|---------------------|---------------------------------------------------------------------|
| `domain_name`       | Inferred from primary entity (e.g., "ticket" → "Ticket Management") |
| `purpose`           | Generated from entities and operations                              |
| `required_features` | Directly from extracted operations                                  |

**Auto-generate from user input:**

- `domain_key`: Lowercase, hyphenated (e.g., "Database Management" → `database-manager`)
- `claude_section`: `## {Domain Name}`
- `progress_file`: `{domain_key}-setup-progress.md`

#### Step 2: Vendor Research

```
Now let's define the qualified vendors for {Domain Name}.

How many vendors would you like to add? (1-10)
>
```

For each vendor, collect:

```
Vendor {N} of {Total}
--------------------

1. Vendor name: (e.g., "PostgreSQL")
   >

2. Vendor key: (lowercase, e.g., "postgres")
   >

3. Feature support: (which required features does it support?)
   Features: {required_features}
   Supports all? (yes/no)
   >

4. Official MCP: (URL if remote, null if none)
   >

5. Community MCP: (npm package name, or null if none)
   >

6. Authentication methods: (comma-separated)
   Examples: OAuth, API Token, Username/Password, IAM
   >

7. Test operation: (command or tool call to verify connection)
   Example: "list_databases" or "SELECT 1"
   >

8. Notes: (brief description, best use case)
   >
```

#### Step 3: Excluded Vendors (Optional)

```
Are there any vendors that appear relevant but should be excluded?
(These are vendors that don't meet all required features)

Enter vendor names and reasons, or "none" to skip:

Format: VendorName: reason
Example: SQLite: No remote connections

>
```

**DOD:** Domain definition and vendor matrix complete

---

### Phase 2.5: Vendor Suggestion (Custom Only with Scenarios)

If scenarios were collected in Phase 1.5, suggest vendors based on extracted model before manual vendor research.

#### Capability Matching Algorithm

Score vendors by matching extracted model against known vendor capabilities:

| Category              | Weight | Scoring                                             |
|-----------------------|--------|-----------------------------------------------------|
| **Entity Support**    | 40%    | % of extracted entities that vendor can model       |
| **Operation Support** | 40%    | % of extracted operations that vendor API supports  |
| **Attribute Support** | 20%    | % of extracted attributes vendor can store          |

**Match Levels:**
- **Full**: Vendor has native support (entity/operation/attribute exists)
- **Partial**: Can be achieved with workarounds (custom fields, tags, etc.)
- **Gap**: Not supported, would need external solution

#### Suggestion Display

```
Vendor Suggestions
==================

Based on your model ({N} entities, {M} operations):

RECOMMENDED

1. Jira (95% match)
   Entity Mapping:
     ticket    → Issue    [Full]
     agent     → User     [Full]
     customer  → Customer [Gap - use custom field]

   Operation Mapping:
     create    → createIssue     [Full]
     assign    → assignIssue     [Full]
     transition → transitionIssue [Full]

   Gaps:
     - customer entity → use custom field or linked Jira Service Management

   Why Jira: Complex workflows, issue linking, JQL search, extensive API

2. Linear (82% match)
   Entity Mapping:
     ticket    → Issue    [Full]
     agent     → User     [Full]
     customer  → Customer [Gap - no native support]

   Gaps:
     - customer entity → no native support, use labels
     - limited link types

   Why Linear: Modern API, fast performance, developer-focused

3. Trello (68% match)
   Entity Mapping:
     ticket    → Card     [Full]
     agent     → Member   [Full]
     customer  → Customer [Gap - no native support]

   Gaps:
     - No native dependencies
     - No status transitions (use lists)
     - Limited custom fields (Power-Ups required)

   Why Trello: Simple, visual, quick setup

Proceed with:
1. Jira (recommended)
2. Linear
3. Trello
4. Skip suggestions, define vendors manually
5. See more vendors
>
```

#### If User Selects a Suggested Vendor

Auto-populate Phase 2 Step 2 (Vendor Research) with the selected vendor's details:
- Pre-fill vendor name, key, features from capability registry
- Pre-fill MCP options from known configurations
- Only ask for any missing custom information

#### If User Skips or Selects Manual

Continue to Phase 2 Step 2 with standard vendor collection flow.

**DOD:** Vendor suggested and selected, OR user chose manual entry

---

### Phase 3: Check for Existing Skill

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

### Phase 4: Generate Setup Skill

Create the SKILL.md file using the domain configuration.

#### Step 1: Create Directory

```bash
mkdir -p plugins/crunch/skills/setup-{domain_key}
```

#### Step 2: Generate SKILL.md

Use the **Template Structure** (below) with these substitutions:

| Placeholder                  | Value                                       |
|------------------------------|---------------------------------------------|
| `{domain_name}`              | Domain name (e.g., "Secret Management")     |
| `{domain_key}`               | Domain key (e.g., "secret-manager")         |
| `{purpose}`                  | Domain purpose                              |
| `{feature_list}`             | Comma-separated features                    |
| `{feature_summary}`          | Brief feature summary for description       |
| `{vendor_list}`              | Comma-separated vendor names                |
| `{qualified_vendors_table}`  | Markdown table of qualified vendors         |
| `{excluded_vendors_table}`   | Markdown table of excluded vendors          |
| `{mcp_options_table}`        | Markdown table of MCP options               |
| `{progress_file_format}`     | Progress file template                      |
| `{phase_N_content}`          | Content for each workflow phase             |
| `{vendor_credentials_guide}` | Vendor-specific credential instructions     |
| `{error_table}`              | Error handling table                        |
| `{checkpoints}`              | Interactive checkpoints                     |
| `{related_skills}`           | Related skill links                         |

#### Step 3: Write File

Write generated content to:
```
plugins/crunch/skills/setup-{domain_key}/SKILL.md
```

**DOD:** SKILL.md file created

---

### Phase 5: Verification

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

# Required capabilities for compatibility analysis
required_entities:
  - task        # Primary work item
  - user        # Team member / assignee
  - project     # Container for tasks
  - tag         # Categorization labels
  - status      # Workflow state

required_operations:
  - create      # Create new tasks
  - read        # View task details
  - update      # Modify tasks
  - list        # List/search tasks
  - assign      # Assign to users
  - transition  # Change status

required_attributes:
  - title       # Task name
  - description # Task details
  - priority    # Urgency level
  - status      # Current state
  - assignee    # Assigned user
  - tags        # Labels/categories

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

Entity Mapping:
  task    → card      [Full Support]
  user    → member    [Full Support]
  project → board     [Full Support]
  tag     → label     [Full Support]
  status  → list      [Partial - position-based]

Operation Mapping:
  create     → createCard      [Full Support]
  read       → getCard         [Full Support]
  update     → updateCard      [Full Support]
  list       → getCardsOnBoard [Full Support]
  assign     → addMemberToCard [Full Support]
  transition → moveCardToList  [Full Support]

Attribute Mapping:
  title       → name        [Full Support]
  description → desc        [Full Support]
  priority    → (label)     [Workaround - use colored labels]
  status      → idList      [Partial - list position]
  assignee    → idMembers   [Full Support]
  tags        → idLabels    [Full Support]

Overall Compatibility: 92% (11 of 12 capabilities supported)

Gaps & Workarounds:
  - priority: No native priority field; use colored labels (red=high, yellow=medium, green=low)
  - status: Status is determined by list position; create lists for each status

Recommendation: Proceed - excellent fit with minor workarounds
```

---

## Vendor Capability Registry

This registry provides **entity and operation mapping aliases** for compatibility analysis between domain requirements and vendor capabilities.

### Entity Mapping Aliases

When matching extracted entities to vendor capabilities, use these aliases:

```yaml
entity_aliases:
  ticket:     [issue, card, task, item]
  user:       [member, person, assignee, agent]
  project:    [board, space, repository, workspace]
  sprint:     [cycle, iteration]
  tag:        [label]
  status:     [state, column]
  priority:   [urgency]
  comment:    [update, story, note]
  customer:   [contact, client, requester]
```

### Operation Mapping Aliases

```yaml
operation_aliases:
  create:     [add, new, insert]
  read:       [get, fetch, retrieve, view]
  update:     [edit, modify, change, set]
  delete:     [remove, archive, trash]
  list:       [search, query, find, filter]
  assign:     [allocate, delegate]
  transition: [move, change_status, update_state]
  link:       [connect, relate, attach]
  comment:    [discuss, note, update]
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

## Domain Template

This skill uses a template file to generate the CLAUDE.md section for {domain_name}.

**Template Location**: `plugins/crunch/skills/setup-project/templates/{domain_key}.template.md`

### Template Usage

When updating CLAUDE.md in Phase 5:

1. Read the template from `plugins/crunch/skills/setup-project/templates/{domain_key}.template.md`
2. Replace all `{placeholder}` variables with values collected during setup
3. If CLAUDE.md exists, find and replace the existing `## {Domain Section}` or append
4. If CLAUDE.md doesn't exist, create it and add the filled template

### Creating Domain Templates

If no template exists for this domain, create one at the template location following this pattern:

1. Start with `## {Domain Section Header}`
2. Include configuration table with `{placeholder}` variables
3. Add operations/commands section
4. Add usage examples section
5. Add any domain-specific notes

## Domain Model (if generated from scenarios)

This section is included when the skill was generated from usage scenarios.

### Entities

| Entity | Description | Vendor Mapping |
|--------|-------------|----------------|
| {entity_name} | {description} | {vendor} → {vendor_entity} |

### Operations

| Operation | Applies To | API Mapping |
|-----------|------------|-------------|
| {operation} | {entities} | {vendor_api_method} |

### Attributes

| Attribute | Entity | Type | Vendor Field |
|-----------|--------|------|--------------|
| {attr_name} | {entity} | {type} | {vendor_field} |

### Source Scenarios

The domain model was extracted from these user scenarios:

1. "{scenario_1_text}"
2. "{scenario_2_text}"

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
- [x] Phase 1: Vendor Selection
- [x] Phase 1.5: Scenario Collection (custom only)
- [x] Phase 1.6: Model Extraction (custom only)
- [ ] Phase 2: Integration Selection <- CURRENT
- [ ] Phase 2.5: Vendor Suggestion (custom only)
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

## Collected Scenarios (Custom Domain)

### Scenario 1
"{scenario text as provided by user}"

### Scenario 2
"{scenario text as provided by user}"

## Extracted Domain Model (Custom Domain)

### Entities
| Entity | Description    | Source Scenario |
|--------|----------------|-----------------|
| ticket | Support ticket | 1               |
| agent  | Support agent  | 1               |

### Operations
| Operation | Applies To | Source Scenario |
|-----------|------------|-----------------|
| create    | ticket     | 1               |
| assign    | ticket     | 1               |

### Attributes
| Attribute | Entity | Type | Source Scenario |
|-----------|--------|------|-----------------|
| priority  | ticket | enum | 1               |
| assignee  | ticket | ref  | 1               |

## Vendor Analysis (Custom Domain with Scenarios)

### Suggested Vendors
| Vendor | Match % | Gaps                         |
|--------|---------|------------------------------|
| Jira   | 95%     | customer (use custom field)  |
| Linear | 82%     | customer (no native support) |

### Selected Vendor
- **Vendor**: {selected from suggestions or manual}
- **Selection Method**: {suggested / manual}

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

1. Create progress file at Phase 1 start (after vendor selected)
2. Update after each phase completion
3. Store non-sensitive data only (never credentials/tokens)
4. Delete only after successful DOD verification
5. Check for existing progress on session start
6. For custom domains: store scenarios as collected (verbatim)
7. For custom domains: store extracted model after Phase 1.6
8. For custom domains: store vendor analysis after Phase 2.5
9. Log all management operations in Management History
10. Update Connection Tests after each test (keep last 10)
11. Update Last Known State after each connection test
12. Track credential metadata (not values) for troubleshooting

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

Update CLAUDE.md with "{Domain Name}" section using the domain template.

#### Step 1: Check if CLAUDE.md Exists

- If not, create it with basic structure
- If exists, prepare to add/update "{Domain Name}" section

#### Step 2: Read Domain Template

\`\`\`bash
cat plugins/crunch/skills/setup-project/templates/{domain_key}.template.md
\`\`\`

#### Step 3: Fill Template Placeholders

Replace all `{placeholder}` variables with values collected during setup:

- `{secrets_backend}` → actual backend name (e.g., "SOPS + age")
- `{integration_type}` → integration method (e.g., "File-based")
- `{config_file}` → actual config path (e.g., ".sops.yaml")
- etc.

#### Step 4: Update CLAUDE.md

**If section exists:** Replace the existing `## {Domain Section}` with filled template

**If section doesn't exist:** Append the filled template to CLAUDE.md

{claude_md_template}

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

### Domain Model Section Generation (Custom Domains with Scenarios)

When generating a skill from scenarios, include the Domain Model section with:

**Entity Table:**
```markdown
| Entity | Description    | Vendor Mapping |
|--------|----------------|----------------|
| ticket | Support ticket | Jira → Issue   |
| agent  | Support agent  | Jira → User    |
```

- List all extracted entities
- Map each entity to the selected vendor's equivalent
- If no direct mapping, note workaround (e.g., "use custom field")

**Operation Table:**
```markdown
| Operation | Applies To | API Mapping |
|-----------|------------|-------------|
| create    | ticket     | createIssue |
| assign    | ticket     | assignIssue |
```

- List all extracted operations
- Map to vendor API methods
- Include any operation-specific notes

**Attribute Table:**
```markdown
| Attribute | Entity | Type | Vendor Field |
|-----------|--------|------|--------------|
| priority  | ticket | enum | priority     |
| assignee  | ticket | ref  | assignee     |
```

- List all extracted attributes
- Include type (enum, ref, text, date, etc.)
- Map to vendor field names

**Source Scenarios:**
- Include verbatim text of user scenarios (quoted)
- Number them for reference
- These provide context for future modifications

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
- [ ] (Custom only) "Domain definition complete. Confirm details?"
- [ ] (Custom only) "Vendor matrix complete. Confirm vendors?"
- [ ] "Ready to generate skill at plugins/crunch/skills/setup-{domain_key}/?"
- [ ] "Skill generated. Review the output?"
