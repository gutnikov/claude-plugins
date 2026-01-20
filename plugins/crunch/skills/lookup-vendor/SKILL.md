---
name: lookup-vendor
description: Shared vendor discovery service. Searches for vendor information (MCP, CLI, API) and returns normalized data that other skills can consume.
---

# Lookup Vendor

A shared skill that discovers and provides vendor information in a normalized format. Other domain skills (setup-secrets, setup-task-management, etc.) call this skill instead of implementing their own vendor discovery logic.

---

## Purpose

This skill serves as a **vendor registry service** for the entire skill ecosystem:

| Consumer Skill          | Calls lookup-vendor to get...                    |
|-------------------------|--------------------------------------------------|
| `setup-secrets`         | SOPS, Vault, AWS Secrets Manager, Doppler info   |
| `setup-task-management` | Jira, Linear, Trello, Asana info                 |
| `setup-ci-cd`           | GitHub Actions, GitLab CI, CircleCI info         |
| `setup-observability`   | Datadog, Grafana, New Relic info                 |
| Any new domain skill    | Any vendor in that domain                        |

---

## Operations

### 1. Discover Vendors for Domain

Find all known vendors for a specific domain.

**Input:**

```yaml
operation: "discover"
domain: "secrets"           # Required: domain key
refresh: false              # Optional: force refresh from web
```

**Process:**

1. Check cache for domain: `cache/{domain}/`
2. If cached and not refresh → return cached vendors
3. If not cached or refresh → search web for "{domain} tools comparison {year}"
4. Parse results into normalized schema
5. Cache results
6. Return vendor list

**Output:**

```yaml
vendors:
  - name: "SOPS + age"
    key: "sops-age"
    description: "File-based encryption using SOPS with age keys"
    best_for: "Git-friendly encrypted files"
    has_mcp: false
    has_cli: true
    has_api: false
  - name: "HashiCorp Vault"
    key: "vault"
    description: "Centralized secrets management"
    best_for: "Enterprise, dynamic secrets"
    has_mcp: true
    has_cli: true
    has_api: true
  # ... more vendors
```

---

### 2. Get Vendor Details

Get full details for a specific vendor.

**Input:**

```yaml
operation: "get"
domain: "secrets"           # Required
vendor: "vault"             # Required: vendor key or name
refresh: false              # Optional: force refresh
```

**Process:**

1. Check cache: `cache/{domain}/{vendor}.yaml`
2. If cached and not refresh → return cached definition
3. If not cached or refresh:
   a. Search "{vendor_name} CLI installation guide {year}"
   b. Search "{vendor_name} MCP server Model Context Protocol"
   c. Search "{vendor_name} API documentation"
   d. Parse and normalize results
   e. Cache result
4. Return full vendor definition

**Output:**

```yaml
# Full vendor definition per schema/vendor.schema.yaml
name: "HashiCorp Vault"
key: "vault"
domain: "secrets"
# ... complete normalized schema
```

---

### 3. Search for Vendor

Search for a vendor by name (fuzzy match).

**Input:**

```yaml
operation: "search"
query: "hashicorp"          # Search term
domain: "secrets"           # Optional: limit to domain
```

**Process:**

1. Search cache for matching vendors
2. If no match, search web: "{query} secrets management tool"
3. Return matches with confidence scores

**Output:**

```yaml
matches:
  - vendor: "vault"
    name: "HashiCorp Vault"
    domain: "secrets"
    confidence: 0.95
  - vendor: "consul"
    name: "HashiCorp Consul"
    domain: "service-discovery"
    confidence: 0.7
```

---

### 4. Validate Vendor Definition

Check if a vendor definition is complete and valid.

**Input:**

```yaml
operation: "validate"
vendor_definition: { ... }  # Vendor data to validate
```

**Output:**

```yaml
valid: true
missing_fields: []
warnings:
  - "No MCP integration found - CLI only"
suggestions:
  - "Consider adding error_patterns for better troubleshooting"
```

---

## Web Search Strategy

### Domain Discovery Search

When discovering vendors for a domain:

```typescript
// Primary search - comparison articles
WebSearch({
  query: `best ${domain} tools CLI ${currentYear} comparison`
})

// Secondary search - specific to developer tools
WebSearch({
  query: `${domain} management tools for developers ${currentYear}`
})

// Extract from results:
// - Vendor names
// - Brief descriptions
// - Key differentiators
```

### Vendor Detail Searches

When getting full details for a vendor:

```typescript
// 1. Installation & CLI
WebSearch({
  query: `${vendorName} CLI installation guide ${currentYear}`
})
// Extract: install commands, CLI tool name, version check command

// 2. MCP Integration
WebSearch({
  query: `${vendorName} MCP server Model Context Protocol`
})
// Extract: official MCP URL, community npm package

// 3. API Documentation
WebSearch({
  query: `${vendorName} API documentation REST`
})
// Extract: base URL, auth methods, OpenAPI spec URL

// 4. Authentication Methods
WebSearch({
  query: `${vendorName} authentication methods API token OAuth`
})
// Extract: supported auth types, env var names

// 5. Common Operations
WebSearch({
  query: `${vendorName} CLI commands cheat sheet`
})
// Extract: CRUD operations, command syntax
```

### Search Result Parsing

Extract structured data from search results:

```typescript
// Look for patterns in results:
const patterns = {
  // Installation commands
  install_brew: /brew install ([\w-]+)/,
  install_apt: /apt install ([\w-]+)/,
  install_npm: /npm install -g ([@\w/-]+)/,

  // Version check
  version_check: /([\w-]+) --version/,

  // MCP packages
  mcp_package: /@[\w-]+\/[\w-]+-mcp/,
  mcp_url: /https:\/\/[\w.]+\/mcp/,

  // API URLs
  api_base: /https:\/\/api\.[\w.]+/,

  // Environment variables
  env_vars: /([A-Z][A-Z0-9_]+)(?:=|:)/g,
};
```

---

## Caching

### Cache Structure

```
plugins/crunch/skills/lookup-vendor/cache/
├── _index.yaml                    # Cache metadata
├── secrets/
│   ├── _domain.yaml               # Domain vendor list
│   ├── sops-age.yaml              # Full vendor definitions
│   ├── vault.yaml
│   └── aws-secrets-manager.yaml
├── task-management/
│   ├── _domain.yaml
│   ├── jira.yaml
│   ├── linear.yaml
│   └── trello.yaml
└── ci-cd/
    ├── _domain.yaml
    └── github-actions.yaml
```

### Cache Index (`_index.yaml`)

```yaml
# cache/_index.yaml
last_updated: "2024-01-20T10:30:00Z"
domains:
  secrets:
    vendor_count: 5
    last_refresh: "2024-01-20T10:30:00Z"
  task-management:
    vendor_count: 4
    last_refresh: "2024-01-19T15:00:00Z"
```

### Domain Cache (`{domain}/_domain.yaml`)

```yaml
# cache/secrets/_domain.yaml
domain: secrets
last_refresh: "2024-01-20T10:30:00Z"
refresh_trigger: "web_search"       # web_search | manual | api

vendors:
  - key: sops-age
    name: "SOPS + age"
    cached: true
  - key: vault
    name: "HashiCorp Vault"
    cached: true
  - key: aws-secrets-manager
    name: "AWS Secrets Manager"
    cached: true
```

### Vendor Cache (`{domain}/{vendor}.yaml`)

```yaml
# cache/secrets/vault.yaml
# Full vendor definition per schema
_cache_metadata:
  created: "2024-01-20T10:30:00Z"
  source: "web_search"
  search_queries:
    - "HashiCorp Vault CLI installation guide 2024"
    - "HashiCorp Vault MCP server"
  confidence: 0.9

name: "HashiCorp Vault"
key: "vault"
domain: "secrets"
# ... rest of normalized schema
```

### Cache Operations

#### Read from Cache

```bash
# Check if vendor is cached
test -f "plugins/crunch/skills/lookup-vendor/cache/{domain}/{vendor}.yaml"

# Read cached vendor
cat "plugins/crunch/skills/lookup-vendor/cache/{domain}/{vendor}.yaml"
```

#### Write to Cache

```bash
# Ensure directory exists
mkdir -p "plugins/crunch/skills/lookup-vendor/cache/{domain}"

# Write vendor definition
cat > "plugins/crunch/skills/lookup-vendor/cache/{domain}/{vendor}.yaml" << 'EOF'
{normalized_vendor_yaml}
EOF

# Update domain index
# ... update _domain.yaml with new vendor entry
```

#### Cache Invalidation

Cache is considered stale after 30 days or when:
- User explicitly requests refresh
- Installation command fails (triggers re-search)
- MCP check fails (triggers MCP-specific re-search)

```typescript
function isCacheStale(cacheMetadata) {
  const thirtyDaysAgo = Date.now() - (30 * 24 * 60 * 60 * 1000);
  return new Date(cacheMetadata.created) < thirtyDaysAgo;
}
```

---

## Normalized Vendor Schema

All vendor definitions follow the schema in `schema/vendor.schema.yaml`.

**Key sections:**

| Section        | Purpose                                      |
|----------------|----------------------------------------------|
| `identity`     | Name, key, domain, description               |
| `integrations` | MCP, CLI, API configurations                 |
| `setup`        | Installation, auth, config files             |
| `operations`   | Available commands/methods                   |
| `testing`      | How to verify setup works                    |
| `errors`       | Known error patterns and solutions           |

See `schema/vendor.schema.yaml` for the complete schema definition.

