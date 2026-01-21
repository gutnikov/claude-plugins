---
name: lookup-vendor
description: Vendor research service. Takes vendor name and requirements, returns a markdown report with integration options, requirement satisfaction, and verification tests.
---

# Lookup Vendor

A shared skill that researches a vendor and produces a structured markdown report showing how to integrate AI tools with the vendor, satisfy specific requirements, and verify the setup works.

---

## Input

```yaml
vendor_name: string           # Required: Vendor name (e.g., "HashiCorp Vault", "Linear", "Jira")
vendor_requirements:          # Required: List of capabilities the vendor must support
  - string                    # e.g., "It should allow to create a new secret"
  - string                    # e.g., "It should allow to read a secret value"
vendor_check:                 # Required: List of e2e verification steps
  - string                    # e.g., "Create a test secret named `_test` with value `test123`"
  - string                    # e.g., "Read the secret back and verify value matches"
```

### Example Input

```yaml
vendor_name: "HashiCorp Vault"
vendor_requirements:
  - It should allow to create a new secret
  - It should allow to read a secret value
  - It should allow to update an existing secret
  - It should allow to delete a secret
  - It should allow to list available secrets
  - It should allow to check whether a secret exists
vendor_check:
  - Create a test secret named `_claude_setup_test` with value `test123`
  - Read the secret back and verify value matches `test123`
  - List secrets and verify `_claude_setup_test` appears
  - Delete the test secret `_claude_setup_test`
  - Verify the secret no longer exists
```

---

## Process

### Step 1: Research Vendor Integrations

Search for vendor integration options:

```typescript
// 1. MCP Integration (highest priority)
WebSearch({ query: `${vendor_name} MCP server Model Context Protocol` })
WebSearch({ query: `${vendor_name} mcp npm package` })

// 2. API Documentation
WebSearch({ query: `${vendor_name} REST API documentation` })
WebSearch({ query: `${vendor_name} API reference` })

// 3. CLI Tools
WebSearch({ query: `${vendor_name} CLI installation` })
WebSearch({ query: `${vendor_name} command line tool` })
```

### Step 2: Map Requirements to Integration Methods

For each requirement:
1. Determine which integration methods can satisfy it
2. Prefer MCP over API over CLI
3. If combined approach needed, document all methods
4. Flag requirements that cannot be satisfied

**Priority Order**: MCP > API > CLI

**Combined Approaches**: If MCP covers 80% of requirements but CLI is needed for the rest, document both.

### Step 3: Generate Verification Commands

For each vendor_check item:
1. Generate actual executable commands
2. Use the best available integration method
3. Include expected output/success indicators

---

## Output

The skill produces a markdown report with three sections:

```markdown
# {Vendor Name} Integration Report

## A. Integration Options

### Available Methods

| Method | Available | Package/URL                    | Notes                        |
|--------|-----------|--------------------------------|------------------------------|
| MCP    | Yes/No    | `@org/package` or URL          | Preferred for AI integration |
| API    | Yes/No    | `https://api.vendor.com/v1`    | REST/GraphQL endpoints       |
| CLI    | Yes/No    | `vendor-cli`                   | Command-line tool            |

### Recommended Approach

{Description of recommended integration approach, explaining why}

### Setup Requirements

#### MCP Setup (if available)
{MCP configuration instructions}

#### CLI Setup (if needed)
{CLI installation and configuration}

#### API Setup (if needed)
{API authentication setup}

---

## B. Requirement Satisfaction

| Requirement                              | Supported | Method | Implementation                           |
|------------------------------------------|-----------|--------|------------------------------------------|
| It should allow to create a new secret   | Yes       | MCP    | Use `create_secret` tool                 |
| It should allow to read a secret value   | Yes       | MCP    | Use `get_secret` tool                    |
| ...                                      | ...       | ...    | ...                                      |

### Unsatisfied Requirements

{List any requirements that cannot be satisfied, with explanation}

### Detailed Implementation

#### {Requirement 1}
- **Method**: MCP / API / CLI
- **Command/Tool**: `{command or tool name}`
- **Example**:
  ```bash
  {example command}
  ```

{Repeat for each requirement}

---

## C. Verification Tests

### Test Commands

Execute these commands to verify the vendor setup works:

#### 1. {First check description}
```bash
{actual command}
```
**Expected**: {expected output or success indicator}

#### 2. {Second check description}
```bash
{actual command}
```
**Expected**: {expected output or success indicator}

