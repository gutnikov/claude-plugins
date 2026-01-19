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

## Reference Documents

Before proceeding, understand these patterns:

1. **Gold Standard**: `plugins/crunch/skills/setup-task-manager/SKILL.md`
2. **Meta-skill Pattern**: `plugins/crunch/skills/create-tool-skills/SKILL.md`

## Domain Abstraction Model

### What Defines a "Project Domain"

| Component | Description | Example (Task Mgmt) |
|-----------|-------------|---------------------|
| **Domain Name** | Human-readable name | "Task Management" |
| **Domain Key** | Lowercase identifier | `task-manager` |
| **Purpose** | What the domain accomplishes | "Track and manage work items" |
| **Domain Explanation** | Educational content for users | "Why this domain matters..." |
| **Required Features** | Features vendors MUST have | Tasks, Tags, Statuses, Dependencies |
| **CLAUDE.md Section** | Section header | `## Task Management` |
| **MCP Key Pattern** | Keys in .mcp.json | `jira`, `asana`, `linear` |

### Integration Methods

Each vendor has an `integration_method` that determines setup workflow:

| Method | Config Location | Setup Approach | Test Method |
|--------|-----------------|----------------|-------------|
| `mcp-official` | `.mcp.json` | OAuth flow via mcp-remote | MCP tool call |
| `mcp-community` | `.mcp.json` | npm package + env vars | MCP tool call |
| `file-based` | Config files (e.g., `.sops.yaml`) | File creation + env vars | CLI command |
| `cli` | Env vars / config files | Install CLI + configure | CLI command |
| `api` | Env vars | Collect API credentials | API call |

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

These domains have pre-researched vendor matrices ready for immediate use:

| Domain | Key | Purpose | Required Features | Vendors |
|--------|-----|---------|-------------------|---------|
| **Task Management** | `task-manager` | Track and manage work items | Tasks, Tags, Statuses, Dependencies | Jira, Asana, Linear, Monday, ClickUp |
| **Secret Management** | `secret-manager` | Store and retrieve secrets | Get, Set, List, Delete | Vault, SOPS+age, AWS Secrets Manager, 1Password |
| **Communication** | `communication` | Team messaging and notifications | Messages, Channels, Threads | Slack, Discord, MS Teams |
| **CI/CD** | `ci-cd` | Continuous integration/deployment | Pipelines, Triggers, Logs, Artifacts | GitHub Actions, GitLab CI, CircleCI |
| **Memory/Knowledge** | `memory` | Persistent memory and context | Store, Retrieve, Search | Memory MCP, Pinecone, Chroma |
| **Monitoring** | `monitoring` | Observability and alerting | Metrics, Logs, Alerts | Datadog, Grafana, PagerDuty |
| **Localization** | `localization` | Internationalization and translation | Extract, Translate, Sync, Manage keys | Lokalise, Crowdin, Phrase, i18next |
| **Custom** | (user-defined) | (user-defined) | (user-defined) | (user-defined) |

---

## Workflow

### Phase 1: Domain Selection

Present domain options to the user:

```
Which project domain would you like to create a setup skill for?

  1. Task Management     - Track and manage work items
                          Features: Tasks, Tags, Statuses, Dependencies
                          Vendors: Jira, Asana, Linear, Monday.com, ClickUp

  2. Secret Management   - Securely store and retrieve secrets
                          Features: Get, Set, List, Delete, Versioning
                          Vendors: Vault, SOPS+age, AWS Secrets Manager, 1Password

  3. Communication       - Team messaging and notifications
                          Features: Messages, Channels, Threads, Reactions
                          Vendors: Slack, Discord, MS Teams

  4. CI/CD               - Continuous integration and deployment
                          Features: Pipelines, Triggers, Logs, Artifacts
                          Vendors: GitHub Actions, GitLab CI, CircleCI

  5. Memory/Knowledge    - Persistent memory and context
                          Features: Store, Retrieve, Search
                          Vendors: Memory MCP, Pinecone, Chroma

  6. Monitoring          - Observability and alerting
                          Features: Metrics, Logs, Alerts
                          Vendors: Datadog, Grafana, PagerDuty

  7. Localization        - Internationalization and translation
                          Features: Extract, Translate, Sync, Manage keys
                          Vendors: Lokalise, Crowdin, Phrase, i18next

  8. Custom Domain       - Define your own domain
                          (Will ask for features and vendors)

Select domain (1-8):
```

**If pre-defined domain selected:** Skip to Phase 3 (use pre-defined configuration)

**If custom domain selected:** Continue to Phase 1.5 (Scenario Collection)

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
| Entity   | Description      | Attributes                    |
|----------|------------------|-------------------------------|
| ticket   | Support ticket   | priority, status, assignee    |
| agent    | Support agent    | name, email, team             |
| customer | Customer record  | name, email                   |

OPERATIONS ({count})
| Operation  | Applies To      | Description                   |
|------------|-----------------|-------------------------------|
| create     | ticket, agent   | Create new items              |
| assign     | ticket          | Assign to owner               |
| transition | ticket          | Change status                 |

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

| Field | Source |
|-------|--------|
| `domain_name` | Inferred from primary entity (e.g., "ticket" → "Ticket Management") |
| `purpose` | Generated from entities and operations |
| `required_features` | Directly from extracted operations |

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

| Category | Weight | Scoring |
|----------|--------|---------|
| **Entity Support** | 40% | % of extracted entities that vendor can model |
| **Operation Support** | 40% | % of extracted operations that vendor API supports |
| **Attribute Support** | 20% | % of extracted attributes vendor can store |

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

| Placeholder | Value |
|-------------|-------|
| `{domain_name}` | Domain name (e.g., "Secret Management") |
| `{domain_key}` | Domain key (e.g., "secret-manager") |
| `{purpose}` | Domain purpose |
| `{feature_list}` | Comma-separated features |
| `{feature_summary}` | Brief feature summary for description |
| `{vendor_list}` | Comma-separated vendor names |
| `{qualified_vendors_table}` | Markdown table of qualified vendors |
| `{excluded_vendors_table}` | Markdown table of excluded vendors |
| `{mcp_options_table}` | Markdown table of MCP options |
| `{progress_file_format}` | Progress file template |
| `{phase_N_content}` | Content for each workflow phase |
| `{vendor_credentials_guide}` | Vendor-specific credential instructions |
| `{error_table}` | Error handling table |
| `{checkpoints}` | Interactive checkpoints |
| `{related_skills}` | Related skill links |

