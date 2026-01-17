---
name: secrets
description: Unified secrets management skill. Reads CLAUDE.md to detect configured secrets backend (Vault, SOPS/age, MCP) and performs get/set/list/delete operations using the appropriate method.
---

# Secrets Management Skill

This skill provides a unified interface for secrets management by detecting the configured backend from CLAUDE.md and routing operations to the appropriate tool.

## How It Works

1. **Read CLAUDE.md** to detect which secrets management is configured
2. **Determine the backend** (Vault, SOPS/age, environment-based, or MCP)
3. **Execute the requested operation** using the appropriate method
4. **Return results** in a consistent format

## Supported Backends

| Backend                | Detection                                             | Operations                      |
| ---------------------- | ----------------------------------------------------- | ------------------------------- |
| **HashiCorp Vault**    | `## Secrets Management` → `### HashiCorp Vault`       | CLI commands (`vault kv ...`)   |
| **SOPS/age**           | `## Secrets Management` → `### SOPS with age`         | SOPS CLI (`sops --decrypt ...`) |
| **Environment/.env**   | `## Secrets Management` → `### Environment Variables` | Read/write `.env` files         |
| **MCP Secrets Server** | `## MCP Servers` → secrets-related MCP                | MCP tool calls                  |

## Workflow

### Phase 1: Detect Backend

1. **Read CLAUDE.md from project root**

   ```bash
   cat CLAUDE.md
   ```

2. **Parse for secrets configuration**
   Look for these sections in order of priority:

   a. **HashiCorp Vault**

   ```markdown
   ## Secrets Management

   ### HashiCorp Vault

   - **Status**: Configured
   - **Address**: http://127.0.0.1:8200
   - **Auth method**: Token
   ```

   b. **SOPS/age**

   ```markdown
   ## Secrets Management

   ### SOPS with age Encryption

   - **Status**: Configured
   - **Config file**: `.sops.yaml`
   - **Encrypted files pattern**: secrets/\*.yaml
   ```

   c. **Environment Variables**

   ```markdown
   ## Secrets Management

   ### Environment Variables

   - **Status**: Configured
   - **File**: `.env`
   ```

   d. **MCP-based secrets**

   ```markdown
   ## MCP Servers

   ### Secrets / 1Password / etc.

   - **Status**: Configured
   ```

3. **If no backend detected**
   - Inform user: "No secrets management configured in CLAUDE.md"
   - Suggest running one of the setup skills:
     - `setup-vault`
     - `setup-sops-age`
   - Ask if they want to set one up now

### Phase 2: Parse User Request

Understand what operation the user wants:

| Operation  | Keywords                         | Examples                    |
| ---------- | -------------------------------- | --------------------------- |
| **Get**    | get, read, fetch, show, retrieve | "get the database password" |
| **Set**    | set, write, store, put, save     | "set API_KEY to xyz123"     |
| **List**   | list, show all, enumerate        | "list all secrets"          |
| **Delete** | delete, remove, unset            | "delete the old token"      |

**Extract from request:**

- Operation type (get/set/list/delete)
- Secret path or key name
- Value (for set operations)
- Options (format, namespace, etc.)

### Phase 3: Execute Operation

Based on detected backend, execute the appropriate commands:

---

## Backend: HashiCorp Vault

**Configuration needed from CLAUDE.md:**

- `VAULT_ADDR` - Server address
- Auth method and credentials location

**Ensure environment is set:**

```bash
# Load from .env if specified
source .env 2>/dev/null || true

# Or check environment variables are set
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

### Get Secret

```bash
# Get entire secret
vault kv get secret/<path>

# Get specific field
vault kv get -field=<field> secret/<path>

# Get as JSON
vault kv get -format=json secret/<path>
```

### Set Secret

```bash
# Set single key-value
vault kv put secret/<path> <key>=<value>

# Set multiple
vault kv put secret/<path> key1=value1 key2=value2

# Patch (update without overwriting)
vault kv patch secret/<path> <key>=<value>
```

### List Secrets

```bash
# List paths
vault kv list secret/