---

## Usage by Consumer Skills

### How to Call lookup-vendor

Consumer skills should invoke lookup-vendor operations by reading this skill's instructions and following the patterns:

```markdown
## Vendor Discovery (in consumer skill)

Before presenting vendor selection, call the lookup-vendor skill:

### Step 1: Discover Available Vendors

Invoke lookup-vendor with:
- operation: "discover"
- domain: "{this_skill_domain}"

This returns a list of vendors with summary info for selection UI.

### Step 2: Get Vendor Details

After user selects a vendor, invoke lookup-vendor with:
- operation: "get"
- domain: "{this_skill_domain}"
- vendor: "{selected_vendor_key}"

This returns the full vendor definition needed for setup.

### Step 3: Handle Unknown Vendors

If user selects "Other", invoke lookup-vendor with:
- operation: "search"
- query: "{user_provided_name}"
- domain: "{this_skill_domain}"

This searches for the vendor and returns matches or creates a new definition.
```

### Example Consumer Integration

```markdown
## In setup-secrets SKILL.md

### Phase 0.5: Vendor Discovery

**Invoke lookup-vendor skill:**

"I need to discover available secrets management vendors.
Using lookup-vendor with operation=discover, domain=secrets"

**Expected response format:**

vendors:
  - name: "SOPS + age"
    key: "sops-age"
    best_for: "Git-friendly encrypted files"
    has_mcp: false
    has_cli: true
  - name: "HashiCorp Vault"
    key: "vault"
    best_for: "Enterprise, dynamic secrets"
    has_mcp: true
    has_cli: true

**Build selection UI from response.**
```

---

## Domain Registry

Known domains and their vendor categories:

| Domain               | Key                    | Typical Vendors                        |
|----------------------|------------------------|----------------------------------------|
| Secrets Management   | `secrets`              | SOPS, Vault, AWS SM, Doppler, 1Password|
| Task Management      | `task-management`      | Jira, Linear, Trello, Asana, GitHub    |
| CI/CD                | `ci-cd`                | GitHub Actions, GitLab CI, CircleCI    |
| Observability        | `observability`        | Datadog, Grafana, New Relic, Honeycomb |
| Documentation        | `documentation`        | Notion, Confluence, GitBook            |
| Communication        | `communication`        | Slack, Discord, Teams                  |
| Source Control       | `source-control`       | GitHub, GitLab, Bitbucket              |
| Container Registry   | `container-registry`   | Docker Hub, ECR, GCR, ACR              |
| Cloud Provider       | `cloud-provider`       | AWS, GCP, Azure                        |

---

## Error Handling

### Discovery Errors

| Error                        | Cause                     | Recovery                              |
|------------------------------|---------------------------|---------------------------------------|
| No vendors found             | Empty search results      | Try broader search terms              |
| Web search failed            | Network/rate limit        | Use cached data if available          |
| Parse error                  | Unexpected result format  | Return partial data with warnings     |

### Cache Errors

| Error                        | Cause                     | Recovery                              |
|------------------------------|---------------------------|---------------------------------------|
| Cache file corrupted         | Invalid YAML              | Delete and re-fetch                   |
| Cache directory missing      | First run                 | Create directory structure            |
| Permission denied            | File system issue         | Fall back to in-memory only           |

---

## Interactive Prompts

When discovery needs user input:

### Ambiguous Vendor Match

```typescript
AskUserQuestion({
  questions: [{
    question: "Found multiple matches for '{query}'. Which did you mean?",
    header: "Vendor",
    options: matches.map(m => ({
      label: m.name,
      description: `${m.domain} - ${m.description}`
    })),
    multiSelect: false
  }]
})
```

### Incomplete Information

```typescript
AskUserQuestion({
  questions: [{
    question: "I found {vendor} but couldn't determine all details. What's missing?",
    header: "Info",
    options: [
      { label: "CLI installation command", description: "How to install the CLI tool" },
      { label: "Authentication method", description: "How to authenticate" },
      { label: "Search again", description: "Try different search terms" },
      { label: "I'll provide details", description: "Let me fill in the gaps" }
    ],
    multiSelect: true
  }]
})
```

### Save to Cache Confirmation

```typescript
AskUserQuestion({
  questions: [{
    question: "Save {vendor} to cache for future use?",
    header: "Cache",
    options: [
      { label: "Yes, save it", description: "Cache for faster access next time" },
      { label: "No, just use it now", description: "Don't persist to disk" }
    ],
    multiSelect: false
  }]
})
```

---

## Definition of Done

A vendor lookup is complete when:

1. Vendor is found (from cache or web search)
2. Definition includes at least one integration method (MCP, CLI, or API)
3. Definition includes test operation to verify setup
4. Definition is validated against schema
5. Definition is cached (unless user declines)
