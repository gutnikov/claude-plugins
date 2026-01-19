---
name: sops-age-use
description: SOPS secrets operations skill. Performs encrypt/decrypt/edit operations on files using SOPS with age encryption by detecting configuration from CLAUDE.md.
---

# Use SOPS with age

This skill provides a unified interface for SOPS encryption operations by detecting the configuration from CLAUDE.md and executing the appropriate commands.

## How It Works

1. **Read CLAUDE.md** to detect SOPS+age configuration
2. **Verify environment** (SOPS_AGE_KEY_FILE set, key accessible)
3. **Execute the requested operation**
4. **Return results** in a consistent format

## Backend Detection

**Read CLAUDE.md from project root and look for:**

```markdown
## Secrets Management

### SOPS with age Encryption

- **Status**: Configured
- **Public key**: age1xxxxxxxxx...
- **Key location**: ~/.config/sops/age/keys.txt
- **Config file**: .sops.yaml
```

**If SOPS+age not detected:**

- Inform user: "No SOPS+age configuration found in CLAUDE.md"
- Suggest running setup: "Would you like to set up SOPS+age? Run `/sops-age-enable`"

## Pre-flight Check

Before any operation, ensure environment is configured:

```bash
# Check environment variable
echo $SOPS_AGE_KEY_FILE

# Check key file exists
ls -la ~/.config/sops/age/keys.txt

# Check sops is installed
sops --version

# Check .sops.yaml exists (optional but recommended)
ls -la .sops.yaml
```

**If not configured:**

```
WARNING SOPS+age environment not configured.

SOPS_AGE_KEY_FILE not set or key file not found.

To fix this:
1. Set environment variable: export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
2. Or run `/sops-age-enable` to set up SOPS+age
```

## Operations

### Encrypt File

**Parse from user request:**
- File path (required)
- Output path (optional, defaults to in-place or stdout)
- Specific recipients (optional, uses .sops.yaml if available)

**Commands:**

```bash
# With .sops.yaml configured (recommended)
sops --encrypt --in-place <file>

# Encrypt to stdout
sops --encrypt <file>

# Encrypt to specific output file
sops --encrypt <file> > <output-file>

# Without .sops.yaml (specify key)
sops --encrypt --age age1xxxxx... <file>
```

**Confirmation (optional):**

```
You're about to encrypt: secrets/config.yaml

This will:
- Encrypt all values in the file
- Keep keys (structure) visible
- Use recipients from .sops.yaml

Proceed? (yes/no)
```

**Response:**

```
OK File encrypted: secrets/config.yaml

Encrypted values: 5
Recipients: 2
File size: 1.2KB -> 2.8KB
```

### Decrypt File

**Parse from user request:**
- File path (required)
- Output mode (stdout, in-place, or to file)
- Specific key extraction (optional)

**Commands:**

```bash
# Decrypt to stdout (default, safe)
sops --decrypt <file>

# Decrypt in place
sops --decrypt --in-place <file>

# Decrypt to specific file
sops --decrypt <file> > <output-file>

# Extract specific value
sops --decrypt --extract '["database"]["password"]' <file>
```

**Response:**

```
OK File decrypted: secrets/config.yaml

Output: stdout
Values decrypted: 5

WARNING Decrypted content shown above. Do not commit decrypted files.
```

### Edit Encrypted File

**Parse from user request:**
- File path (required)

**Commands:**

```bash
# Opens in $EDITOR, decrypted, re-encrypts on save
sops <file>
```

**Response:**

```
OK Opening secrets/config.yaml for editing

Editor: $EDITOR (vim)
Note: File will be decrypted for editing and re-encrypted when you save.

After editing, the file has been re-encrypted automatically.
```

### Extract Value

**Parse from user request:**
- File path (required)
- Key path (required, e.g., database.password or ["database"]["password"])

**Commands:**

```bash
sops --decrypt --extract '["database"]["password"]' <file>
```

**Response:**

```
OK Extracted value from secrets/config.yaml

Path: database.password
Value: ******* (hidden)
```

Or with `--show` flag:

```
OK Extracted value from secrets/config.yaml

Path: database.password
Value: supersecretpassword
```

### List Encrypted Files

**Parse from user request:**
- Directory path (optional, defaults to current)
- Pattern (optional)

**Commands:**

```bash
# Find encrypted files (they contain sops metadata)
grep -l "sops:" secrets/*.yaml 2>/dev/null

# Or check for ENC[ prefix
grep -l "ENC\[" secrets/*.yaml 2>/dev/null
```

**Response:**