#### Step 3: Write File

Write generated content to:
```
plugins/crunch/skills/setup-{domain_key}/SKILL.md
```

**DOD:** SKILL.md file created

---

### Phase 5: Verification

Display result and verification options:

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

Would you like to:
1. Review the generated skill
2. Generate another domain skill
3. Done
```

**If user selects "Review":** Read and display the generated SKILL.md

**DOD:** User confirms skill is correct or exits

---

## Pre-Defined Domain Configurations

### Task Management

```yaml
domain_name: "Task Management"
domain_key: "task-manager"
purpose: "Track and manage work items, bugs, features, and team tasks"
explanation: |
  ## Why Task Management Integration?

  Task management tools (Jira, Trello, Linear) track what needs to be done.
  With this integration, Claude can create tasks, update status, and help
  you stay organized without switching between tools.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Working Without Integration                            │
  │                                                         │
  │  "Claude, I found a bug in the login flow"              │
  │                                                         │
  │  Then you have to:                                      │
  │  1. Open Jira/Trello in browser                         │
  │  2. Create new ticket manually                          │
  │  3. Copy details from conversation                      │
  │  4. Assign, set priority, add labels...                 │
  │  5. Come back to coding                                 │
  │                                                         │
  │  Easy to forget, inconsistent tracking                  │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  ┌─────────────────────────────────────────────────────────┐
  │  "Claude, create a high-priority bug ticket for the     │
  │   login issue we just discussed"                        │
  │                                                         │
  │  Claude: "Created PROJ-123: Login flow bug              │
  │           Priority: High, Assigned to: You"             │
  └─────────────────────────────────────────────────────────┘

  ### When You Need This

  - You want Claude to create/update tasks during work
  - You need to check task status without context-switching
  - You want Claude to understand project priorities
  - You need automated task creation from code reviews
required_features:
  - Create tasks
  - Update tasks
  - List/search tasks
  - Manage labels/tags
  - Set status/priority
claude_section: "## Task Management"

vendors:
  - name: "Jira"
    key: "jira"
    integration_method: "mcp-community"
    features: [Create, Update, List, Search, Labels, Status, Priority, Comments, Attachments]
    official_mcp: null
    community_mcp: "@modelcontextprotocol/server-atlassian"
    auth: ["API Token", "OAuth"]
    test_op: "search_issues"
    notes: "Enterprise-grade, complex workflows, JQL search"
    credential_update:
      api_token:
        env_vars: ["ATLASSIAN_API_TOKEN", "ATLASSIAN_EMAIL", "ATLASSIAN_DOMAIN"]
        regenerate_url: "https://id.atlassian.com/manage-profile/security/api-tokens"
        instructions: "Generate new API token in Atlassian Account Settings"

  - name: "Linear"
    key: "linear"
    integration_method: "mcp-community"
    features: [Create, Update, List, Search, Labels, Status, Priority, Comments]
    official_mcp: null
    community_mcp: "linear-mcp"
    auth: ["API Key"]
    test_op: "list_issues"
    notes: "Modern, fast, developer-focused"
    credential_update:
      api_token:
        env_vars: ["LINEAR_API_KEY"]
        regenerate_url: "https://linear.app/settings/api"
        instructions: "Generate new API key in Linear Settings > API"

  - name: "Trello"
    key: "trello"
    integration_method: "mcp-community"
    features: [Create, Update, List, Labels, Move, Comments, Checklists]
    official_mcp: null
    community_mcp: "trello-mcp"
    auth: ["API Key", "Token"]
    test_op: "list_boards"
    notes: "Simple, visual, quick setup"
    credential_update:
      api_token:
        env_vars: ["TRELLO_API_KEY", "TRELLO_TOKEN"]
        regenerate_url: "https://trello.com/app-key"
        instructions: "Get API key and generate token at Trello Developer page"

  - name: "Asana"
    key: "asana"
    integration_method: "mcp-community"
    features: [Create, Update, List, Search, Tags, Status, Subtasks, Comments]
    official_mcp: null
    community_mcp: "asana-mcp"
    auth: ["API Token", "OAuth"]
    test_op: "list_projects"
    notes: "Clean interface, good for project management"
    credential_update:
      api_token:
        env_vars: ["ASANA_ACCESS_TOKEN"]
        regenerate_url: "https://app.asana.com/0/developer-console"
        instructions: "Generate new Personal Access Token in Asana Developer Console"

  - name: "ClickUp"
    key: "clickup"
    integration_method: "mcp-community"
    features: [Create, Update, List, Search, Tags, Status, Priority, Time Tracking]
    official_mcp: null
    community_mcp: "clickup-mcp"
    auth: ["API Token"]
    test_op: "list_spaces"
    notes: "Feature-rich, generous free tier"
    credential_update:
      api_token:
        env_vars: ["CLICKUP_API_TOKEN"]
        regenerate_url: "https://app.clickup.com/settings/apps"
        instructions: "Generate new API token in ClickUp Settings > Apps"

excluded:
  - name: "Todoist"
    reason: "Personal task manager, limited team features"
  - name: "Apple Reminders"
    reason: "No API access, personal only"
```

### Secret Management

```yaml
domain_name: "Secret Management"
domain_key: "secret-manager"
purpose: "Securely store, retrieve, and manage secrets and credentials"
explanation: |
  ## Why Secret Management?

  Many parts of your app need sensitive values - database passwords, API keys,
  encryption secrets. If these get committed to your repo in plain text, anyone
  with access to your code can steal them.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Your Code Repository                                   │
  │                                                         │
  │  config.js                                              │
  │  ┌─────────────────────────────────────┐                │
  │  │ DB_PASSWORD = "super_secret_123"    │ ← EXPOSED!     │
  │  │ API_KEY = "sk-abc123..."            │ ← EXPOSED!     │
  │  └─────────────────────────────────────┘                │
  │                                                         │
  │  Anyone who can see your repo can steal these values    │
  │  (hackers, leaked backups, accidental public repos)     │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  A secrets manager keeps sensitive values separate from your code:

  ┌──────────────┐      ┌──────────────────┐
  │  Your Code   │      │ Secrets Manager  │
  │              │      │                  │
  │  DB_PASSWORD │─────▶│ ************     │ Encrypted &
  │  = get(...)  │      │ (stored safely)  │ access-controlled
  └──────────────┘      └──────────────────┘

  Your code only contains references, not actual secrets.

  ### When You Need This

  - Your project has database credentials, API keys, or tokens
  - Multiple team members need access to the same secrets
  - You want to rotate credentials without changing code
  - You need audit logs of who accessed what secrets
  - Your deployment pipeline needs secure credential injection