# List recursively (no native support, iterate)
vault kv list secret/<path>/
```

### Delete Secret

```bash
# Soft delete (can recover)
vault kv delete secret/<path>

# Permanent delete
vault kv destroy -versions=all secret/<path>
```

---

## Backend: SOPS/age

**Configuration needed from CLAUDE.md:**

- Encrypted files pattern (e.g., `secrets/*.yaml`)
- Config file location (`.sops.yaml`)

**Determine secrets file:**

- Check for pattern in CLAUDE.md
- Default to `secrets/secrets.yaml` or `secrets.enc.yaml`

### Pre-flight Check (REQUIRED before any SOPS operation)

Before running any SOPS decrypt/encrypt command, verify the environment is configured:

```bash
# Check if SOPS_AGE_KEY_FILE is set
if [ -z "$SOPS_AGE_KEY_FILE" ] && [ -z "$SOPS_AGE_KEY" ]; then
  echo "ERROR: No SOPS age key configured"
fi

# Verify the key file exists (if using SOPS_AGE_KEY_FILE)
if [ -n "$SOPS_AGE_KEY_FILE" ]; then
  ls -la "$SOPS_AGE_KEY_FILE"
fi
```

**If not configured, guide the user:**

```
⚠️ SOPS age key not found in environment.

SOPS needs to know where your age private key is located.

To fix this, add to your shell profile (~/.zshrc or ~/.bashrc):

  export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

Then reload your shell:

  source ~/.zshrc

Or set it for this session only:

  export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

**Only proceed with SOPS operations after confirming the key is accessible.**

### Get Secret

```bash
# Get all secrets (decrypted)
sops --decrypt secrets/secrets.yaml

# Get specific value
sops --decrypt --extract '["<path>"]["<key>"]' secrets/secrets.yaml

# For nested paths like database.password
sops --decrypt --extract '["database"]["password"]' secrets/secrets.yaml
```

### Set Secret

SOPS doesn't support direct key setting. Workflow:

1. **Decrypt to temp file or edit in place**

   ```bash
   sops secrets/secrets.yaml
   # Opens in $EDITOR, modify the value, save
   ```

2. **Or programmatic update:**

   ```bash
   # Decrypt
   sops --decrypt secrets/secrets.yaml > /tmp/secrets.yaml

   # Modify (use yq or similar)
   yq -i '.<path>.<key> = "<value>"' /tmp/secrets.yaml

   # Re-encrypt
   sops --encrypt /tmp/secrets.yaml > secrets/secrets.yaml

   # Clean up
   rm /tmp/secrets.yaml
   ```

3. **Ask user to confirm** before making changes

### List Secrets

```bash
# Show structure (keys visible even when encrypted)
cat secrets/secrets.yaml | grep -v "ENC\[" | grep -v "sops:"

# Or decrypt and show keys
sops --decrypt secrets/secrets.yaml | yq 'keys'
```

### Delete Secret

1. Edit the file with `sops secrets/secrets.yaml`
2. Remove the key
3. Save (automatically re-encrypts)

---

## Backend: Environment Variables / .env

**Configuration needed from CLAUDE.md:**

- `.env` file location (default: `.env`)

### Get Secret

```bash
# From .env file
grep "^<KEY>=" .env | cut -d'=' -f2-

# From environment
echo $<KEY>
```

### Set Secret

```bash
# Add or update in .env
if grep -q "^<KEY>=" .env; then
  sed -i '' "s/^<KEY>=.*/<KEY>=<value>/" .env
else
  echo "<KEY>=<value>" >> .env
fi
```

### List Secrets

```bash
# List all keys (not values for security)
grep -v "^#" .env | cut -d'=' -f1 | grep -v "^$"
```

### Delete Secret

```bash
# Remove from .env
sed -i '' "/^<KEY>=/d" .env
```

---

## Backend: MCP Secrets Server

**Configuration needed from CLAUDE.md:**

- MCP server name for secrets
- Available tools

**Use MCP tools directly:**

- The MCP server provides tools for secrets operations
- Call the appropriate MCP tool based on operation

### Example MCP Tools

```
# These depend on the specific MCP server configured
mcp_secrets_get(path="database/password")
mcp_secrets_set(path="api/key", value="xyz123")
mcp_secrets_list(prefix="database/")
mcp_secrets_delete(path="old/secret")
```

---

## Response Format

Always return results in a consistent format:

### Success - Get

```
✓ Secret retrieved: <path>

