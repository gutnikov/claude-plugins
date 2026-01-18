---
name: vault-use
description: Vault secrets operations skill. Performs get/set/list/delete operations on HashiCorp Vault secrets by detecting configuration from CLAUDE.md.
---

# Use HashiCorp Vault

This skill provides a unified interface for Vault secrets operations by detecting the configuration from CLAUDE.md and executing the appropriate commands.

## How It Works

1. **Read CLAUDE.md** to detect Vault configuration
2. **Verify connection** to Vault server
3. **Execute the requested operation**
4. **Return results** in a consistent format

## Backend Detection

**Read CLAUDE.md from project root and look for:**

```markdown
## Secrets Management

### HashiCorp Vault

- **Status**: Configured
- **Address**: http://127.0.0.1:8200
- **Auth method**: Token
- **Config location**: .env
```

**If Vault not detected:**

- Inform user: "No Vault configuration found in CLAUDE.md"
- Suggest running setup: "Would you like to set up Vault? Run `/vault-enable`"

## Pre-flight Check

Before any operation, ensure environment is configured:

```bash
# Load from .env if specified
source .env 2>/dev/null || true

# Check required variables
echo $VAULT_ADDR
echo $VAULT_TOKEN
```

**If not configured:**

```
⚠️ Vault environment not configured.

VAULT_ADDR or VAULT_TOKEN not set.

To fix this:
1. Check that Vault is configured in CLAUDE.md
2. Ensure your .env file contains VAULT_ADDR and VAULT_TOKEN
3. Or run: export VAULT_ADDR=<address> && export VAULT_TOKEN=<token>
```

## Operations

### Get Secret

**Parse from user request:**

- Secret path (e.g., "database/password", "api/key")
- Specific field (optional)

**Commands:**

```bash
# Get entire secret
vault kv get secret/<path>

# Get specific field
vault kv get -field=<field> secret/<path>

# Get as JSON
vault kv get -format=json secret/<path>
```

**Response:**

```
✓ Secret retrieved: database/password

Value: ******* (hidden)
```

Or with `--show` flag:

```
✓ Secret retrieved: database/password

Value: my-secret-password-123
```

### Set Secret

**Parse from user request:**

- Secret path
- Key-value pairs

**Commands:**

```bash
# Set single key-value
vault kv put secret/<path> <key>=<value>

# Set multiple
vault kv put secret/<path> key1=value1 key2=value2

# Patch (update without overwriting other keys)
vault kv patch secret/<path> <key>=<value>
```

**Confirmation before write:**

```
You're about to set secret: api/key

Backend: Vault
Path: secret/myapp/api/key
Value: [hidden - 32 characters]

Proceed? (yes/no)
```

**Response:**

```
✓ Secret stored: api/key

Backend: HashiCorp Vault
Path: secret/myapp/api/key
```

### List Secrets

**Commands:**

```bash
# List paths at root
vault kv list secret/

# List paths at specific location
vault kv list secret/<path>/
```

**Response:**

```
✓ Secrets in secret/myapp/:

- database/
- api/
- cache/

Total: 3 paths
```

### Delete Secret

**Parse from user request:**

- Secret path to delete

**Confirmation required:**

```
⚠️ You're about to delete secret: database/password

This action cannot be undone. Continue? (yes/no)
```

**Commands:**

```bash
# Soft delete (can recover with undelete)
vault kv delete secret/<path>

# Permanent delete (all versions)
vault kv destroy -versions=all secret/<path>
```

**Response:**

```
✓ Secret deleted: database/password

Backend: HashiCorp Vault
```

## Response Format

### Success - Get

```
✓ Secret retrieved: <path>

Value: ******* (hidden)
```

### Success - Set

```
✓ Secret stored: <path>

Backend: HashiCorp Vault
```

### Success - List

```
✓ Secrets in <path>:

- database/username
- database/password
- api/key

Total: 3 secrets
```

### Success - Delete

```
✓ Secret deleted: <path>

Backend: HashiCorp Vault
```

### Error

```
✗ Failed to <operation> secret: <path>

Error: <error message>
Backend: HashiCorp Vault

Suggestions:
- <suggestion 1>
- <suggestion 2>
```

## Error Handling

### Common Issues

**"connection refused" error:**
- Vault server not running
- Wrong address/port
- Firewall blocking connection

**"permission denied" error:**
- Token doesn't have access to path
- Policy doesn't allow operation
- Token expired

**"seal status: sealed" error:**
- Vault needs to be unsealed
- In production, requires unseal keys
- Dev server should auto-unseal

**"token not found" or "missing client token":**
- `VAULT_TOKEN` not set
- Token file `~/.vault-token` not present
- Need to authenticate first

**KV v1 vs v2 path issues:**
- KV v2 requires `/data/` in path for API
- CLI handles this automatically with `kv` commands
- Check secrets engine version: `vault secrets list`

### Error Table

| Error                  | Cause              | Solution                               |
| ---------------------- | ------------------ | -------------------------------------- |
| `permission denied`    | Token lacks access | Check policy, get new token            |
| `connection refused`   | Vault not running  | Start Vault or check address           |
| `missing client token` | Not authenticated  | Run `vault login` or set `VAULT_TOKEN` |

## Interactive Checkpoints

- [ ] Confirm before destructive operations (delete)
- [ ] Confirm before writing secrets (optional, can be skipped)

## Related Skills

- `/vault-enable` - Set up Vault for this project
- `/vault-disable` - Remove Vault configuration