required_features:
  - Get secrets
  - Set secrets
  - List secrets
  - Delete secrets
claude_section: "## Secrets Management"

vendors:
  - name: "HashiCorp Vault"
    key: "vault"
    integration_method: "mcp-community"
    alternative_method: "cli"          # Fallback to CLI if MCP not preferred
    features: [Get, Set, List, Delete, Versioning, Audit]
    official_mcp: null
    community_mcp: "vault-mcp"
    cli_tools:
      - name: "vault"
        install: "brew install vault"
        check: "vault --version"
    env_vars:
      - name: "VAULT_ADDR"
        description: "Vault server address"
      - name: "VAULT_TOKEN"
        description: "Vault authentication token"
    auth: ["Token", "AppRole", "OIDC"]
    test_op: "vault kv list secret/"
    notes: "Enterprise-grade, self-hosted or HCP"
    credential_update:
      api_token:
        env_vars: ["VAULT_TOKEN", "VAULT_ADDR"]
        regenerate_url: "Vault UI or CLI: vault token create"
        instructions: "Generate new token via Vault CLI or UI, update VAULT_TOKEN"

  - name: "SOPS + age"
    key: "sops-age"
    integration_method: "file-based"    # NOT MCP - uses config files and CLI
    features: [Get, Set, List, Delete]
    official_mcp: null
    community_mcp: null                 # CORRECTED - no such MCP exists
    config_files:
      - path: ".sops.yaml"
        description: "SOPS encryption configuration"
        template: |
          creation_rules:
            - path_regex: .*\.enc\.(yaml|json)$
              age: '{public_key}'
      - path: "~/.config/sops/age/keys.txt"
        description: "age private key file"
    cli_tools:
      - name: "sops"
        install: "brew install sops"
        check: "sops --version"
      - name: "age"
        install: "brew install age"
        check: "age --version"
    env_vars:
      - name: "SOPS_AGE_KEY_FILE"
        description: "Path to age private key file"
        default: "~/.config/sops/age/keys.txt"
    setup_steps:
      - "Generate age keys: age-keygen -o ~/.config/sops/age/keys.txt"
      - "Copy public key from output (starts with 'age1...')"
      - "Create .sops.yaml with public key"
      - "Set SOPS_AGE_KEY_FILE environment variable"
      - "Test: sops -e test.yaml > test.enc.yaml && sops -d test.enc.yaml"
    auth: ["age keys"]
    test_op: "sops -d test.enc.yaml"
    notes: "File-based, git-friendly, no external services"
    credential_update:
      file_based:
        config_files: [".sops.yaml", "~/.config/sops/age/keys.txt"]
        regenerate_instructions: "Regenerate keys with age-keygen and update .sops.yaml"
        instructions: "Update SOPS_AGE_KEY_FILE path or regenerate keys with age-keygen"

  - name: "AWS Secrets Manager"
    key: "aws-secrets"
    integration_method: "mcp-community"
    features: [Get, Set, List, Delete, Versioning, Rotation]
    official_mcp: null
    community_mcp: "aws-mcp"
    env_vars:
      - name: "AWS_ACCESS_KEY_ID"
        description: "AWS access key ID"
      - name: "AWS_SECRET_ACCESS_KEY"
        description: "AWS secret access key"
      - name: "AWS_REGION"
        description: "AWS region"
    auth: ["IAM", "Access Keys"]
    test_op: "aws secretsmanager list-secrets"
    notes: "AWS native, automatic rotation"
    credential_update:
      api_token:
        env_vars: ["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_REGION"]
        regenerate_url: "https://console.aws.amazon.com/iam/home#/security_credentials"
        instructions: "Generate new access keys in AWS IAM console"

  - name: "1Password"
    key: "1password"
    integration_method: "mcp-official"
    features: [Get, Set, List, Delete]
    official_mcp: "https://mcp.1password.com/sse"
    community_mcp: null
    auth: ["OAuth", "Service Account"]
    test_op: "list vaults"
    notes: "Team password manager"
    credential_update:
      oauth:
        method: "force_reauth"
        instructions: "Remove cached OAuth token and restart Claude Code to re-authenticate"
      service_account:
        env_vars: ["OP_SERVICE_ACCOUNT_TOKEN"]
        regenerate_url: "https://my.1password.com/integrations/directory"
        instructions: "Create new service account token in 1Password admin console"

excluded:
  - name: ".env files"
    reason: "No versioning, no access control, plaintext"
  - name: "Git-crypt"
    reason: "Limited operations, complex key management"
```

### Communication

```yaml
domain_name: "Communication"
domain_key: "communication"
purpose: "Team messaging, notifications, and collaboration"
explanation: |
  ## Why Communication Integration?

  Claude can send messages, post updates, and notify your team automatically.
  Instead of manually copying information between tools, Claude becomes part of
  your team's communication flow.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Manual Notification Flow                               │
  │                                                         │
  │  Claude: "Build completed successfully"                 │
  │     │                                                   │
  │     └──▶ You copy this message                          │
  │             │                                           │
  │             └──▶ Paste into Slack                       │
  │                     │                                   │
  │                     └──▶ Team finally sees it           │
  │                                                         │
  │  Tedious, easy to forget, delays information flow       │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
  │   Claude    │─────▶│    Slack    │─────▶│    Team     │
  │             │      │             │      │             │
  │ "Notify the │      │ #deploys:   │      │ Gets update │
  │  team..."   │      │ Build done! │      │ instantly   │
  └─────────────┘      └─────────────┘      └─────────────┘

  Claude posts directly - no manual steps needed.

  ### When You Need This

  - You want Claude to post deployment notifications
  - You need automated alerts when tasks complete
  - You want to discuss code changes in team channels
  - You need Claude to read channel history for context
required_features:
  - Send messages
  - List channels
  - Thread replies
claude_section: "## Communication"