Value: <value>
```

Or for sensitive values:

```
✓ Secret retrieved: <path>

Value: ******* (hidden)
Use --show to display value
```

### Success - Set

```
✓ Secret stored: <path>

Backend: [Vault / SOPS / .env]
```

### Success - List

```
✓ Secrets in <path>:

- database/username
- database/password
- api/key
- api/secret

Total: 4 secrets
```

### Success - Delete

```
✓ Secret deleted: <path>

Backend: [Vault / SOPS / .env]
```

### Error

```
✗ Failed to <operation> secret: <path>

Error: <error message>
Backend: [Vault / SOPS / .env]

Suggestions:
- <suggestion 1>
- <suggestion 2>
```

---

## Interactive Behavior

### When Backend Not Detected

```
I couldn't find a secrets management configuration in CLAUDE.md.

Would you like to set one up?
1. HashiCorp Vault (recommended for teams)
2. SOPS with age (recommended for git-based secrets)
3. Environment variables only (simple, local)
```

### When Multiple Backends Configured

```
I found multiple secrets backends configured:
1. HashiCorp Vault
2. SOPS/age

Which one should I use for this operation?
```

### Confirmation for Destructive Operations

```
⚠️ You're about to delete secret: database/password

This action cannot be undone. Continue? (yes/no)
```

### Confirmation for Set Operations

```
You're about to set secret: api/key

Backend: Vault
Path: secret/myapp/api/key
Value: [hidden - 32 characters]

Proceed? (yes/no)
```

---

## Security Considerations

1. **Never echo secret values in logs**
   - Use `--show` flag to explicitly reveal
   - Default to masked output

2. **Confirm destructive operations**
   - Always ask before delete
   - Show what will be affected

3. **Validate backend connection**
   - Check connectivity before operations
   - Provide helpful errors if auth fails

4. **Audit trail**
   - Note that Vault provides audit logging
   - SOPS changes tracked in git
   - .env changes are local only

---

## Error Handling

### Backend-Specific Errors

**Vault Errors:**
| Error | Cause | Solution |
|-------|-------|----------|
| `permission denied` | Token lacks access | Check policy, get new token |
| `connection refused` | Vault not running | Start Vault or check address |
| `missing client token` | Not authenticated | Run `vault login` or set `VAULT_TOKEN` |

**SOPS Errors:**
| Error | Cause | Solution |
|-------|-------|----------|
| `no identity matched any of the recipients` | `SOPS_AGE_KEY_FILE` not set or key file not found | Set `export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt` in shell profile and reload |
| `no key found` | Private key missing | Check `~/.config/sops/age/keys.txt` exists |
| `MAC mismatch` | File corrupted/modified | Re-encrypt from source |
| `could not find common keys` | Wrong key for file | Check `.sops.yaml` recipients |

**.env Errors:**
| Error | Cause | Solution |
|-------|-------|----------|
| `file not found` | `.env` doesn't exist | Create it or check path |
| `permission denied` | File permissions | Check file permissions |

---

## Usage Examples

### Get a secret

```
User: "get the database password"
→ Detects Vault backend
→ Runs: vault kv get -field=password secret/myapp/database
→ Returns: ✓ Secret retrieved (value hidden)
```

### Set a secret

```
User: "store the API key ABC123 in api/key"
→ Detects SOPS backend
→ Edits secrets/secrets.yaml
→ Sets api.key = "ABC123"
→ Re-encrypts
→ Returns: ✓ Secret stored
```

### List secrets

```
User: "what secrets do we have?"
→ Detects .env backend
→ Reads .env file
→ Returns list of keys (not values)
```

### Delete a secret

```
User: "remove the old_api_key"
→ Confirms with user
→ Deletes from backend
→ Returns: ✓ Secret deleted
```
