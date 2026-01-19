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
| **Required Features** | Features vendors MUST have | Tasks, Tags, Statuses, Dependencies |
| **CLAUDE.md Section** | Section header | `## Task Management` |
| **MCP Key Pattern** | Keys in .mcp.json | `jira`, `asana`, `linear` |

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
| **Code Quality** | `code-quality` | Static analysis and security | Lint, Analyze, Security Scan | SonarQube, CodeClimate, Snyk |
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

  7. Code Quality        - Static analysis and security
                          Features: Lint, Format, Analyze
                          Vendors: SonarQube, CodeClimate, Snyk

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

### Secret Management

```yaml
domain_name: "Secret Management"
domain_key: "secret-manager"
purpose: "Securely store, retrieve, and manage secrets and credentials"
required_features:
  - Get secrets
  - Set secrets
  - List secrets
  - Delete secrets
claude_section: "## Secrets Management"

vendors:
  - name: "HashiCorp Vault"
    key: "vault"
    features: [Get, Set, List, Delete, Versioning, Audit]
    official_mcp: null
    community_mcp: "vault-mcp"
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
    features: [Get, Set, List, Delete]
    official_mcp: null
    community_mcp: "sops-mcp"
    auth: ["age keys"]
    test_op: "sops -d secrets.enc.yaml"
    notes: "File-based, git-friendly"
    credential_update:
      api_token:
        env_vars: ["SOPS_AGE_KEY_FILE"]
        regenerate_url: "N/A (local key file)"
        instructions: "Update path to age key file or regenerate keys with age-keygen"

  - name: "AWS Secrets Manager"
    key: "aws-secrets"
    features: [Get, Set, List, Delete, Versioning, Rotation]
    official_mcp: null
    community_mcp: "aws-mcp"
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

### Code Quality

```yaml
domain_name: "Code Quality"
domain_key: "code-quality"
purpose: "Static analysis, linting, and security scanning"
required_features:
  - Analyze code
  - Report issues
  - Track quality metrics
claude_section: "## Code Quality"

vendors:
  - name: "SonarQube"
    key: "sonarqube"
    features: [Analysis, Issues, Metrics, Quality Gates]
    official_mcp: null
    community_mcp: "sonarqube-mcp"
    auth: ["Token"]
    test_op: "list_projects"
    notes: "Comprehensive code quality"
    credential_update:
      api_token:
        env_vars: ["SONARQUBE_URL", "SONARQUBE_TOKEN"]
        regenerate_url: "SonarQube instance > My Account > Security > Tokens"
        instructions: "Generate new user token in SonarQube user security settings"

  - name: "CodeClimate"
    key: "codeclimate"
    features: [Analysis, Issues, Metrics, Trends]
    official_mcp: null
    community_mcp: "codeclimate-mcp"
    auth: ["API Token"]
    test_op: "list_repos"
    notes: "Quality and maintainability"
    credential_update:
      api_token:
        env_vars: ["CODECLIMATE_API_TOKEN"]
        regenerate_url: "https://codeclimate.com/profile/tokens"
        instructions: "Generate new Personal Access Token in CodeClimate profile"

  - name: "Snyk"
    key: "snyk"
    features: [Security Scan, Vulnerabilities, Dependencies]
    official_mcp: null
    community_mcp: "snyk-mcp"
    auth: ["API Token"]
    test_op: "list_projects"
    notes: "Security-focused scanning"
    credential_update:
      api_token:
        env_vars: ["SNYK_TOKEN"]
        regenerate_url: "https://app.snyk.io/account"
        instructions: "Generate new API token in Snyk Account Settings"

  - name: "Semgrep"
    key: "semgrep"
    features: [Analysis, Security, Custom Rules]
    official_mcp: null
    community_mcp: "semgrep-mcp"
    auth: ["API Token", "None (OSS)"]
    test_op: "list_rules"
    notes: "Fast, customizable analysis"
    credential_update:
      api_token:
        env_vars: ["SEMGREP_APP_TOKEN"]
        regenerate_url: "https://semgrep.dev/orgs/-/settings/tokens"
        instructions: "Generate new token in Semgrep App Organization Settings (or use without token for OSS)"

excluded:
  - name: "ESLint/Prettier alone"
    reason: "No centralized tracking, no quality metrics"
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
2. MCP is configured (official OAuth or community with API token)
3. User successfully executes a test operation
4. CLAUDE.md is updated with "{Domain Name}" section documenting capabilities

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

## MCP Options by Vendor

{mcp_options_table}

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

- [x] Phase 0: Check Existing
- [x] Phase 1: Vendor Selection
- [x] Phase 1.5: Scenario Collection (custom only)
- [x] Phase 1.6: Model Extraction (custom only)
- [ ] Phase 2: Domain Configuration <- CURRENT
- [ ] Phase 2.5: Vendor Suggestion (custom only)
- [ ] Phase 3: Check Existing Skill
- [ ] Phase 4: Generate Setup Skill
- [ ] Phase 5: Verification

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
- **MCP Type**: {Official / Community}
- **MCP Package/URL**: {value}
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
  MCP: {package or URL}
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

**Use case:** API token expired, OAuth needs refresh, or user got new credentials.

#### Workflow Display