vendors:
  - name: "Slack"
    key: "slack"
    features: [Messages, Channels, Threads, Reactions, Files]
    official_mcp: null
    community_mcp: "@modelcontextprotocol/server-slack"
    auth: ["Bot Token", "OAuth"]
    test_op: "list_channels"
    notes: "Most popular enterprise messaging"
    credential_update:
      api_token:
        env_vars: ["SLACK_BOT_TOKEN", "SLACK_TEAM_ID"]
        regenerate_url: "https://api.slack.com/apps"
        instructions: "Regenerate Bot User OAuth Token in Slack App settings"

  - name: "Discord"
    key: "discord"
    features: [Messages, Channels, Threads, Reactions]
    official_mcp: null
    community_mcp: "discord-mcp"
    auth: ["Bot Token"]
    test_op: "list_guilds"
    notes: "Gaming/community focused"
    credential_update:
      api_token:
        env_vars: ["DISCORD_BOT_TOKEN"]
        regenerate_url: "https://discord.com/developers/applications"
        instructions: "Regenerate Bot Token in Discord Developer Portal"

  - name: "Microsoft Teams"
    key: "teams"
    features: [Messages, Channels, Threads]
    official_mcp: null
    community_mcp: "teams-mcp"
    auth: ["OAuth", "App Registration"]
    test_op: "list_teams"
    notes: "Microsoft 365 integration"
    credential_update:
      oauth:
        method: "force_reauth"
        instructions: "Clear cached OAuth tokens and restart Claude Code to re-authenticate"
      api_token:
        env_vars: ["TEAMS_CLIENT_ID", "TEAMS_CLIENT_SECRET", "TEAMS_TENANT_ID"]
        regenerate_url: "https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps"
        instructions: "Regenerate client secret in Azure App Registration"

excluded:
  - name: "Email (SMTP)"
    reason: "No real-time messaging, no channels/threads"
```

### CI/CD

```yaml
domain_name: "CI/CD"
domain_key: "ci-cd"
purpose: "Continuous integration and deployment pipelines"
explanation: |
  ## Why CI/CD Integration?

  CI/CD (Continuous Integration/Continuous Deployment) automates building,
  testing, and deploying your code. With this integration, Claude can trigger
  builds, check pipeline status, and help debug failures.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Manual Pipeline Interaction                            │
  │                                                         │
  │  1. Switch to GitHub/GitLab UI                          │
  │  2. Navigate to Actions/Pipelines                       │
  │  3. Find the failing build                              │
  │  4. Click through to see logs                           │
  │  5. Copy error messages                                 │
  │  6. Come back to Claude to ask about them               │
  │                                                         │
  │  Context-switching slows you down                       │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  ┌─────────────────────────────────────────────────────────┐
  │  "Claude, why did the last build fail?"                 │
  │                                                         │
  │  Claude checks pipeline ──▶ Gets logs ──▶ Explains:     │
  │                                                         │
  │  "The build failed because test_auth.py has a          │
  │   missing import. Here's the fix..."                    │
  └─────────────────────────────────────────────────────────┘

  ### When You Need This

  - You want to check build status without leaving your editor
  - You need Claude to help debug failing pipelines
  - You want to trigger builds or deployments via conversation
  - You need to review build artifacts and logs
required_features:
  - List pipelines/workflows
  - Trigger builds
  - View logs
  - Get artifacts
claude_section: "## CI/CD"

vendors:
  - name: "GitHub Actions"
    key: "github-actions"
    features: [Workflows, Triggers, Logs, Artifacts, Secrets]
    official_mcp: null
    community_mcp: "@modelcontextprotocol/server-github"
    auth: ["PAT", "GitHub App"]
    test_op: "list_workflows"
    notes: "Integrated with GitHub repos"
    credential_update:
      api_token:
        env_vars: ["GITHUB_PERSONAL_ACCESS_TOKEN"]
        regenerate_url: "https://github.com/settings/tokens"
        instructions: "Generate new PAT with workflow scope at GitHub Settings > Developer settings"

  - name: "GitLab CI"
    key: "gitlab-ci"
    features: [Pipelines, Triggers, Logs, Artifacts]
    official_mcp: null
    community_mcp: "@modelcontextprotocol/server-gitlab"
    auth: ["PAT", "OAuth"]
    test_op: "list_pipelines"
    notes: "Full DevOps platform"
    credential_update:
      api_token:
        env_vars: ["GITLAB_PERSONAL_ACCESS_TOKEN", "GITLAB_API_URL"]
        regenerate_url: "https://gitlab.com/-/profile/personal_access_tokens"
        instructions: "Generate new token with api scope at GitLab User Settings > Access Tokens"

  - name: "CircleCI"
    key: "circleci"
    features: [Pipelines, Triggers, Logs, Artifacts]
    official_mcp: null
    community_mcp: "circleci-mcp"
    auth: ["API Token"]
    test_op: "list_pipelines"
    notes: "Cloud-native CI/CD"
    credential_update:
      api_token:
        env_vars: ["CIRCLECI_TOKEN"]
        regenerate_url: "https://app.circleci.com/settings/user/tokens"
        instructions: "Generate new Personal API Token in CircleCI User Settings"

  - name: "Jenkins"
    key: "jenkins"
    features: [Jobs, Triggers, Logs, Artifacts]
    official_mcp: null
    community_mcp: "jenkins-mcp"
    auth: ["API Token", "Username/Password"]
    test_op: "list_jobs"
    notes: "Self-hosted, highly extensible"
    credential_update:
      api_token:
        env_vars: ["JENKINS_URL", "JENKINS_USER", "JENKINS_API_TOKEN"]
        regenerate_url: "Jenkins instance > User > Configure > API Token"
        instructions: "Generate new API token in your Jenkins user profile"

excluded:
  - name: "Make/Makefile"
    reason: "Local only, no remote triggers or artifacts"
```

### Memory/Knowledge

```yaml
domain_name: "Memory & Knowledge"
domain_key: "memory"
purpose: "Persistent memory, context, and knowledge retrieval"
explanation: |
  ## Why Memory Integration?

  By default, Claude forgets everything when you start a new session. A memory
  integration lets Claude remember important facts about your project,
  preferences, and decisions across conversations.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Session 1:                                             │
  │  "We use PostgreSQL, deploy to AWS, prefer TypeScript"  │
  │                                                         │
  │  Session 2 (new day):                                   │
  │  "What database do we use?"                             │
  │  Claude: "I don't have that information..."             │
  │                                                         │
  │  You have to re-explain context every session           │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  ┌─────────────────────────────────────────────────────────┐
  │  Claude stores facts ──▶ Memory System ──▶ Recalls later│
  │                                                         │
  │  "Remember: We use PostgreSQL on AWS"                   │
  │           ↓                                             │
  │  [Stored in memory]                                     │
  │           ↓                                             │
  │  Next session: Claude already knows your stack          │
  └─────────────────────────────────────────────────────────┘

  ### When You Need This

  - You want Claude to remember project conventions
  - You need persistent context across sessions
  - You want Claude to recall past decisions and why
  - You have complex project knowledge to maintain