{Continue for all vendor_check items}

### Full Test Script

```bash
#!/bin/bash
# {Vendor Name} Setup Verification
# Run this script to verify your setup is working

set -e

echo "Testing {Vendor Name} setup..."

# Test 1: {description}
{command}

# Test 2: {description}
{command}

# ... more tests

# Cleanup
{cleanup commands}

echo "All tests passed!"
```

---

## Summary

- **Integration**: {primary method} {+ secondary if combined}
- **Requirements**: {X}/{Y} satisfied
- **Status**: {Ready / Partial / Blocked}
```

---

## Example Output

```markdown
# HashiCorp Vault Integration Report

## A. Integration Options

### Available Methods

| Method | Available | Package/URL                              | Notes                          |
|--------|-----------|------------------------------------------|--------------------------------|
| MCP    | Yes       | `mcp-vault` (community)                  | Preferred for AI integration   |
| API    | Yes       | `http://127.0.0.1:8200/v1`               | Full REST API                  |
| CLI    | Yes       | `vault`                                  | Comprehensive CLI tool         |

### Recommended Approach

Use **MCP + CLI** combination:
- MCP (`mcp-vault`) for primary secret operations (create, read, update, delete, list)
- CLI for existence checks (MCP lacks dedicated exists check)

This provides the best AI integration while covering all requirements.

### Setup Requirements

#### MCP Setup
```json
// .mcp.json
{
  "mcpServers": {
    "vault": {
      "command": "npx",
      "args": ["-y", "mcp-vault"],
      "env": {
        "VAULT_ADDR": "http://127.0.0.1:8200",
        "VAULT_TOKEN": "${VAULT_TOKEN}"
      }
    }
  }
}
```

#### CLI Setup
```bash
# macOS
brew tap hashicorp/tap && brew install hashicorp/tap/vault

# Linux
sudo apt update && sudo apt install vault

# Verify installation
vault version
```

#### Environment Variables
```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="your-token-here"
```

---

## B. Requirement Satisfaction

| Requirement                                | Supported | Method | Implementation                             |
|--------------------------------------------|-----------|--------|--------------------------------------------|
| It should allow to create a new secret     | Yes       | MCP    | `create_secret` tool                       |
| It should allow to read a secret value     | Yes       | MCP    | `get_secret` tool                          |
| It should allow to update an existing secret | Yes     | MCP    | `update_secret` tool                       |
| It should allow to delete a secret         | Yes       | MCP    | `delete_secret` tool                       |
| It should allow to list available secrets  | Yes       | MCP    | `list_secrets` tool                        |
| It should allow to check whether a secret exists | Yes  | CLI    | `vault kv get` (check exit code)           |

### Unsatisfied Requirements

None - all requirements can be satisfied.

### Detailed Implementation

#### Create a new secret
- **Method**: MCP
- **Tool**: `create_secret`
- **Example**:
  ```
  Use the create_secret tool with path="secret/myapp" and data={"username": "admin", "password": "secret123"}
  ```
- **CLI Fallback**:
  ```bash
  vault kv put secret/myapp username=admin password=secret123
  ```

#### Read a secret value
- **Method**: MCP
- **Tool**: `get_secret`
- **Example**:
  ```
  Use the get_secret tool with path="secret/myapp"
  ```
- **CLI Fallback**:
  ```bash
  vault kv get secret/myapp
  ```

#### Update an existing secret
- **Method**: MCP
- **Tool**: `update_secret`
- **Example**:
  ```
  Use the update_secret tool with path="secret/myapp" and data={"password": "newpassword"}
  ```
- **CLI Fallback**:
  ```bash
  vault kv put secret/myapp username=admin password=newpassword
  ```

#### Delete a secret
- **Method**: MCP
- **Tool**: `delete_secret`
- **Example**:
  ```
  Use the delete_secret tool with path="secret/myapp"
  ```
- **CLI Fallback**:
  ```bash
  vault kv delete secret/myapp
  ```

#### List available secrets
- **Method**: MCP
- **Tool**: `list_secrets`
- **Example**:
  ```
  Use the list_secrets tool with path="secret/"
  ```
- **CLI Fallback**:
  ```bash
  vault kv list secret/
  ```

#### Check whether a secret exists
- **Method**: CLI (MCP lacks dedicated exists check)
- **Command**:
  ```bash
  vault kv get secret/myapp > /dev/null 2>&1 && echo "exists" || echo "not found"
  ```