\`\`\`
Update Credentials
------------------

Current vendor: {vendor}
MCP type: {Official OAuth | Community (API Token)}
\`\`\`

**For OAuth MCPs:**

\`\`\`
To re-authenticate:
1. I'll update .mcp.json to force re-auth
2. Restart Claude Code
3. Complete OAuth flow in browser

Proceed with OAuth refresh? (yes/no)
>
\`\`\`

**For API Token MCPs:**

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

#### Steps

1. Detect current MCP type (OAuth vs API token)
2. For OAuth: Update config to trigger re-auth on reload
3. For API tokens: Collect new values, update .mcp.json env section
4. Instruct reload:
   \`\`\`
   Credentials updated in .mcp.json

   Please restart Claude Code to apply changes.
   After restart, run this skill again to verify the connection.
   \`\`\`
5. After reload: Run connection test to verify

---

### Mode C: Test Connection (Option 4)

**Use case:** Quick health check without changing anything.

#### Workflow Display

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

#### Test Operations by Vendor

{test_operations_table}

---

### Mode D: Diagnose Issues (Option 5)

**Use case:** Something isn't working, user needs help figuring out why.

#### Diagnostic Checklist Display

\`\`\`
Diagnostics: {Domain Name}
==========================

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

#### Diagnostic Checks

| Check | Method | Pass Condition |
|-------|--------|----------------|
| .mcp.json exists | File read | File present |
| Vendor entry present | JSON parse | Key exists |
| JSON valid | Parse attempt | No errors |
| Env vars defined | Check .mcp.json env section | Variables have values |
| MCP loaded | Check available tools | Vendor tools present |
| Test operation | Execute test | Returns valid data |

#### Common Diagnostic Scenarios

**Scenario: 401 Unauthorized**
- Likely cause: API token expired or invalid
- Fix: Regenerate token, run Update credentials

**Scenario: MCP not loaded**
- Likely cause: .mcp.json syntax error or missing dependency
- Fix: Validate JSON, check npx availability

**Scenario: Connection timeout**
- Likely cause: Network issue or service down
- Fix: Check network, verify service status

---

### Mode E: View Configuration (Option 6)

**Use case:** User wants to see what's configured without changing anything.

#### Display Format

\`\`\`
Configuration View: {Domain Name}
=================================

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
...
\`\`\`

Files:
  - .mcp.json: {path}
  - CLAUDE.md: {path}
  - Progress file: {exists | not found}

Press Enter to continue...
\`\`\`

**Security Note:** Always mask sensitive values (show only last 4 characters).

---

### Mode F: Reset Configuration (Option 7)

**Use case:** User wants to completely remove setup and start fresh.

#### Workflow Display

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

#### Steps

1. Show what will be removed
2. Require explicit confirmation (user must type "RESET")
3. If confirmed:
   a. Remove MCP entry from .mcp.json
   b. Remove section from CLAUDE.md
   c. Delete progress file if exists
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

### Phase 1: Vendor Selection

Present qualified vendors with feature highlights:

{vendor_selection_display}

**After vendor selection, create progress file.**

**DOD:** User selects a vendor

---

### Phase 2: MCP Selection

Based on selected vendor, present MCP options:

{mcp_selection_by_vendor}

**Update progress file with MCP selection**

**DOD:** User selects an MCP type

---

### Phase 3: MCP Setup

Setup varies based on MCP type (Official OAuth vs Community Local).

#### For Official Remote MCPs (OAuth-based)

1. **Configure `.mcp.json` with remote URL:**

{official_mcp_configs}

2. **Instruct user to restart Claude Code**

3. **After reload, OAuth flow will trigger automatically**

#### For Community Local MCPs (API Token-based)

{community_mcp_setup_guides}

#### Verify .gitignore

\`\`\`bash
grep -q "^\.mcp\.json$" .gitignore 2>/dev/null
\`\`\`

- If `.mcp.json` is not in `.gitignore`, offer to add it

#### Update Progress File for Reload

Update to indicate pending reload and resume point.

#### Instruct User to Reload

\`\`\`
MCP configuration written to .mcp.json

Claude Code needs to reload to activate the {Vendor} MCP.

Please restart Claude Code, then run this skill again.
Progress has been saved - setup will resume from the connection test.
\`\`\`

**DOD:** MCP configured, user instructed to reload

---

### Phase 4: Connection Test

After Claude Code reload, verify MCP is working.

#### Step 1: Verify MCP is Loaded

- Check that vendor MCP tools are now available
- If not available, troubleshoot configuration

#### Step 2: Run Test Operation

{test_operations_table}

#### Step 3: Confirm with User

\`\`\`
Test successful! I was able to {describe what was retrieved}.

Did you see the expected data? Please confirm.
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

\`\`\`
{Vendor} {domain_name} setup complete!

Configuration Summary:
  - Vendor: {vendor}
  - MCP: {package or "Official OAuth"}
  - Config file: .mcp.json
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

### Phase 1 Checkpoints
- [ ] "Which vendor would you like to use?"

### Phase 2 Checkpoints
- [ ] "Official MCP (OAuth) or community option (API Token)?"

### Phase 3 Checkpoints
- [ ] "Credentials collected. Ready to configure?"
- [ ] "Configuration written. Ready to restart Claude Code?"

### Phase 4 Checkpoints
- [ ] "Test successful! Did you see the expected data?"

### Phase 5 Checkpoints
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

For MCP options table:

```markdown
| Vendor | Official MCP | Community MCP | Recommended | Auth Type |
|--------|--------------|---------------|-------------|-----------|
| **{Vendor1}** | {url or "None"} | {package or "None"} | {recommendation} | {auth_types} |
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