required_features:
  - Store entities/facts
  - Retrieve by query
  - Search/similarity
  - Update/delete
claude_section: "## Memory & Knowledge"

vendors:
  - name: "Memory MCP"
    key: "memory"
    features: [Store, Retrieve, Search, Relations]
    official_mcp: null
    community_mcp: "@modelcontextprotocol/server-memory"
    auth: []
    test_op: "list_entities"
    notes: "Built-in knowledge graph, file-based"
    credential_update:
      api_token:
        env_vars: []
        regenerate_url: "N/A (no credentials required)"
        instructions: "Memory MCP uses local file storage, no credentials needed"

  - name: "Pinecone"
    key: "pinecone"
    features: [Store, Retrieve, Similarity Search]
    official_mcp: null
    community_mcp: "pinecone-mcp"
    auth: ["API Key"]
    test_op: "list_indexes"
    notes: "Managed vector database for AI"
    credential_update:
      api_token:
        env_vars: ["PINECONE_API_KEY", "PINECONE_ENVIRONMENT"]
        regenerate_url: "https://app.pinecone.io/organizations/-/projects/-/keys"
        instructions: "Generate new API key in Pinecone Console > API Keys"

  - name: "Chroma"
    key: "chroma"
    features: [Store, Retrieve, Similarity Search]
    official_mcp: null
    community_mcp: "chroma-mcp"
    auth: ["None", "API Key"]
    test_op: "list_collections"
    notes: "Open-source embeddings DB"
    credential_update:
      api_token:
        env_vars: ["CHROMA_HOST", "CHROMA_API_KEY"]
        regenerate_url: "Chroma Cloud dashboard or self-hosted config"
        instructions: "Update API key from Chroma Cloud or self-hosted server config"

  - name: "Weaviate"
    key: "weaviate"
    features: [Store, Retrieve, Similarity Search, GraphQL]
    official_mcp: null
    community_mcp: "weaviate-mcp"
    auth: ["API Key", "OIDC"]
    test_op: "list_classes"
    notes: "Vector database with GraphQL"
    credential_update:
      api_token:
        env_vars: ["WEAVIATE_URL", "WEAVIATE_API_KEY"]
        regenerate_url: "https://console.weaviate.cloud/"
        instructions: "Generate new API key in Weaviate Cloud Console"
      oauth:
        method: "force_reauth"
        instructions: "Clear OIDC tokens and restart Claude Code to re-authenticate"

excluded:
  - name: "Plain text files"
    reason: "No search/similarity, no structured retrieval"
```

### Monitoring

```yaml
domain_name: "Monitoring"
domain_key: "monitoring"
purpose: "Observability, metrics, logs, and alerting"
explanation: |
  ## Why Monitoring Integration?

  Monitoring tools track your application's health - errors, performance,
  uptime. With this integration, Claude can check metrics, investigate
  alerts, and help diagnose production issues.

  ### The Solution

  Instead of switching to Datadog/Grafana dashboards, ask Claude directly:

  "Claude, are there any errors in production right now?"
  "What's the API latency over the last hour?"
  "Why did we get paged at 3am?"

  ### When You Need This

  - You want to check system health during development
  - You need Claude to help investigate incidents
  - You want alerts and metrics in your workflow
  - You need to correlate code changes with metrics
required_features:
  - Query metrics
  - Search logs
  - Manage alerts
claude_section: "## Monitoring"

vendors:
  - name: "Datadog"
    key: "datadog"
    features: [Metrics, Logs, Traces, Alerts, Dashboards]
    official_mcp: null
    community_mcp: "datadog-mcp"
    auth: ["API Key", "App Key"]
    test_op: "list_dashboards"
    notes: "Full-stack observability platform"
    credential_update:
      api_token:
        env_vars: ["DD_API_KEY", "DD_APP_KEY", "DD_SITE"]
        regenerate_url: "https://app.datadoghq.com/organization-settings/api-keys"
        instructions: "Generate new API/App keys in Datadog Organization Settings"

  - name: "Grafana"
    key: "grafana"
    features: [Metrics, Logs, Dashboards, Alerts]
    official_mcp: null
    community_mcp: "grafana-mcp"
    auth: ["API Key", "Service Account"]
    test_op: "list_dashboards"
    notes: "Open-source visualization"
    credential_update:
      api_token:
        env_vars: ["GRAFANA_URL", "GRAFANA_API_KEY"]
        regenerate_url: "Grafana instance > Configuration > API Keys"
        instructions: "Generate new API key or service account token in Grafana admin"

  - name: "PagerDuty"
    key: "pagerduty"
    features: [Alerts, Incidents, Escalations, On-call]
    official_mcp: null
    community_mcp: "pagerduty-mcp"
    auth: ["API Key"]
    test_op: "list_services"
    notes: "Incident management"
    credential_update:
      api_token:
        env_vars: ["PAGERDUTY_API_KEY"]
        regenerate_url: "https://support.pagerduty.com/docs/api-access-keys"
        instructions: "Generate new API key in PagerDuty User Settings > API Access"

  - name: "Prometheus"
    key: "prometheus"
    features: [Metrics, Alerts, Rules]
    official_mcp: null
    community_mcp: "prometheus-mcp"
    auth: ["None", "Basic Auth"]
    test_op: "query"
    notes: "Open-source metrics"
    credential_update:
      api_token:
        env_vars: ["PROMETHEUS_URL", "PROMETHEUS_USER", "PROMETHEUS_PASSWORD"]
        regenerate_url: "N/A (configured in Prometheus server)"
        instructions: "Update basic auth credentials in your Prometheus server configuration"

excluded:
  - name: "Simple logging (stdout)"
    reason: "No querying, no alerting"