```
OK Encrypted files in secrets/:

1. secrets/config.yaml (encrypted)
2. secrets/api-keys.yaml (encrypted)
3. secrets/database.yaml (encrypted)

Total: 3 encrypted files
```

### Update Recipients

**Parse from user request:**
- File path (required)

**Commands:**

```bash
# Re-encrypt with updated .sops.yaml recipients
sops updatekeys <file>
```

**Response:**

```
OK Recipients updated: secrets/config.yaml

Previous recipients: 2
New recipients: 3
Added: age1newmember...
```

### Rotate Keys

**Parse from user request:**
- File path or pattern (required)

**Commands:**

```bash
# Rotate data key (re-encrypt with same recipients)
sops --rotate --in-place <file>
```

**Response:**

```
OK Keys rotated: secrets/config.yaml

Data key regenerated.
All values re-encrypted with new data key.
```

### Verify File

**Parse from user request:**
- File path (required)

**Commands:**

```bash
# Check if file is encrypted and valid
sops --decrypt --output-type json <file> > /dev/null 2>&1 && echo "Valid" || echo "Invalid"
```

**Response:**

```
OK File verification: secrets/config.yaml

Status: Valid encrypted file
Recipients: 2
  - age1xxxxx... (your key)
  - age1yyyyy... (team member)
Last modified: 2024-01-15T10:30:00Z
```

## Response Format

### Success - Read Operations

```
OK {Operation} complete: {file}

{Details}
```

### Success - Write Operations

```
OK {Action}: {file}

{Details}
Backend: SOPS+age
```

### Error

```
X Failed to {operation}: {file}

Error: {error message}
Backend: SOPS+age

Suggestions:
- {suggestion 1}
- {suggestion 2}
```

## Error Handling

### Common Issues

**"no identity matched any of the recipients" error:**

```bash
# Check if SOPS_AGE_KEY_FILE is set
echo $SOPS_AGE_KEY_FILE

# If empty, set it:
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

**"could not find common encryption keys" error:**
- `.sops.yaml` path_regex doesn't match the file
- Use `--age` flag to specify key explicitly

**"MAC mismatch" error:**
- File was modified after encryption
- Re-encrypt from a known good decrypted source

**"failed to get the data key" error:**
- You're not a recipient of this file
- Ask file owner to add your public key and re-encrypt

### Error Table

| Error                       | Cause                    | Solution                              |
| --------------------------- | ------------------------ | ------------------------------------- |
| `no identity matched`       | SOPS_AGE_KEY_FILE not set| Set environment variable              |
| `could not find common keys`| .sops.yaml mismatch      | Check path regex, use --age flag      |
| `MAC mismatch`              | File corrupted/modified  | Re-encrypt from source                |
| `failed to get data key`    | Not a recipient          | Ask owner to add your public key      |
| `file not found`            | Wrong path               | Verify file path                      |

## Interactive Checkpoints

- [ ] Confirm before encrypting files (optional)
- [ ] Confirm before decrypting in-place (recommended)
- [ ] Warn when showing decrypted content

## Security Reminders

When using this skill:

1. **Never commit decrypted files** - Use `sops --decrypt` to stdout, not in-place
2. **Encrypted files ARE safe to commit** - Values are encrypted, only keys visible
3. **Private key must stay private** - Never share `keys.txt`
4. **Public keys can be shared** - Add team members via .sops.yaml

## Usage Examples

**Encrypt a file:**
```
/sops-age-use encrypt secrets/config.yaml
```

**Decrypt to stdout:**
```
/sops-age-use decrypt secrets/config.yaml
```

**Edit encrypted file:**
```
/sops-age-use edit secrets/config.yaml
```

**Extract a specific value:**
```
/sops-age-use extract database.password from secrets/config.yaml
```

**Update recipients after .sops.yaml change:**
```
/sops-age-use updatekeys secrets/config.yaml
```

**List encrypted files:**
```
/sops-age-use list secrets/
```

## File Format Reference

### Before Encryption (YAML)

```yaml
database:
  host: localhost
  password: supersecret
api_key: abc123
```

### After Encryption

```yaml
database:
  host: localhost
  password: ENC[AES256_GCM,data:abc123...,iv:...,tag:...,type:str]
api_key: ENC[AES256_GCM,data:xyz789...,iv:...,tag:...,type:str]
sops:
  age:
    - recipient: age1xxxxx...
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2024-01-15T10:30:00Z"
  mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
  version: 3.8.1
```

## Related Skills

- `/sops-age-enable` - Set up SOPS+age
- `/sops-age-disable` - Remove SOPS+age configuration