---

## C. Verification Tests

### Test Commands

Execute these commands to verify the Vault setup works:

#### 1. Create a test secret named `_claude_setup_test` with value `test123`
```bash
vault kv put secret/_claude_setup_test value=test123
```
**Expected**: `Success! Data written to: secret/data/_claude_setup_test`

#### 2. Read the secret back and verify value matches `test123`
```bash
vault kv get -field=value secret/_claude_setup_test
```
**Expected**: `test123`

#### 3. List secrets and verify `_claude_setup_test` appears
```bash
vault kv list secret/ | grep _claude_setup_test
```
**Expected**: `_claude_setup_test` in output

#### 4. Delete the test secret `_claude_setup_test`
```bash
vault kv delete secret/_claude_setup_test
```
**Expected**: `Success! Data deleted (if it existed) at: secret/data/_claude_setup_test`

#### 5. Verify the secret no longer exists
```bash
vault kv get secret/_claude_setup_test 2>&1 | grep -q "No value found" && echo "Confirmed deleted" || echo "Still exists"
```
**Expected**: `Confirmed deleted`

### Full Test Script

```bash
#!/bin/bash
# HashiCorp Vault Setup Verification
# Run this script to verify your Vault setup is working

set -e

echo "Testing HashiCorp Vault setup..."

# Test 1: Create test secret
echo "1. Creating test secret..."
vault kv put secret/_claude_setup_test value=test123

# Test 2: Read and verify
echo "2. Reading secret back..."
VALUE=$(vault kv get -field=value secret/_claude_setup_test)
if [ "$VALUE" = "test123" ]; then
  echo "   Value matches!"
else
  echo "   ERROR: Value mismatch. Expected 'test123', got '$VALUE'"
  exit 1
fi

# Test 3: List secrets
echo "3. Listing secrets..."
vault kv list secret/ | grep -q _claude_setup_test || { echo "   ERROR: Secret not in list"; exit 1; }
echo "   Secret found in list!"

# Test 4: Delete secret
echo "4. Deleting test secret..."
vault kv delete secret/_claude_setup_test

# Test 5: Verify deletion
echo "5. Verifying deletion..."
if vault kv get secret/_claude_setup_test 2>&1 | grep -q "No value found"; then
  echo "   Secret successfully deleted!"
else
  echo "   WARNING: Secret may still exist"
fi

echo ""
echo "All tests passed! Vault setup is working correctly."
```

---

## Summary

- **Integration**: MCP (primary) + CLI (for exists check)
- **Requirements**: 6/6 satisfied
- **Status**: Ready
```

---

## Handling Unsatisfied Requirements

When a requirement cannot be satisfied, clearly document it:

```markdown
### Unsatisfied Requirements

| Requirement                                | Reason                                    | Workaround                              |
|--------------------------------------------|-------------------------------------------|-----------------------------------------|
| It should allow to audit secret access     | Requires Enterprise license               | Enable audit device manually            |
| It should allow to rotate secrets auto     | Not exposed via MCP/CLI                   | Use API directly or scheduled jobs      |
```

---

## Web Search Strategy

### MCP Discovery

```typescript
// Search for MCP packages
WebSearch({ query: `${vendor} MCP server npm` })
WebSearch({ query: `${vendor} Model Context Protocol github` })

// Look for patterns:
// - npm package names: @org/vendor-mcp, mcp-vendor, vendor-mcp-server
// - GitHub repos: */vendor-mcp, */mcp-vendor
```

### API Discovery

```typescript
// Search for API docs
WebSearch({ query: `${vendor} REST API documentation` })
WebSearch({ query: `${vendor} API reference endpoints` })

// Look for:
// - Base URL patterns: api.vendor.com, vendor.com/api
// - OpenAPI/Swagger specs
// - Authentication methods
```

### CLI Discovery

```typescript
// Search for CLI tools
WebSearch({ query: `${vendor} CLI tool installation` })
WebSearch({ query: `${vendor} command line reference` })

// Look for:
// - Package managers: brew install, apt install, npm install -g
// - Binary names
// - Common commands
```

---

## Definition of Done

The vendor lookup is complete when:

1. All three integration methods (MCP, API, CLI) have been researched
2. Each vendor_requirement has a satisfaction status and implementation
3. Each vendor_check has executable commands with expected outputs
4. Unsatisfied requirements are clearly flagged with reasons
5. A full test script is provided for verification