```

### Localization

```yaml
domain_name: "Localization"
domain_key: "localization"
purpose: "Manage internationalization, translation, and localized content"
explanation: |
  ## Why Localization Integration?

  If your app supports multiple languages, you need a system to manage
  translation strings, keep them in sync, and coordinate with translators.
  This integration lets Claude help manage your i18n workflow.

  ### The Problem

  ┌─────────────────────────────────────────────────────────┐
  │  Manual Localization Workflow                           │
  │                                                         │
  │  1. Add new string in code: t('welcome_message')        │
  │  2. Add key to en.json manually                         │
  │  3. Remember to add to fr.json, de.json, es.json...     │
  │  4. Send files to translators via email                 │
  │  5. Merge translations back, handle conflicts           │
  │  6. Discover missing keys in production                 │
  │                                                         │
  │  Error-prone, hard to track, translation drift          │
  └─────────────────────────────────────────────────────────┘

  ### The Solution

  ┌─────────────────────────────────────────────────────────┐
  │  "Claude, add a new string 'welcome_message' with       │
  │   English text 'Welcome back!' and request translation" │
  │                                                         │
  │  Claude:                                                │
  │  - Added to en.json ✓                                   │
  │  - Created translation task in Lokalise ✓               │
  │  - Translators notified ✓                               │
  └─────────────────────────────────────────────────────────┘

  ### When You Need This

  - Your app supports multiple languages
  - You want to track missing translations
  - You need to sync translation files with a TMS
  - You want Claude to help extract hardcoded strings
  - You need to coordinate with translation teams
required_features:
  - List translation keys
  - Add/update keys
  - Sync with source files
  - Track translation status
  - Export translations
claude_section: "## Localization"

vendors:
  - name: "Lokalise"
    key: "lokalise"
    integration_method: "mcp-community"
    features: [Keys, Upload, Download, Tasks, Comments, Screenshots]
    official_mcp: null
    community_mcp: "lokalise-mcp"
    auth: ["API Token"]
    test_op: "list_projects"
    notes: "Developer-friendly, good CI/CD integration"
    credential_update:
      api_token:
        env_vars: ["LOKALISE_API_TOKEN", "LOKALISE_PROJECT_ID"]
        regenerate_url: "https://app.lokalise.com/profile#apitokens"
        instructions: "Generate new API token in Lokalise Profile Settings"

  - name: "Crowdin"
    key: "crowdin"
    integration_method: "mcp-community"
    features: [Keys, Upload, Download, Tasks, Glossary, TM]
    official_mcp: null
    community_mcp: "crowdin-mcp"
    auth: ["API Token"]
    test_op: "list_projects"
    notes: "Popular, strong community translation features"
    credential_update:
      api_token:
        env_vars: ["CROWDIN_API_TOKEN", "CROWDIN_PROJECT_ID"]
        regenerate_url: "https://crowdin.com/settings#api-key"
        instructions: "Generate new API token in Crowdin Account Settings"

  - name: "Phrase"
    key: "phrase"
    integration_method: "mcp-community"
    features: [Keys, Upload, Download, Jobs, Glossary, TM]
    official_mcp: null
    community_mcp: "phrase-mcp"
    auth: ["API Token"]
    test_op: "list_projects"
    notes: "Enterprise translation management"
    credential_update:
      api_token:
        env_vars: ["PHRASE_ACCESS_TOKEN", "PHRASE_PROJECT_ID"]
        regenerate_url: "https://app.phrase.com/settings/oauth_access_tokens"
        instructions: "Generate new Access Token in Phrase Settings"

  - name: "i18next"
    key: "i18next"
    integration_method: "file-based"
    features: [Keys, Namespaces, Plurals, Context]
    official_mcp: null
    community_mcp: null
    config_files:
      - path: "i18next.config.js"
        description: "i18next configuration"
      - path: "locales/"
        description: "Translation files directory"
    cli_tools:
      - name: "i18next-parser"
        install: "npm install -g i18next-parser"
        check: "i18next --version"
    setup_steps:
      - "Install i18next-parser: npm install -g i18next-parser"
      - "Create i18next-parser.config.js in project root"
      - "Run extraction: i18next 'src/**/*.{js,jsx,ts,tsx}'"
    auth: []
    test_op: "i18next 'src/**/*.{js,jsx}' --dry-run"
    notes: "File-based, works with any i18next setup"

excluded:
  - name: "Google Translate API alone"
    reason: "Translation only, no key management or sync"
  - name: "DeepL API alone"
    reason: "Translation only, no project management"
```

---

## Vendor Capability Registry

This registry defines known vendor capabilities for automated matching against extracted domain models. Used by Phase 2.5 to suggest vendors.

### Task/Issue Management Vendors

```yaml
jira:
  display_name: "Jira"
  entities:
    - issue          # Primary work item
    - user           # Team members
    - project        # Container for issues
    - sprint         # Time-boxed iteration
    - epic           # Large work item grouping
    - label          # Categorization tags
    - comment        # Discussion on issues
    - attachment     # Files on issues
    - component      # Project subdivision
    - version        # Release tracking
  operations:
    - create         # createIssue
    - read           # getIssue
    - update         # updateIssue
    - delete         # deleteIssue
    - list           # searchIssues (JQL)
    - assign         # assignIssue
    - transition     # transitionIssue (workflow)
    - link           # linkIssues
    - comment        # addComment
    - attach         # addAttachment
    - search         # JQL search
  attributes:
    - priority       # enum (Highest, High, Medium, Low, Lowest)
    - status         # enum (workflow states)
    - assignee       # reference to user
    - reporter       # reference to user
    - labels         # list of strings
    - sprint         # reference to sprint
    - epic           # reference to epic
    - due_date       # date
    - estimate       # number (story points or time)
    - custom_fields  # extensible
  strengths:
    - Complex workflows with customizable states
    - JQL search language
    - Extensive custom fields
    - Issue linking and dependencies
    - Sprint planning and agile boards
  limitations:
    - Complex setup
    - Can be slow for large instances
  mcp:
    official: null
    community: "@modelcontextprotocol/server-atlassian"
    auth: ["API Token", "OAuth"]

linear:
  display_name: "Linear"
  entities:
    - issue          # Primary work item
    - user           # Team members
    - team           # Organizational unit
    - project        # Grouping of issues
    - cycle          # Time-boxed iteration (like sprint)
    - label          # Categorization tags
    - comment        # Discussion on issues
  operations:
    - create         # createIssue
    - read           # issue query
    - update         # updateIssue
    - delete         # deleteIssue (archive)
    - list           # issues query
    - assign         # update assignee
    - transition     # update state
    - comment        # createComment
    - search         # GraphQL search
  attributes:
    - priority       # enum (Urgent, High, Medium, Low, No Priority)
    - status         # enum (workflow states)
    - assignee       # reference to user
    - labels         # list of labels
    - cycle          # reference to cycle
    - estimate       # number (points)
    - due_date       # date
  strengths:
    - Modern, fast interface
    - Developer-focused
    - Keyboard-driven
    - GraphQL API
    - Built-in Git integration
  limitations:
    - Less customizable than Jira
    - Fewer integration options
    - No native customer tracking
  mcp:
    official: null
    community: "linear-mcp"
    auth: ["API Key"]

trello:
  display_name: "Trello"
  entities:
    - card           # Primary work item (maps to ticket/issue)
    - member         # Team members (maps to user/agent)
    - board          # Container for lists
    - list           # Column/status container
    - label          # Color-coded tags
    - checklist      # Sub-tasks
    - comment        # Discussion on cards
    - attachment     # Files on cards
  operations:
    - create         # createCard
    - read           # getCard
    - update         # updateCard
    - delete         # deleteCard (archive)
    - list           # getCardsOnBoard
    - move           # moveCard (between lists)
    - assign         # addMemberToCard
    - label          # addLabelToCard
    - comment        # addComment
    - attach         # addAttachment
  attributes:
    - name           # card title
    - description    # card description
    - due_date       # date
    - labels         # list of color labels
    - members        # list of assigned members
    - position       # order in list
    - checklist      # sub-items
  strengths:
    - Simple and visual
    - Quick setup
    - Drag-and-drop interface
    - Free tier available
  limitations:
    - No native dependencies
    - Limited custom fields (Power-Ups required)
    - No priority field (use labels)
    - Status = list position only
  mcp:
    official: null
    community: "trello-mcp"
    auth: ["API Key", "Token"]

asana:
  display_name: "Asana"
  entities:
    - task           # Primary work item
    - user           # Team members
    - project        # Container for tasks
    - section        # Grouping within project
    - tag            # Categorization
    - subtask        # Child tasks
    - comment        # Discussion (stories)
    - attachment     # Files on tasks
  operations:
    - create         # createTask
    - read           # getTask
    - update         # updateTask
    - delete         # deleteTask
    - list           # getTasks
    - assign         # update assignee
    - move           # addToSection
    - comment        # createStory
    - attach         # createAttachment
    - subtask        # createSubtask
  attributes:
    - name           # task title
    - notes          # description
    - assignee       # reference to user
    - due_date       # date
    - due_at         # datetime
    - tags           # list of tags
    - completed      # boolean
    - custom_fields  # extensible
  strengths:
    - Clean interface
    - Timeline view
    - Portfolios for project grouping
    - Custom fields available
  limitations:
    - Less dev-focused than Linear
    - Workflow automation costs extra
  mcp:
    official: null
    community: "asana-mcp"
    auth: ["API Token", "OAuth"]

github_issues:
  display_name: "GitHub Issues"
  entities:
    - issue          # Primary work item
    - user           # GitHub users
    - repository     # Container for issues
    - label          # Categorization tags
    - milestone      # Release/version grouping
    - comment        # Discussion on issues
    - project        # Project board
  operations:
    - create         # createIssue
    - read           # getIssue
    - update         # updateIssue
    - close          # closeIssue
    - list           # listIssues
    - assign         # addAssignees
    - label          # addLabels
    - comment        # createComment
    - search         # GitHub search syntax
  attributes:
    - title          # issue title
    - body           # description (markdown)
    - assignees      # list of users
    - labels         # list of labels
    - milestone      # reference to milestone
    - state          # open/closed
  strengths:
    - Integrated with code
    - Free for public repos
    - Markdown support
    - PR linking
  limitations:
    - Basic workflow (open/closed only)
    - No native priority field
    - Limited project management features
  mcp:
    official: null
    community: "@modelcontextprotocol/server-github"
    auth: ["PAT", "GitHub App"]

monday:
  display_name: "Monday.com"
  entities:
    - item           # Primary work item
    - user           # Team members
    - board          # Container for items
    - group          # Section within board
    - column         # Custom field definition
    - update         # Comments/activity
  operations:
    - create         # createItem
    - read           # getItem
    - update         # changeColumnValue
    - delete         # deleteItem (archive)
    - list           # getItems
    - move           # moveItemToGroup
    - comment        # createUpdate
  attributes:
    - name           # item name
    - status         # status column
    - person         # assignee column
    - date           # date column
    - priority       # priority column
    - custom_columns # fully extensible
  strengths:
    - Highly customizable columns
    - Visual automations
    - Multiple views (timeline, calendar, etc.)
  limitations:
    - Can become complex
    - Pricing by seat
  mcp:
    official: null
    community: "monday-mcp"
    auth: ["API Token"]

clickup:
  display_name: "ClickUp"
  entities:
    - task           # Primary work item
    - user           # Team members
    - space          # Top-level container
    - folder         # Grouping within space
    - list           # Container for tasks
    - tag            # Categorization
    - comment        # Discussion
  operations:
    - create         # createTask
    - read           # getTask
    - update         # updateTask
    - delete         # deleteTask
    - list           # getTasks
    - assign         # update assignees
    - move           # moveTask
    - comment        # createComment
  attributes:
    - name           # task name
    - description    # task description
    - assignees      # list of users
    - status         # enum
    - priority       # enum (Urgent, High, Normal, Low)
    - due_date       # date
    - tags           # list of tags
    - custom_fields  # extensible
  strengths:
    - Feature-rich
    - Multiple views
    - Time tracking built-in
    - Generous free tier
  limitations:
    - Can be overwhelming
    - Performance with large datasets
  mcp:
    official: null
    community: "clickup-mcp"
    auth: ["API Token"]
```

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
description: Interactive setup wizard for {domain_name} integration. Guides through vendor selection ({vendor_list}), MCP choice, and configuration with CLAUDE.md documentation. {feature_summary}.
---

# Setup {Domain Name}

This skill guides users through the complete end-to-end process of setting up {domain_name} integration with vendors that support {feature_list}.

## Definition of Done

The setup is complete when:

1. {Domain name} vendor is selected
2. Integration is configured (MCP, CLI, or file-based depending on vendor)
3. User successfully executes a test operation
4. CLAUDE.md is updated with "{Domain Name}" section documenting capabilities and integration method

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

| Timestamp | Operation | Details | Result |
|-----------|-----------|---------|--------|
| {datetime} | Test Connection | {vendor} | {Success / Failed: error} |
| {datetime} | Update Credentials | {env_vars updated} | {Success / Failed} |
| {datetime} | Change Vendor | {old_vendor} → {new_vendor} | {Success / Failed} |
| {datetime} | Diagnostics | {issues_found} | {recommendations} |
| {datetime} | Reset | {vendor removed} | Success |

## Connection Tests

| Timestamp | Vendor | Test Operation | Result | Error |
|-----------|--------|----------------|--------|-------|
| {datetime} | {vendor} | {test_op} | ✓ Pass | - |
| {datetime} | {vendor} | {test_op} | ✗ Fail | {error_message} |

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
| Entity   | Description      | Source Scenario |
|----------|------------------|-----------------|
| ticket   | Support ticket   | 1               |
| agent    | Support agent    | 1               |

### Operations
| Operation  | Applies To | Source Scenario |
|------------|------------|-----------------|
| create     | ticket     | 1               |
| assign     | ticket     | 1               |

### Attributes
| Attribute | Entity | Type   | Source Scenario |
|-----------|--------|--------|-----------------|
| priority  | ticket | enum   | 1               |
| assignee  | ticket | ref    | 1               |

## Vendor Analysis (Custom Domain with Scenarios)

### Suggested Vendors
| Vendor | Match % | Gaps |
|--------|---------|------|
| Jira   | 95%     | customer (use custom field) |
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

When {domain_name} is already configured, display comprehensive management options:

\`\`\`
{Domain Name} Management
========================

Current Configuration:
  Vendor: {detected vendor}
  Integration: {MCP (Official) | MCP (Community) | CLI | File-based}
  Config: {.mcp.json | env vars | config files}
  Status: {Connected | Disconnected | Error}
  Last tested: {timestamp from progress file or "never"}

What would you like to do?

  SETUP
  1. Add another vendor      - Configure additional vendor alongside current

  MANAGE
  2. Change vendor           - Migrate to a different vendor
  3. Update credentials      - Refresh API tokens or re-authenticate
  4. Test connection         - Verify current setup is working

  TROUBLESHOOT
  5. Diagnose issues         - Run diagnostics and suggest fixes
  6. View configuration      - Show current .mcp.json and CLAUDE.md entries
  7. Reset configuration     - Remove current setup and start fresh

  8. Exit                    - Keep current setup

Select option (1-8):
\`\`\`

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

| Check | Method | Pass Condition |
|-------|--------|----------------|
| .mcp.json exists | File read | File present |
| Vendor entry present | JSON parse | Key exists |
| JSON valid | Parse attempt | No errors |
| Env vars defined | Check .mcp.json env section | Variables have values |
| MCP loaded | Check available tools | Vendor tools present |
| Test operation | Execute test | Returns valid data |

**For CLI integrations:**

| Check | Method | Pass Condition |
|-------|--------|----------------|
| CLI tool installed | Run `{tool} --version` | Command succeeds |
| Env vars set | Check shell environment | Variables have values |
| Test operation | Execute CLI command | Returns valid data |

**For File-based integrations:**

| Check | Method | Pass Condition |
|-------|--------|----------------|
| CLI tools installed | Run `{tool} --version` | Commands succeed |
| Config files exist | File read | Files present |
| Config syntax valid | Parse attempt | No errors |
| Key files exist | File read | Files present at expected paths |
| Env vars set | Check shell environment | Variables have values |
| Test operation | Execute test command | Returns valid data |

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

When a progress file exists (setup was interrupted):

\`\`\`
{Domain Name} Setup - Resume
============================

Found incomplete setup from {timestamp}

Progress:
  Vendor: {selected_vendor}
  Current Phase: Phase {N} - {phase_name}
  Completed: {completed_steps}

Would you like to:
1. Resume from Phase {N}
2. Start over (discard progress)
3. Exit

>
\`\`\`

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

\`\`\`
How would you like to integrate {vendor}?

  1. MCP Integration (Recommended)
     - Tools available directly in Claude
     - Auto-refresh, seamless experience

  2. CLI/File-based Integration
     - Uses native tools and config files
     - More control, works offline

Select option (1-2):
\`\`\`

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
- If exists, add/update "{Domain Name}" section

#### Step 2: Generate Documentation

{claude_md_template}

#### Step 3: Cleanup Progress File

\`\`\`bash
rm {domain_key}-setup-progress.md
\`\`\`

#### Step 4: Summarize Completion

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
| Vendor | {Feature1} | {Feature2} | {Feature3} | Notes |
|--------|------------|------------|------------|-------|
| **{Vendor1}** | {support} | {support} | {support} | {notes} |
| **{Vendor2}** | {support} | {support} | {support} | {notes} |
```

For excluded vendors table:

```markdown
| Vendor | Why Excluded |
|--------|--------------|
| {Vendor1} | {reason} |
| {Vendor2} | {reason} |
```

For integration options table:

```markdown
| Vendor | Integration | Method Details | Auth Type |
|--------|-------------|----------------|-----------|
| **{Vendor1}** | MCP | Official: {url} | {auth_types} |
| **{Vendor2}** | MCP | Community: {package} | {auth_types} |
| **{Vendor3}** | File-based | Config: {config_files} | {auth_types} |
| **{Vendor4}** | CLI | Tools: {cli_tools} | {auth_types} |
| **{Vendor5}** | MCP / CLI | Primary: MCP, Alt: CLI | {auth_types} |
```

### Vendor Selection Display Generation

```
Which {domain_name} tool would you like to integrate?

All options support: {feature_list}

  1. {Vendor1}     - {vendor1_notes}
                    Best for: {use_case}
                    {key_feature}: {description}

  2. {Vendor2}     - {vendor2_notes}
                    Best for: {use_case}
                    {key_feature}: {description}

Enter number or name:
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
| Entity | Description | Vendor Mapping |
|--------|-------------|----------------|
| ticket | Support ticket | Jira → Issue |
| agent  | Support agent  | Jira → User  |
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

---

## Related Skills

- `/setup-task-manager` - Task management setup (example of generated skill)
- `/create-tool-skills` - Create enable/use/disable skill sets
- `/setup-mcp` - Generic MCP setup wizard
- `/setup-vault` - Vault-specific setup
- `/setup-slack-bot` - Slack-specific setup
